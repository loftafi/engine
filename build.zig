pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const test_filters = b.option([]const []const u8, "test-filter", "Skip tests that do not match any filter") orelse &[0][]const u8{};

    const resources = b.dependency("resources", .{ .target = target, .optimize = optimize });
    const resources_module = resources.module("resources");
    for (platforms.getSystemPaths(b, &target)) |path| resources_module.addSystemIncludePath(path);
    if (platforms.getFrameworkPath(b, &target)) |path| resources_module.addSystemFrameworkPath(path);

    const praxis = resources.builder.dependency("praxis", .{ .target = target, .optimize = optimize });
    const praxis_module = praxis.module("praxis");

    const translator = b.dependency("translator", .{ .target = target, .optimize = optimize });
    const translator_module = translator.module("translator");

    const zstbi = resources.builder.dependency("zstbi", .{ .target = target, .optimize = optimize });
    const zstbi_module = zstbi.module("root");

    const truetype = b.dependency("TrueType", .{ .target = target, .optimize = optimize });
    const truetype_module = truetype.module("TrueType");

    const sdl_module = try define_sdl_module(b, &target, &optimize);
    const mixer_module = try define_mixer_module(b, &target, &optimize);

    const lib_mod = b.addModule("engine", .{
        .root_source_file = b.path("src/engine.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "praxis", .module = praxis_module },
            .{ .name = "resources", .module = resources_module },
            .{ .name = "zstbi", .module = zstbi_module },
            .{ .name = "sdl", .module = sdl_module },
            .{ .name = "mixer", .module = mixer_module },
            .{ .name = "translator", .module = translator_module },
            .{ .name = "TrueType", .module = truetype_module },
        },
    });
    for (platforms.getSystemPaths(b, &target)) |path| lib_mod.addSystemIncludePath(path);
    if (platforms.getFrameworkPath(b, &target)) |path| lib_mod.addSystemFrameworkPath(path);
    link_sdl_framework(b, &target, lib_mod);
    if (target.result.os.tag == .ios) {
        const objc = b.dependency("zig_objc", .{ .target = target, .optimize = optimize });
        lib_mod.addImport("objc", objc.module("objc"));
    }

    const lib = b.addLibrary(.{
        .name = "engine",
        .root_module = lib_mod,
    });
    b.installArtifact(lib);

    const real_tests = b.addTest(.{
        .root_module = lib_mod,
        .filters = test_filters,
    });

    const run_lib_unit_tests = b.addRunArtifact(real_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);

    const install_docs = b.addInstallDirectory(.{
        .source_dir = lib.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });
    const docs_step = b.step("docs", "Generate docs into zig-out/docs");
    docs_step.dependOn(&install_docs.step);
    test_step.dependOn(&run_lib_unit_tests.step);

    {
        //
        // xcode template exporter task
        //
        const export_xcode_template = b.step("export_xcode_template", "Build xcode for ios");

        const ios_app_name = b.option([]const u8, "ios_app_name", "iOS app name.");
        const ios_app_version = b.option([]const u8, "ios_app_version", "iOS app version");
        const ios_app_bundle = b.option([]const u8, "ios_app_bundle", "Default app resource bundle filename");
        const ios_app_id = b.option([]const u8, "ios_app_id", "iOS the app id");
        const ios_splash_screen = b.option(std.Build.LazyPath, "ios_splash_screen", "iOS app startup splash screen jpg");
        const ios_icon = b.option(std.Build.LazyPath, "ios_icon", "The iOS icon png");
        const ios_icon_light = b.option(std.Build.LazyPath, "ios_icon_light", "Optional iOS light icon png");
        const ios_icon_dark = b.option(std.Build.LazyPath, "ios_icon_dark", "Optional iOSdark icon png");

        // Copy the xcode template
        var copy_xcode_template = b.step("xcode_template_copy", "Copy ios template");
        const template_path = b.path("templates/xcode/");
        const do_copy = b.addInstallDirectory(.{
            .source_dir = template_path,
            .install_dir = .{ .custom = "xcode/" },
            .install_subdir = "",
        });
        copy_xcode_template.dependOn(&do_copy.step);
        export_xcode_template.dependOn(copy_xcode_template);

        // Ammend the xcode template with project information
        var patch_xcode_template = b.step("patch_xcode_template", "Update the xcode template");
        patch_xcode_template.dependOn(copy_xcode_template);
        const xcode_template_update = b.addExecutable(.{
            .name = "xcode_template_update",
            .root_module = b.createModule(.{
                .root_source_file = b.path("build/xcode_template_update.zig"),
                .target = target,
                .optimize = optimize,
            }),
        });

        var run_xcode_update = b.addRunArtifact(xcode_template_update);
        run_xcode_update.addFileArg(b.graph.path(.install_prefix, "xcode/"));
        run_xcode_update.addArg("Dialectos.xcodeproj/project.pbxproj");
        if (ios_app_name) |name| {
            run_xcode_update.addArg(name);
        } else {
            run_xcode_update.step.dependOn(&b.addFail("Specify -Dios_app_name to build ios package.").step);
        }
        if (ios_app_version) |version| {
            run_xcode_update.addArg(version);
        } else {
            run_xcode_update.step.dependOn(&b.addFail("Specify -Dios_app_version to build ios package.").step);
        }
        if (ios_app_id) |id| {
            run_xcode_update.addArg(id);
        } else {
            run_xcode_update.step.dependOn(&b.addFail("Specify -Dios_app_id to build ios package.").step);
        }
        run_xcode_update.has_side_effects = true;
        run_xcode_update.step.dependOn(copy_xcode_template);
        patch_xcode_template.dependOn(&run_xcode_update.step);
        export_xcode_template.dependOn(patch_xcode_template);

        if (ios_app_bundle) |name| {
            copyStep(b, patch_xcode_template, copy_xcode_template, name, "xcode/Dialectos/app_bundle.bd");
        } else {
            //std.log.warn("No ios_app_bundle set", .{});
        }
        if (ios_splash_screen) |jpg| {
            copyStepP(b, patch_xcode_template, copy_xcode_template, jpg, "xcode/startup-screen.jpg");
        } else {
            //std.log.warn("No ios_splash_screen set", .{});
        }
        if (ios_icon) |png| {
            copyStepP(b, patch_xcode_template, copy_xcode_template, png, "xcode/Dialectos/Assets.xcassets/AppIcon.appiconset/app-icon-3-full.png");
            copyStepP(b, patch_xcode_template, copy_xcode_template, png, "xcode/Dialectos/Assets.xcassets/AppIcon.appiconset/app-icon-3-full 1.png");
            copyStepP(b, patch_xcode_template, copy_xcode_template, png, "xcode/Dialectos/Assets.xcassets/AppIcon.appiconset/app-icon-3-full 2.png");
        }
        if (ios_icon_light) |png| {
            copyStepP(b, patch_xcode_template, copy_xcode_template, png, "xcode/Dialectos/Assets.xcassets/AppIcon.appiconset/app-icon-3-full 1.png");
        }
        if (ios_icon_dark) |png| {
            copyStepP(b, patch_xcode_template, copy_xcode_template, png, "xcode/Dialectos/Assets.xcassets/AppIcon.appiconset/app-icon-3-full 2.png");
        }
        if (ios_icon == null and ios_icon_dark == null and ios_icon_light == null) {
            //std.log.warn("No ios_icon set", .{});
        }
    }
}

