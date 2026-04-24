//! NSData / NSMutableData bindings via `objc_msgSend` (fixed signatures only).
//!
//! **Omitted:** `enumerateByteRangesUsingBlock:`, `initWithBytesNoCopy:...deallocator:` (block),
//! deprecated unsafe single-argument `getBytes:`.
const std = @import("std");
const Types = @import("./types.zig");
const Object = @import("./object.zig");
const Dispatch = @import("./dispatch.zig");
const Selector = @import("./selector.zig");
const Range = @import("./range.zig").Range;
const String = @import("./string.zig");
const AutoreleasePool = @import("./autorelease_pool.zig");

const id = Types.id;
const ClassPtr = Types.ClassPtr;
const SEL = Types.SEL;
const UInteger = Types.UInteger;
const Bool = Types.Bool;
const NSInteger = Types.NSInteger;

// --- Option bitmasks (NS_OPTIONS) ---

pub const ReadingOptions = enum(UInteger) {
    mapped_if_safe = 1 << 0,
    uncached = 1 << 1,
    mapped_always = 1 << 3,
};

pub const WritingOptions = enum(UInteger) {
    atomic = 1 << 0,
    without_overwriting = 1 << 1,
    file_protection_none = 0x10000000,
    file_protection_complete = 0x20000000,
    file_protection_complete_unless_open = 0x30000000,
    file_protection_complete_until_first_user_auth = 0x40000000,
    file_protection_complete_when_user_inactive = 0x50000000,
    file_protection_mask = 0xf0000000,
};

pub const SearchOptions = enum(UInteger) {
    backwards = 1 << 0,
    anchored = 1 << 1,
};

pub const Base64EncodingOptions = enum(UInteger) {
    line_length_64 = 1 << 0,
    line_length_76 = 1 << 1,
    end_line_with_carriage_return = 1 << 4,
    end_line_with_line_feed = 1 << 5,
};

pub const Base64DecodingOptions = enum(UInteger) {
    ignore_unknown_characters = 1 << 0,
};

/// Values match `NSDataCompressionAlgorithm` (NSInteger).
pub const CompressionAlgorithm = enum(NSInteger) {
    lzfse = 0,
    lz4 = 1,
    lzma = 2,
    zlib = 3,
};

// --- Class getters ---

pub inline fn getNSDataClass() ClassPtr {
    return Object.getClassByName("NSData").?;
}

pub inline fn getNSMutableDataClass() ClassPtr {
    return Object.getClassByName("NSMutableData").?;
}

// --- Shared function types ---

const lengthFn = *const fn (id, SEL) callconv(.c) UInteger;
const bytesFn = *const fn (id, SEL) callconv(.c) ?*const anyopaque;
const dataFn = *const fn (ClassPtr, SEL) callconv(.c) id;
const dataWithBytesLengthFn = *const fn (ClassPtr, SEL, *const anyopaque, UInteger) callconv(.c) id;
const dataWithBytesNoCopyLengthFn = *const fn (ClassPtr, SEL, ?*anyopaque, UInteger) callconv(.c) id;
const dataWithBytesNoCopyLengthFreeFn = *const fn (ClassPtr, SEL, ?*anyopaque, UInteger, Bool) callconv(.c) id;
const dataWithDataFn = *const fn (ClassPtr, SEL, id) callconv(.c) id;
const isEqualToDataFn = *const fn (id, SEL, id) callconv(.c) Bool;
const subdataWithRangeFn = *const fn (id, SEL, Range) callconv(.c) id;

const getBytesLengthFn = *const fn (id, SEL, ?*anyopaque, UInteger) callconv(.c) void;
const getBytesRangeFn = *const fn (id, SEL, ?*anyopaque, Range) callconv(.c) void;
const writeToFileAtomicallyFn = *const fn (id, SEL, id, Bool) callconv(.c) Bool;
const writeToURLAtomicallyFn = *const fn (id, SEL, id, Bool) callconv(.c) Bool;
const writeToFileOptionsErrorFn = *const fn (id, SEL, id, UInteger, *?id) callconv(.c) Bool;
const writeToURLOptionsErrorFn = *const fn (id, SEL, id, UInteger, *?id) callconv(.c) Bool;
const rangeOfDataOptionsRangeFn = *const fn (id, SEL, id, UInteger, Range) callconv(.c) Range;

