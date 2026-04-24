/// ObjC array pointer. `owned == true` after `alloc`/`init`; call [`deinit`] to `release`.
/// Class convenience methods (`+array`, `+arrayWithObject:`, etc.) return autoreleased objects — set `owned = false` or drain an [`AutoreleasePool`].
///
/// NSArray / NSMutableArray wrappers use `objc_msgSend` with fixed signatures only.
///
/// **Omitted** (Objective-C blocks, unsupported in this layer): enumeration and predicate blocks,
/// `sortedArrayUsingComparator:`, `sortedArrayWithOptions:usingComparator:`, binary search with
/// `NSComparator`, `differenceFromArray:*`, `applyDifference:`, and variadic
/// `+arrayWithObjects:, ...` / `-initWithObjects:, ...` — use [`arrayWithObjectsCount`] /
/// [`initWithObjectsCount`] instead.
id: Types.id,
owned: bool = true,

const std = @import("std");
const Types = @import("./types.zig");
const Object = @import("./object.zig");
const Dispatch = @import("./dispatch.zig");
const Selector = @import("./selector.zig");
const Range = @import("./range.zig").Range;
const String = @import("./string.zig");
const AutoreleasePool = @import("./autorelease_pool.zig");

const NSArray = @This();

pub const SortFunction = *const fn (Types.id, Types.id, ?*anyopaque) callconv(.c) Types.NSInteger;

// --- Class getters ---

pub inline fn getNSArrayClass() Types.ClassPtr {
    return Object.getClassByName("NSArray").?;
}

pub inline fn getNSMutableArrayClass() Types.ClassPtr {
    return Object.getClassByName("NSMutableArray").?;
}

fn allocateArray(cls: Types.ClassPtr) Types.id {
    return Object.alloc(cls);
}

// --- Factories (class) ---

const arrayFn = *const fn (Types.ClassPtr, Types.SEL) callconv(.c) Types.id;
const arrayWithObjectFn = *const fn (Types.ClassPtr, Types.SEL, Types.id) callconv(.c) Types.id;
const arrayWithObjectsCountClassFn = *const fn (Types.ClassPtr, Types.SEL, [*]const Types.id, Types.UInteger) callconv(.c) Types.id;
const arrayWithArrayFn = *const fn (Types.ClassPtr, Types.SEL, Types.id) callconv(.c) Types.id;
const arrayWithContentsOfURLErrorClassFn = *const fn (Types.ClassPtr, Types.SEL, Types.id, *?Types.id) callconv(.c) ?Types.id;

/// `+[NSArray array]` — autoreleased.
pub fn array() NSArray {
    const raw = Dispatch.msgSend(arrayFn, @ptrCast(getNSArrayClass()), Selector.selector("array"), .{});
    return .{ .id = raw, .owned = false };
}

/// `+[NSArray arrayWithObject:]` — autoreleased.
pub fn arrayWithObject(an_object: Types.id) NSArray {
    const raw = Dispatch.msgSend(arrayWithObjectFn, @ptrCast(getNSArrayClass()), Selector.selector("arrayWithObject:"), .{an_object});
    return .{ .id = raw, .owned = false };
}

/// `+[NSArray arrayWithObjects:count:]`. `objects` may be empty when `count == 0`.
pub fn arrayWithObjectsCount(objects: [*]const Types.id, cnt: usize) NSArray {
    const raw = Dispatch.msgSend(arrayWithObjectsCountClassFn, @ptrCast(getNSArrayClass()), Selector.selector("arrayWithObjects:count:"), .{
        objects,
        @as(Types.UInteger, cnt),
    });
    return .{ .id = raw, .owned = false };
}

/// `+[NSArray arrayWithArray:]` — autoreleased.
pub fn arrayWithArray(other: *const NSArray) NSArray {
    const raw = Dispatch.msgSend(arrayWithArrayFn, @ptrCast(getNSArrayClass()), Selector.selector("arrayWithArray:"), .{other.id});
    return .{ .id = raw, .owned = false };
}

/// `+[NSArray arrayWithContentsOfURL:error:]`
pub fn arrayWithContentsOfURLError(url: Types.id, error_out: *?Types.id) ?NSArray {
    const raw = Dispatch.msgSend(arrayWithContentsOfURLErrorClassFn, @ptrCast(getNSArrayClass()), Selector.selector("arrayWithContentsOfURL:error:"), .{ url, error_out });
    if (raw) |rid| return .{ .id = rid, .owned = false };
    return null;
}

const mutableArrayFn = *const fn (Types.ClassPtr, Types.SEL) callconv(.c) Types.id;
const arrayWithCapacityFn = *const fn (Types.ClassPtr, Types.SEL, Types.UInteger) callconv(.c) Types.id;

/// `+[NSMutableArray array]` — empty mutable array, autoreleased.
pub fn mutableArray() NSArray {
    const raw = Dispatch.msgSend(mutableArrayFn, @ptrCast(getNSMutableArrayClass()), Selector.selector("array"), .{});
    return .{ .id = raw, .owned = false };
}

