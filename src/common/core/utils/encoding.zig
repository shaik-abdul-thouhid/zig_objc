//! Objective-C **type encodings** (Apple’s `@encode` / runtime string format).
//!
//! These strings describe C and ObjC types for the runtime (method signatures, block `signature`,
//! etc.). See Apple’s [Type Encodings](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html).
//!
//! ## API
//!
//! - **`Encoding`**: `union(enum)` representing a type; use **`Encoding.init(T)`** to classify a Zig
//!   type, then **`format`** to write letters and composite forms (`i`, `d`, `@`, `#`, `:`, `^`,
//!   `{Name=...}`, `[Ni]`, …).
//! - **`comptimeEncode(T)`**: builds a **null-terminated** `[N:0]u8` at **comptime** (used e.g. by
//!   [`Block`](../block.zig) for the block descriptor’s `signature` field via
//!   [`utils/root.zig`](./root.zig)).
//!
//! `types.id`, `types.Class`, and `types.SEL` must match the aliases in [`types.zig`](../types.zig).
//! Because `Class` is an alias of `ObjCObject`, a bare `ObjCObject` value encodes like a class (`#`);
//! `id` (`*ObjCObject`) still encodes as `@`.
//!
//! ## Caveats
//!
//! - Unsupported types trigger **`@compileError`**.
//! - Struct and union nodes in encodings require **`extern`** layout (`format` asserts this).
//! - **`format`** only handles **single-item** pointers (`.one`); slices and other sizes error.
//! - **Function** encodings require **`callconv(.c)`**; order is **return type**, then each parameter.
//!
//! ## Tests
//!
//! From the repository root (macOS): `zig build test`

const std = @import("std");

const types = @import("../types.zig");

const assert = std.debug.assert;
const SEL = types.SEL;
const Class = types.Class;
const id = types.id;

fn indirectionCountAndType(comptime T: type) struct { child: type, indirection_levels: comptime_int } {
    var WalkType = T;
    var count: usize = 0;
    while (@typeInfo(WalkType) == .pointer) : (count += 1) {
        WalkType = @typeInfo(WalkType).pointer.child;
    }

    return .{ .child = WalkType, .indirection_levels = count };
}

