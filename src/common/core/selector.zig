const std = @import("std");
const Types = @import("./types.zig");

const SEL = Types.SEL;

extern fn sel_registerName(name: [*:0]const u8) SEL;
extern fn sel_getName(sel: SEL) ?[*:0]const u8;

/// Register a selector by **compile-time** UTF-8 name (null-terminated). Only comptime-known names
/// are accepted, so message names are fixed when the unit is compiled. The returned `SEL` is still
/// produced at **runtime** via `sel_registerName` and must not be used in `comptime` context.
pub fn selector(comptime name: [:0]const u8) SEL {
    return sel_registerName(name);
}

/// Get the name of a selector.
/// Returns an empty string if the selector is null.
pub fn getName(sel: SEL) [:0]const u8 {
    const name = sel_getName(sel);

    if (name) |n| return std.mem.span(n);

    return "";
}
