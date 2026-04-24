//! `NSCoder` and related keyed archiver helpers. Receivers are Objective-C `id` (there is no separate
//! `CoderPtr` type — use `Types.id` for any `NSCoder` subclass instance). Keys are `NSString *`;
//! pass `key.id` from [`String`](./string.zig) wrappers.

const std = @import("std");
const Types = @import("./types.zig");
const Object = @import("./object.zig");
const Dispatch = @import("./dispatch.zig");
const Selector = @import("./selector.zig");

const id = Types.id;
const SEL = Types.SEL;
const Bool = Types.Bool;
const ClassPtr = Types.ClassPtr;
const Integer = Types.Integer;
const NSInteger = Types.NSInteger;

// --- Phase 1: keyed primitives ---

const allowsKeyedCodingFn = *const fn (id, SEL) callconv(.c) Bool;
const requiresSecureCodingFn = *const fn (id, SEL) callconv(.c) Bool;

const encodeBoolForKeyFn = *const fn (id, SEL, Bool, id) callconv(.c) void;
const encodeIntForKeyFn = *const fn (id, SEL, c_int, id) callconv(.c) void;
const encodeInt32ForKeyFn = *const fn (id, SEL, i32, id) callconv(.c) void;
const encodeInt64ForKeyFn = *const fn (id, SEL, i64, id) callconv(.c) void;
const encodeFloatForKeyFn = *const fn (id, SEL, f32, id) callconv(.c) void;
const encodeDoubleForKeyFn = *const fn (id, SEL, f64, id) callconv(.c) void;
const encodeIntegerForKeyFn = *const fn (id, SEL, NSInteger, id) callconv(.c) void;

const decodeBoolForKeyFn = *const fn (id, SEL, id) callconv(.c) Bool;
const decodeIntForKeyFn = *const fn (id, SEL, id) callconv(.c) c_int;
const decodeInt32ForKeyFn = *const fn (id, SEL, id) callconv(.c) i32;
const decodeInt64ForKeyFn = *const fn (id, SEL, id) callconv(.c) i64;
const decodeFloatForKeyFn = *const fn (id, SEL, id) callconv(.c) f32;
const decodeDoubleForKeyFn = *const fn (id, SEL, id) callconv(.c) f64;
const decodeIntegerForKeyFn = *const fn (id, SEL, id) callconv(.c) NSInteger;

const containsValueForKeyFn = *const fn (id, SEL, id) callconv(.c) Bool;

// --- Phase 2: objects, errors, top-level ---

const encodeObjectForKeyFn = *const fn (id, SEL, ?id, id) callconv(.c) void;
const decodeObjectForKeyFn = *const fn (id, SEL, id) callconv(.c) ?id;
const decodeTopLevelObjectAndReturnErrorFn = *const fn (id, SEL, *?id) callconv(.c) ?id;
const decodeTopLevelObjectForKeyErrorFn = *const fn (id, SEL, id, *?id) callconv(.c) ?id;
const failWithErrorFn = *const fn (id, SEL, id) callconv(.c) void;
const errorFn = *const fn (id, SEL) callconv(.c) ?id;
const decodingFailurePolicyFn = *const fn (id, SEL) callconv(.c) Integer;

// --- Phase 3: secure / collection helpers ---

const decodeObjectOfClassForKeyFn = *const fn (id, SEL, ClassPtr, id) callconv(.c) ?id;
const decodeObjectOfClassesForKeyFn = *const fn (id, SEL, id, id) callconv(.c) ?id;
const decodeArrayOfObjectsOfClassForKeyFn = *const fn (id, SEL, ClassPtr, id) callconv(.c) ?id;
const decodeDictionaryWithKeysOfClassObjectsOfClassForKeyFn = *const fn (id, SEL, ClassPtr, ClassPtr, id) callconv(.c) ?id;

/// `NSDecodingFailurePolicy` (NSKeyedUnarchiver may use `setDecodingFailurePolicy:`; base `NSCoder` exposes read-only `decodingFailurePolicy`).
pub const DecodingFailurePolicy = enum(Integer) {
    raise_exception = 0,
    set_error_and_return = 1,
};

pub fn allowsKeyedCoding(coder: id) Bool {
    return Dispatch.msgSend(allowsKeyedCodingFn, coder, Selector.selector("allowsKeyedCoding"), .{});
}