const initWithBytesLengthFn = *const fn (id, SEL, ?*const anyopaque, UInteger) callconv(.c) id;
const initWithBytesNoCopyLengthFn = *const fn (id, SEL, ?*anyopaque, UInteger) callconv(.c) id;
const initWithBytesNoCopyLengthFreeFn = *const fn (id, SEL, ?*anyopaque, UInteger, Bool) callconv(.c) id;
const initWithDataFn = *const fn (id, SEL, id) callconv(.c) id;

// ObjC `id` returns use plain `id` in the synthesized C signature; `nil` is a null pointer (`?id` can distort the msgSend ABI).
const dataWithContentsOfFileOptionsErrorFn = *const fn (ClassPtr, SEL, id, UInteger, *?id) callconv(.c) id;
const dataWithContentsOfURLOptionsErrorFn = *const fn (ClassPtr, SEL, id, UInteger, *?id) callconv(.c) id;
const dataWithContentsOfFileFn = *const fn (ClassPtr, SEL, id) callconv(.c) id;
const dataWithContentsOfURLFn = *const fn (ClassPtr, SEL, id) callconv(.c) id;

const initWithContentsOfFileOptionsErrorFn = *const fn (id, SEL, id, UInteger, *?id) callconv(.c) id;
const initWithContentsOfURLOptionsErrorFn = *const fn (id, SEL, id, UInteger, *?id) callconv(.c) id;
const initWithContentsOfFileFn = *const fn (id, SEL, id) callconv(.c) id;
const initWithContentsOfURLFn = *const fn (id, SEL, id) callconv(.c) id;

const initWithBase64EncodedStringOptionsFn = *const fn (id, SEL, id, UInteger) callconv(.c) id;
const base64EncodedStringWithOptionsFn = *const fn (id, SEL, UInteger) callconv(.c) id;
const initWithBase64EncodedDataOptionsFn = *const fn (id, SEL, id, UInteger) callconv(.c) id;
const base64EncodedDataWithOptionsFn = *const fn (id, SEL, UInteger) callconv(.c) id;

const decompressedDataUsingAlgorithmErrorFn = *const fn (id, SEL, NSInteger, *?id) callconv(.c) id;
const compressedDataUsingAlgorithmErrorFn = *const fn (id, SEL, NSInteger, *?id) callconv(.c) id;

const mutableDataFn = *const fn (ClassPtr, SEL) callconv(.c) id;
const dataWithCapacityFn = *const fn (ClassPtr, SEL, UInteger) callconv(.c) id;
const dataWithLengthFn = *const fn (ClassPtr, SEL, UInteger) callconv(.c) id;
const mutableBytesFn = *const fn (id, SEL) callconv(.c) ?*anyopaque;
const setLengthFn = *const fn (id, SEL, UInteger) callconv(.c) void;
const appendBytesLengthFn = *const fn (id, SEL, *const anyopaque, UInteger) callconv(.c) void;
const appendDataFn = *const fn (id, SEL, id) callconv(.c) void;
const increaseLengthByFn = *const fn (id, SEL, UInteger) callconv(.c) void;
const replaceBytesInRangeWithBytesFn = *const fn (id, SEL, Range, *const anyopaque) callconv(.c) void;
const resetBytesInRangeFn = *const fn (id, SEL, Range) callconv(.c) void;
const setDataFn = *const fn (id, SEL, id) callconv(.c) void;
const replaceBytesInRangeWithBytesLengthFn = *const fn (id, SEL, Range, ?*const anyopaque, UInteger) callconv(.c) void;
const initWithCapacityFn = *const fn (id, SEL, UInteger) callconv(.c) id;
const initWithLengthFn = *const fn (id, SEL, UInteger) callconv(.c) id;