fn copyStep(b: *std.Build, before: *std.Build.Step, after: *std.Build.Step, src: []const u8, dst: []const u8) void {
    var cp = b.addInstallFile(b.graph.path(.install_prefix, src), dst);
    cp.step.dependOn(after);
    before.dependOn(&cp.step);
}

fn copyStepP(b: *std.Build, before: *std.Build.Step, after: *std.Build.Step, src: std.Build.LazyPath, dst: []const u8) void {
    var cp = b.addInstallFile(src, dst);
    cp.step.dependOn(after);
    before.dependOn(&cp.step);
}

fn define_mixer_module(
    b: *std.Build,
    target: *const std.Build.ResolvedTarget,
    optimize: *const std.builtin.OptimizeMode,
) error{OutOfMemory}!*std.Build.Module {

    // Android needs a libc file for translate_c
    const libc_file: ?std.Build.LazyPath = if (b.user_input_options.get("libc_file")) |v| v.value.lazy_path else null;

    const translate_c_dep = b.dependency("translate_c", .{
        .libc_paths_file = libc_file,
    });

    // Android targets aarch64 android, and not the relatively rare alternatives.
    //   arm-linux-androideabi, armv7-linux-androideabi, i686-linux-android

    const c_header = switch (target.result.os.tag) {
        .ios => b.addWriteFiles().add("c.h",
            \\#define TARGET_OS_IPHONE 1
            \\#define SDL_PLATFORM_IOS 1
            \\#define SDL_DISABLE_OLD_NAMES
            \\#include <SDL3/SDL.h>
            \\#include <SDL3/SDL_revision.h>
            \\#define SDL_MAIN_HANDLED
            \\#include <SDL3/SDL_main.h>
            \\#include <SDL_mixer.h>
        ),
        .linux => b.addWriteFiles().add("c.h",
            \\#define __ANDROID_MIN_SDK_VERSION__ 27
            \\#define TARGET_ARCH aarch64-linux-android
            \\#define HOST aarch64-linux-android
            \\#define SDL_DISABLE_OLD_NAMES
            \\#include <SDL3/SDL.h>
            \\#include <SDL3/SDL_revision.h>
            \\#define SDL_MAIN_HANDLED
            \\#include <SDL3/SDL_main.h>
            \\#include <SDL_mixer.h>
        ),
        else => b.addWriteFiles().add("c.h",
            \\#define SDL_DISABLE_OLD_NAMES
            \\#include <SDL3/SDL.h>
            \\#include <SDL3/SDL_revision.h>
            \\#define SDL_MAIN_HANDLED
            \\#include <SDL3/SDL_main.h>
            \\#include <SDL_mixer.h>
        ),
    };

    var headers = try b.graph.arena.create(Translator);
    headers.* = .init(translate_c_dep, .{
        .c_source_file = c_header,
        .target = target.*,
        .optimize = optimize.*,
        .libc_file = libc_file,
    });

    for (platforms.getSystemPaths(b, target)) |path| headers.addSystemIncludePath(path);
    if (platforms.getFrameworkPath(b, target)) |path| headers.addSystemFrameworkPath(path);
    headers.addIncludePath(b.path("libs/sdl"));
    headers.addIncludePath(b.path("libs/SDL3.xcframework/macos-arm64_x86_64/SDL3.framework/Versions/A/Headers/"));
    headers.addIncludePath(b.path("libs/SDL3_mixer.xcframework/macos-arm64_x86_64/SDL3_mixer.framework/Versions/A/Headers/"));

    for (platforms.getSystemPaths(b, target)) |path| headers.mod.addSystemIncludePath(path);
    //if (platforms.getFrameworkPath(b, target)) |path| headers.mod.addSystemFrameworkPath(path);

    return headers.mod;
}

