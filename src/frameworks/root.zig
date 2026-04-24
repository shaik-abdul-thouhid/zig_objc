const std = @import("std");

const testing = std.testing;

pub const Foundation = @import("./foundation/root.zig");

test {
    _ = testing.refAllDecls(Foundation);
}
