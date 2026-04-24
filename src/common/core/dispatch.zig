const std = @import("std");
const builtin = @import("builtin");

const Types = @import("./types.zig");
const Selector = @import("./selector.zig");

const id = Types.id;
const SEL = Types.SEL;
const ClassPtr = Types.ClassPtr;

/// Objective-C `nil` (address zero). Zig disallows `@ptrFromInt(0)` for `id`, so we materialize 0 in the return register.
fn nilId() id {
    return switch (builtin.cpu.arch) {
        .aarch64 => asm volatile ("mov %[ret], xzr"
            : [ret] "={x0}" (-> id),
        ),
        .x86_64 => asm volatile ("xor %[ret], %[ret]"
            : [ret] "={rax}" (-> id),
        ),
        else => @compileError("nilId: add asm for this arch or use a different nil strategy"),
    };
}

fn nilSel() SEL {
    return switch (builtin.cpu.arch) {
        .aarch64 => asm volatile ("mov %[ret], xzr"
            : [ret] "={x0}" (-> SEL),
        ),
        .x86_64 => asm volatile ("xor %[ret], %[ret]"
            : [ret] "={rax}" (-> SEL),
        ),
        else => @compileError("nilSel: add asm for this arch or use a different nil strategy"),
    };
}

// Runtime symbols; the typed pointer you cast to must match the message ABI (`.c` on the current target).
extern fn objc_msgSend() callconv(.c) void;
extern fn objc_msgSend_fpret() callconv(.c) void;

/// Strip `*const` / `*` so we can use `std.meta.ArgsTuple` and `@typeInfo(.@"fn")`.
fn bareFnType(comptime MaybePtrFn: type) type {
    return switch (@typeInfo(MaybePtrFn)) {
        .@"fn" => MaybePtrFn,
        .pointer => |ptr| switch (@typeInfo(ptr.child)) {
            .@"fn" => ptr.child,
            else => @compileError("expected pointer to function, got pointer to " ++ @typeName(ptr.child)),
        },
        else => @compileError("expected function type or *const fn, got " ++ @typeName(MaybePtrFn)),
    };
}

fn returnType(comptime MaybePtrFn: type) type {
    const bare = bareFnType(MaybePtrFn);
    return @typeInfo(bare).@"fn".return_type orelse
        @compileError("objc_msgSend wrapper requires an explicit return type on Fn");
}

fn assertCCallconv(comptime bare: type) void {
    const info = @typeInfo(bare).@"fn";
    const want = builtin.target.cCallingConvention().?;
    if (!std.meta.eql(info.calling_convention, want)) {
        @compileError("Fn must use C calling convention (`callconv(.c)`) for this target; use the same convention as C/ObjC objc_msgSend family");
    }
}

fn assertMsgSendSignature(comptime MaybePtrFn: type) void {
    const bare = bareFnType(MaybePtrFn);
    comptime assertCCallconv(bare);

    const info = @typeInfo(bare).@"fn";
    if (info.is_generic) @compileError("Fn must not be generic");
    if (info.is_var_args) @compileError("Fn must not be C-style variadic; use a fixed signature");
    if (info.params.len < 2) @compileError("Fn must be at least fn (id, SEL, ...)");

    const p0 = info.params[0].type orelse @compileError("first parameter (self) must have a concrete type");
    const p1 = info.params[1].type orelse @compileError("second parameter (_cmd) must have a concrete type");

    if (p0 != id and p0 != ClassPtr)
        @compileError("first parameter must be `id` (" ++ @typeName(id) ++ "), got " ++ @typeName(p0));

    if (p1 != SEL)
        @compileError("second parameter must be `SEL` (" ++ @typeName(SEL) ++ "), got " ++ @typeName(p1));
}