/// Build an SDL module from the SDL3 and SDL3_mixer header files that we
/// import as dependencies from zig packages that contain these headers.
fn define_sdl_module(
    b: *std.Build,
    target: *const std.Build.ResolvedTarget,
    optimize: *const std.builtin.OptimizeMode,
) error{OutOfMemory}!*std.Build.Module {

    // Android needs a libc file for translate_c
    const libc_file: ?std.Build.LazyPath = if (b.user_input_options.get("libc_file")) |v| v.value.lazy_path else null;

    const translate_c_dep = b.dependency("translate_c", .{
        .libc_paths_file = libc_file,
    });

    const c_header = switch (target.result.os.tag) {
        .ios => b.addWriteFiles().add("c.h",
            \\#define TARGET_OS_IPHONE 1
            \\#define SDL_PLATFORM_IOS 1
            \\#define SDL_DISABLE_OLD_NAMES
            \\#include <SDL3/SDL.h>
            \\#include <SDL3/SDL_revision.h>
            \\#define SDL_MAIN_HANDLED
            \\#include <SDL3/SDL_main.h>
        ),
        .linux => b.addWriteFiles().add("c.h",
            \\#define __ANDROID_MIN_SDK_VERSION__ 27
            \\#define TARGET_ARCH aarch64-linux-android
            \\#define HOST aarch64-linux-android
            \\#define SDL_DISABLE_OLD_NAMES
            \\#include <SDL3/SDL.h>
            \\#include <SDL3/SDL_revision.h>
            \\#define SDL_MAIN_HANDLED
            \\#include <SDL3/SDL_main.h>
        ),
        else => b.addWriteFiles().add("c.h",
            \\#define SDL_DISABLE_OLD_NAMES
            \\#include <SDL3/SDL.h>
            \\#include <SDL3/SDL_revision.h>
            \\#define SDL_MAIN_HANDLED
            \\#include <SDL3/SDL_main.h>
        ),
    };

    var headers = try b.graph.arena.create(Translator);
    headers.* = .init(translate_c_dep, .{
        .c_source_file = c_header,
        .target = target.*,
        .optimize = optimize.*,
        .libc_file = libc_file,
    });

    for (platforms.getSystemPaths(b, target)) |path| headers.mod.addSystemIncludePath(path);
    for (platforms.getSystemPaths(b, target)) |path| headers.addSystemIncludePath(path);
    if (platforms.getFrameworkPath(b, target)) |path| headers.mod.addSystemFrameworkPath(path);
    if (platforms.getFrameworkPath(b, target)) |path| headers.addSystemFrameworkPath(path);
    headers.addIncludePath(b.path("libs/SDL3.xcframework/macos-arm64_x86_64/SDL3.framework/Versions/A/Headers/"));
    headers.addIncludePath(b.path("libs/SDL3_mixer.xcframework/macos-arm64_x86_64/SDL3_mixer.framework/Versions/A/Headers/"));
    headers.addIncludePath(b.path("libs/sdl"));

    for (platforms.getSystemPaths(b, target)) |path| headers.mod.addSystemIncludePath(path);
    //if (platforms.getFrameworkPath(b, target)) |path| headers.mod.addSystemFrameworkPath(path);

    return headers.mod;
}

