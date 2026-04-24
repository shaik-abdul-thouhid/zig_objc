//! Bindings for Apple `NSAffineTransform` (Foundation).
//!
//! The **Objective-C object** is a heap `NSAffineTransform *`, represented by `AffineTransform`: a thin handle holding `core.id` and an `owned` flag. The **plain matrix** is `NSAffineTransformStruct` (Apple’s layout); it is not an object—use `AffineTransform.transformStruct` and `AffineTransform.setTransformStruct` on an instance to read and write it.
//!
//! **Memory:** `AffineTransform.allocInit` and `AffineTransform.allocInitWithTransform` return `owned == true`; call `AffineTransform.deinit` to `release`. `AffineTransform.transform` (`+transform`) returns an **autoreleased** instance (`owned == false`); keep an `AutoreleasePool` for the lifetime you use that value (in tests, `AutoreleasePool.push` / `pop`).
//!
//! Apple documentation: `NSAffineTransform`, `NSAffineTransformStruct`.

const std = @import("std");
const core = @import("core");

const types = core.types;
const Object = core.Object;
const AutoreleasePool = core.AutoreleasePool;

const id = core.id;
const ClassPtr = core.ClassPtr;
const CGFloat = types.CGFloat;

const testing = std.testing;

/// 2D point matching 64-bit macOS `NSPoint` / `CGPoint` (`CGFloat` = `double`).
pub const Point = extern struct {
    x: CGFloat,
    y: CGFloat,
};

/// 2D size matching 64-bit macOS `NSSize` / `CGSize`.
pub const Size = extern struct {
    width: CGFloat,
    height: CGFloat,
};

/// Plain 2×3 affine matrix for `NSAffineTransform` (Apple `NSAffineTransformStruct`).
pub const NSAffineTransformStruct = extern struct {
    m11: CGFloat,
    m12: CGFloat,
    m21: CGFloat,
    m22: CGFloat,
    tX: CGFloat,
    tY: CGFloat,
};

const classTransformFn = *const fn (ClassPtr, core.SEL) callconv(.c) id;
const initFn = *const fn (id, core.SEL) callconv(.c) id;
const initWithTransformFn = *const fn (id, core.SEL, id) callconv(.c) id;
const translateFn = *const fn (id, core.SEL, CGFloat, CGFloat) callconv(.c) void;
const rotateByDegreesFn = *const fn (id, core.SEL, CGFloat) callconv(.c) void;
const rotateByRadiansFn = *const fn (id, core.SEL, CGFloat) callconv(.c) void;
const scaleByFn = *const fn (id, core.SEL, CGFloat) callconv(.c) void;
const scaleXByYByFn = *const fn (id, core.SEL, CGFloat, CGFloat) callconv(.c) void;
const invertFn = *const fn (id, core.SEL) callconv(.c) void;
const appendTransformFn = *const fn (id, core.SEL, id) callconv(.c) void;
const prependTransformFn = *const fn (id, core.SEL, id) callconv(.c) void;
const transformPointFn = *const fn (id, core.SEL, Point) callconv(.c) Point;
const transformSizeFn = *const fn (id, core.SEL, Size) callconv(.c) Size;
const transformStructGetFn = *const fn (id, core.SEL) callconv(.c) NSAffineTransformStruct;
const transformStructSetFn = *const fn (id, core.SEL, NSAffineTransformStruct) callconv(.c) void;

fn classPtr() ?ClassPtr {
    return Object.getClassByName("NSAffineTransform");
}

