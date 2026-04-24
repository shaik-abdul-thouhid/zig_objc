const std = @import("std");
const Types = @import("./types.zig");

pub const Range = extern struct {
    location: Types.UInteger,
    length: Types.UInteger,

    pub inline fn init(location: usize, length: usize) Range {
        return .{
            .location = @as(Types.UInteger, location),
            .length = @as(Types.UInteger, length),
        };
    }

    /// Returns the maximum of the range (location + length)
    pub fn max(self: Range) usize {
        const sum = self.location + self.length;

        // check overflow
        std.debug.assert(sum >= self.location);

        return @as(usize, sum);
    }

    /// Returns whether the location `loc` is within the Range
    pub fn contains(self: Range, loc: usize) bool {
        return (!(loc < self.location) and (loc - self.location) < self.length);
    }

    /// Compares two Ranges for equality
    pub fn eql(a: Range, b: Range) bool {
        return a.location == b.location and a.length == b.length;
    }

    /// Returns the smallest Range that contains both range1 and range2
    pub fn @"union"(a: Range, b: Range) Range {
        const start = if (a.location < b.location) a.location else b.location;
        const end_a = a.location + a.length;
        const end_b = b.location + b.length;
        const end = if (end_a > end_b) end_a else end_b;
        return Range.init(start, end - start);
    }

    /// Returns the intersection of two Ranges. If they do not overlap, returns an empty Range at the greater location.
    pub fn intersection(a: Range, b: Range) Range {
        const start = if (a.location > b.location) a.location else b.location;
        const end_a = a.location + a.length;
        const end_b = b.location + b.length;
        const end = if (end_a < end_b) end_a else end_b;
        if (end < start) {
            return Range.init(start, 0);
        }
        return Range.init(start, end - start);
    }

    /// Formats the range as a string: "{location, length}"
    pub fn toString(self: Range, allocator: std.mem.Allocator) ![]u8 {
        const string = try std.fmt.allocPrint(allocator, "{{{}, {}}}", .{ self.location, self.length });
        return string;
    }

    /// Attempts to parse a Range from a string (e.g., "{0, 10}")
    pub fn fromString(s: []const u8) ?Range {
        var it = std.mem.tokenizeAny(u8, s, "{}, ");

        var fields: [2]usize = undefined;
        var i: usize = 0;

        while (it.next()) |token| : (i += 1) {
            if (i >= 2) break;
            const parsed = std.fmt.parseInt(usize, token, 10) catch return null;
            fields[i] = parsed;
        }

        if (i < 2) return null;

        return Range.init(fields[0], fields[1]);
    }
};

const testing = std.testing;

test "Range init and max" {
    const r = Range.init(10, 5);
    try testing.expectEqual(@as(usize, 10), r.location);
    try testing.expectEqual(@as(usize, 5), r.length);
    try testing.expectEqual(@as(usize, 15), r.max());

    const zero_len = Range.init(7, 0);
    try testing.expectEqual(@as(usize, 7), zero_len.max());
}

test "Range contains" {
    const empty = Range.init(3, 0);
    try testing.expect(!empty.contains(2));
    try testing.expect(!empty.contains(3));
    try testing.expect(!empty.contains(4));

    const r = Range.init(5, 4);
    try testing.expect(!r.contains(4));
    try testing.expect(r.contains(5));
    try testing.expect(r.contains(6));
    try testing.expect(r.contains(8));
    try testing.expect(!r.contains(9));
}

test "Range eql" {
    const a = Range.init(1, 2);
    try testing.expect(Range.eql(a, a));
    try testing.expect(Range.eql(a, Range.init(1, 2)));
    try testing.expect(!Range.eql(a, Range.init(1, 3)));
    try testing.expect(!Range.eql(a, Range.init(0, 2)));
}

test "Range union" {
    try testing.expect(Range.eql(
        Range.@"union"(Range.init(0, 5), Range.init(10, 5)),
        Range.init(0, 15),
    ));

    try testing.expect(Range.eql(
        Range.@"union"(Range.init(0, 5), Range.init(5, 5)),
        Range.init(0, 10),
    ));

    try testing.expect(Range.eql(
        Range.@"union"(Range.init(2, 8), Range.init(5, 4)),
        Range.init(2, 8),
    ));

    const inner = Range.init(4, 2);
    const outer = Range.init(0, 10);
    try testing.expect(Range.eql(Range.@"union"(inner, outer), outer));

    const same = Range.init(3, 7);
    try testing.expect(Range.eql(Range.@"union"(same, same), same));
}

test "Range intersection" {
    try testing.expect(Range.eql(
        Range.intersection(Range.init(0, 5), Range.init(6, 5)),
        Range.init(6, 0),
    ));

    try testing.expect(Range.eql(
        Range.intersection(Range.init(0, 10), Range.init(4, 6)),
        Range.init(4, 6),
    ));

    try testing.expect(Range.eql(
        Range.intersection(Range.init(2, 4), Range.init(5, 10)),
        Range.init(5, 1),
    ));

    const a = Range.init(1, 8);
    const b = Range.init(3, 2);
    try testing.expect(Range.eql(Range.intersection(a, b), b));

    const x = Range.init(5, 3);
    try testing.expect(Range.eql(Range.intersection(x, x), x));
}

test "Range toString and fromString round-trip" {
    const alloc = testing.allocator;
    const r = Range.init(42, 7);
    const s = try r.toString(alloc);
    defer alloc.free(s);
    try testing.expectEqualStrings("{42, 7}", s);

    const parsed = Range.fromString(s).?;
    try testing.expect(Range.eql(r, parsed));
}

test "Range fromString rejects invalid input" {
    try testing.expect(Range.fromString("") == null);
    try testing.expect(Range.fromString("{1}") == null);
    try testing.expect(Range.fromString("{x, 2}") == null);
    try testing.expect(Range.fromString("not numbers") == null);
}
