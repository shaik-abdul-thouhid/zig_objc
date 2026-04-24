const Types = @import("./types.zig");
const Dispatch = @import("./dispatch.zig");
const Selector = @import("./selector.zig");
const AutoreleasePool = @import("./autorelease_pool.zig");

const Bool = Types.Bool;
const id = Types.id;
const ClassPtr = Types.ClassPtr;
const SEL = Types.SEL;
const Protocol = Types.Protocol;

extern fn objc_getClass(cls_name: [*:0]const u8) ?ClassPtr;
extern fn objc_getProtocol(name: [*:0]const u8) ?Protocol;

const classFn = *const fn (id, SEL) callconv(.c) ClassPtr;
const isKindOfClassFn = *const fn (id, SEL, ClassPtr) callconv(.c) Bool;
const isProxyFn = *const fn (id, SEL) callconv(.c) Bool;
const isMemberOfClassFn = *const fn (id, SEL, ClassPtr) callconv(.c) Bool;
const conformsToProtocolFn = *const fn (id, SEL, Protocol) callconv(.c) Bool;
const allocFn = *const fn (ClassPtr, SEL) callconv(.c) id;
const initFn = *const fn (id, SEL) callconv(.c) id;
const releaseFn = *const fn (id, SEL) callconv(.c) void;
const retainFn = *const fn (id, SEL) callconv(.c) id;
const autoreleaseFn = *const fn (id, SEL) callconv(.c) id;
const respondsToSelectorFn = *const fn (id, SEL, SEL) callconv(.c) Bool;
const descriptionFn = *const fn (id, SEL) callconv(.c) id;
const isEqualFn = *const fn (id, SEL, id) callconv(.c) Bool;
const hashFn = *const fn (id, SEL) callconv(.c) Types.UInteger;

// Selectors are registered at runtime via `sel_registerName`; call `Selector.selector` inside
// each function so names stay `comptime` while registration does not run at comptime.
//
// These wrappers do not validate `id` / `ClassPtr` / `Protocol` for null or garbage; messaging
// nil is usually a no-op in ObjC, but `release`/`init`/etc. on invalid pointers is undefined.
pub fn getClassByName(cls_name: [:0]const u8) ?ClassPtr {
    return objc_getClass(cls_name);
}

pub fn getProtocol(name: [:0]const u8) ?Protocol {
    return objc_getProtocol(name);
}

pub fn getClassOf(receiver: id) ClassPtr {
    return Dispatch.msgSend(classFn, receiver, Selector.selector("class"), .{});
}

pub fn isKindOfClass(receiver: id, cls: ClassPtr) Bool {
    return Dispatch.msgSend(isKindOfClassFn, receiver, Selector.selector("isKindOfClass:"), .{cls});
}

pub fn isProxy(receiver: id) Bool {
    return Dispatch.msgSend(isProxyFn, receiver, Selector.selector("isProxy"), .{});
}

pub fn isMemberOfClass(receiver: id, cls: ClassPtr) Bool {
    return Dispatch.msgSend(isMemberOfClassFn, receiver, Selector.selector("isMemberOfClass:"), .{cls});
}

pub fn conformsToProtocol(receiver: id, protocol: Protocol) Bool {
    return Dispatch.msgSend(conformsToProtocolFn, receiver, Selector.selector("conformsToProtocol:"), .{protocol});
}

pub fn alloc(receiver: ClassPtr) id {
    return Dispatch.msgSend(allocFn, receiver, Selector.selector("alloc"), .{});
}

pub fn init(obj: id) id {
    return Dispatch.msgSend(initFn, obj, Selector.selector("init"), .{});
}

pub fn release(obj: id) void {
    return Dispatch.msgSend(releaseFn, obj, Selector.selector("release"), .{});
}

pub fn retain(obj: id) id {
    return Dispatch.msgSend(retainFn, obj, Selector.selector("retain"), .{});
}

pub fn autorelease(obj: id) id {
    return Dispatch.msgSend(autoreleaseFn, obj, Selector.selector("autorelease"), .{});
}

pub fn respondsToSelector(receiver: id, sel: SEL) Bool {
    return Dispatch.msgSend(respondsToSelectorFn, receiver, Selector.selector("respondsToSelector:"), .{sel});
}

/// Returns `description` as `id` (typically an `NSString`; use `String.fromIdUnowned` to wrap).
pub fn descriptionId(receiver: id) id {
    return Dispatch.msgSend(descriptionFn, receiver, Selector.selector("description"), .{});
}

pub fn isEqual(receiver: id, other: id) Bool {
    return Dispatch.msgSend(isEqualFn, receiver, Selector.selector("isEqual:"), .{other});
}

pub fn hash(receiver: id) Types.UInteger {
    return Dispatch.msgSend(hashFn, receiver, Selector.selector("hash"), .{});
}

const testing = @import("std").testing;

test "Object NSString class metadata and lifecycle" {
    const nsstring = getClassByName("NSString").?;
    try testing.expect(@intFromPtr(nsstring) != 0);

    const nsobject = getClassByName("NSObject").?;
    try testing.expect(@intFromPtr(nsobject) != 0);

    const obj = init(alloc(nsstring));
    defer release(obj);

    const concrete = getClassOf(obj);
    try testing.expect(@intFromPtr(concrete) != 0);
    try testing.expect(isMemberOfClass(obj, concrete));
    try testing.expect(isKindOfClass(obj, nsstring));
    try testing.expect(isKindOfClass(obj, nsobject));
    try testing.expect(!isMemberOfClass(obj, nsobject));
    try testing.expect(!isProxy(obj));
}

test "Object getClassByName missing class is null" {
    try testing.expect(getClassByName("ZptoNonexistentClassName") == null);
}

test "Object IB kind and protocol on NSString instance" {
    const nsstring = getClassByName("NSString").?;
    const nsnumber = getClassByName("NSNumber").?;
    try testing.expect(@intFromPtr(nsnumber) != 0);

    const obj = init(alloc(nsstring));
    defer release(obj);

    try testing.expect(isKindOfClass(obj, nsstring));
    try testing.expect(!isKindOfClass(obj, nsnumber));

    const p = getProtocol("NSObject").?;
    try testing.expect(conformsToProtocol(obj, p));
}

test "Object retain autorelease balances" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const nsstring = getClassByName("NSString").?;
    const obj = init(alloc(nsstring));
    defer release(obj);

    _ = retain(obj);
    _ = autorelease(obj);
}

test "Object respondsToSelector description isEqual hash" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const nsstring = getClassByName("NSString").?;
    const obj = init(alloc(nsstring));
    defer release(obj);

    try testing.expect(respondsToSelector(obj, Selector.selector("length")));
    const desc = descriptionId(obj);
    try testing.expect(@intFromPtr(desc) != 0);
    try testing.expect(isEqual(obj, obj));
    const h = hash(obj);
    try testing.expectEqual(h, hash(obj));
}
