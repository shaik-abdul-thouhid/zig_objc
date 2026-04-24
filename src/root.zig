const std = @import("std");

const frameworks = @import("framework");

const core = @import("core");
const build_options = @import("build_options");

const testing = std.testing;

const Foundation = if (build_options.foundation_framework) frameworks.Foundation else void;

pub fn sanity(allocator: std.mem.Allocator, io: std.Io) !void {
    const str: core.String = .initWithUTF8String("Hello, World!...“‘“¥");
    defer str.deinit();
    // 4. Test your wrapper methods

    const cls = core.Object.getClassOf(str.id);
    const is_nsobject = core.Object.isKindOfClass(str.id, cls);
    const is_member = core.Object.isMemberOfClass(str.id, cls);
    const is_proxy = core.Object.isProxy(str.id);

    const buffer = try allocator.alloc(u8, 1024);
    defer allocator.free(buffer);

    var stdout_file: std.Io.File.Writer = .init(.stdout(), io, buffer);
    const stdout = &stdout_file.interface;
    defer stdout.flush() catch {};

    try stdout.print("cls: {}\n", .{cls});
    try stdout.print("is_nsobject: {}\n", .{is_nsobject});
    try stdout.print("is_member: {}\n", .{is_member});
    try stdout.print("is_proxy: {}\n", .{is_proxy});

    const actual_class = core.Object.getClassOf(str.id);
    const is_exact = core.Object.isMemberOfClass(str.id, actual_class);

    try stdout.print("is exact class: {}\n", .{is_exact});

    const cstr = str.toUTF8();

    try stdout.print("string: {s}\n", .{cstr});
    try stdout.print("length: {}\n", .{str.length()});
    try stdout.print("character at index 0: {}\n", .{str.characterAtIndex(16)});

    const substring = str.substringFromIndex(4).?;

    try stdout.print("substring: {s}\n", .{substring.toUTF8()});

    const range = core.Range.fromString("{2, 4}");
    try stdout.print("range: {s}, length: {}, location: {}\n", .{ try range.?.toString(allocator), range.?.length, range.?.location });

    const substring_with_range = str.substringWithRange(range.?).?;
    try stdout.print("substring with range: {s}\n", .{substring_with_range.toUTF8()});
}

test {
    _ = testing.refAllDecls(frameworks);
}
