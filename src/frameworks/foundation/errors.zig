pub const ErrorCodeType = c_long;

const unknown = "Unknown error";

pub const NsFileError = enum(ErrorCodeType) {
    /// Attempt to do a file system operation on a non-existent file
    NoSuchFile = 4,
    /// Couldn't get a lock on file
    Locking = 255,
    /// Read error (reason unknown)
    ReadUnknown = 256,
    /// Read error (permission problem)
    ReadNoPermission = 257,
    /// Read error (invalid file name)
    ReadInvalidFileName = 258,
    /// Read error (file corrupt, bad format, etc)
    ReadCorruptFile = 259,
    /// Read error (no such file)
    ReadNoSuchFile = 260,
    /// Read error (string encoding not applicable)
    ReadInapplicableStringEncoding = 261,
    /// Read error (unsupported URL scheme)
    ReadUnsupportedScheme = 262,
    /// Read error (file too large)
    ReadTooLarge = 263,
    /// Read error (string encoding of file contents could not be determined)
    ReadUnknownStringEncoding = 264,
    /// Write error (reason unknown)
    WriteUnknown = 512,
    /// Write error (permission problem)
    WriteNoPermission = 513,
    /// Write error (invalid file name)
    WriteInvalidFileName = 514,
    /// Write error (file exists)
    WriteFileExists = 516,
    /// Write error (string encoding not applicable)
    WriteInapplicableStringEncoding = 517,
    /// Write error (unsupported URL scheme)
    WriteUnsupportedScheme = 518,
    /// Write error (out of disk space)
    WriteOutOfSpace = 640,
    /// Write error (readonly volume)
    WriteVolumeReadOnly = 642,

    _,

    // Inclusive error range definitions, for checking future error codes
    pub const MinRange: ErrorCodeType = 0;
    pub const MaxRange: ErrorCodeType = 1023;

    pub fn describe(error_code: NsFileError) []const u8 {
        return switch (error_code) {
            .NoSuchFile => "No such file",
            .Locking => "Locking",
            .ReadUnknown => "Read unknown",
            .ReadNoPermission => "Read no permission",
            .ReadInvalidFileName => "Read invalid file name",
            .ReadCorruptFile => "Read corrupt file",
            .ReadNoSuchFile => "Read no such file",
            .ReadInapplicableStringEncoding => "Read inapplicable string encoding",
            .ReadUnsupportedScheme => "Read unsupported scheme",
            .ReadTooLarge => "Read too large",
            .ReadUnknownStringEncoding => "Read unknown string encoding",
            .WriteUnknown => "Write unknown",
            .WriteNoPermission => "Write no permission",
            .WriteInvalidFileName => "Write invalid file name",
            .WriteFileExists => "Write file exists",
            .WriteInapplicableStringEncoding => "Write inapplicable string encoding",
            .WriteUnsupportedScheme => "Write unsupported scheme",
            .WriteOutOfSpace => "Write out of space",
            .WriteVolumeReadOnly => "Write volume read only",

            _ => unknown,
        };
    }
};

pub const NsFileManagerError = enum(ErrorCodeType) {
    /// The volume could not be unmounted (reason unknown)
    UnmountUnknown = 768,
    /// The volume could not be unmounted because it is in use
    UnmountBusy = 769,

    _,

    pub const MinRange: ErrorCodeType = 768;
    pub const MaxRange: ErrorCodeType = 769;

    pub fn describe(error_code: NsFileManagerError) []const u8 {
        return switch (error_code) {
            .UnmountUnknown => "Unmount unknown",
            .UnmountBusy => "Unmount busy",
            _ => unknown,
        };
    }
};

