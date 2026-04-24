//! Apple Blocks runtime: stack-allocated block layout, heap copy/release, and typed helpers.
//!
//! ## Usage
//!
//! 1. Pick a **captures** struct (fields become part of the block layout after the runtime header).
//! 2. Call `Block(Captures, extra_param_types, ReturnType)` — second argument is a **type tuple** of
//!    parameters after `*const Context` (use `.{}` when the callback only receives `ctx`).
//! 3. Implement the callback as **`callconv(.c)`**, first parameter **`*const B.Context`**, then any
//!    extra parameters matching the tuple. Pass it to **`B.init`**; **`B.invoke`** takes `&ctx` and a
//!    **value tuple** for the extra args (`.{}` if there are none).
//!
//! ### Example: captures only (stack block)
//!
//! ```zig
//! const std = @import("std");
//! const block = @import("block.zig"); // or `core.block` from your root module
//!
//! const AddBlock = block.Block(struct { a: i32, b: i32 }, .{}, i32);
//!
//! var ctx = AddBlock.init(.{ .a = 2, .b = 3 }, (struct {
//!     fn run(self: *const AddBlock.Context) callconv(.c) i32 {
//!         return self.a + self.b;
//!     }
//! }).run);
//!
//! const sum = AddBlock.invoke(&ctx, .{}); // 5
//! _ = sum;
//! ```
//!
//! ### Example: extra invocation arguments
//!
//! ```zig
//! const ScaleBlock = block.Block(struct { k: i32 }, .{c_int}, i32);
//!
//! var ctx = ScaleBlock.init(.{ .k = 10 }, (struct {
//!     fn run(self: *const ScaleBlock.Context, n: c_int) callconv(.c) i32 {
//!         return self.k * @as(i32, @intCast(n));
//!     }
//! }).run);
//!
//! const product = ScaleBlock.invoke(&ctx, .{7}); // 70 — tuple matches `.{c_int}`
//! _ = product;
//! ```
//!
//! ### Example: heap copy (store or hand off lifetime)
//!
//! ```zig
//! var stack_ctx = AddBlock.init(.{ .a = 1, .b = 2 }, (struct {
//!     fn run(self: *const AddBlock.Context) callconv(.c) i32 {
//!         return self.a + self.b;
//!     }
//! }).run);
//!
//! const heap = try AddBlock.copy(&stack_ctx);
//! defer AddBlock.release(heap); // only for pointers from `copy`
//!
//! _ = AddBlock.invoke(heap, .{});
//! ```
//!
//! - **`init`** — **Stack** block ([`NSConcreteStackBlock`]); safe to `invoke` while `ctx` lives.
//! - **`copy` / `release`** — `_Block_copy` / `_Block_release`. **`release` only** values returned by
//!   `copy`; never `release` the stack `Context` from `init`.
//!
//! ## Stack vs heap
//!
//! - After `init`, the block is a **stack** block until something copies it (your `copy` call, or an
//!   API that copies blocks when passing them into ObjC/C).
//! - After `copy`, `isa` is a **malloc** block ([`NSConcreteMallocBlock`]); captures may have been
//!   relocated; use the returned pointer for further `invoke`/`release` as appropriate.
//!
//! ## `types.id` captures
//!
//! Fields typed exactly as [`types.id`](./types.zig) are handled in copy/dispose helpers via
//! `_Block_object_assign` / `_Block_object_dispose`. They are **not** retained when you only call
//! `init`; retention happens when the block is **copied**. Use [`types.id`](./types.zig) for captured
//! NSObject pointers, not wrapper structs.
//!
//! ## Caveats
//!
//! - **Lifetime:** Treat stack contexts like C stack blocks; do not use them after the frame ends if
//!   ownership is unclear. Prefer `copy` + `release` for async or stored blocks.
//! - **Struct returns:** `stret` is set when `Return` is a struct; large struct returns may still
//!   need platform-specific validation beyond small-struct tests.
//! - **`release`:** Passing a non-heap block to `release` is undefined (debug `assert` checks `isa`).

const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;

const types = @import("./types.zig");
const utils = @import("./utils/root.zig");

