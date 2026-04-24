/// ObjC object pointer. When `owned == true`, the wrapper holds +1 retain from `alloc`/`init`; call [`deinit`] to `release`.
/// When `owned == false` (e.g. substring APIs), the instance is typically autoreleased; [`deinit`] does not call `release`. Tests should use `AutoreleasePool.push` / `pop` so autoreleased objects drain.
id: Types.id,
owned: bool = true,

const std = @import("std");
const Types = @import("./types.zig");
const Object = @import("./object.zig");
const Dispatch = @import("./dispatch.zig");
const Selector = @import("./selector.zig");
const Range = @import("./range.zig").Range;
const AutoreleasePool = @import("./autorelease_pool.zig");

const NSString = @This();
const NSStringEncodingType = Types.UInteger;

const initWithUTF8StringFn = *const fn (Types.id, Types.SEL, [*:0]const u8) callconv(.c) Types.id;
const utf8StringFn = *const fn (Types.id, Types.SEL) callconv(.c) [*:0]const u8;
const lengthFn = *const fn (Types.id, Types.SEL) callconv(.c) Types.UInteger;
const characterAtIndexFn = *const fn (Types.id, Types.SEL, Types.UInteger) callconv(.c) Types.UniChar;
const substringFromIndexFn = *const fn (Types.id, Types.SEL, Types.UInteger) callconv(.c) ?Types.id;
const substringToIndexFn = *const fn (Types.id, Types.SEL, Types.UInteger) callconv(.c) ?Types.id;
const substringWithRangeFn = *const fn (Types.id, Types.SEL, Range) callconv(.c) ?Types.id;
const getCharactersFn = *const fn (Types.id, Types.SEL, [*]Types.UniChar, Range) callconv(.c) void;
const isEqualToStringFn = *const fn (Types.id, Types.SEL, Types.id) callconv(.c) Types.Bool;
const compareFn = *const fn (Types.id, Types.SEL, Types.id) callconv(.c) Types.NSComparisonResult;
const compareOptionsFn = *const fn (Types.id, Types.SEL, Types.id, Types.UInteger) callconv(.c) Types.NSComparisonResult;
const compareOptionsRangeFn = *const fn (Types.id, Types.SEL, Types.id, Types.UInteger, Range) callconv(.c) Types.NSComparisonResult;
const hasPrefixFn = *const fn (Types.id, Types.SEL, Types.id) callconv(.c) Types.Bool;
const hasSuffixFn = *const fn (Types.id, Types.SEL, Types.id) callconv(.c) Types.Bool;
const containsStringFn = *const fn (Types.id, Types.SEL, Types.id) callconv(.c) Types.Bool;
const localizedCaseInsensitiveContainsStringFn = *const fn (Types.id, Types.SEL, Types.id) callconv(.c) Types.Bool;
const uppercaseStringFn = *const fn (Types.id, Types.SEL) callconv(.c) Types.id;
const lowercaseStringFn = *const fn (Types.id, Types.SEL) callconv(.c) Types.id;
const capitalizedStringFn = *const fn (Types.id, Types.SEL) callconv(.c) Types.id;

pub const StringEncoding = enum(NSStringEncodingType) {
    /// 0..127 only
    ASCIIStringEncoding = 1,
    NextStepStringEncoding = 2,
    JapaneseEUCStringEncoding = 3,
    UTF8StringEncoding = 4,
    ISOLatin1StringEncoding = 5,
    SymbolStringEncoding = 6,
    NonLossyASCIIStringEncoding = 7,
    /// kCFStringEncodingDOSJapanese
    ShiftJISStringEncoding = 8,
    ISOLatin2StringEncoding = 9,
    UnicodeStringEncoding = 10,
    /// Cyrillic; same as AdobeStandardCyrillic
    WindowsCP1251StringEncoding = 11,
    /// WinLatin1
    WindowsCP1252StringEncoding = 12,
    /// Greek
    WindowsCP1253StringEncoding = 13,
    /// Turkish
    WindowsCP1254StringEncoding = 14,
    /// WinLatin2
    WindowsCP1250StringEncoding = 15,
    /// ISO 2022 Japanese encoding for e-mail
    ISO2022JPStringEncoding = 21,
    MacOSRomanStringEncoding = 30,

    /// UTF16StringEncoding encoding with explicit endianness specified
    UTF16BigEndianStringEncoding = 0x90000100,
    /// UTF16StringEncoding encoding with explicit endianness specified
    UTF16LittleEndianStringEncoding = 0x94000100,

    UTF32StringEncoding = 0x8c000100,
    /// UTF32StringEncoding encoding with explicit endianness specified
    UTF32BigEndianStringEncoding = 0x98000100,
    /// UTF32StringEncoding encoding with explicit endianness specified
    UTF32LittleEndianStringEncoding = 0x9c000100,
};

