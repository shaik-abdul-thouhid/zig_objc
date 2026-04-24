/// On Apple Silicon, libobjc does not define `objc_msgSend_stret`; struct-return
/// message dispatches use `objc_msgSend` (same as scalar). LLVM may still emit
/// references to `_objc_msgSend_stret` when Zig lowers a struct-return through
/// a cast `objc_msgSend` pointer — this alias satisfies the linker.
.text
.globl _objc_msgSend_stret
.set _objc_msgSend_stret, _objc_msgSend