/// Block descriptor: size, optional copy/dispose helpers, and ObjC type encoding string.
const Descriptor = extern struct {
    reserved: c_ulong = 0,
    size: c_ulong,
    copy_helper: *const fn (dst: *anyopaque, src: *anyopaque) callconv(.c) void,
    dispose_helper: *const fn (src: *anyopaque) callconv(.c) void,
    signature: ?[*:0]const u8,
};

/// Block `flags` word (see Apple `Block_private.h`).
const BlockFlags = packed struct(c_int) {
    _unused: u23 = 0,
    no_escape: bool = false,
    _unused_2: u1 = 0,
    copy_dispose: bool = false,
    ctor: bool = false,
    _unused_3: u1 = 0,
    global: bool = false,
    stret: bool = false,
    signature: bool = false,
    _unused_4: u1 = 0,
};

/// Flags for `_Block_object_assign` / `_Block_object_dispose`.
const BlockFieldFlags = enum(c_int) {
    object = 3,
    block = 7,
    by_ref = 8,
    weak = 16,
    by_ref_caller = 128,
};

extern fn _Block_copy(src: *const anyopaque) callconv(.c) ?*anyopaque;
extern fn _Block_release(src: *const anyopaque) callconv(.c) void;
extern fn _Block_object_assign(dst: *anyopaque, src: *const anyopaque, flag: BlockFieldFlags) callconv(.c) void;
extern fn _Block_object_dispose(src: *const anyopaque, flag: BlockFieldFlags) callconv(.c) void;

/// Linker symbol: `isa` value for a **stack** block (until copied).
pub const NSConcreteStackBlock = @extern(*opaque {}, .{ .name = "_NSConcreteStackBlock" });
/// Linker symbol: `isa` value for a **heap** (malloc) block after `_Block_copy`.
pub const NSConcreteMallocBlock = @extern(*opaque {}, .{ .name = "_NSConcreteMallocBlock" });

/// Layout of the first fields of a block, then capture fields. See [`Block`].
fn BlockContext(comptime Captures: type, comptime InvokeFn: type) type {
    const captures_info = @typeInfo(Captures).@"struct";
    var fields: [captures_info.fields.len + 5]std.builtin.Type.StructField = undefined;
    fields[0] = .{
        .name = "isa",
        .type = *const anyopaque,
        .default_value_ptr = null,
        .is_comptime = false,
        .alignment = @alignOf(*const anyopaque),
    };
    fields[1] = .{
        .name = "flags",
        .type = BlockFlags,
        .default_value_ptr = null,
        .is_comptime = false,
        .alignment = @alignOf(c_int),
    };
    fields[2] = .{
        .name = "reserved",
        .type = c_int,
        .default_value_ptr = null,
        .is_comptime = false,
        .alignment = @alignOf(c_int),
    };
    fields[3] = .{
        .name = "invoke",
        .type = *const InvokeFn,
        .default_value_ptr = null,
        .is_comptime = false,
        .alignment = @typeInfo(*const InvokeFn).pointer.alignment,
    };
    fields[4] = .{
        .name = "descriptor",
        .type = *const Descriptor,
        .default_value_ptr = null,
        .is_comptime = false,
        .alignment = @alignOf(*const Descriptor),
    };

    for (captures_info.fields, 5..) |capture, i| {
        switch (capture.type) {
            comptime_int => @compileError("capture should not be a comptime_int, try using @as"),
            comptime_float => @compileError("capture should not be a comptime_float, try using @as"),
            else => {},
        }
        fields[i] = .{ .name = capture.name, .type = capture.type, .default_value_ptr = null, .is_comptime = false, .alignment = capture.alignment };
    }

    var field_names: [fields.len][]const u8 = undefined;
    var field_types: [fields.len]type = undefined;
    var field_attrs: [fields.len]std.builtin.Type.StructField.Attributes = undefined;
    for (fields, 0..) |field, i| {
        field_names[i] = field.name;
        field_types[i] = field.type;
        field_attrs[i] = .{ .@"align" = field.alignment };
    }

    return @Struct(.@"extern", null, &field_names, &field_types, &field_attrs);
}