pub const SearchFindFlags = enum(Types.UInteger) {
    NSCaseInsensitiveSearch = 1,
    /// Exact character-by-character equivalence
    NSLiteralSearch = 2,
    /// Search from end of source string
    NSBackwardsSearch = 4,
    /// Search is limited to start (or end, if NSBackwardsSearch) of source string
    NSAnchoredSearch = 8,
    /// Added in 10.2; Numbers within strings are compared using numeric value, that is, Foo2.txt < Foo7.txt < Foo25.txt; only applies to compare methods, not find
    NSNumericSearch = 64,
    /// If specified, ignores diacritics (o-umlaut == o)
    NSDiacriticInsensitiveSearch = 128,
    /// If specified, ignores width differences ('a' == UFF41)
    NSWidthInsensitiveSearch = 256,
    /// If specified, comparisons are forced to return either NSOrderedAscending or NSOrderedDescending if the strings are equivalent but not strictly equal, for stability when sorting (e.g. "aaa" > "AAA" with NSCaseInsensitiveSearch specified)
    NSForcedOrderingSearch = 512,
    /// Applies to rangeOfString:..., stringByReplacingOccurrencesOfString:..., and replaceOccurrencesOfString:... methods only; the search string is treated as an ICU-compatible regular expression; if set, no other options can apply except NSCaseInsensitiveSearch and NSAnchoredSearch
    NSRegularExpressionSearch = 1024,
};

/// Alias for Apple's `NSStringCompareOptions` (bitmask; combine flags with `|`).
pub const NSStringCompareOptions = SearchFindFlags;

pub const EncodingConversionOptions = enum(Types.UInteger) {
    AllowLossy = 1,
    ExternalRepresentation = 2,
};

pub inline fn getStringClass() Types.ClassPtr {
    return Object.getClassByName("NSString") orelse @panic("NSString class not found");
}

pub inline fn allocateString(cls: Types.ClassPtr) Types.id {
    return Object.alloc(cls);
}

/// Create a new empty NSString object.
/// To initialize it with a string, use `initWithUTF8String`.
pub inline fn new() NSString {
    const cls = getStringClass();
    const id = Object.init(allocateString(cls));

    return .{ .id = id };
}

pub fn initWithUTF8String(string: [:0]const u8) NSString {
    const cls = getStringClass();
    const obj = allocateString(cls);

    const initialized = Dispatch.msgSend(initWithUTF8StringFn, obj, Selector.selector("initWithUTF8String:"), .{string});
    return .{ .id = initialized };
}

pub fn deinit(self: *const NSString) void {
    // Unowned strings (e.g. autoreleased substrings): do not `release`. Owned: balance `alloc`/`init`.
    if (!self.owned) return;

    Object.release(self.id);
}

pub fn toUTF8(self: *const NSString) [*:0]const u8 {
    return Dispatch.msgSend(utf8StringFn, self.id, Selector.selector("UTF8String"), .{});
}

/// `length` and `characterAtIndex:` use **UTF-16 code units** (see Apple `NSString.h`).
pub fn length(self: *const NSString) usize {
    return Dispatch.msgSend(lengthFn, self.id, Selector.selector("length"), .{});
}

pub fn characterAtIndex(self: *const NSString, index: usize) u16 {
    const char: u16 = @intCast(Dispatch.msgSend(
        characterAtIndexFn,
        self.id,
        Selector.selector("characterAtIndex:"),
        .{@as(Types.UInteger, index)},
    ));

    return @as(u16, char);
}

/// Returns a new NSString object containing the characters of the receiver from the
/// given index to the end of the receiver.
/// The returned string is AUTO-RELEASED, not “owned by runtime”
pub fn substringFromIndex(self: *const NSString, index: usize) ?NSString {
    const raw = Dispatch.msgSend(
        substringFromIndexFn,
        self.id,
        Selector.selector("substringFromIndex:"),
        .{@as(Types.UInteger, index)},
    );

    if (raw) |id| {
        return .{ .id = id, .owned = false };
    }

    return null;
}