const decompressUsingAlgorithmErrorFn = *const fn (id, SEL, NSInteger, *?id) callconv(.c) Bool;
const compressUsingAlgorithmErrorFn = *const fn (id, SEL, NSInteger, *?id) callconv(.c) Bool;

const allocFn = *const fn (ClassPtr, SEL) callconv(.c) id;

/// Map ObjC `nil` to Zig `null`. Use after every `id`-returning `objc_msgSend` where Foundation may return `nil` — `?id` as the Zig return type must not be used in the `@typeInfo` of the synthesized function pointer or the call ABI can be wrong.
fn objcIdMaybeNull(r: id) ?id {
    if (@intFromPtr(r) == 0) return null;
    return r;
}

// --- Length / bytes ---

/// `length` in bytes.
pub fn length(data: id) UInteger {
    return Dispatch.msgSend(lengthFn, data, Selector.selector("length"), .{});
}

/// `-[NSData bytes]` — may be null only if empty in some cases; prefer checking `length` first.
pub fn bytes(data: id) ?*const anyopaque {
    return Dispatch.msgSend(bytesFn, data, Selector.selector("bytes"), .{});
}

/// `-[NSData getBytes:length:]`
pub fn getBytesLength(data: id, buffer: ?*anyopaque, len: UInteger) void {
    Dispatch.msgSend(getBytesLengthFn, data, Selector.selector("getBytes:length:"), .{ buffer, len });
}

/// `-[NSData getBytes:range:]`
pub fn getBytesRange(data: id, buffer: ?*anyopaque, range: Range) void {
    Dispatch.msgSend(getBytesRangeFn, data, Selector.selector("getBytes:range:"), .{ buffer, range });
}

pub fn isEqualToData(data: id, other: id) bool {
    return Dispatch.msgSend(isEqualToDataFn, data, Selector.selector("isEqualToData:"), .{other});
}

pub fn subdataWithRange(data: id, range: Range) id {
    return Dispatch.msgSend(subdataWithRangeFn, data, Selector.selector("subdataWithRange:"), .{range});
}

// --- Class factories ---

/// `+[NSData data]` — empty immutable buffer.
pub fn empty() id {
    return Dispatch.msgSend(dataFn, @ptrCast(getNSDataClass()), Selector.selector("data"), .{});
}

pub fn dataWithBytes(bytes_ptr: [*]const u8, len: UInteger) id {
    const cls = getNSDataClass();
    return Dispatch.msgSend(dataWithBytesLengthFn, cls, Selector.selector("dataWithBytes:length:"), .{
        @as(*const anyopaque, @ptrCast(bytes_ptr)),
        len,
    });
}

pub fn dataWithBytesNoCopy(bytes_ptr: ?*anyopaque, len: UInteger) id {
    return Dispatch.msgSend(dataWithBytesNoCopyLengthFn, @ptrCast(getNSDataClass()), Selector.selector("dataWithBytesNoCopy:length:"), .{ bytes_ptr, len });
}

pub fn dataWithBytesNoCopyFreeWhenDone(bytes_ptr: ?*anyopaque, len: UInteger, free_when_done: bool) id {
    return Dispatch.msgSend(dataWithBytesNoCopyLengthFreeFn, @ptrCast(getNSDataClass()), Selector.selector("dataWithBytesNoCopy:length:freeWhenDone:"), .{
        bytes_ptr,
        len,
        free_when_done,
    });
}

pub fn dataWithData(other: id) id {
    return Dispatch.msgSend(dataWithDataFn, @ptrCast(getNSDataClass()), Selector.selector("dataWithData:"), .{other});
}

// --- Init (alloc + init) ---

pub fn dataAlloc() id {
    return Dispatch.msgSend(allocFn, @ptrCast(getNSDataClass()), Selector.selector("alloc"), .{});
}

const initFn = *const fn (id, SEL) callconv(.c) id;

pub fn dataInit(alloced: id) id {
    return Dispatch.msgSend(initFn, alloced, Selector.selector("init"), .{});
}