/// Returns an anonymous struct type with `Captures`, `Fn`, `Context`, and `init` / `invoke` / `copy` / `release`.
///
/// - **`CapturesArg`**: struct of captured variables (embeds after the standard block header).
/// - **`Args`**: tuple of **extra** parameter types passed at invoke, e.g. `.{c_int}` or `.{}`.
/// - **`Return`**: callback return type; use `callconv(.c)` on the implementation.
///
/// Only fields with type exactly [`types.id`](./types.zig) get retain/release in copy/dispose.
pub fn Block(
    comptime CapturesArg: type,
    comptime Args: anytype,
    comptime Return: type,
) type {
    return struct {
        const Self = @This();
        const captures_info = @typeInfo(Captures).@"struct";
        const InvokeFn = FnType(anyopaque);
        const descriptor: Descriptor = .{
            .reserved = 0,
            .size = @sizeOf(Context),
            .copy_helper = &descCopyHelper,
            .dispose_helper = &descDisposeHelper,
            .signature = &utils.comptimeEncode(InvokeFn),
        };

        /// C calling convention: `fn (*const Context, ...) Return`.
        pub const Fn = FnType(Context);

        /// Capture struct type.
        pub const Captures = CapturesArg;

        /// Extern layout: header + captures. First argument to the invoke function.
        pub const Context = BlockContext(Captures, InvokeFn);

        /// Builds a **stack** block. NSObject (`types.id`) captures are not retained until [`copy`].
        ///
        /// Prefer letting ObjC copy the block when passing it across the boundary, or pair [`copy`]
        /// with [`release`] for manual heap ownership.
        pub fn init(captures: Captures, func: *const Fn) Context {
            var ctx: Context = undefined;
            ctx.isa = @ptrCast(NSConcreteStackBlock);
            ctx.flags = .{
                .copy_dispose = true,
                .stret = @typeInfo(Return) == .@"struct",
                .signature = true,
            };
            ctx.invoke = @ptrCast(func);
            ctx.descriptor = &descriptor;
            inline for (captures_info.fields) |field| {
                @field(ctx, field.name) = @field(captures, field.name);
            }

            return ctx;
        }

        /// Runs the block with `args` as the tuple of invocation arguments after `ctx`.
        pub fn invoke(ctx: *const Context, args: anytype) Return {
            return @call(
                .auto,
                ctx.invoke,
                .{ctx} ++ args,
            );
        }

        /// Heap-copy via `_Block_copy`. **Must** be paired with [`release`] on the returned pointer.
        /// Errors with `error.OutOfMemory` if copy fails.
        pub fn copy(ctx: *const Context) Allocator.Error!*Context {
            const copied = _Block_copy(@ptrCast(@alignCast(ctx))) orelse
                return error.OutOfMemory;
            return @ptrCast(@alignCast(copied));
        }

        /// **`copy` results only.** Debug build asserts `isa == NSConcreteMallocBlock`.
        pub fn release(ctx: *const Context) void {
            assert(@intFromPtr(ctx.isa) == @intFromPtr(NSConcreteMallocBlock));
            _Block_release(@ptrCast(@alignCast(ctx)));
        }

        fn descCopyHelper(dst: *anyopaque, src: *anyopaque) callconv(.c) void {
            const real_dst: *Context = @ptrCast(@alignCast(dst));
            const real_src: *Context = @ptrCast(@alignCast(src));
            inline for (captures_info.fields) |field| {
                if (field.type == types.id) {
                    _Block_object_assign(
                        @ptrCast(&@field(real_dst, field.name)),
                        @field(real_src, field.name),
                        .object,
                    );
                }
            }
        }

        fn descDisposeHelper(src: *anyopaque) callconv(.c) void {
            const real_src: *Context = @ptrCast(@alignCast(src));
            inline for (captures_info.fields) |field| {
                if (field.type == types.id) {
                    _Block_object_dispose(
                        @field(real_src, field.name),
                        .object,
                    );
                }
            }
        }

        fn FnType(comptime ContextArg: type) type {
            var param_types: [Args.len + 1]type = undefined;
            param_types[0] = *const ContextArg;
            for (Args, 1..) |Arg, i| param_types[i] = Arg;

            return @Fn(&param_types, &@splat(.{}), Return, .{ .@"callconv" = .c });
        }
    };
}