pub fn requiresSecureCoding(coder: id) Bool {
    return Dispatch.msgSend(requiresSecureCodingFn, coder, Selector.selector("requiresSecureCoding"), .{});
}

pub fn encodeBoolForKey(coder: id, value: Bool, key: id) void {
    return Dispatch.msgSend(encodeBoolForKeyFn, coder, Selector.selector("encodeBool:forKey:"), .{ value, key });
}

pub fn encodeIntForKey(coder: id, value: c_int, key: id) void {
    return Dispatch.msgSend(encodeIntForKeyFn, coder, Selector.selector("encodeInt:forKey:"), .{ value, key });
}

pub fn encodeInt32ForKey(coder: id, value: i32, key: id) void {
    return Dispatch.msgSend(encodeInt32ForKeyFn, coder, Selector.selector("encodeInt32:forKey:"), .{ value, key });
}

pub fn encodeInt64ForKey(coder: id, value: i64, key: id) void {
    return Dispatch.msgSend(encodeInt64ForKeyFn, coder, Selector.selector("encodeInt64:forKey:"), .{ value, key });
}

pub fn encodeFloatForKey(coder: id, value: f32, key: id) void {
    return Dispatch.msgSend(encodeFloatForKeyFn, coder, Selector.selector("encodeFloat:forKey:"), .{ value, key });
}

pub fn encodeDoubleForKey(coder: id, value: f64, key: id) void {
    return Dispatch.msgSend(encodeDoubleForKeyFn, coder, Selector.selector("encodeDouble:forKey:"), .{ value, key });
}

pub fn encodeIntegerForKey(coder: id, value: NSInteger, key: id) void {
    return Dispatch.msgSend(encodeIntegerForKeyFn, coder, Selector.selector("encodeInteger:forKey:"), .{ value, key });
}

pub fn decodeBoolForKey(coder: id, key: id) Bool {
    return Dispatch.msgSend(decodeBoolForKeyFn, coder, Selector.selector("decodeBoolForKey:"), .{key});
}

pub fn decodeIntForKey(coder: id, key: id) c_int {
    return Dispatch.msgSend(decodeIntForKeyFn, coder, Selector.selector("decodeIntForKey:"), .{key});
}

pub fn decodeInt32ForKey(coder: id, key: id) i32 {
    return Dispatch.msgSend(decodeInt32ForKeyFn, coder, Selector.selector("decodeInt32ForKey:"), .{key});
}

pub fn decodeInt64ForKey(coder: id, key: id) i64 {
    return Dispatch.msgSend(decodeInt64ForKeyFn, coder, Selector.selector("decodeInt64ForKey:"), .{key});
}

pub fn decodeFloatForKey(coder: id, key: id) f32 {
    return Dispatch.msgSend(decodeFloatForKeyFn, coder, Selector.selector("decodeFloatForKey:"), .{key});
}

pub fn decodeDoubleForKey(coder: id, key: id) f64 {
    return Dispatch.msgSend(decodeDoubleForKeyFn, coder, Selector.selector("decodeDoubleForKey:"), .{key});
}

pub fn decodeIntegerForKey(coder: id, key: id) NSInteger {
    return Dispatch.msgSend(decodeIntegerForKeyFn, coder, Selector.selector("decodeIntegerForKey:"), .{key});
}

pub fn containsValueForKey(coder: id, key: id) Bool {
    return Dispatch.msgSend(containsValueForKeyFn, coder, Selector.selector("containsValueForKey:"), .{key});
}

pub fn encodeObjectForKey(coder: id, object: ?id, key: id) void {
    return Dispatch.msgSend(encodeObjectForKeyFn, coder, Selector.selector("encodeObject:forKey:"), .{ object, key });
}

pub fn decodeObjectForKey(coder: id, key: id) ?id {
    return Dispatch.msgSend(decodeObjectForKeyFn, coder, Selector.selector("decodeObjectForKey:"), .{key});
}

/// `NSError **` out-parameter uses `*?id` (`NSError *` is an object pointer).
pub fn decodeTopLevelObjectAndReturnError(coder: id, error_out: *?id) ?id {
    return Dispatch.msgSend(decodeTopLevelObjectAndReturnErrorFn, coder, Selector.selector("decodeTopLevelObjectAndReturnError:"), .{error_out});
}