/// `+[NSMutableArray arrayWithCapacity:]` — autoreleased.
pub fn arrayWithCapacity(capacity: usize) NSArray {
    const raw = Dispatch.msgSend(arrayWithCapacityFn, @ptrCast(getNSMutableArrayClass()), Selector.selector("arrayWithCapacity:"), .{@as(Types.UInteger, capacity)});
    return .{ .id = raw, .owned = false };
}

// --- Initializers (alloc + init => owned) ---

const initFn = *const fn (Types.id, Types.SEL) callconv(.c) Types.id;
const initWithObjectsCountFn = *const fn (Types.id, Types.SEL, [*]const Types.id, Types.UInteger) callconv(.c) Types.id;
const initWithArrayFn = *const fn (Types.id, Types.SEL, Types.id) callconv(.c) Types.id;
const initWithArrayCopyItemsFn = *const fn (Types.id, Types.SEL, Types.id, Types.Bool) callconv(.c) Types.id;
const initWithCapacityFn = *const fn (Types.id, Types.SEL, Types.UInteger) callconv(.c) Types.id;
const initWithContentsOfURLErrorFn = *const fn (Types.id, Types.SEL, Types.id, *?Types.id) callconv(.c) ?Types.id;

/// `- [[NSArray alloc] init]`
pub fn new() NSArray {
    const cls = getNSArrayClass();
    const obj = allocateArray(cls);
    const initialized = Dispatch.msgSend(initFn, obj, Selector.selector("init"), .{});
    return .{ .id = initialized, .owned = true };
}

/// `- initWithObjects:count:` after `alloc`.
pub fn initWithObjectsCount(objects: [*]const Types.id, cnt: usize) NSArray {
    const obj = allocateArray(getNSArrayClass());
    const initialized = Dispatch.msgSend(initWithObjectsCountFn, obj, Selector.selector("initWithObjects:count:"), .{
        objects,
        @as(Types.UInteger, cnt),
    });
    return .{ .id = initialized, .owned = true };
}

/// `- initWithArray:`
pub fn initWithArray(other: *const NSArray) NSArray {
    const obj = allocateArray(getNSArrayClass());
    const initialized = Dispatch.msgSend(initWithArrayFn, obj, Selector.selector("initWithArray:"), .{other.id});
    return .{ .id = initialized, .owned = true };
}

/// `- initWithArray:copyItems:`
pub fn initWithArrayCopyItems(other: *const NSArray, copy_items: bool) NSArray {
    const obj = allocateArray(getNSArrayClass());
    const initialized = Dispatch.msgSend(initWithArrayCopyItemsFn, obj, Selector.selector("initWithArray:copyItems:"), .{ other.id, copy_items });
    return .{ .id = initialized, .owned = true };
}

/// `- [[NSMutableArray alloc] init]`
pub fn newMutable() NSArray {
    const cls = getNSMutableArrayClass();
    const obj = allocateArray(cls);
    const initialized = Dispatch.msgSend(initFn, obj, Selector.selector("init"), .{});
    return .{ .id = initialized, .owned = true };
}

/// `- [[NSMutableArray alloc] initWithCapacity:]`
pub fn initMutableWithCapacity(capacity: usize) NSArray {
    const obj = allocateArray(getNSMutableArrayClass());
    const initialized = Dispatch.msgSend(initWithCapacityFn, obj, Selector.selector("initWithCapacity:"), .{@as(Types.UInteger, capacity)});
    return .{ .id = initialized, .owned = true };
}

/// `- initWithContentsOfURL:error:` after `alloc` on NSArray.
pub fn initWithContentsOfURLError(url: Types.id, error_out: *?Types.id) ?NSArray {
    const obj = allocateArray(getNSArrayClass());
    const initialized = Dispatch.msgSend(initWithContentsOfURLErrorFn, obj, Selector.selector("initWithContentsOfURL:error:"), .{ url, error_out });
    if (initialized) |rid| return .{ .id = rid, .owned = true };
    Object.release(obj);
    return null;
}

pub inline fn fromIdUnowned(obj: Types.id) NSArray {
    return .{ .id = obj, .owned = false };
}

pub inline fn fromIdOwned(obj: Types.id) NSArray {
    return .{ .id = obj, .owned = true };
}

pub fn deinit(self: *const NSArray) void {
    if (!self.owned) return;
    Object.release(self.id);
}

// --- Core ---

const countFn = *const fn (Types.id, Types.SEL) callconv(.c) Types.UInteger;
const objectAtIndexFn = *const fn (Types.id, Types.SEL, Types.UInteger) callconv(.c) Types.id;
const objectAtIndexedSubscriptFn = *const fn (Types.id, Types.SEL, Types.UInteger) callconv(.c) Types.id;

pub fn count(self: *const NSArray) usize {
    return @as(usize, Dispatch.msgSend(countFn, self.id, Selector.selector("count"), .{}));
}

