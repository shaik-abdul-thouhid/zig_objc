pub const Integer = c_long;
/// Objective-C `NSInteger` (same representation as `Integer` on Apple 64-bit platforms).
pub const NSInteger = Integer;
pub const UInteger = c_ulong;
pub const LongDouble = c_longdouble;
pub const Bool = bool;
pub const UniChar = c_ushort;

pub const CGFloat = f64;

pub const ObjCObject = opaque {};
pub const id = *ObjCObject;
pub const SEL = *opaque {};
pub const IMP = *opaque {};

pub const Class = ObjCObject;
pub const ClassPtr = *Class;

pub const Protocol = *opaque {};

/// `NSComparisonResult` from `NSString` / `NSObject` compare APIs (`NSOrderedAscending`, etc.).
pub const NSComparisonResult = enum(c_int) {
    OrderedAscending = -1,
    OrderedSame = 0,
    OrderedDescending = 1,
};

pub const objc_object = extern struct {
    isa: ClassPtr,
};

/// Strongly typed handle for `NSError *` (still message-compatible with `id`).
pub const NSError = opaque {};
pub const NSErrorPtr = *NSError;

/// Strongly typed handle for `NSData *` (instances are still `id` for `objc_msgSend`).
pub const NSData = opaque {};
pub const NSDataPtr = *NSData;

pub const NSArray = opaque {};
pub const NSArrayPtr = *NSArray;

pub const NSDictionary = opaque {};
pub const NSDictionaryPtr = *NSDictionary;

pub const NSSet = opaque {};
pub const NSSetPtr = *NSSet;