/// Returns a new NSString object containing the characters of the receiver up to, but not including, the character at the given index.
/// The returned string is AUTO-RELEASED, not “owned by runtime”
pub fn substringToIndex(self: *const NSString, index: usize) ?NSString {
    const raw = Dispatch.msgSend(
        substringToIndexFn,
        self.id,
        Selector.selector("substringToIndex:"),
        .{@as(Types.UInteger, index)},
    );

    if (raw) |id| {
        return .{ .id = id, .owned = false };
    }

    return null;
}

/// Returns a new NSString object containing the characters of the receiver in the given range.
/// The returned string is AUTO-RELEASED, not “owned by runtime”
pub fn substringWithRange(self: *const NSString, range: Range) ?NSString {
    const raw = Dispatch.msgSend(
        substringWithRangeFn,
        self.id,
        Selector.selector("substringWithRange:"),
        .{range},
    );

    if (raw) |id| {
        return .{ .id = id, .owned = false };
    }

    return null;
}

pub fn getCharacters(self: *const NSString, buffer: []u16, range: Range) !void {
    if (buffer.len < range.length) {
        return error.BufferTooSmall;
    } else if (range.max() > self.length()) {
        return error.RangeOutOfBounds;
    }

    const cast: [*]Types.UniChar = @ptrCast(@alignCast(buffer.ptr));

    Dispatch.msgSend(
        getCharactersFn,
        self.id,
        Selector.selector("getCharacters:range:"),
        .{ cast, range },
    );

    return;
}

/// Wrap an `NSString` you do not own (autoreleased or returned from another API).
pub inline fn fromIdUnowned(obj: Types.id) NSString {
    return .{ .id = obj, .owned = false };
}

pub fn isEqualToString(self: *const NSString, other: *const NSString) bool {
    return Dispatch.msgSend(isEqualToStringFn, self.id, Selector.selector("isEqualToString:"), .{other.id});
}

pub fn compare(self: *const NSString, other: *const NSString) Types.NSComparisonResult {
    return Dispatch.msgSend(compareFn, self.id, Selector.selector("compare:"), .{other.id});
}

/// `options` is an `NSStringCompareOptions` bitmask (use `@intFromEnum` on a single flag or `|` multiple).
pub fn compareOptions(self: *const NSString, other: *const NSString, options: Types.UInteger) Types.NSComparisonResult {
    return Dispatch.msgSend(compareOptionsFn, self.id, Selector.selector("compare:options:"), .{ other.id, options });
}

pub fn compareOptionsRange(self: *const NSString, other: *const NSString, options: Types.UInteger, range: Range) Types.NSComparisonResult {
    return Dispatch.msgSend(compareOptionsRangeFn, self.id, Selector.selector("compare:options:range:"), .{ other.id, options, range });
}

pub fn hasPrefix(self: *const NSString, prefix: *const NSString) bool {
    return Dispatch.msgSend(hasPrefixFn, self.id, Selector.selector("hasPrefix:"), .{prefix.id});
}

pub fn hasSuffix(self: *const NSString, suffix: *const NSString) bool {
    return Dispatch.msgSend(hasSuffixFn, self.id, Selector.selector("hasSuffix:"), .{suffix.id});
}

pub fn containsString(self: *const NSString, other: *const NSString) bool {
    return Dispatch.msgSend(containsStringFn, self.id, Selector.selector("containsString:"), .{other.id});
}

pub fn localizedCaseInsensitiveContainsString(self: *const NSString, other: *const NSString) bool {
    return Dispatch.msgSend(localizedCaseInsensitiveContainsStringFn, self.id, Selector.selector("localizedCaseInsensitiveContainsString:"), .{other.id});
}

/// Autoreleased copy; not +1 from your `alloc`.
pub fn uppercaseString(self: *const NSString) NSString {
    const raw = Dispatch.msgSend(uppercaseStringFn, self.id, Selector.selector("uppercaseString"), .{});
    return fromIdUnowned(raw);
}

/// Autoreleased copy; not +1 from your `alloc`.
pub fn lowercaseString(self: *const NSString) NSString {
    const raw = Dispatch.msgSend(lowercaseStringFn, self.id, Selector.selector("lowercaseString"), .{});
    return fromIdUnowned(raw);
}

/// Autoreleased copy; not +1 from your `alloc`.
pub fn capitalizedString(self: *const NSString) NSString {
    const raw = Dispatch.msgSend(capitalizedStringFn, self.id, Selector.selector("capitalizedString"), .{});
    return fromIdUnowned(raw);
}

const string_testing = @import("std").testing;

const retainCountFn = *const fn (Types.id, Types.SEL) callconv(.c) Types.UInteger;