fn mergeRecvSelArgs(
    comptime MaybePtrFn: type,
    receiver: ?id,
    sel: ?SEL,
    rest: anytype,
) std.meta.ArgsTuple(bareFnType(MaybePtrFn)) {
    const recv = receiver orelse nilId();
    const cmd = sel orelse nilSel();

    const Bare = bareFnType(MaybePtrFn);
    const Args = std.meta.ArgsTuple(Bare);

    const rest_info = @typeInfo(@TypeOf(rest));

    if (rest_info != .@"struct" or !rest_info.@"struct".is_tuple) {
        @compileError("`args` must be a tuple, e.g. `.{}` or `.{ x, y }`");
    }

    comptime {
        const want = @typeInfo(Args).@"struct".fields.len;
        const got_rest = rest_info.@"struct".fields.len;
        if (want != 2 + got_rest) {
            @compileError(std.fmt.comptimePrint(
                "Fn expects {} arguments (including receiver + selector); `args` has {} value(s) (expected {})",
                .{ want, got_rest, want - 2 },
            ));
        }
    }

    var out: Args = undefined;
    const out_fields = @typeInfo(Args).@"struct".fields;
    const rest_fields = rest_info.@"struct".fields;

    inline for (out_fields, 0..) |field, i| {
        if (i == 0) {
            if (field.type == ClassPtr) {
                @field(out, field.name) = @ptrCast(recv);
                continue;
            }

            @field(out, field.name) = recv;
        } else if (i == 1) {
            @field(out, field.name) = cmd;
        } else {
            @field(out, field.name) = @field(rest, rest_fields[i - 2].name);
        }
    }

    return out;
}

fn msgSendWith(
    comptime Fn: type,
    comptime send: *const anyopaque,
    receiver: ?id,
    sel: ?SEL,
    args: anytype,
) returnType(Fn) {
    comptime assertMsgSendSignature(Fn);
    const f: Fn = @ptrCast(@alignCast(send));

    const call_args = mergeRecvSelArgs(Fn, receiver, sel, args);

    return @call(.auto, f, call_args);
}

/// Typed wrapper around `objc_msgSend` (scalar / normal returns).
///
/// `Fn` must be `*const fn (id, SEL, ...) callconv(.c) R` (or an equivalent bare `fn` type).
/// Pass additional message arguments as a **tuple** in `args` (use `.{}` when there are none).
///
/// `receiver` and `sel` may be `null` for Objective-C **nil** / null selector; behavior matches
/// `objc_msgSend` (e.g. messaging nil returns zero / null for most return types).
///
/// Example:
/// ```zig
/// const T = *const fn (id, SEL, c_int) callconv(.c) void;
/// msgSend(T, receiver, sel, .{@as(c_int, 42)});
/// ```
pub inline fn msgSend(comptime Fn: type, receiver: ?id, sel: ?SEL, args: anytype) returnType(Fn) {
    return msgSendWith(Fn, &objc_msgSend, receiver, sel, args);
}

/// Typed wrapper around `objc_msgSend_fpret` (legacy x86 float returns; on Apple Silicon the symbol exists for ABI compatibility—often equivalent to plain `msgSend`).
///
/// `receiver` / `sel` may be `null` (same as [`msgSend`]).
pub inline fn msgSendFpret(comptime Fn: type, receiver: ?id, sel: ?SEL, args: anytype) returnType(Fn) {
    return msgSendWith(Fn, &objc_msgSend_fpret, receiver, sel, args);
}

test {
    comptime {
        const MsgFn = *const fn (id, SEL, c_int) callconv(.c) c_int;
        assertMsgSendSignature(MsgFn);
        _ = std.meta.ArgsTuple(bareFnType(MsgFn));
        const ObjReturnFn = *const fn (id, SEL) callconv(.c) Types.objc_object;
        assertMsgSendSignature(ObjReturnFn);
        const FpretFn = *const fn (id, SEL) callconv(.c) f64;
        assertMsgSendSignature(FpretFn);

        const ClassAllocFn = *const fn (ClassPtr, SEL) callconv(.c) id;
        assertMsgSendSignature(ClassAllocFn);
        _ = std.meta.ArgsTuple(bareFnType(ClassAllocFn));

        const VoidFn = *const fn (id, SEL, c_int) callconv(.c) void;
        assertMsgSendSignature(VoidFn);
        _ = std.meta.ArgsTuple(bareFnType(VoidFn));

        const OptIdFn = *const fn (id, SEL) callconv(.c) ?id;
        assertMsgSendSignature(OptIdFn);
        _ = std.meta.ArgsTuple(bareFnType(OptIdFn));

        const PtrRetFn = *const fn (id, SEL) callconv(.c) *const u8;
        assertMsgSendSignature(PtrRetFn);

        const CmpFn = *const fn (id, SEL, id) callconv(.c) Types.NSComparisonResult;
        assertMsgSendSignature(CmpFn);
    }
}