pub fn objectAtIndex(self: *const NSArray, index: usize) Types.id {
    return Dispatch.msgSend(objectAtIndexFn, self.id, Selector.selector("objectAtIndex:"), .{@as(Types.UInteger, index)});
}

pub fn objectAtIndexedSubscript(self: *const NSArray, idx: usize) Types.id {
    return Dispatch.msgSend(objectAtIndexedSubscriptFn, self.id, Selector.selector("objectAtIndexedSubscript:"), .{@as(Types.UInteger, idx)});
}

// --- Extended ---

const arrayByAddingObjectFn = *const fn (Types.id, Types.SEL, Types.id) callconv(.c) Types.id;
const arrayByAddingObjectsFromArrayFn = *const fn (Types.id, Types.SEL, Types.id) callconv(.c) Types.id;
const componentsJoinedByStringFn = *const fn (Types.id, Types.SEL, Types.id) callconv(.c) Types.id;
const containsObjectFn = *const fn (Types.id, Types.SEL, Types.id) callconv(.c) Types.Bool;
const descriptionWithLocaleFn = *const fn (Types.id, Types.SEL, Types.id) callconv(.c) Types.id;
const descriptionWithLocaleIndentFn = *const fn (Types.id, Types.SEL, Types.id, Types.UInteger) callconv(.c) Types.id;
const firstObjectCommonWithArrayFn = *const fn (Types.id, Types.SEL, Types.id) callconv(.c) ?Types.id;
const getObjectsRangeFn = *const fn (Types.id, Types.SEL, [*]Types.id, Range) callconv(.c) void;
const indexOfObjectFn = *const fn (Types.id, Types.SEL, Types.id) callconv(.c) Types.UInteger;
const indexOfObjectInRangeFn = *const fn (Types.id, Types.SEL, Types.id, Range) callconv(.c) Types.UInteger;
const indexOfObjectIdenticalToFn = *const fn (Types.id, Types.SEL, Types.id) callconv(.c) Types.UInteger;
const indexOfObjectIdenticalToInRangeFn = *const fn (Types.id, Types.SEL, Types.id, Range) callconv(.c) Types.UInteger;
const isEqualToArrayFn = *const fn (Types.id, Types.SEL, Types.id) callconv(.c) Types.Bool;
const firstObjectFn = *const fn (Types.id, Types.SEL) callconv(.c) ?Types.id;
const lastObjectFn = *const fn (Types.id, Types.SEL) callconv(.c) ?Types.id;
const objectEnumeratorFn = *const fn (Types.id, Types.SEL) callconv(.c) Types.id;
const reverseObjectEnumeratorFn = *const fn (Types.id, Types.SEL) callconv(.c) Types.id;
const sortedArrayHintFn = *const fn (Types.id, Types.SEL) callconv(.c) Types.id;
const sortedArrayUsingFunctionContextFn = *const fn (Types.id, Types.SEL, SortFunction, ?*anyopaque) callconv(.c) Types.id;
const sortedArrayUsingFunctionContextHintFn = *const fn (Types.id, Types.SEL, SortFunction, ?*anyopaque, Types.id) callconv(.c) Types.id;
const sortedArrayUsingSelectorFn = *const fn (Types.id, Types.SEL, Types.SEL) callconv(.c) Types.id;
const subarrayWithRangeFn = *const fn (Types.id, Types.SEL, Range) callconv(.c) Types.id;
const writeToURLErrorFn = *const fn (Types.id, Types.SEL, Types.id, *?Types.id) callconv(.c) Types.Bool;
const objectsAtIndexesFn = *const fn (Types.id, Types.SEL, Types.id) callconv(.c) Types.id;
const makeObjectsPerformSelectorFn = *const fn (Types.id, Types.SEL, Types.SEL) callconv(.c) void;
const makeObjectsPerformSelectorWithObjectFn = *const fn (Types.id, Types.SEL, Types.SEL, Types.id) callconv(.c) void;

pub fn arrayByAddingObject(self: *const NSArray, an_object: Types.id) NSArray {
    const raw = Dispatch.msgSend(arrayByAddingObjectFn, self.id, Selector.selector("arrayByAddingObject:"), .{an_object});
    return fromIdUnowned(raw);
}

pub fn arrayByAddingObjectsFromArray(self: *const NSArray, other: *const NSArray) NSArray {
    const raw = Dispatch.msgSend(arrayByAddingObjectsFromArrayFn, self.id, Selector.selector("arrayByAddingObjectsFromArray:"), .{other.id});
    return fromIdUnowned(raw);
}

pub fn componentsJoinedByString(self: *const NSArray, separator: *const String) String {
    const raw = Dispatch.msgSend(componentsJoinedByStringFn, self.id, Selector.selector("componentsJoinedByString:"), .{separator.id});
    return String.fromIdUnowned(raw);
}