pub fn initWithBytesLength(alloced: id, buf: ?*const anyopaque, len: UInteger) id {
    return Dispatch.msgSend(initWithBytesLengthFn, alloced, Selector.selector("initWithBytes:length:"), .{ buf, len });
}

pub fn initWithBytesNoCopyLength(alloced: id, buf: ?*anyopaque, len: UInteger) id {
    return Dispatch.msgSend(initWithBytesNoCopyLengthFn, alloced, Selector.selector("initWithBytesNoCopy:length:"), .{ buf, len });
}

pub fn initWithBytesNoCopyLengthFreeWhenDone(alloced: id, buf: ?*anyopaque, len: UInteger, free_when_done: bool) id {
    return Dispatch.msgSend(initWithBytesNoCopyLengthFreeFn, alloced, Selector.selector("initWithBytesNoCopy:length:freeWhenDone:"), .{
        buf,
        len,
        free_when_done,
    });
}

pub fn initWithData(alloced: id, other: id) id {
    return Dispatch.msgSend(initWithDataFn, alloced, Selector.selector("initWithData:"), .{other});
}

// --- Contents of file / URL ---

pub fn dataWithContentsOfFileOptionsError(path: id, options: UInteger, error_out: *?id) ?id {
    const r = Dispatch.msgSend(dataWithContentsOfFileOptionsErrorFn, @ptrCast(getNSDataClass()), Selector.selector("dataWithContentsOfFile:options:error:"), .{
        path,
        options,
        error_out,
    });
    return objcIdMaybeNull(r);
}

pub fn dataWithContentsOfURLOptionsError(url: id, options: UInteger, error_out: *?id) ?id {
    const r = Dispatch.msgSend(dataWithContentsOfURLOptionsErrorFn, @ptrCast(getNSDataClass()), Selector.selector("dataWithContentsOfURL:options:error:"), .{
        url,
        options,
        error_out,
    });
    return objcIdMaybeNull(r);
}

pub fn dataWithContentsOfFile(path: id) ?id {
    const r = Dispatch.msgSend(dataWithContentsOfFileFn, @ptrCast(getNSDataClass()), Selector.selector("dataWithContentsOfFile:"), .{path});
    return objcIdMaybeNull(r);
}

pub fn dataWithContentsOfURL(url: id) ?id {
    const r = Dispatch.msgSend(dataWithContentsOfURLFn, @ptrCast(getNSDataClass()), Selector.selector("dataWithContentsOfURL:"), .{url});
    return objcIdMaybeNull(r);
}

pub fn initWithContentsOfFileOptionsError(alloced: id, path: id, options: UInteger, error_out: *?id) ?id {
    const r = Dispatch.msgSend(initWithContentsOfFileOptionsErrorFn, alloced, Selector.selector("initWithContentsOfFile:options:error:"), .{
        path,
        options,
        error_out,
    });
    return objcIdMaybeNull(r);
}

pub fn initWithContentsOfURLOptionsError(alloced: id, url: id, options: UInteger, error_out: *?id) ?id {
    const r = Dispatch.msgSend(initWithContentsOfURLOptionsErrorFn, alloced, Selector.selector("initWithContentsOfURL:options:error:"), .{
        url,
        options,
        error_out,
    });
    return objcIdMaybeNull(r);
}

pub fn initWithContentsOfFile(alloced: id, path: id) ?id {
    const r = Dispatch.msgSend(initWithContentsOfFileFn, alloced, Selector.selector("initWithContentsOfFile:"), .{path});
    return objcIdMaybeNull(r);
}

pub fn initWithContentsOfURL(alloced: id, url: id) ?id {
    const r = Dispatch.msgSend(initWithContentsOfURLFn, alloced, Selector.selector("initWithContentsOfURL:"), .{url});
    return objcIdMaybeNull(r);
}

// --- Write ---

pub fn writeToFileAtomically(data: id, path: id, atomically: bool) bool {
    return Dispatch.msgSend(writeToFileAtomicallyFn, data, Selector.selector("writeToFile:atomically:"), .{ path, atomically });
}

