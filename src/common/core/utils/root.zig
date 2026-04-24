const encoding = @import("./encoding.zig");

pub const Encoding = encoding.Encoding;
pub const comptimeEncode = encoding.comptimeEncode;

test {
    _ = encoding;
}