/// Internal representation of a type’s Objective-C encoding, before formatting to a string.
pub const Encoding = union(enum) {
    char,
    int,
    short,
    long,
    longlong,
    uchar,
    uint,
    ushort,
    ulong,
    ulonglong,
    float,
    double,
    bool,
    void,
    char_string,
    object,
    class,
    selector,
    array: struct { arr_type: type, len: usize },
    structure: struct { struct_type: type, show_type_spec: bool },
    @"union": struct { union_type: type, show_type_spec: bool },
    bitfield: u32,
    pointer: struct { ptr_type: type, size: std.builtin.Type.Pointer.Size },
    function: std.builtin.Type.Fn,
    unknown,

    pub fn init(comptime T: type) Encoding {
        return switch (T) {
            i8, c_char => .char,
            c_short => .short,
            i32, c_int => .int,
            c_long => .long,
            i64, c_longlong => .longlong,
            u8 => .uchar,
            c_ushort => .ushort,
            u32, c_uint => .uint,
            c_ulong => .ulong,
            u64, c_ulonglong => .ulonglong,
            f32 => .float,
            f64 => .double,
            bool => .bool,
            void, anyopaque => .void,
            [*c]u8, [*c]const u8 => .char_string,
            SEL => .selector,
            Class => .class,
            id => .object,
            else => switch (@typeInfo(T)) {
                .@"opaque" => .void,
                .@"enum" => |m| .init(m.tag_type),
                .array => |arr| .{ .array = .{ .len = arr.len, .arr_type = arr.child } },
                .@"struct" => |m| switch (m.layout) {
                    .@"packed" => .init(m.backing_integer.?),

                    else => .{ .structure = .{ .struct_type = T, .show_type_spec = true } },
                },
                .@"union" => .{
                    .@"union" = .{ .union_type = T, .show_type_spec = true },
                },
                .optional => |m| switch (@typeInfo(m.child)) {
                    .pointer => |ptr| .{ .pointer = .{ .ptr_type = m.child, .size = ptr.size } },

                    else => @compileError("unsupported non-pointer optional type: " ++ @typeName(T)),
                },
                .pointer => |ptr| .{ .pointer = .{ .ptr_type = T, .size = ptr.size } },
                .@"fn" => |fn_info| .{ .function = fn_info },

                else => @compileError("unsupported type: " ++ @typeName(T)),
            },
        };
    }

    pub fn format(comptime self: Encoding, writer: *std.Io.Writer) !void {
        switch (self) {
            .char => try writer.writeAll("c"),
            .int => try writer.writeAll("i"),
            .short => try writer.writeAll("s"),
            .long => try writer.writeAll("l"),
            .longlong => try writer.writeAll("q"),
            .uchar => try writer.writeAll("C"),
            .uint => try writer.writeAll("I"),
            .ushort => try writer.writeAll("S"),
            .ulong => try writer.writeAll("L"),
            .ulonglong => try writer.writeAll("Q"),
            .float => try writer.writeAll("f"),
            .double => try writer.writeAll("d"),
            .bool => try writer.writeAll("B"),
            .void => try writer.writeAll("v"),
            .char_string => try writer.writeAll("*"),
            .object => try writer.writeAll("@"),
            .class => try writer.writeAll("#"),
            .selector => try writer.writeAll(":"),
            .array => |a| {
                try writer.print("[{}", .{a.len});
                const encode_type: Encoding = .init(a.arr_type);
                try encode_type.format(writer);
                try writer.writeAll("]");
            },
            .structure => |s| {
                const struct_info = @typeInfo(s.struct_type);
                assert(struct_info.@"struct".layout == .@"extern");

                // Strips the fully qualified type name to leave just the
                // type name. Used in naming the Struct in an encoding.
                var type_name_iter = std.mem.splitBackwardsScalar(u8, @typeName(s.struct_type), '.');
                const type_name = type_name_iter.first();
                try writer.print("{{{s}", .{type_name});

                // if the encoding should show the internal type specification
                // of the struct (determined by levels of pointer indirection)
                if (s.show_type_spec) {
                    try writer.writeAll("=");
                    inline for (struct_info.@"struct".fields) |field| {
                        const field_encode: Encoding = .init(field.type);
                        try field_encode.format(writer);
                    }
                }

                try writer.writeAll("}");
            },
            .@"union" => |u| {
                const union_info = @typeInfo(u.union_type);
                assert(union_info.@"union".layout == .@"extern");

                // Strips the fully qualified type name to leave just the
                // type name. Used in naming the Union in an encoding
                var type_name_iter = std.mem.splitBackwardsScalar(u8, @typeName(u.union_type), '.');
                const type_name = type_name_iter.first();
                try writer.print("({s}", .{type_name});

                // if the encoding should show the internal type specification
                // of the Union (determined by levels of pointer indirection)
                if (u.show_type_spec) {
                    try writer.writeAll("=");
                    inline for (union_info.@"union".fields) |field| {
                        const field_encode: Encoding = .init(field.type);
                        try field_encode.format(writer);
                    }
                }

                try writer.writeAll(")");
            },
            .bitfield => |b| try writer.print("b{}", .{b}), // not sure if needed from Zig -> Obj-C
            .pointer => |p| {
                switch (p.size) {
                    .one => {
                        // get the pointer info (count of levels of direction
                        // and the underlying type)
                        const pointer_info = indirectionCountAndType(p.ptr_type);
                        for (0..pointer_info.indirection_levels) |_| {
                            try writer.writeAll("^");
                        }

                        // create a new Encoding union from the pointers child
                        // type, giving an encoding of the underlying pointer type
                        comptime var encoding: Encoding = .init(pointer_info.child);

                        // if the indirection levels are greater than 1, for
                        // certain types that means getting rid of it's
                        // internal type specification
                        //
                        // https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html#//apple_ref/doc/uid/TP40008048-CH100
                        if (pointer_info.indirection_levels > 1) {
                            switch (encoding) {
                                .structure => |*s| s.show_type_spec = false,
                                .@"union" => |*u| u.show_type_spec = false,
                                else => {},
                            }
                        }

                        // call this format function again, this time with the child type encoding
                        try encoding.format(writer);
                    },
                    else => @compileError("Pointer size not supported for encoding"),
                }
            },
            .function => |fn_info| {
                assert(std.meta.eql(fn_info.calling_convention, std.builtin.CallingConvention.c));

                // Return type is first in a method encoding
                const ret_type_enc: Encoding = .init(fn_info.return_type.?);
                try ret_type_enc.format(writer);
                inline for (fn_info.params) |param| {
                    const param_enc: Encoding = .init(param.type.?);
                    try param_enc.format(writer);
                }
            },
            .unknown => {},
        }
    }
};

fn comptimeEncodedLen(comptime T: type) usize {
    comptime {
        const encoding = Encoding.init(T);
        var scratch: [8192]u8 = undefined;
        const printed = std.fmt.bufPrintSentinel(
            scratch[0 .. scratch.len - 1],
            "{f}",
            .{encoding},
            0,
        ) catch @compileError("ObjC type encoding exceeds scratch buffer; bump size in encoding.zig");
        return printed.len;
    }
}