// `getCharacters` validates range and buffer before `objc_msgSend`. For `characterAtIndex` and
// substring methods, out-of-range indices are not checked in Zig; Foundation raises
// `NSRangeException` (aborts the test process if exercised).
test "NSString initWithUTF8String length and UTF8" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const s = initWithUTF8String("hello");
    defer deinit(&s);

    try string_testing.expectEqual(@as(usize, 5), s.length());
    const utf8 = s.toUTF8();
    try string_testing.expectEqualStrings("hello", std.mem.span(utf8));
}

test "NSString characterAtIndex" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const s = initWithUTF8String("abc");
    defer deinit(&s);

    try string_testing.expectEqual(@as(u16, 'a'), s.characterAtIndex(0));
    try string_testing.expectEqual(@as(u16, 'b'), s.characterAtIndex(1));
    try string_testing.expectEqual(@as(u16, 'c'), s.characterAtIndex(2));
}

test "NSString substrings and owned flag" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const s = initWithUTF8String("hello");
    defer deinit(&s);

    const from = s.substringFromIndex(2).?;
    defer deinit(&from);
    try string_testing.expect(!from.owned);

    const to = s.substringToIndex(3).?;
    defer deinit(&to);
    try string_testing.expect(!to.owned);

    const sub = s.substringWithRange(Range.init(1, 3)).?;
    defer deinit(&sub);
    try string_testing.expect(!sub.owned);
    try string_testing.expectEqual(@as(usize, 3), sub.length());
}

test "NSString getCharacters success and errors" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const s = initWithUTF8String("hi");
    defer deinit(&s);

    var buf: [8]u16 = undefined;
    const full = Range.init(0, s.length());
    try s.getCharacters(buf[0..2], full);
    try string_testing.expectEqual(@as(u16, 'h'), buf[0]);
    try string_testing.expectEqual(@as(u16, 'i'), buf[1]);

    try string_testing.expectError(error.BufferTooSmall, s.getCharacters(buf[0..1], full));

    var large: [128]u16 = undefined;
    try string_testing.expectError(error.RangeOutOfBounds, s.getCharacters(large[0..99], Range.init(0, 99)));
}

test "NSString new and deinit" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const s = new();
    defer deinit(&s);
    try string_testing.expectEqual(@as(usize, 0), s.length());
}

test "NSString unowned deinit is no-op" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const s = initWithUTF8String("x");
    defer deinit(&s);

    const sub = s.substringFromIndex(0).?;
    deinit(&sub);
}

test "NSString IB empty string and zero-length getCharacters" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const empty = initWithUTF8String("");
    defer deinit(&empty);

    try string_testing.expectEqual(@as(usize, 0), empty.length());
    try string_testing.expectEqualStrings("", std.mem.span(empty.toUTF8()));

    var buf: [1]u16 = undefined;
    try empty.getCharacters(buf[0..0], Range.init(0, 0));
}

test "NSString IB last index and UTF-16 surrogate pair" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const ascii = initWithUTF8String("ab");
    defer deinit(&ascii);
    try string_testing.expectEqual(@as(u16, 'b'), ascii.characterAtIndex(ascii.length() - 1));

    const emoji = initWithUTF8String("😀");
    defer deinit(&emoji);
    try string_testing.expectEqual(@as(usize, 2), emoji.length());
    const hi = emoji.characterAtIndex(0);
    const lo = emoji.characterAtIndex(1);
    try string_testing.expect((hi & 0xFC00) == 0xD800);
    try string_testing.expect((lo & 0xFC00) == 0xDC00);
}

test "NSString IB substring at length and empty head; full range" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const s = initWithUTF8String("hello");
    defer deinit(&s);

    const tail = s.substringFromIndex(s.length()).?;
    defer deinit(&tail);
    try string_testing.expectEqual(@as(usize, 0), tail.length());

    const head = s.substringToIndex(0).?;
    defer deinit(&head);
    try string_testing.expectEqual(@as(usize, 0), head.length());

    const whole = s.substringWithRange(Range.init(0, s.length())).?;
    defer deinit(&whole);
    try string_testing.expectEqual(s.length(), whole.length());
}

test "NSString IB getCharacters partial range and zero-length at upper bound" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const s = initWithUTF8String("abcd");
    defer deinit(&s);

    var buf: [4]u16 = undefined;
    try s.getCharacters(buf[0..2], Range.init(1, 2));
    try string_testing.expectEqual(@as(u16, 'b'), buf[0]);
    try string_testing.expectEqual(@as(u16, 'c'), buf[1]);

    try s.getCharacters(buf[0..0], Range.init(2, 0));

    const hi = initWithUTF8String("hi");
    defer deinit(&hi);
    try hi.getCharacters(buf[0..0], Range.init(2, 0));
}

