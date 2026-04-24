//! Drains autoreleased Objective-C objects (e.g. `NSString` substring results) when the pool is popped.
//!
//! Zig’s `std.testing.allocator` does not track Foundation refcounts. In tests that create
//! autoreleased substrings, use [`push`] / [`pop`] (typically `const pool = push(); defer pop(pool);`).
//!
//! Optional manual check (macOS): after `zig build test`, run `leaks --atExit -- /path/to/test` on the
//! `test` binary under `.zig-cache/o/<hash>/` (or use Instruments Leaks).

handle: *anyopaque,

extern fn objc_autoreleasePoolPush() callconv(.c) *anyopaque;
extern fn objc_autoreleasePoolPop(pool: *anyopaque) callconv(.c) void;

const AutoRelease = @This();

pub inline fn push() AutoRelease {
    return .{ .handle = objc_autoreleasePoolPush() };
}

pub inline fn pop(self: *const AutoRelease) void {
    objc_autoreleasePoolPop(self.handle);
}