test "Block stack primitives invoke twice" {
    const AddBlock = Block(struct {
        x: i32,
        y: i32,
    }, .{}, i32);

    const captures: AddBlock.Captures = .{ .x = 2, .y = 3 };

    var stack_ctx = AddBlock.init(captures, (struct {
        fn addFn(block: *const AddBlock.Context) callconv(.c) i32 {
            return block.x + block.y;
        }
    }).addFn);

    try std.testing.expectEqual(@as(i32, 5), AddBlock.invoke(&stack_ctx, .{}));
    try std.testing.expectEqual(@as(i32, 5), AddBlock.invoke(&stack_ctx, .{}));
    try std.testing.expectEqual(@intFromPtr(stack_ctx.isa), @intFromPtr(NSConcreteStackBlock));
}

test "Block stack empty captures" {
    const ConstBlock = Block(struct {}, .{}, i32);

    var stack_ctx = ConstBlock.init(.{}, (struct {
        fn fn0(block: *const ConstBlock.Context) callconv(.c) i32 {
            _ = block;
            return 42;
        }
    }).fn0);

    try std.testing.expectEqual(@as(i32, 42), ConstBlock.invoke(&stack_ctx, .{}));
}

test "Block heap copy release and isa" {
    const MulBlock = Block(struct { a: i32 }, .{c_int}, i32);

    var stack_ctx = MulBlock.init(.{ .a = 6 }, (struct {
        fn mul(block: *const MulBlock.Context, b: c_int) callconv(.c) i32 {
            return block.a * @as(i32, @intCast(b));
        }
    }).mul);

    try std.testing.expectEqual(@intFromPtr(stack_ctx.isa), @intFromPtr(NSConcreteStackBlock));

    const heap = try MulBlock.copy(&stack_ctx);
    defer MulBlock.release(heap);

    try std.testing.expectEqual(@intFromPtr(heap.isa), @intFromPtr(NSConcreteMallocBlock));
    try std.testing.expectEqual(@as(i32, 42), MulBlock.invoke(heap, .{7}));
}

test "Block invocation extra arguments" {
    const SumBlock = Block(struct { k: i32 }, .{c_int}, i32);

    var stack_ctx = SumBlock.init(.{ .k = 10 }, (struct {
        fn sum(block: *const SumBlock.Context, n: c_int) callconv(.c) i32 {
            return block.k + @as(i32, @intCast(n));
        }
    }).sum);

    try std.testing.expectEqual(@as(i32, 32), SumBlock.invoke(&stack_ctx, .{22}));
}

test "Block struct return" {
    const Pair = extern struct {
        a: i32,
        b: i32,
    };

    const PairBlock = Block(struct { x: i32 }, .{}, Pair);

    var stack_ctx = PairBlock.init(.{ .x = 1 }, (struct {
        fn make(block: *const PairBlock.Context) callconv(.c) Pair {
            return .{ .a = block.x, .b = block.x + 10 };
        }
    }).make);

    const p = PairBlock.invoke(&stack_ctx, .{});
    try std.testing.expectEqual(@as(i32, 1), p.a);
    try std.testing.expectEqual(@as(i32, 11), p.b);
}

test "Block f64 return" {
    const FloatBlock = Block(struct { v: f64 }, .{}, f64);

    var stack_ctx = FloatBlock.init(.{ .v = 2.5 }, (struct {
        fn dbl(block: *const FloatBlock.Context) callconv(.c) f64 {
            return block.v * 2.0;
        }
    }).dbl);

    try std.testing.expectEqual(@as(f64, 5.0), FloatBlock.invoke(&stack_ctx, .{}));
}

test "Block copy id capture retain dispose" {
    const Object = @import("./object.zig");
    const AutoreleasePool = @import("./autorelease_pool.zig");

    var pool = AutoreleasePool.push();
    defer pool.pop();

    const cls = Object.getClassByName("NSObject") orelse return error.MissingNSObject;
    var obj = Object.alloc(cls);
    obj = Object.init(obj);
    defer Object.release(obj);

    const IdBlock = Block(struct {
        captured: types.id,
    }, .{}, types.id);

    var stack_ctx = IdBlock.init(.{ .captured = obj }, (struct {
        fn retId(block: *const IdBlock.Context) callconv(.c) types.id {
            return block.captured;
        }
    }).retId);

    const heap = try IdBlock.copy(&stack_ctx);
    defer IdBlock.release(heap);

    const out = IdBlock.invoke(heap, .{});
    try std.testing.expectEqual(obj, out);
}