pub fn containsObject(self: *const NSArray, an_object: Types.id) bool {
    return Dispatch.msgSend(containsObjectFn, self.id, Selector.selector("containsObject:"), .{an_object});
}

/// `description` as NSString — autoreleased; use `String.fromIdUnowned`.
pub fn descriptionString(self: *const NSArray) String {
    return String.fromIdUnowned(Object.descriptionId(self.id));
}

pub fn descriptionWithLocale(self: *const NSArray, locale: ?Types.id) String {
    const raw = Dispatch.msgSend(descriptionWithLocaleFn, self.id, Selector.selector("descriptionWithLocale:"), .{locale orelse @as(Types.id, @ptrFromInt(0))});
    return String.fromIdUnowned(raw);
}

pub fn descriptionWithLocaleIndent(self: *const NSArray, locale: ?Types.id, level: usize) String {
    const loc = locale orelse @as(Types.id, @ptrFromInt(0));
    const raw = Dispatch.msgSend(descriptionWithLocaleIndentFn, self.id, Selector.selector("descriptionWithLocale:indent:"), .{ loc, @as(Types.UInteger, level) });
    return String.fromIdUnowned(raw);
}

pub fn firstObjectCommonWithArray(self: *const NSArray, other: *const NSArray) ?Types.id {
    return Dispatch.msgSend(firstObjectCommonWithArrayFn, self.id, Selector.selector("firstObjectCommonWithArray:"), .{other.id});
}

/// Fills `buffer[0..range.length]` with objects from `range`.
pub fn getObjectsRange(self: *const NSArray, buffer: [*]Types.id, range: Range) void {
    Dispatch.msgSend(getObjectsRangeFn, self.id, Selector.selector("getObjects:range:"), .{ buffer, range });
}

pub fn indexOfObject(self: *const NSArray, an_object: Types.id) usize {
    return @as(usize, Dispatch.msgSend(indexOfObjectFn, self.id, Selector.selector("indexOfObject:"), .{an_object}));
}

pub fn indexOfObjectInRange(self: *const NSArray, an_object: Types.id, range: Range) usize {
    return @as(usize, Dispatch.msgSend(indexOfObjectInRangeFn, self.id, Selector.selector("indexOfObject:inRange:"), .{ an_object, range }));
}

pub fn indexOfObjectIdenticalTo(self: *const NSArray, an_object: Types.id) usize {
    return @as(usize, Dispatch.msgSend(indexOfObjectIdenticalToFn, self.id, Selector.selector("indexOfObjectIdenticalTo:"), .{an_object}));
}

pub fn indexOfObjectIdenticalToInRange(self: *const NSArray, an_object: Types.id, range: Range) usize {
    return @as(usize, Dispatch.msgSend(indexOfObjectIdenticalToInRangeFn, self.id, Selector.selector("indexOfObjectIdenticalTo:inRange:"), .{ an_object, range }));
}

pub fn isEqualToArray(self: *const NSArray, other: *const NSArray) bool {
    return Dispatch.msgSend(isEqualToArrayFn, self.id, Selector.selector("isEqualToArray:"), .{other.id});
}

pub fn firstObject(self: *const NSArray) ?Types.id {
    return Dispatch.msgSend(firstObjectFn, self.id, Selector.selector("firstObject"), .{});
}

pub fn lastObject(self: *const NSArray) ?Types.id {
    return Dispatch.msgSend(lastObjectFn, self.id, Selector.selector("lastObject"), .{});
}

/// Returns `NSEnumerator *` as `id`.
pub fn objectEnumerator(self: *const NSArray) Types.id {
    return Dispatch.msgSend(objectEnumeratorFn, self.id, Selector.selector("objectEnumerator"), .{});
}

pub fn reverseObjectEnumerator(self: *const NSArray) Types.id {
    return Dispatch.msgSend(reverseObjectEnumeratorFn, self.id, Selector.selector("reverseObjectEnumerator"), .{});
}

/// Hint data for sorting; autorelease pool should drain the result if unowned.
pub fn sortedArrayHintId(self: *const NSArray) Types.id {
    return Dispatch.msgSend(sortedArrayHintFn, self.id, Selector.selector("sortedArrayHint"), .{});
}

pub fn sortedArrayUsingFunctionContext(self: *const NSArray, comparator: SortFunction, context: ?*anyopaque) NSArray {
    const raw = Dispatch.msgSend(sortedArrayUsingFunctionContextFn, self.id, Selector.selector("sortedArrayUsingFunction:context:"), .{ comparator, context });
    return fromIdUnowned(raw);
}

pub fn sortedArrayUsingFunctionContextHint(self: *const NSArray, comparator: SortFunction, context: ?*anyopaque, hint: Types.id) NSArray {
    const raw = Dispatch.msgSend(sortedArrayUsingFunctionContextHintFn, self.id, Selector.selector("sortedArrayUsingFunction:context:hint:"), .{ comparator, context, hint });
    return fromIdUnowned(raw);
}