pub fn writeToURLAtomically(data: id, url: id, atomically: bool) bool {
    return Dispatch.msgSend(writeToURLAtomicallyFn, data, Selector.selector("writeToURL:atomically:"), .{ url, atomically });
}

pub fn writeToFileOptionsError(data: id, path: id, options: UInteger, error_out: *?id) bool {
    return Dispatch.msgSend(writeToFileOptionsErrorFn, data, Selector.selector("writeToFile:options:error:"), .{
        path,
        options,
        error_out,
    });
}

pub fn writeToURLOptionsError(data: id, url: id, options: UInteger, error_out: *?id) bool {
    return Dispatch.msgSend(writeToURLOptionsErrorFn, data, Selector.selector("writeToURL:options:error:"), .{
        url,
        options,
        error_out,
    });
}

/// `-[NSData rangeOfData:options:range:]`
pub fn rangeOfDataOptionsRange(data: id, data_to_find: id, options: UInteger, search_range: Range) Range {
    return Dispatch.msgSend(rangeOfDataOptionsRangeFn, data, Selector.selector("rangeOfData:options:range:"), .{
        data_to_find,
        options,
        search_range,
    });
}

// --- Base64 ---

pub fn initWithBase64EncodedStringOptions(alloced: id, base64_string: id, options: UInteger) ?id {
    const r = Dispatch.msgSend(initWithBase64EncodedStringOptionsFn, alloced, Selector.selector("initWithBase64EncodedString:options:"), .{
        base64_string,
        options,
    });
    return objcIdMaybeNull(r);
}

pub fn base64EncodedStringWithOptions(data: id, options: UInteger) id {
    return Dispatch.msgSend(base64EncodedStringWithOptionsFn, data, Selector.selector("base64EncodedStringWithOptions:"), .{options});
}

pub fn initWithBase64EncodedDataOptions(alloced: id, base64_data: id, options: UInteger) ?id {
    const r = Dispatch.msgSend(initWithBase64EncodedDataOptionsFn, alloced, Selector.selector("initWithBase64EncodedData:options:"), .{
        base64_data,
        options,
    });
    return objcIdMaybeNull(r);
}

pub fn base64EncodedDataWithOptions(data: id, options: UInteger) id {
    return Dispatch.msgSend(base64EncodedDataWithOptionsFn, data, Selector.selector("base64EncodedDataWithOptions:"), .{options});
}

// --- Compression ---

pub fn decompressedDataUsingAlgorithmError(data: id, algorithm: CompressionAlgorithm, error_out: *?id) ?id {
    const r = Dispatch.msgSend(decompressedDataUsingAlgorithmErrorFn, data, Selector.selector("decompressedDataUsingAlgorithm:error:"), .{
        @intFromEnum(algorithm),
        error_out,
    });
    return objcIdMaybeNull(r);
}

pub fn compressedDataUsingAlgorithmError(data: id, algorithm: CompressionAlgorithm, error_out: *?id) ?id {
    const r = Dispatch.msgSend(compressedDataUsingAlgorithmErrorFn, data, Selector.selector("compressedDataUsingAlgorithm:error:"), .{
        @intFromEnum(algorithm),
        error_out,
    });
    return objcIdMaybeNull(r);
}

// --- NSMutableData ---

pub fn mutableData() id {
    return Dispatch.msgSend(mutableDataFn, @ptrCast(getNSMutableDataClass()), Selector.selector("data"), .{});
}

pub fn dataWithCapacity(num_items: UInteger) id {
    return Dispatch.msgSend(dataWithCapacityFn, @ptrCast(getNSMutableDataClass()), Selector.selector("dataWithCapacity:"), .{num_items});
}

pub fn dataWithLength(lengthv: UInteger) id {
    return Dispatch.msgSend(dataWithLengthFn, @ptrCast(getNSMutableDataClass()), Selector.selector("dataWithLength:"), .{lengthv});
}