/// Tell a library/exe how to link to the SDL and SDL_mixer libraries
pub fn link_sdl_framework(
    b: *std.Build,
    target: *const std.Build.ResolvedTarget,
    lib: *std.Build.Module,
) void {
    switch (target.result.os.tag) {
        .macos => {
            lib.addFrameworkPath(b.path("libs/SDL3.xcframework/macos-arm64_x86_64/"));
            lib.addFrameworkPath(b.path("libs/SDL3_mixer.xcframework/macos-arm64_x86_64/"));
            lib.addRPath(b.path("libs/SDL3.xcframework/macos-arm64_x86_64/"));
            lib.addRPath(b.path("libs/SDL3_mixer.xcframework/macos-arm64_x86_64/"));
            lib.linkFramework("SDL3", .{});
            lib.linkFramework("SDL3_mixer", .{});
        },
        .ios => {
            if (target.result.abi == .simulator) {
                lib.addFrameworkPath(b.path("libs/SDL3.xcframework/ios-arm64_x86_64-simulator/"));
                lib.addFrameworkPath(b.path("libs/SDL3_mixer.xcframework/ios-arm64_x86_64-simulator/"));
                lib.addRPath(b.path("libs/SDL3.xcframework/ios-arm64_x86_64-simulator/"));
                lib.addRPath(b.path("libs/SDL3_mixer.xcframework/ios-arm64_x86_64-simulator/"));
                lib.linkFramework("SDL3", .{});
                lib.linkFramework("SDL3_mixer", .{});
            } else {
                lib.addFrameworkPath(b.path("libs/SDL3.xcframework/ios-arm64/"));
                lib.addFrameworkPath(b.path("libs/SDL3_mixer.xcframework/ios-arm64/"));
                lib.addRPath(b.path("libs/SDL3.xcframework/ios-arm64/"));
                lib.addRPath(b.path("libs/SDL3_mixer.xcframework/ios-arm64/"));
                lib.linkFramework("SDL3", .{});
                lib.linkFramework("SDL3_mixer", .{});
            }
        },
        .linux => {
            if (target.result.cpu.arch == .aarch64) {
                // Dynamic linking on android
                //lib.linkSystemLibrary("SDL3", .{});
                //lib.linkSystemLibrary("SDL3_mixer", .{});
            } else if (target.result.cpu.arch == .x86_64) {
                // Dynamic linking on android
                //lib.linkSystemLibrary("SDL3", .{});
                //lib.linkSystemLibrary("SDL3_mixer", .{});
            } else {
                std.log.err("Only aarch and x86_64 is supported for linux builds.", .{});
            }
        },
        else => {
            debug("link_sdl_framework not configured for {s}", .{@tagName(target.result.os.tag)});
            //@panic("link_sdl_framework not configured for this platform");
        },
    }
}

const std = @import("std");
const debug = std.log.debug;

const Translator = @import("translate_c").Translator;

const platforms = @import("build/platforms.zig");