pub fn sortedArrayUsingSelector(self: *const NSArray, comparator_sel: Types.SEL) NSArray {
    const raw = Dispatch.msgSend(sortedArrayUsingSelectorFn, self.id, Selector.selector("sortedArrayUsingSelector:"), .{comparator_sel});
    return fromIdUnowned(raw);
}

pub fn subarrayWithRange(self: *const NSArray, range: Range) NSArray {
    const raw = Dispatch.msgSend(subarrayWithRangeFn, self.id, Selector.selector("subarrayWithRange:"), .{range});
    return fromIdUnowned(raw);
}

pub fn writeToURLError(self: *const NSArray, url: Types.id, error_out: *?Types.id) bool {
    return Dispatch.msgSend(writeToURLErrorFn, self.id, Selector.selector("writeToURL:error:"), .{ url, error_out });
}

pub fn objectsAtIndexes(self: *const NSArray, indexes: Types.id) NSArray {
    const raw = Dispatch.msgSend(objectsAtIndexesFn, self.id, Selector.selector("objectsAtIndexes:"), .{indexes});
    return fromIdUnowned(raw);
}

pub fn makeObjectsPerformSelector(self: *const NSArray, a_selector: Types.SEL) void {
    Dispatch.msgSend(makeObjectsPerformSelectorFn, self.id, Selector.selector("makeObjectsPerformSelector:"), .{a_selector});
}

pub fn makeObjectsPerformSelectorWithObject(self: *const NSArray, a_selector: Types.SEL, argument: Types.id) void {
    Dispatch.msgSend(makeObjectsPerformSelectorWithObjectFn, self.id, Selector.selector("makeObjectsPerformSelector:withObject:"), .{ a_selector, argument });
}

// --- NSMutableArray ---

const addObjectFn = *const fn (Types.id, Types.SEL, Types.id) callconv(.c) void;
const insertObjectAtIndexFn = *const fn (Types.id, Types.SEL, Types.id, Types.UInteger) callconv(.c) void;
const removeLastObjectFn = *const fn (Types.id, Types.SEL) callconv(.c) void;
const removeObjectAtIndexFn = *const fn (Types.id, Types.SEL, Types.UInteger) callconv(.c) void;
const replaceObjectAtIndexWithObjectFn = *const fn (Types.id, Types.SEL, Types.UInteger, Types.id) callconv(.c) void;
const addObjectsFromArrayFn = *const fn (Types.id, Types.SEL, Types.id) callconv(.c) void;
const exchangeObjectAtIndexWithObjectAtIndexFn = *const fn (Types.id, Types.SEL, Types.UInteger, Types.UInteger) callconv(.c) void;
const removeAllObjectsFn = *const fn (Types.id, Types.SEL) callconv(.c) void;
const removeObjectFn = *const fn (Types.id, Types.SEL, Types.id) callconv(.c) void;
const removeObjectInRangeFn = *const fn (Types.id, Types.SEL, Types.id, Range) callconv(.c) void;
const removeObjectIdenticalToFn = *const fn (Types.id, Types.SEL, Types.id) callconv(.c) void;
const removeObjectIdenticalToInRangeFn = *const fn (Types.id, Types.SEL, Types.id, Range) callconv(.c) void;
const removeObjectsInArrayFn = *const fn (Types.id, Types.SEL, Types.id) callconv(.c) void;
const removeObjectsInRangeFn = *const fn (Types.id, Types.SEL, Range) callconv(.c) void;
const replaceObjectsInRangeWithObjectsFromArrayFn = *const fn (Types.id, Types.SEL, Range, Types.id) callconv(.c) void;
const replaceObjectsInRangeWithObjectsFromArrayRangeFn = *const fn (Types.id, Types.SEL, Range, Types.id, Range) callconv(.c) void;
const setArrayFn = *const fn (Types.id, Types.SEL, Types.id) callconv(.c) void;
const sortUsingFunctionContextFn = *const fn (Types.id, Types.SEL, SortFunction, ?*anyopaque) callconv(.c) void;
const sortUsingSelectorFn = *const fn (Types.id, Types.SEL, Types.SEL) callconv(.c) void;
const insertObjectsAtIndexesFn = *const fn (Types.id, Types.SEL, Types.id, Types.id) callconv(.c) void;
const removeObjectsAtIndexesFn = *const fn (Types.id, Types.SEL, Types.id) callconv(.c) void;
const replaceObjectsAtIndexesWithObjectsFn = *const fn (Types.id, Types.SEL, Types.id, Types.id) callconv(.c) void;
const setObjectAtIndexedSubscriptFn = *const fn (Types.id, Types.SEL, Types.id, Types.UInteger) callconv(.c) void;

pub fn addObject(self: *const NSArray, an_object: Types.id) void {
    Dispatch.msgSend(addObjectFn, self.id, Selector.selector("addObject:"), .{an_object});
}