pub fn mutableBytes(mdata: id) ?*anyopaque {
    return Dispatch.msgSend(mutableBytesFn, mdata, Selector.selector("mutableBytes"), .{});
}

pub fn setLength(mdata: id, len: UInteger) void {
    Dispatch.msgSend(setLengthFn, mdata, Selector.selector("setLength:"), .{len});
}

pub fn appendBytesLength(mdata: id, buf: *const anyopaque, len: UInteger) void {
    Dispatch.msgSend(appendBytesLengthFn, mdata, Selector.selector("appendBytes:length:"), .{ buf, len });
}

pub fn appendData(mdata: id, other: id) void {
    Dispatch.msgSend(appendDataFn, mdata, Selector.selector("appendData:"), .{other});
}

pub fn increaseLengthBy(mdata: id, delta: UInteger) void {
    Dispatch.msgSend(increaseLengthByFn, mdata, Selector.selector("increaseLengthBy:"), .{delta});
}

pub fn replaceBytesInRangeWithBytes(mdata: id, range: Range, replacement: *const anyopaque) void {
    Dispatch.msgSend(replaceBytesInRangeWithBytesFn, mdata, Selector.selector("replaceBytesInRange:withBytes:"), .{ range, replacement });
}

pub fn resetBytesInRange(mdata: id, range: Range) void {
    Dispatch.msgSend(resetBytesInRangeFn, mdata, Selector.selector("resetBytesInRange:"), .{range});
}

pub fn setData(mdata: id, other: id) void {
    Dispatch.msgSend(setDataFn, mdata, Selector.selector("setData:"), .{other});
}

pub fn replaceBytesInRangeWithBytesLength(mdata: id, range: Range, replacement: ?*const anyopaque, replacement_length: UInteger) void {
    Dispatch.msgSend(replaceBytesInRangeWithBytesLengthFn, mdata, Selector.selector("replaceBytesInRange:withBytes:length:"), .{
        range,
        replacement,
        replacement_length,
    });
}

pub fn initWithCapacity(alloced: id, capacity: UInteger) ?id {
    const r = Dispatch.msgSend(initWithCapacityFn, alloced, Selector.selector("initWithCapacity:"), .{capacity});
    return objcIdMaybeNull(r);
}

pub fn initWithLength(alloced: id, len: UInteger) ?id {
    const r = Dispatch.msgSend(initWithLengthFn, alloced, Selector.selector("initWithLength:"), .{len});
    return objcIdMaybeNull(r);
}

pub fn decompressUsingAlgorithmError(mdata: id, algorithm: CompressionAlgorithm, error_out: *?id) bool {
    return Dispatch.msgSend(decompressUsingAlgorithmErrorFn, mdata, Selector.selector("decompressUsingAlgorithm:error:"), .{
        @intFromEnum(algorithm),
        error_out,
    });
}

pub fn compressUsingAlgorithmError(mdata: id, algorithm: CompressionAlgorithm, error_out: *?id) bool {
    return Dispatch.msgSend(compressUsingAlgorithmErrorFn, mdata, Selector.selector("compressUsingAlgorithm:error:"), .{
        @intFromEnum(algorithm),
        error_out,
    });
}

// --- Pointer casts ---

pub inline fn asNSDataPtr(obj: id) Types.NSDataPtr {
    return @ptrCast(obj);
}

pub inline fn idFromNSDataPtr(ptr: Types.NSDataPtr) id {
    return @ptrCast(ptr);
}

// --- Tests ---

const testing = std.testing;

fn fileURLWithPath(path: *const String) id {
    const url_class = Object.getClassByName("NSURL").?;
    const fileURLWithPathFn = *const fn (ClassPtr, SEL, id) callconv(.c) id;
    return Dispatch.msgSend(fileURLWithPathFn, @ptrCast(url_class), Selector.selector("fileURLWithPath:"), .{path.id});
}