pub const NsExecutableLoadingError = enum(ErrorCodeType) {
    /// Executable is of a type that is not loadable in the current process
    NotLoadable = 3584,
    /// Executable does not provide an architecture compatible with the current process
    ArchitectureMismatch = 3585,
    /// Executable has Objective C runtime information incompatible with the current process
    RuntimeMismatch = 3586,
    /// Executable cannot be loaded for some other reason, such as a problem with a library it depends on
    LoadError = 3587,
    /// Executable fails due to linking issues
    LinkError = 3588,

    _,

    // Inclusive error range definitions, for checking future error codes
    pub const MinRange: ErrorCodeType = 3584;
    pub const MaxRange: ErrorCodeType = 3839;

    pub fn describe(error_code: NsExecutableLoadingError) []const u8 {
        return switch (error_code) {
            .NotLoadable => "Executable is of a type that is not loadable in the current process",
            .ArchitectureMismatch => "Executable does not provide an architecture compatible with the current process",
            .RuntimeMismatch => "Executable has Objective C runtime information incompatible with the current process",
            .LoadError => "Executable cannot be loaded for some other reason, such as a problem with a library it depends on",
            .LinkError => "Executable fails due to linking issues",
            _ => unknown,
        };
    }
};

pub const NsPropertyListError = enum(ErrorCodeType) {
    /// Error parsing a property list
    ReadCorruptError = 3840,
    /// The version number in the property list is unknown
    ReadUnknownVersionError = 3841,
    /// Stream error reading a property list
    ReadStreamError = 3842,
    /// Stream error writing a property list
    WriteStreamError = 3851,
    /// Invalid property list object or invalid property list type specified when writing
    WriteInvalidError = 3852,

    _,

    // Inclusive error range definitions, for checking future error codes
    pub const MinRange: ErrorCodeType = 3840;
    pub const MaxRange: ErrorCodeType = 4095;

    pub fn describe(error_code: NsPropertyListError) []const u8 {
        return switch (error_code) {
            .ReadCorruptError => "Error parsing a property list",
            .ReadUnknownVersionError => "The version number in the property list is unknown",
            .ReadStreamError => "Stream error reading a property list",
            .WriteStreamError => "Stream error writing a property list",
            .WriteInvalidError => "Invalid property list object or invalid property list type specified when writing",
            _ => unknown,
        };
    }
};

pub const NsXpcConnectionError = enum(ErrorCodeType) {
    /// The connection was interrupted
    Interrupted = 4097,
    /// The connection is invalid
    Invalid = 4099,
    /// The connection reply is invalid
    ReplyInvalid = 4101,
    /// The connection code signing requirement failed
    CodeSigningRequirementFailure = 4102,

    _,

    // Inclusive error range definitions, for checking future error codes
    pub const MinRange: ErrorCodeType = 4096;
    pub const MaxRange: ErrorCodeType = 4224;

    pub fn describe(error_code: NsXpcConnectionError) []const u8 {
        return switch (error_code) {
            .Interrupted => "The connection was interrupted",
            .Invalid => "The connection is invalid",
            .ReplyInvalid => "The connection reply is invalid",
            .CodeSigningRequirementFailure => "The connection code signing requirement failed",
            _ => unknown,
        };
    }
};

pub const NsUbiquitousFileError = enum(ErrorCodeType) {
    /// The item is unavailable
    Unavailable = 4353,
    /// The item could not be uploaded to iCloud because it would make the account go over-quota
    NotUploadedDueToQuota = 4354,
    /// The iCloud server is not available
    ServerNotAvailable = 4355,

    _,

    // Inclusive error range definitions, for checking future error codes
    pub const MinRange: ErrorCodeType = 4352;
    pub const MaxRange: ErrorCodeType = 4607;

    pub fn describe(error_code: NsUbiquitousFileError) []const u8 {
        return switch (error_code) {
            .Unavailable => "The item is unavailable",
            .NotUploadedDueToQuota => "The item could not be uploaded to iCloud because it would make the account go over-quota",
            .ServerNotAvailable => "The iCloud server is not available",
            _ => unknown,
        };
    }
};