/// Returns the **null-terminated** encoding string for `T` at **comptime** (`[N:0]u8`).
///
/// Use `std.mem.sliceTo(&value, 0)` (or equivalent) to get a `[:0]const u8` slice in tests or callers.
pub fn comptimeEncode(comptime T: type) [comptimeEncodedLen(T):0]u8 {
    comptime {
        const encoding: Encoding = .init(T);
        var scratch: [8192]u8 = undefined;
        const printed = std.fmt.bufPrintSentinel(
            scratch[0 .. scratch.len - 1],
            "{f}",
            .{encoding},
            0,
        ) catch @compileError("ObjC type encoding exceeds scratch buffer; bump size in encoding.zig");
        const len = comptimeEncodedLen(T);
        std.debug.assert(printed.len == len);
        var out: [len:0]u8 = undefined;
        @memcpy(out[0..printed.len], printed);
        return out;
    }
}

/// Extern fixtures for substring assertions (names must stay stable for `contains` checks).
const EncodingTestPoint = extern struct {
    x: c_int,
    y: c_int,
};

const EncodingTestPayload = extern union {
    i: c_int,
    f: f64,
};

const EncodingTestEnum = enum(c_int) {
    a = 0,
    b = 1,
};

fn expectEnc(comptime T: type, comptime expected: [:0]const u8) void {
    comptime {
        const got = std.mem.sliceTo(&comptimeEncode(T), 0);
        if (!std.mem.eql(u8, got, expected)) {
            @compileError(std.fmt.comptimePrint("encoding for {s}: want {s}, got {s}", .{
                @typeName(T),
                expected,
                got,
            }));
        }
    }
}

fn encSlice(comptime T: type) [:0]const u8 {
    return comptime std.mem.sliceTo(&comptimeEncode(T), 0);
}

test "encoding scalars" {
    expectEnc(void, "v");
    expectEnc(c_int, "i");
    expectEnc(c_short, "s");
    expectEnc(c_long, "l");
    expectEnc(f64, "d");
    expectEnc(bool, "B");
    expectEnc([*c]const u8, "*");
}

test "encoding ObjC handles" {
    expectEnc(SEL, ":");
    expectEnc(Class, "#");
    expectEnc(id, "@");
}

test "encoding pointers" {
    // `id` is already `*ObjCObject`; `ObjCObject` is the same type as `Class` → `#`. Extra `^` per level.
    expectEnc(*const id, "^^#");
    // `SEL` is `*opaque`; pointee encodes as `v`.
    expectEnc(*const SEL, "^^v");
    expectEnc(*const *const id, "^^^#");
}

test "encoding optional id" {
    // `?id` uses the optional lowering to `id` (`*ObjCObject`); one indirection to class token `#`.
    expectEnc(?id, "^#");
}

test "encoding array" {
    expectEnc([3]c_int, "[3i]");
}

test "encoding enum uses tag type" {
    expectEnc(EncodingTestEnum, "i");
}

test "encoding C function types return first" {
    const Fn1 = fn (c_int, id) callconv(.c) bool;
    expectEnc(Fn1, "Bi@");

    const Fn2 = fn (c_int) callconv(.c) void;
    expectEnc(Fn2, "vi");

    const Fn3 = fn () callconv(.c) void;
    expectEnc(Fn3, "v");
}

test "encoding extern struct substring" {
    const s = encSlice(EncodingTestPoint);
    try std.testing.expect(std.mem.indexOf(u8, s, "EncodingTestPoint=") != null);
    try std.testing.expect(std.mem.indexOf(u8, s, "ii") != null);
}

test "encoding extern union substring" {
    const s = encSlice(EncodingTestPayload);
    try std.testing.expect(std.mem.indexOf(u8, s, "EncodingTestPayload=") != null);
    try std.testing.expect(std.mem.indexOf(u8, s, "=id") != null);
}

test "encoding double pointer strips struct type spec" {
    const s = encSlice(*const *const EncodingTestPoint);
    try std.testing.expect(std.mem.indexOf(u8, s, "^^{EncodingTestPoint}") != null);
    try std.testing.expect(std.mem.indexOf(u8, s, "EncodingTestPoint=") == null);
}

test "comptimeEncode len matches sliceTo length" {
    comptime {
        const T = fn (id, SEL) callconv(.c) void;
        const arr = comptimeEncode(T);
        const s = std.mem.sliceTo(&arr, 0);
        std.debug.assert(s.len == arr.len);
    }
}