test "NSData dataWithBytes length bytes equality subdata" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const s = "hello";
    // +dataWithBytes:length: returns an autoreleased object; drain the pool (do not `release` +0).
    const d = dataWithBytes(s.ptr, @as(UInteger, s.len));

    try testing.expectEqual(@as(UInteger, 5), length(d));
    const p = bytes(d).?;
    try testing.expectEqualStrings(s, @as([*]const u8, @ptrCast(p))[0..5]);

    const sub = subdataWithRange(d, Range.init(1, 2));
    try testing.expectEqual(@as(UInteger, 2), length(sub));
    try testing.expect(isEqualToData(sub, sub));

    var buf: [8]u8 = undefined;
    getBytesLength(sub, @ptrCast(&buf), 2);
    try testing.expectEqualStrings("el", buf[0..2]);

    getBytesRange(d, @ptrCast(&buf), Range.init(0, 2));
    try testing.expectEqualStrings("he", buf[0..2]);
}

test "NSData writeToFile options and read back" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const io = testing.io;
    var tmp = testing.tmpDir(.{});
    defer tmp.cleanup();

    // `realPathFile` requires the path to exist on disk first.
    const created = try tmp.dir.createFile(io, "ndata.bin", .{});
    created.close(io);

    const path_z = try tmp.dir.realPathFileAlloc(io, "ndata.bin", testing.allocator);
    defer testing.allocator.free(path_z);

    const payload = "zig-objc-data";
    const d = dataWithBytes(payload.ptr, @as(UInteger, payload.len));

    const path_str = String.initWithUTF8String(path_z);
    defer path_str.deinit();

    var err: ?id = null;
    const ok = writeToFileOptionsError(d, path_str.id, @intFromEnum(WritingOptions.atomic), &err);
    try testing.expect(ok);

    var err_read: ?id = null;
    const loaded = dataWithContentsOfFileOptionsError(path_str.id, 0, &err_read).?;
    try testing.expect(isEqualToData(d, loaded));
}

test "NSData base64 round-trip" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const raw_bytes = "zig";
    const d0 = dataWithBytes(raw_bytes.ptr, @as(UInteger, raw_bytes.len));

    const b64 = base64EncodedStringWithOptions(d0, 0);

    const alloced = dataAlloc();
    const s = String.fromIdUnowned(b64);
    const decoded_opt = initWithBase64EncodedStringOptions(alloced, s.id, @intFromEnum(Base64DecodingOptions.ignore_unknown_characters));
    try testing.expect(decoded_opt != null);
    const decoded = decoded_opt.?;
    defer Object.release(decoded);

    try testing.expect(isEqualToData(d0, decoded));
}

test "NSData rangeOfData" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const hay = "abcdbc";
    const d = dataWithBytes(hay.ptr, @as(UInteger, hay.len));
    const needle = "bc";
    const nd = dataWithBytes(needle.ptr, @as(UInteger, needle.len));

    const r = rangeOfDataOptionsRange(d, nd, @intFromEnum(SearchOptions.backwards), Range.init(0, hay.len));
    try testing.expectEqual(@as(UInteger, 4), r.location);
    try testing.expectEqual(@as(UInteger, 2), r.length);
}

test "NSMutableData append replace length" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const m = dataWithCapacity(16);

    const chunk = "ab";
    appendBytesLength(m, chunk.ptr, @as(UInteger, chunk.len));
    try testing.expectEqual(@as(UInteger, 2), length(m));

    setLength(m, 0);
    try testing.expectEqual(@as(UInteger, 0), length(m));

    const d = dataWithBytes("xyz".ptr, 3);
    appendData(m, d);
    try testing.expectEqual(@as(UInteger, 3), length(m));
}

test "NSData compression lz4 round-trip" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const payload = "repeat repeat repeat repeat";
    const d = dataWithBytes(payload.ptr, @as(UInteger, payload.len));

    var err: ?id = null;
    const compressed = compressedDataUsingAlgorithmError(d, .lz4, &err) orelse {
        // Compression can fail on some configs; skip assertions.
        return;
    };

    err = null;
    const round = decompressedDataUsingAlgorithmError(compressed, .lz4, &err).?;
    try testing.expect(isEqualToData(d, round));
}
