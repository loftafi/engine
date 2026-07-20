pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const test_filters = b.option([]const []const u8, "test-filter", "Skip tests that do not match any filter") orelse &[0][]const u8{};

    const resources = b.dependency("resources", .{ .target = target, .optimize = optimize });
    const resources_module = resources.module("resources");
    if (platforms.getSystemPath(b, &target)) |path| resources_module.addSystemIncludePath(path);
    if (platforms.getFrameworkPath(b, &target)) |path| resources_module.addSystemFrameworkPath(path);

    const praxis = resources.builder.dependency("praxis", .{ .target = target, .optimize = optimize });
    const praxis_module = praxis.module("praxis");

    const translator = b.dependency("translator", .{ .target = target, .optimize = optimize });
    const translator_module = translator.module("translator");

    const zstbi = resources.builder.dependency("zstbi", .{ .target = target, .optimize = optimize });
    const zstbi_module = zstbi.module("root");

    const truetype = b.dependency("TrueType", .{ .target = target, .optimize = optimize });
    const truetype_module = truetype.module("TrueType");

    const sdl_module = define_sdl_module(b, &target, &optimize);

    const mixer_module = define_mixer_module(b, &target, &optimize);

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
    if (platforms.getSystemPath(b, &target)) |path| lib_mod.addSystemIncludePath(path);
    if (platforms.getFrameworkPath(b, &target)) |path| lib_mod.addSystemFrameworkPath(path);
    link_sdl_framework(b, &target, lib_mod);

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "engine",
        .root_module = lib_mod,
    });
    b.installArtifact(lib);

    const test_mod = b.createModule(.{
        .root_source_file = b.path("src/test.zig"),
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
    if (platforms.getSystemPath(b, &target)) |path| test_mod.addSystemIncludePath(path);
    if (platforms.getFrameworkPath(b, &target)) |path| test_mod.addSystemFrameworkPath(path);
    link_sdl_framework(b, &target, test_mod);

    const real_tests = b.addTest(.{
        .root_module = test_mod,
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
}

fn define_mixer_module(
    b: *std.Build,
    target: *const std.Build.ResolvedTarget,
    optimize: *const std.builtin.OptimizeMode,
) *std.Build.Module {
    var headers = b.addTranslateC(.{
        .root_source_file = b.path("libs/SDL3_mixer.xcframework/macos-arm64_x86_64/SDL3_mixer.framework/Versions/A/Headers/SDL_mixer.h"),
        .target = target.*,
        .optimize = optimize.*,
    });
    if (platforms.getSystemPath(b, target)) |path| headers.addSystemIncludePath(path);
    if (platforms.getFrameworkPath(b, target)) |path| headers.addSystemFrameworkPath(path);
    headers.addIncludePath(b.path("libs/sdl"));
    headers.addIncludePath(b.path("libs/SDL3.xcframework/macos-arm64_x86_64/SDL3.framework/Versions/A/Headers/SDL.h"));
    headers.addIncludePath(b.path("SDL_mixer.h"));

    const sdl_mix_mod = headers.addModule("mixer");
    if (platforms.getSystemPath(b, target)) |path| sdl_mix_mod.addSystemIncludePath(path);
    if (platforms.getFrameworkPath(b, target)) |path| sdl_mix_mod.addSystemFrameworkPath(path);

    return sdl_mix_mod;
}

/// Build an SDL module from the SDL3 and SDL3_mixer header files that we
/// import as dependencies from zig packages that contain these headers.
fn define_sdl_module(
    b: *std.Build,
    target: *const std.Build.ResolvedTarget,
    optimize: *const std.builtin.OptimizeMode,
) *std.Build.Module {

    // Use TranslateC to with the SDL and SDL_mixer headers found in
    // zig sdl projects. The `xcframework` folders dont contain a
    // usable `include` folder, only a `Headers` folder which
    // doesnt work here.
    const translate_c_dep = b.dependency("translate_c", .{});

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
        else => b.addWriteFiles().add("c.h",
            \\#define SDL_DISABLE_OLD_NAMES
            \\#include <SDL3/SDL.h>
            \\#include <SDL3/SDL_revision.h>
            \\#define SDL_MAIN_HANDLED
            \\#include <SDL3/SDL_main.h>
        ),
    };

    var headers: Translator = .init(translate_c_dep, .{
        .c_source_file = c_header,
        .target = target.*,
        .optimize = optimize.*,
    });

    if (platforms.getSystemPath(b, target)) |path| headers.mod.addSystemIncludePath(path);
    if (platforms.getFrameworkPath(b, target)) |path| headers.mod.addSystemFrameworkPath(path);
    if (platforms.getSystemPath(b, target)) |path| headers.addSystemIncludePath(path);
    if (platforms.getFrameworkPath(b, target)) |path| headers.addSystemFrameworkPath(path);
    headers.addIncludePath(b.path("libs/SDL3.xcframework/macos-arm64_x86_64/SDL3.framework/Versions/A/Headers/"));
    headers.addIncludePath(b.path("libs/sdl"));
    headers.addIncludePath(b.path("libs/SDL3_mixer.xcframework/macos-arm64_x86_64/SDL3_mixer.framework/Versions/A/Headers/"));

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
            //lib.addLibraryPath(b.path("libs/vorbis/"));
            //lib.linkSystemLibrary("vorbis.0.4.9", .{});
            //lib.linkSystemLibrary("ogg.0.8.5", .{});
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
                lib.addLibraryPath(b.path("libs/ubuntu-aarch64/"));
                lib.linkSystemLibrary("SDL3.0.4.0", .{});
            } else if (target.result.cpu.arch == .x86_64) {
                lib.addLibraryPath(b.path("libs/ubuntu-x64/"));
                lib.linkSystemLibrary("SDL3.0.4.0", .{});
                lib.linkSystemLibrary("SDL3_mixer.0.1.2", .{});
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

const FindNDK = @import("build/find_ndk.zig").FindNDK;
const platforms = @import("build/platforms.zig");