pub const NsUserActivityError = enum(ErrorCodeType) {
    /// The data for the user activity was not available
    HandoffFailed = 4608,
    /// The user activity could not be continued because a required connection was not available
    ConnectionUnavailable = 4609,
    /// The remote application failed to send data in time
    RemoteApplicationTimedOut = 4610,
    /// The NSUserActivity userInfo dictionary was too large to receive
    UserInfoTooLarge = 4611,

    _,

    // Inclusive error range definitions, for checking future error codes
    pub const MinRange: ErrorCodeType = 4608;
    pub const MaxRange: ErrorCodeType = 4863;

    pub fn describe(error_code: NsUserActivityError) []const u8 {
        return switch (error_code) {
            .HandoffFailed => "The data for the user activity was not available",
            .ConnectionUnavailable => "The user activity could not be continued because a required connection was not available",
            .RemoteApplicationTimedOut => "The remote application failed to send data in time",
            .UserInfoTooLarge => "The NSUserActivity userInfo dictionary was too large to receive",
            _ => unknown,
        };
    }
};

pub const NsCoderError = enum(ErrorCodeType) {
    /// Error parsing data during decode
    ReadCorruptError = 4864,
    /// Data requested was not found
    ReadNotFoundError = 4865,
    /// Data was not valid to encode
    ReadInvalidError = 4866,

    _,

    // Inclusive error range definitions, for checking future error codes
    pub const MinRange: ErrorCodeType = 4864;
    pub const MaxRange: ErrorCodeType = 4991;

    pub fn describe(error_code: NsCoderError) []const u8 {
        return switch (error_code) {
            .ReadCorruptError => "Error parsing data during decode",
            .ReadNotFoundError => "Data requested was not found",
            .ReadInvalidError => "Data was not valid to encode",
            _ => unknown,
        };
    }
};

pub const NsBundleError = enum(ErrorCodeType) {
    /// There was not enough space available to download the requested On Demand Resources.
    OnDemandResourceOutOfSpace = 4992,
    /// The application exceeded the amount of On Demand Resources content in use at one time
    OnDemandResourceExceededMaximumSize = 4993,
    /// The application specified a tag which the system could not find in the application tag manifest
    OnDemandResourceInvalidTag = 4994,

    _,

    // Inclusive error range definitions, for checking future error codes
    pub const MinRange: ErrorCodeType = 4992;
    pub const MaxRange: ErrorCodeType = 5119;

    pub fn describe(error_code: NsBundleError) []const u8 {
        return switch (error_code) {
            .OnDemandResourceOutOfSpace => "There was not enough space available to download the requested On Demand Resources.",
            .OnDemandResourceExceededMaximumSize => "The application exceeded the amount of On Demand Resources content in use at one time",
            .OnDemandResourceInvalidTag => "The application specified a tag which the system could not find in the application tag manifest",
            _ => unknown,
        };
    }
};

pub const NsCloudSharingError = enum(ErrorCodeType) {
    /// Sharing failed due to a network failure.
    NetworkFailure = 5120,
    /// The user doesn't have enough storage space available to share the requested items.
    QuotaExceeded = 5121,
    /// Additional participants could not be added to the share, because the limit was reached.
    TooManyParticipants = 5122,
    /// A conflict occurred while trying to save changes to the CKShare and/or root CKRecord. Respond to this error by first fetching the server's changes to the records, then either handle the conflict manually or present it, which will instruct the user to try the operation again.
    Conflict = 5123,

    /// The current user doesn't have permission to perform the requested actions.
    NoPermission = 5124,
    /// These errors may require application-specific responses. For CloudKit sharing, use the NSUnderlyingErrorKey, which is a CKErrorDomain error, to discover the specific error and refer to the CloudKit documentation for the proper response to these errors.
    Other = 5375,

    _,

    // Inclusive error range definitions, for checking future error codes
    pub const MinRange: ErrorCodeType = 5120;
    pub const MaxRange: ErrorCodeType = 5375;

    pub fn describe(error_code: NsCloudSharingError) []const u8 {
        return switch (error_code) {
            .NetworkFailure => "Sharing failed due to a network failure.",
            .QuotaExceeded => "The user doesn't have enough storage space available to share the requested items.",
            .TooManyParticipants => "Additional participants could not be added to the share, because the limit was reached.",
            .Conflict => "A conflict occurred while trying to save changes to the CKShare and/or root CKRecord. Respond to this error by first fetching the server's changes to the records, then either handle the conflict manually or present it, which will instruct the user to try the operation again.",
            .NoPermission => "The current user doesn't have permission to perform the requested actions.",
            .Other => "These errors may require application-specific responses. For CloudKit sharing, use the NSUnderlyingErrorKey, which is a CKErrorDomain error, to discover the specific error and refer to the CloudKit documentation for the proper response to these errors.",
            _ => unknown,
        };
    }
};