pub fn decodeTopLevelObjectForKeyError(coder: id, key: id, error_out: *?id) ?id {
    return Dispatch.msgSend(decodeTopLevelObjectForKeyErrorFn, coder, Selector.selector("decodeTopLevelObjectForKey:error:"), .{ key, error_out });
}

pub fn failWithError(coder: id, err: id) void {
    return Dispatch.msgSend(failWithErrorFn, coder, Selector.selector("failWithError:"), .{err});
}

pub fn errorProperty(coder: id) ?id {
    return Dispatch.msgSend(errorFn, coder, Selector.selector("error"), .{});
}

pub fn decodingFailurePolicy(coder: id) DecodingFailurePolicy {
    const v = Dispatch.msgSend(decodingFailurePolicyFn, coder, Selector.selector("decodingFailurePolicy"), .{});
    return @enumFromInt(v);
}

pub fn decodeObjectOfClassForKey(coder: id, cls: ClassPtr, key: id) ?id {
    return Dispatch.msgSend(decodeObjectOfClassForKeyFn, coder, Selector.selector("decodeObjectOfClass:forKey:"), .{ cls, key });
}

/// `classes` is an `NSSet` of `Class` objects (typically from [`NSSet.setWithObject`]).
pub fn decodeObjectOfClassesForKey(coder: id, classes: id, key: id) ?id {
    return Dispatch.msgSend(decodeObjectOfClassesForKeyFn, coder, Selector.selector("decodeObjectOfClasses:forKey:"), .{ classes, key });
}

pub fn decodeArrayOfObjectsOfClassForKey(coder: id, cls: ClassPtr, key: id) ?id {
    return Dispatch.msgSend(decodeArrayOfObjectsOfClassForKeyFn, coder, Selector.selector("decodeArrayOfObjectsOfClass:forKey:"), .{ cls, key });
}

pub fn decodeDictionaryWithKeysOfClassObjectsOfClassForKey(coder: id, key_class: ClassPtr, object_class: ClassPtr, key: id) ?id {
    return Dispatch.msgSend(decodeDictionaryWithKeysOfClassObjectsOfClassForKeyFn, coder, Selector.selector("decodeDictionaryWithKeysOfClass:objectsOfClass:forKey:"), .{ key_class, object_class, key });
}

/// `+[NSSet setWithObject:]`
pub fn setWithObject(set_class: ClassPtr, object: id) id {
    const setWithObjectFn = *const fn (ClassPtr, SEL, id) callconv(.c) id;
    return Dispatch.msgSend(setWithObjectFn, set_class, Selector.selector("setWithObject:"), .{object});
}

pub inline fn getNSSetClass() ClassPtr {
    return Object.getClassByName("NSSet").?;
}

// --- NSKeyedArchiver / NSKeyedUnarchiver (integration + tests) ---

pub const KeyedArchiver = struct {
    pub inline fn getClass() ClassPtr {
        return Object.getClassByName("NSKeyedArchiver").?;
    }

    const archivedDataWithRootObjectFn = *const fn (ClassPtr, SEL, id, Bool, *?id) callconv(.c) ?id;
    const initRequiringSecureCodingFn = *const fn (id, SEL, Bool) callconv(.c) ?id;
    const encodedDataFn = *const fn (id, SEL) callconv(.c) id;
    const finishEncodingFn = *const fn (id, SEL) callconv(.c) void;

    /// `+[NSKeyedArchiver archivedDataWithRootObject:requiringSecureCoding:error:]`
    pub fn archivedDataWithRootObject(root: id, requiring_secure_coding: Bool, error_out: *?id) ?id {
        const cls = getClass();
        return Dispatch.msgSend(archivedDataWithRootObjectFn, cls, Selector.selector("archivedDataWithRootObject:requiringSecureCoding:error:"), .{
            root,
            requiring_secure_coding,
            error_out,
        });
    }

    /// `-[NSKeyedArchiver initRequiringSecureCoding:]` (after `alloc`). Prefer this over deprecated `initForWritingWithMutableData:`.
    pub fn initRequiringSecureCoding(self: id, requires_secure_coding: Bool) ?id {
        return Dispatch.msgSend(initRequiringSecureCodingFn, self, Selector.selector("initRequiringSecureCoding:"), .{requires_secure_coding});
    }

    /// `encodedData` — after encoding, yields the archive (`NSData`). Accessing may call `finishEncoding`.
    pub fn encodedData(archiver: id) id {
        return Dispatch.msgSend(encodedDataFn, archiver, Selector.selector("encodedData"), .{});
    }

    pub fn finishEncoding(archiver: id) void {
        return Dispatch.msgSend(finishEncodingFn, archiver, Selector.selector("finishEncoding"), .{});
    }
};