pub fn insertObjectAtIndex(self: *const NSArray, an_object: Types.id, index: usize) void {
    Dispatch.msgSend(insertObjectAtIndexFn, self.id, Selector.selector("insertObject:atIndex:"), .{ an_object, @as(Types.UInteger, index) });
}

pub fn removeLastObject(self: *const NSArray) void {
    Dispatch.msgSend(removeLastObjectFn, self.id, Selector.selector("removeLastObject"), .{});
}

pub fn removeObjectAtIndex(self: *const NSArray, index: usize) void {
    Dispatch.msgSend(removeObjectAtIndexFn, self.id, Selector.selector("removeObjectAtIndex:"), .{@as(Types.UInteger, index)});
}

pub fn replaceObjectAtIndexWithObject(self: *const NSArray, index: usize, an_object: Types.id) void {
    Dispatch.msgSend(replaceObjectAtIndexWithObjectFn, self.id, Selector.selector("replaceObjectAtIndex:withObject:"), .{ @as(Types.UInteger, index), an_object });
}

pub fn addObjectsFromArray(self: *const NSArray, other: *const NSArray) void {
    Dispatch.msgSend(addObjectsFromArrayFn, self.id, Selector.selector("addObjectsFromArray:"), .{other.id});
}

pub fn exchangeObjectAtIndexWithObjectAtIndex(self: *const NSArray, idx1: usize, idx2: usize) void {
    Dispatch.msgSend(exchangeObjectAtIndexWithObjectAtIndexFn, self.id, Selector.selector("exchangeObjectAtIndex:withObjectAtIndex:"), .{
        @as(Types.UInteger, idx1),
        @as(Types.UInteger, idx2),
    });
}

pub fn removeAllObjects(self: *const NSArray) void {
    Dispatch.msgSend(removeAllObjectsFn, self.id, Selector.selector("removeAllObjects"), .{});
}

pub fn removeObject(self: *const NSArray, an_object: Types.id) void {
    Dispatch.msgSend(removeObjectFn, self.id, Selector.selector("removeObject:"), .{an_object});
}

pub fn removeObjectInRange(self: *const NSArray, an_object: Types.id, range: Range) void {
    Dispatch.msgSend(removeObjectInRangeFn, self.id, Selector.selector("removeObject:inRange:"), .{ an_object, range });
}

pub fn removeObjectIdenticalTo(self: *const NSArray, an_object: Types.id) void {
    Dispatch.msgSend(removeObjectIdenticalToFn, self.id, Selector.selector("removeObjectIdenticalTo:"), .{an_object});
}

pub fn removeObjectIdenticalToInRange(self: *const NSArray, an_object: Types.id, range: Range) void {
    Dispatch.msgSend(removeObjectIdenticalToInRangeFn, self.id, Selector.selector("removeObjectIdenticalTo:inRange:"), .{ an_object, range });
}

pub fn removeObjectsInArray(self: *const NSArray, other: *const NSArray) void {
    Dispatch.msgSend(removeObjectsInArrayFn, self.id, Selector.selector("removeObjectsInArray:"), .{other.id});
}

pub fn removeObjectsInRange(self: *const NSArray, range: Range) void {
    Dispatch.msgSend(removeObjectsInRangeFn, self.id, Selector.selector("removeObjectsInRange:"), .{range});
}

pub fn replaceObjectsInRangeWithObjectsFromArray(self: *const NSArray, range: Range, other: *const NSArray) void {
    Dispatch.msgSend(replaceObjectsInRangeWithObjectsFromArrayFn, self.id, Selector.selector("replaceObjectsInRange:withObjectsFromArray:"), .{ range, other.id });
}

pub fn replaceObjectsInRangeWithObjectsFromArrayRange(self: *const NSArray, range: Range, other: *const NSArray, other_range: Range) void {
    Dispatch.msgSend(replaceObjectsInRangeWithObjectsFromArrayRangeFn, self.id, Selector.selector("replaceObjectsInRange:withObjectsFromArray:range:"), .{ range, other.id, other_range });
}

pub fn setArray(self: *const NSArray, other: *const NSArray) void {
    Dispatch.msgSend(setArrayFn, self.id, Selector.selector("setArray:"), .{other.id});
}

pub fn sortUsingFunctionContext(self: *const NSArray, comparator: SortFunction, context: ?*anyopaque) void {
    Dispatch.msgSend(sortUsingFunctionContextFn, self.id, Selector.selector("sortUsingFunction:context:"), .{ comparator, context });
}

pub fn sortUsingSelector(self: *const NSArray, comparator_sel: Types.SEL) void {
    Dispatch.msgSend(sortUsingSelectorFn, self.id, Selector.selector("sortUsingSelector:"), .{comparator_sel});
}

pub fn insertObjectsAtIndexes(self: *const NSArray, objects: *const NSArray, indexes: Types.id) void {
    Dispatch.msgSend(insertObjectsAtIndexesFn, self.id, Selector.selector("insertObjects:atIndexes:"), .{ objects.id, indexes });
}

