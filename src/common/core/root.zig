pub const types = @import("./types.zig");
const Dispatch = @import("./dispatch.zig");
const Selector = @import("./selector.zig");
const range = @import("./range.zig");
pub const block = @import("./block.zig");
pub const utils = @import("./utils/root.zig");

pub const Integer = types.Integer;
pub const NSInteger = types.NSInteger;
pub const UInteger = types.UInteger;
pub const Bool = types.Bool;

pub const NSError = types.NSError;
pub const NSErrorPtr = types.NSErrorPtr;
pub const NSData = types.NSData;
pub const NSDataPtr = types.NSDataPtr;
pub const NSArray = types.NSArray;
pub const NSDictionary = types.NSDictionary;
pub const NSSet = types.NSSet;

pub const LongDouble = types.LongDouble;
pub const Class = types.Class;
pub const ClassPtr = types.ClassPtr;

pub const id = types.id;
pub const SEL = types.SEL;

pub const NSComparisonResult = types.NSComparisonResult;

pub const msgSend = Dispatch.msgSend;
pub const msgSendFpret = Dispatch.msgSendFpret;

pub const selector = Selector.selector;
pub const selectorName = Selector.getName;

pub const Object = @import("./object.zig");

pub const String = @import("./string.zig");

pub const Range = range.Range;

pub const AutoreleasePool = @import("./autorelease_pool.zig");

pub const Data = @import("./data.zig");
pub const Array = @import("./array.zig");
pub const Coder = @import("./coder.zig");

pub const Block = block.Block;

// Submodule tests are only linked when each file is referenced from this test block.
test {
    _ = range;
    _ = Dispatch;
    _ = Object;
    _ = String;
    _ = AutoreleasePool;
    _ = Data;
    _ = Array;
    _ = Coder;
    _ = block;
    _ = utils;
}