pub const KeyedUnarchiver = struct {
    pub inline fn getClass() ClassPtr {
        return Object.getClassByName("NSKeyedUnarchiver").?;
    }

    const initForReadingFromDataFn = *const fn (id, SEL, id, *?id) callconv(.c) ?id;
    const setDecodingFailurePolicyFn = *const fn (id, SEL, Integer) callconv(.c) void;

    /// `-[NSKeyedUnarchiver initForReadingFromData:error:]` (after `alloc`).
    pub fn initForReadingFromData(self: id, archive_data: id, error_out: *?id) ?id {
        return Dispatch.msgSend(initForReadingFromDataFn, self, Selector.selector("initForReadingFromData:error:"), .{ archive_data, error_out });
    }

    /// `-[NSKeyedUnarchiver setDecodingFailurePolicy:]` (`NSCoder` itself only exposes a read-only `decodingFailurePolicy`).
    pub fn setDecodingFailurePolicy(unarchiver: id, policy: DecodingFailurePolicy) void {
        return Dispatch.msgSend(setDecodingFailurePolicyFn, unarchiver, Selector.selector("setDecodingFailurePolicy:"), .{@intFromEnum(policy)});
    }
};

const testing = std.testing;
const AutoreleasePool = @import("./autorelease_pool.zig");
const String = @import("./string.zig");
const nsdata = @import("./data.zig");

test "NSCoder keyed round-trip primitives via NSKeyedArchiver" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const key_bool = String.initWithUTF8String("kBool");
    defer key_bool.deinit();
    const key_int = String.initWithUTF8String("kInt");
    defer key_int.deinit();
    const key_i32 = String.initWithUTF8String("kI32");
    defer key_i32.deinit();
    const key_i64 = String.initWithUTF8String("kI64");
    defer key_i64.deinit();
    const key_f32 = String.initWithUTF8String("kF32");
    defer key_f32.deinit();
    const key_f64 = String.initWithUTF8String("kF64");
    defer key_f64.deinit();
    const key_nsint = String.initWithUTF8String("kNSInt");
    defer key_nsint.deinit();

    const arch_class = KeyedArchiver.getClass();
    const arch_alloc = Object.alloc(arch_class);
    const archiver = KeyedArchiver.initRequiringSecureCoding(arch_alloc, true) orelse {
        Object.release(arch_alloc);
        return try testing.expect(false);
    };
    defer Object.release(archiver);

    try testing.expect(allowsKeyedCoding(archiver));
    try testing.expect(requiresSecureCoding(archiver));

    encodeBoolForKey(archiver, true, key_bool.id);
    encodeIntForKey(archiver, -7, key_int.id);
    encodeInt32ForKey(archiver, 300111, key_i32.id);
    encodeInt64ForKey(archiver, -9_000_000_000_000, key_i64.id);
    encodeFloatForKey(archiver, 1.5, key_f32.id);
    encodeDoubleForKey(archiver, 2.25, key_f64.id);
    encodeIntegerForKey(archiver, 42, key_nsint.id);

    KeyedArchiver.finishEncoding(archiver);
    const md = KeyedArchiver.encodedData(archiver);
    try testing.expect(nsdata.length(md) > 0);

    var dec_err: ?id = null;
    const u_alloc = Object.alloc(KeyedUnarchiver.getClass());
    const unarchiver = KeyedUnarchiver.initForReadingFromData(u_alloc, md, &dec_err) orelse {
        Object.release(u_alloc);
        return try testing.expect(false);
    };
    defer Object.release(unarchiver);

    try testing.expect(containsValueForKey(unarchiver, key_bool.id));
    try testing.expect(decodeBoolForKey(unarchiver, key_bool.id));
    try testing.expectEqual(@as(c_int, -7), decodeIntForKey(unarchiver, key_int.id));
    try testing.expectEqual(@as(i32, 300111), decodeInt32ForKey(unarchiver, key_i32.id));
    try testing.expectEqual(@as(i64, -9_000_000_000_000), decodeInt64ForKey(unarchiver, key_i64.id));
    try testing.expectEqual(@as(f32, 1.5), decodeFloatForKey(unarchiver, key_f32.id));
    try testing.expectEqual(@as(f64, 2.25), decodeDoubleForKey(unarchiver, key_f64.id));
    try testing.expectEqual(@as(NSInteger, 42), decodeIntegerForKey(unarchiver, key_nsint.id));
}