pub fn removeObjectsAtIndexes(self: *const NSArray, indexes: Types.id) void {
    Dispatch.msgSend(removeObjectsAtIndexesFn, self.id, Selector.selector("removeObjectsAtIndexes:"), .{indexes});
}

pub fn replaceObjectsAtIndexesWithObjects(self: *const NSArray, indexes: Types.id, objects: *const NSArray) void {
    Dispatch.msgSend(replaceObjectsAtIndexesWithObjectsFn, self.id, Selector.selector("replaceObjectsAtIndexes:withObjects:"), .{ indexes, objects.id });
}

pub fn setObjectAtIndexedSubscript(self: *const NSArray, obj: Types.id, idx: usize) void {
    Dispatch.msgSend(setObjectAtIndexedSubscriptFn, self.id, Selector.selector("setObject:atIndexedSubscript:"), .{ obj, @as(Types.UInteger, idx) });
}

// --- Deprecated convenience (property list / legacy paths) ---

const writeToFileAtomicallyFn = *const fn (Types.id, Types.SEL, Types.id, Types.Bool) callconv(.c) Types.Bool;
const writeToURLAtomicallyFn = *const fn (Types.id, Types.SEL, Types.id, Types.Bool) callconv(.c) Types.Bool;
const initWithContentsOfFileFn = *const fn (Types.id, Types.SEL, Types.id) callconv(.c) ?Types.id;
const initWithContentsOfURLFn = *const fn (Types.id, Types.SEL, Types.id) callconv(.c) ?Types.id;

/// Deprecated: `- writeToFile:atomically:`
pub fn writeToFileAtomically(self: *const NSArray, path: *const String, atomically: bool) bool {
    return Dispatch.msgSend(writeToFileAtomicallyFn, self.id, Selector.selector("writeToFile:atomically:"), .{ path.id, atomically });
}

/// Deprecated: `- writeToURL:atomically:`
pub fn writeToURLAtomically(self: *const NSArray, url: Types.id, atomically: bool) bool {
    return Dispatch.msgSend(writeToURLAtomicallyFn, self.id, Selector.selector("writeToURL:atomically:"), .{ url, atomically });
}

/// Deprecated: `- initWithContentsOfFile:` after alloc.
pub fn initWithContentsOfFile(path: *const String) ?NSArray {
    const obj = allocateArray(getNSArrayClass());
    const initialized = Dispatch.msgSend(initWithContentsOfFileFn, obj, Selector.selector("initWithContentsOfFile:"), .{path.id});
    if (initialized) |rid| return .{ .id = rid, .owned = true };
    Object.release(obj);
    return null;
}

/// Deprecated: `- initWithContentsOfURL:` after alloc.
pub fn initWithContentsOfURL(url: Types.id) ?NSArray {
    const obj = allocateArray(getNSArrayClass());
    const initialized = Dispatch.msgSend(initWithContentsOfURLFn, obj, Selector.selector("initWithContentsOfURL:"), .{url});
    if (initialized) |rid| return .{ .id = rid, .owned = true };
    Object.release(obj);
    return null;
}

// --- Tests ---

const testing = std.testing;

fn nsstringId(s: [:0]const u8) String {
    return String.initWithUTF8String(s);
}

/// `+[NSURL fileURLWithPath:]` — returns autoreleased URL as `id`.
fn fileURLWithPath(path: *const String) Types.id {
    const url_class = Object.getClassByName("NSURL").?;
    const fileURLWithPathSel = Selector.selector("fileURLWithPath:");
    const fileURLWithPathFn = *const fn (Types.ClassPtr, Types.SEL, Types.id) callconv(.c) Types.id;
    return Dispatch.msgSend(fileURLWithPathFn, @ptrCast(url_class), fileURLWithPathSel, .{path.id});
}

fn compareStringsAscending(a: Types.id, b: Types.id, _: ?*anyopaque) callconv(.c) Types.NSInteger {
    const sa = String.fromIdUnowned(a);
    const sb = String.fromIdUnowned(b);
    return @as(Types.NSInteger, @intCast(@intFromEnum(sa.compare(&sb))));
}

test "NSArray empty and count" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const a = array();
    defer a.deinit();
    try testing.expectEqual(@as(usize, 0), a.count());
}

test "NSArray arrayWithObjects initWithObjects strings" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const s1 = nsstringId("a");
    defer s1.deinit();
    const s2 = nsstringId("b");
    defer s2.deinit();

    var objs: [2]Types.id = .{ s1.id, s2.id };
    const a = arrayWithObjectsCount(&objs, 2);
    defer a.deinit();

    try testing.expectEqual(@as(usize, 2), a.count());
    try testing.expect(Object.isEqual(a.objectAtIndex(0), s1.id));
    try testing.expect(Object.isEqual(a.objectAtIndex(1), s2.id));

    const b = initWithObjectsCount(&objs, 2);
    defer b.deinit();
    try testing.expect(b.isEqualToArray(&a));
}