test "NSString UB range max at string length (empty slice at end)" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const s = initWithUTF8String("x");
    defer deinit(&s);
    try string_testing.expectEqual(@as(usize, 1), s.length());

    var buf: [2]u16 = undefined;
    try s.getCharacters(buf[0..0], Range.init(1, 0));
}

test "NSString getCharacters OOB range and empty receiver" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const s = initWithUTF8String("hi");
    defer deinit(&s);

    var buf: [8]u16 = undefined;
    try string_testing.expectError(error.RangeOutOfBounds, s.getCharacters(buf[0..3], Range.init(0, 3)));
    try string_testing.expectError(error.RangeOutOfBounds, s.getCharacters(buf[0..2], Range.init(1, 2)));
    try string_testing.expectError(error.RangeOutOfBounds, s.getCharacters(buf[0..1], Range.init(2, 1)));

    const empty = initWithUTF8String("");
    defer deinit(&empty);
    try string_testing.expectError(error.RangeOutOfBounds, empty.getCharacters(buf[0..1], Range.init(0, 1)));
}

test "NSString getCharacters BufferTooSmall checked before range OOB" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const s = initWithUTF8String("hi");
    defer deinit(&s);

    var buf: [4]u16 = undefined;
    try string_testing.expectError(error.BufferTooSmall, s.getCharacters(buf[0..1], Range.init(0, 3)));
}

test "NSString ownership retainCount smoke" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const s = initWithUTF8String("a");
    defer deinit(&s);

    // `retainCount` is deprecated and can misrepresent tagged pointers; only a coarse sanity check.
    const rc = Dispatch.msgSend(retainCountFn, s.id, Selector.selector("retainCount"), .{});
    try string_testing.expect(rc > 0);
}

test "NSString autorelease pool drains repeated substrings" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const s = initWithUTF8String("abcdefghijklmnopqrstuvwxyz");
    defer deinit(&s);

    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const sub = s.substringFromIndex(0).?;
        defer deinit(&sub);
        try string_testing.expectEqual(@as(usize, 26), sub.length());
    }
}

test "NSString Phase A compare equality and search" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const a = initWithUTF8String("HelloWorld");
    defer deinit(&a);
    const b = initWithUTF8String("HelloWorld");
    defer deinit(&b);
    const hello = initWithUTF8String("Hello");
    defer deinit(&hello);
    const world = initWithUTF8String("World");
    defer deinit(&world);
    const lower = initWithUTF8String("hello");
    defer deinit(&lower);
    const alt = initWithUTF8String("helloworld");
    defer deinit(&alt);

    try string_testing.expect(a.isEqualToString(&b));
    try string_testing.expectEqual(Types.NSComparisonResult.OrderedSame, a.compare(&b));
    try string_testing.expect(a.hasPrefix(&hello));
    try string_testing.expect(a.hasSuffix(&world));
    try string_testing.expect(a.containsString(&hello));
    try string_testing.expect(a.localizedCaseInsensitiveContainsString(&lower));

    const ci = @as(Types.UInteger, @intFromEnum(NSStringCompareOptions.NSCaseInsensitiveSearch));
    try string_testing.expectEqual(Types.NSComparisonResult.OrderedSame, a.compareOptions(&alt, ci));
    try string_testing.expectEqual(Types.NSComparisonResult.OrderedSame, a.compareOptionsRange(&hello, ci, Range.init(0, 5)));
}

test "NSString Phase A case copies" {
    const pool = AutoreleasePool.push();
    defer pool.pop();

    const a = initWithUTF8String("HelloWorld");
    defer deinit(&a);

    const up = a.uppercaseString();
    defer deinit(&up);
    const expectUpper = initWithUTF8String("HELLOWORLD");
    defer deinit(&expectUpper);
    try string_testing.expect(up.isEqualToString(&expectUpper));

    const lo = a.lowercaseString();
    defer deinit(&lo);
    const expectLower = initWithUTF8String("helloworld");
    defer deinit(&expectLower);
    try string_testing.expect(lo.isEqualToString(&expectLower));

    const cap = initWithUTF8String("hello world");
    defer deinit(&cap);
    const titled = cap.capitalizedString();
    defer deinit(&titled);
    const hiWord = initWithUTF8String("Hello");
    defer deinit(&hiWord);
    try string_testing.expect(titled.containsString(&hiWord));
}