test "NSData dataWithBytes and NSKeyedArchiver root object" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const bytes: []const u8 = "ping";
    const d = nsdata.dataWithBytes(@ptrCast(bytes.ptr), @intCast(bytes.len));
    try testing.expectEqual(@as(Types.UInteger, 4), nsdata.length(d));

    const num_class = Object.getClassByName("NSNumber").?;
    const numberWithIntFn = *const fn (ClassPtr, SEL, c_int) callconv(.c) id;
    const n = Dispatch.msgSend(numberWithIntFn, num_class, Selector.selector("numberWithInt:"), .{@as(c_int, 99)});
    var err: ?id = null;
    const blob = KeyedArchiver.archivedDataWithRootObject(n, true, &err) orelse return try testing.expect(false);
    try testing.expect(nsdata.length(blob) > 0);

    const u_alloc = Object.alloc(KeyedUnarchiver.getClass());
    var uerr: ?id = null;
    const u = KeyedUnarchiver.initForReadingFromData(u_alloc, blob, &uerr) orelse {
        Object.release(u_alloc);
        return try testing.expect(false);
    };
    defer Object.release(u);

    const root_key = String.initWithUTF8String("root");
    defer root_key.deinit();
    const decoded = decodeObjectForKey(u, root_key.id) orelse return try testing.expect(false);
    const intValueFn = *const fn (id, SEL) callconv(.c) c_int;
    const v = Dispatch.msgSend(intValueFn, decoded, Selector.selector("intValue"), .{});
    try testing.expectEqual(@as(c_int, 99), v);
}

test "decodeObjectOfClass:forKey: and decodeObjectOfClasses:forKey:" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const key_obj = String.initWithUTF8String("obj");
    defer key_obj.deinit();

    const arch_alloc = Object.alloc(KeyedArchiver.getClass());
    const archiver = KeyedArchiver.initRequiringSecureCoding(arch_alloc, true) orelse {
        Object.release(arch_alloc);
        return try testing.expect(false);
    };
    defer Object.release(archiver);

    const str = String.initWithUTF8String("secure");
    defer str.deinit();
    encodeObjectForKey(archiver, str.id, key_obj.id);
    KeyedArchiver.finishEncoding(archiver);
    const md = KeyedArchiver.encodedData(archiver);

    var dec_err: ?id = null;
    const u_alloc = Object.alloc(KeyedUnarchiver.getClass());
    const unarchiver = KeyedUnarchiver.initForReadingFromData(u_alloc, md, &dec_err) orelse {
        Object.release(u_alloc);
        return try testing.expect(false);
    };
    defer Object.release(unarchiver);

    const str_cls = String.getStringClass();
    const s1 = decodeObjectOfClassForKey(unarchiver, str_cls, key_obj.id) orelse return try testing.expect(false);
    try testing.expect(String.fromIdUnowned(s1).isEqualToString(&str));

    const arch2_alloc = Object.alloc(KeyedArchiver.getClass());
    const archiver2 = KeyedArchiver.initRequiringSecureCoding(arch2_alloc, true) orelse {
        Object.release(arch2_alloc);
        return try testing.expect(false);
    };
    defer Object.release(archiver2);
    encodeObjectForKey(archiver2, str.id, key_obj.id);
    KeyedArchiver.finishEncoding(archiver2);
    const md2 = KeyedArchiver.encodedData(archiver2);

    var dec_err2: ?id = null;
    const u2_alloc = Object.alloc(KeyedUnarchiver.getClass());
    const unarchiver2 = KeyedUnarchiver.initForReadingFromData(u2_alloc, md2, &dec_err2) orelse {
        Object.release(u2_alloc);
        return try testing.expect(false);
    };
    defer Object.release(unarchiver2);

    const set = setWithObject(getNSSetClass(), @as(id, @ptrCast(str_cls)));
    const s2 = decodeObjectOfClassesForKey(unarchiver2, set, key_obj.id) orelse return try testing.expect(false);
    try testing.expect(String.fromIdUnowned(s2).isEqualToString(&str));
}
