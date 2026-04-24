const std = @import("std");

const Build = std.Build;

const default_link_framework_options = Build.Module.LinkFrameworkOptions{
    .needed = true,
    .weak = false,
};

/// Fails the build unless the resolved target is macOS. Call this from `build`
/// so dependents that run this `build.zig` with e.g. `-Dtarget=x86_64-linux` get a clear error.
fn requireMacos(target: Build.ResolvedTarget) error{UnsupportedTarget}!void {
    if (target.result.os.tag != .macos) {
        std.log.err("zpto supports only macOS (resolved OS tag: {s}). Pass a macOS triple, e.g. -Dtarget=aarch64-macos or -Dtarget=x86_64-macos.", .{
            @tagName(target.result.os.tag),
        });
        return error.UnsupportedTarget;
    }
}

/// SDK root for `--sysroot` and framework search. Override with `-Dmacos_sdk=...`; otherwise runs `xcrun --show-sdk-path`.
fn macosSdkRoot(b: *Build) []const u8 {
    if (b.option([]const u8, "macos_sdk", "Path to the macOS SDK root (default: from xcrun --show-sdk-path)")) |p| {
        return b.dupe(p);
    }
    const out = b.run(&.{ "xcrun", "--show-sdk-path" });
    return b.dupe(std.mem.trim(u8, out, " \n\r\t"));
}

const frameworks = [_]struct {
    /// The name of the framework module
    /// Example: Foundation / Metal / AudioToolbox
    name: []const u8,
    /// The description of the framework
    /// Example: Link Foundation.framework
    description: []const u8,
    /// The option key for the framework
    /// Example: foundation_framework
    option_key: []const u8,
}{
    .{
        .name = "Foundation",
        .description = "Link Foundation.framework",
        .option_key = "foundation_framework",
    },
    .{
        .name = "Metal",
        .description = "Link Metal.framework",
        .option_key = "metal_framework",
    },
};

pub fn build(b: *Build) !void {
    const target = b.standardTargetOptions(.{
        .whitelist = &.{
            std.Target.Query{
                .os_tag = .macos,
                .os_version_min = .{ .semver = .{ .major = 26, .minor = 4, .patch = 0 } },
            },
        },
    });
    const optimize = b.standardOptimizeOption(.{});

    try requireMacos(target);

    const sdk_path = macosSdkRoot(b);
    b.sysroot = sdk_path;

    const test_root = b.option(bool, "test_root", "Test the root module") orelse true;

    const core = b.addModule("core", .{
        .root_source_file = b.path("src/common/core/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{},
    });

    if (target.result.cpu.arch == .aarch64) {
        // TODO: This is a hack to get the stret ABI working on aarch64.
        // The assembly file is a simple alias for the objc_msgSend_stret function.
        core.addAssemblyFile(b.path("src/common/core/objc_msgSend_stret_alias_aarch64.s"));
    }

    const frameworks_module = b.addModule("framework", .{
        .root_source_file = b.path("src/frameworks/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "core", .module = core },
        },
    });

    frameworks_module.addSystemFrameworkPath(.{ .cwd_relative = b.pathJoin(&.{ sdk_path, "System/Library/Frameworks" }) });
    core.addSystemFrameworkPath(.{ .cwd_relative = b.pathJoin(&.{ sdk_path, "System/Library/Frameworks" }) });

    const options = b.addOptions();

    for (frameworks) |framework| {
        const option = b.option(bool, framework.name, framework.description) orelse true;
        options.addOption(bool, framework.option_key, option);

        if (option) {
            frameworks_module.linkFramework(framework.name, default_link_framework_options);
            core.linkFramework(framework.name, default_link_framework_options);
        }
    }

    const root = b.addModule("objc", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "core", .module = core },
            .{ .name = "framework", .module = frameworks_module },
        },
    });

    root.addImport("build_options", options.createModule());

    const exe = b.addExecutable(.{
        .name = "objc-exe",
        .root_module = b.addModule("main", .{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "objc", .module = root },
            },
        }),
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the executable");
    run_step.dependOn(&run_cmd.step);

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    if (test_root) {
        const core_test = b.addTest(.{
            .root_module = core,
        });
        const run_core_tests = b.addRunArtifact(core_test);

        const root_test = b.addTest(.{
            .root_module = root,
        });
        const run_root_tests = b.addRunArtifact(root_test);

        // `framework` is its own module; `src/root.zig` tests do not pull in these files' tests.
        const framework_test = b.addTest(.{
            .root_module = frameworks_module,
        });
        const run_framework_tests = b.addRunArtifact(framework_test);

        const root_test_step = b.step("test", "Run the tests");
        root_test_step.dependOn(&run_core_tests.step);
        root_test_step.dependOn(&run_root_tests.step);
        root_test_step.dependOn(&run_framework_tests.step);
    }
}