pub const NsCompressionError = enum(ErrorCodeType) {
    /// Compression failed
    Failed = 5376,
    /// Decompression failed
    DecompressionFailed = 5377,

    _,

    // Inclusive error range definitions, for checking future error codes
    pub const MinRange: ErrorCodeType = 5376;
    pub const MaxRange: ErrorCodeType = 5503;

    pub fn describe(error_code: NsCompressionError) []const u8 {
        return switch (error_code) {
            .Failed => "Compression failed",
            .DecompressionFailed => "Decompression failed",
            _ => unknown,
        };
    }
};

pub const NsOtherError = enum(ErrorCodeType) {
    /// KVC validation error
    KeyValueValidationError = 1024,
    /// Formatting error
    FormattingError = 2048,
    /// User cancelled operation (this one often doesn't deserve a panel and might be a good one to special case)
    UserCancelled = 3072,
    /// Feature unsupported error
    FeatureUnsupported = 3328,

    _,

    // Inclusive error range definitions, for checking future error codes
    pub const ValidationMinRange: ErrorCodeType = 1024;
    pub const ValidationMaxRange: ErrorCodeType = 2047;

    pub const FormattingMinRange: ErrorCodeType = 2048;
    pub const FormattingMaxRange: ErrorCodeType = 2559;

    pub fn describe(error_code: NsOtherError) []const u8 {
        return switch (error_code) {
            .KeyValueValidationError => "KVC validation error",
            .FormattingError => "Formatting error",
            .UserCancelled => "User cancelled",
            .FeatureUnsupported => "Feature unsupported",
            _ => unknown,
        };
    }
};

pub inline fn describe(code: ErrorCodeType) []const u8 {
    if (code >= NsFileError.MinRange and code <= NsFileError.MaxRange)
        return NsFileError.describe(@enumFromInt(code));

    if (code >= NsFileManagerError.MinRange and code <= NsFileManagerError.MaxRange)
        return NsFileManagerError.describe(@enumFromInt(code));

    if (code >= NsExecutableLoadingError.MinRange and code <= NsExecutableLoadingError.MaxRange)
        return NsExecutableLoadingError.describe(@enumFromInt(code));

    if (code >= NsPropertyListError.MinRange and code <= NsPropertyListError.MaxRange)
        return NsPropertyListError.describe(@enumFromInt(code));

    if (code >= NsXpcConnectionError.MinRange and code <= NsXpcConnectionError.MaxRange)
        return NsXpcConnectionError.describe(@enumFromInt(code));

    if (code >= NsUbiquitousFileError.MinRange and code <= NsUbiquitousFileError.MaxRange)
        return NsUbiquitousFileError.describe(@enumFromInt(code));

    if (code >= NsUserActivityError.MinRange and code <= NsUserActivityError.MaxRange)
        return NsUserActivityError.describe(@enumFromInt(code));

    if (code >= NsCoderError.MinRange and code <= NsCoderError.MaxRange)
        return NsCoderError.describe(@enumFromInt(code));

    if (code >= NsBundleError.MinRange and code <= NsBundleError.MaxRange)
        return NsBundleError.describe(@enumFromInt(code));

    if (code >= NsCloudSharingError.MinRange and code <= NsCloudSharingError.MaxRange)
        return NsCloudSharingError.describe(@enumFromInt(code));

    if (code >= NsCompressionError.MinRange and code <= NsCompressionError.MaxRange)
        return NsCompressionError.describe(@enumFromInt(code));

    if ((code >= NsOtherError.ValidationMinRange and code <= NsOtherError.ValidationMaxRange) or
        (code >= NsOtherError.FormattingMinRange and code <= NsOtherError.FormattingMaxRange))
        return NsOtherError.describe(@enumFromInt(code));

    return unknown;
}