/// Thin handle for an `NSAffineTransform *`. When `owned == true`, call `deinit` to balance `release`.
pub const AffineTransform = struct {
    id: id,
    owned: bool = true,

    /// Class method `+transform`. Result is **autoreleased** (`owned == false`); use an autorelease pool.
    pub fn transform() ?AffineTransform {
        const cls = classPtr() orelse return null;
        const obj = core.msgSend(classTransformFn, cls, core.selector("transform"), .{});
        if (@intFromPtr(obj) == 0) return null;
        return .{ .id = obj, .owned = false };
    }

    /// `alloc` + `init`. Caller owns the instance (`owned == true`).
    pub fn allocInit() error{ClassUnavailable}!AffineTransform {
        const cls = classPtr() orelse return error.ClassUnavailable;
        const a = Object.alloc(cls);
        const inst = core.msgSend(initFn, a, core.selector("init"), .{});
        if (@intFromPtr(inst) == 0) return error.ClassUnavailable;
        return .{ .id = inst, .owned = true };
    }

    /// `alloc` + `initWithTransform:`. Caller owns the instance (`owned == true`).
    pub fn allocInitWithTransform(other: *const AffineTransform) error{ClassUnavailable}!AffineTransform {
        const cls = classPtr() orelse return error.ClassUnavailable;
        const a = Object.alloc(cls);
        const inst = core.msgSend(initWithTransformFn, a, core.selector("initWithTransform:"), .{other.id});
        if (@intFromPtr(inst) == 0) return error.ClassUnavailable;
        return .{ .id = inst, .owned = true };
    }

    pub fn deinit(self: *const AffineTransform) void {
        if (!self.owned) return;
        Object.release(self.id);
    }

    /// Instance `translateXBy:yBy:`.
    pub fn translateXByYBy(self: *const AffineTransform, dx: CGFloat, dy: CGFloat) void {
        core.msgSend(translateFn, self.id, core.selector("translateXBy:yBy:"), .{ dx, dy });
    }

    /// Instance `rotateByDegrees:`.
    pub fn rotateByDegrees(self: *const AffineTransform, angle_degrees: CGFloat) void {
        core.msgSend(rotateByDegreesFn, self.id, core.selector("rotateByDegrees:"), .{angle_degrees});
    }

    /// Instance `rotateByRadians:`.
    pub fn rotateByRadians(self: *const AffineTransform, angle_radians: CGFloat) void {
        core.msgSend(rotateByRadiansFn, self.id, core.selector("rotateByRadians:"), .{angle_radians});
    }

    /// Instance `scaleBy:` (uniform scale).
    pub fn scaleBy(self: *const AffineTransform, scale: CGFloat) void {
        core.msgSend(scaleByFn, self.id, core.selector("scaleBy:"), .{scale});
    }

    /// Instance `scaleXBy:yBy:`.
    pub fn scaleXByYBy(self: *const AffineTransform, sx: CGFloat, sy: CGFloat) void {
        core.msgSend(scaleXByYByFn, self.id, core.selector("scaleXBy:yBy:"), .{ sx, sy });
    }

    /// Instance `invert`.
    pub fn invert(self: *const AffineTransform) void {
        core.msgSend(invertFn, self.id, core.selector("invert"), .{});
    }

    /// Instance `appendTransform:`.
    pub fn appendTransform(self: *const AffineTransform, other: *const AffineTransform) void {
        core.msgSend(appendTransformFn, self.id, core.selector("appendTransform:"), .{other.id});
    }

    /// Instance `prependTransform:`.
    pub fn prependTransform(self: *const AffineTransform, other: *const AffineTransform) void {
        core.msgSend(prependTransformFn, self.id, core.selector("prependTransform:"), .{other.id});
    }

    /// Instance `transformPoint:`.
    pub fn transformPoint(self: *const AffineTransform, point: Point) Point {
        return core.msgSend(transformPointFn, self.id, core.selector("transformPoint:"), .{point});
    }

    /// Instance `transformSize:`.
    pub fn transformSize(self: *const AffineTransform, size: Size) Size {
        return core.msgSend(transformSizeFn, self.id, core.selector("transformSize:"), .{size});
    }

    /// Property getter `transformStruct`.
    pub fn transformStruct(self: *const AffineTransform) NSAffineTransformStruct {
        return core.msgSend(transformStructGetFn, self.id, core.selector("transformStruct"), .{});
    }

    /// Property setter `setTransformStruct:`.
    pub fn setTransformStruct(self: *const AffineTransform, matrix: NSAffineTransformStruct) void {
        core.msgSend(transformStructSetFn, self.id, core.selector("setTransformStruct:"), .{matrix});
    }
};

test "NSAffineTransform class exists" {
    if (classPtr() == null) return error.SkipZigTest;
}

test "NSAffineTransform transform returns id under pool" {
    if (classPtr() == null) return error.SkipZigTest;

    var pool = AutoreleasePool.push();
    defer AutoreleasePool.pop(&pool);

    const t = AffineTransform.transform() orelse return error.UnexpectedNull;
    defer t.deinit();
    try testing.expect(@intFromPtr(t.id) != 0);
    try testing.expect(!t.owned);
}

test "NSAffineTransform struct round-trip" {
    if (classPtr() == null) return error.SkipZigTest;

    var t = try AffineTransform.allocInit();
    defer t.deinit();

    const want: NSAffineTransformStruct = .{
        .m11 = 1,
        .m12 = 2,
        .m21 = 3,
        .m22 = 4,
        .tX = 5,
        .tY = 6,
    };
    t.setTransformStruct(want);
    const got = t.transformStruct();

    inline for (.{ "m11", "m12", "m21", "m22", "tX", "tY" }) |field| {
        try testing.expectApproxEqAbs(
            @field(want, field),
            @field(got, field),
            1e-9,
        );
    }
}

test "NSAffineTransform translateXByYBy and transformPoint" {
    if (classPtr() == null) return error.SkipZigTest;

    var t = try AffineTransform.allocInit();
    defer t.deinit();

    const dx: CGFloat = 3;
    const dy: CGFloat = -2.5;
    t.translateXByYBy(dx, dy);

    const p = t.transformPoint(.{ .x = 0, .y = 0 });
    try testing.expectApproxEqAbs(dx, p.x, 1e-9);
    try testing.expectApproxEqAbs(dy, p.y, 1e-9);
}

test "NSAffineTransform transformSize translate only affects position not size" {
    if (classPtr() == null) return error.SkipZigTest;

    var t = try AffineTransform.allocInit();
    defer t.deinit();
    t.translateXByYBy(10, 20);

    const s = t.transformSize(.{ .width = 2, .height = 3 });
    try testing.expectApproxEqAbs(2, s.width, 1e-9);
    try testing.expectApproxEqAbs(3, s.height, 1e-9);
}

test "NSAffineTransform invert toggles translation" {
    if (classPtr() == null) return error.SkipZigTest;

    var t = try AffineTransform.allocInit();
    defer t.deinit();
    t.translateXByYBy(7, 11);
    t.invert();
    const p = t.transformPoint(.{ .x = 0, .y = 0 });
    try testing.expectApproxEqAbs(-7, p.x, 1e-9);
    try testing.expectApproxEqAbs(-11, p.y, 1e-9);
}