test "NSMutableArray add replace remove" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const m = newMutable();
    defer m.deinit();

    const s1 = nsstringId("x");
    defer s1.deinit();
    m.addObject(s1.id);
    try testing.expectEqual(@as(usize, 1), m.count());

    const s2 = nsstringId("y");
    defer s2.deinit();
    m.addObject(s2.id);
    try testing.expectEqual(@as(usize, 2), m.count());

    const s3 = nsstringId("z");
    defer s3.deinit();
    m.replaceObjectAtIndexWithObject(0, s3.id);
    try testing.expect(Object.isEqual(m.objectAtIndex(0), s3.id));

    m.removeObjectAtIndex(1);
    try testing.expectEqual(@as(usize, 1), m.count());

    m.removeAllObjects();
    try testing.expectEqual(@as(usize, 0), m.count());
}

test "NSArray contains indexOf subarray joined" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const s1 = nsstringId("one");
    defer s1.deinit();
    const s2 = nsstringId("two");
    defer s2.deinit();
    const s3 = nsstringId("three");
    defer s3.deinit();

    var objs: [3]Types.id = .{ s1.id, s2.id, s3.id };
    const a = arrayWithObjectsCount(&objs, 3);
    defer a.deinit();

    try testing.expect(a.containsObject(s2.id));
    try testing.expectEqual(@as(usize, 1), a.indexOfObject(s2.id));

    const sub = a.subarrayWithRange(Range.init(1, 2));
    defer sub.deinit();
    try testing.expectEqual(@as(usize, 2), sub.count());

    const sep = nsstringId(",");
    defer sep.deinit();
    const joined = a.componentsJoinedByString(&sep);
    defer joined.deinit();
    try testing.expectEqualStrings("one,two,three", std.mem.span(joined.toUTF8()));
}

test "NSArray sortedArrayUsingFunction and sortedArrayUsingSelector" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const s1 = nsstringId("b");
    defer s1.deinit();
    const s2 = nsstringId("a");
    defer s2.deinit();
    var objs: [2]Types.id = .{ s1.id, s2.id };
    const a = arrayWithObjectsCount(&objs, 2);
    defer a.deinit();

    const sorted = a.sortedArrayUsingFunctionContext(compareStringsAscending, null);
    defer sorted.deinit();
    const first = String.fromIdUnowned(sorted.objectAtIndex(0));
    try testing.expectEqualStrings("a", std.mem.span(first.toUTF8()));

    const sorted2 = a.sortedArrayUsingSelector(Selector.selector("compare:"));
    defer sorted2.deinit();
    const first2 = String.fromIdUnowned(sorted2.objectAtIndex(0));
    try testing.expectEqualStrings("a", std.mem.span(first2.toUTF8()));
}

test "NSArray firstObject lastObject objectAtIndexedSubscript getObjects" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const s0 = nsstringId("only");
    defer s0.deinit();
    var objs: [1]Types.id = .{s0.id};
    const a = arrayWithObjectsCount(&objs, 1);
    defer a.deinit();

    try testing.expect(Object.isEqual(a.firstObject().?, s0.id));
    try testing.expect(Object.isEqual(a.lastObject().?, s0.id));
    try testing.expect(Object.isEqual(a.objectAtIndexedSubscript(0), s0.id));

    var buf: [4]Types.id = undefined;
    a.getObjectsRange(&buf, Range.init(0, 1));
    try testing.expect(Object.isEqual(buf[0], s0.id));
}

test "NSArray arrayByAddingObject isEqualToArray" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const s1 = nsstringId("1");
    defer s1.deinit();
    var one: [1]Types.id = .{s1.id};
    const a = arrayWithObjectsCount(&one, 1);
    defer a.deinit();

    const s2 = nsstringId("2");
    defer s2.deinit();
    const b = a.arrayByAddingObject(s2.id);
    defer b.deinit();
    try testing.expectEqual(@as(usize, 2), b.count());
    try testing.expect(!a.isEqualToArray(&b));
}

test "NSArray writeToURL property list roundtrip" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const io = testing.io;
    var tmp = testing.tmpDir(.{});
    defer tmp.cleanup();

    const created = try tmp.dir.createFile(io, "arr.plist", .{});
    created.close(io);

    const joined = try tmp.dir.realPathFileAlloc(io, "arr.plist", testing.allocator);
    defer testing.allocator.free(joined);

    const p = String.initWithUTF8String(joined);
    defer p.deinit();

    const s1 = nsstringId("x");
    defer s1.deinit();
    var objs: [1]Types.id = .{s1.id};
    const arr = arrayWithObjectsCount(&objs, 1);
    defer arr.deinit();

    const url = fileURLWithPath(&p);
    var err: ?Types.id = null;
    const ok = arr.writeToURLError(url, &err);
    try testing.expect(ok);

    var err2: ?Types.id = null;
    const loaded = arrayWithContentsOfURLError(url, &err2).?;
    defer loaded.deinit();
    try testing.expect(loaded.isEqualToArray(&arr));
}
