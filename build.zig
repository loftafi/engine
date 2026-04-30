pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const test_filters = b.option([]const []const u8, "test-filter", "Skip tests that do not match any filter") orelse &[0][]const u8{};

    const resources = b.dependency("resources", .{ .target = target, .optimize = optimize });
    const resources_module = resources.module("resources");
    addSystemPathsToModule(b, &target, resources_module);

    const praxis = resources.builder.dependency("praxis", .{ .target = target, .optimize = optimize });
    const praxis_module = praxis.module("praxis");

    const translator = b.dependency("translator", .{ .target = target, .optimize = optimize });
    const translator_module = translator.module("translator");

    const zstbi = resources.builder.dependency("zstbi", .{ .target = target, .optimize = optimize });
    const zstbi_module = zstbi.module("root");

    const sdl_module = define_sdl_module(b, &target, &optimize);
    const mixer_module = define_mixer_module(b, &target, &optimize);

    const lib_mod = b.addModule("engine", .{
        .root_source_file = b.path("src/engine.zig"),
        .target = target,
        .optimize = optimize,
    });
    lib_mod.addImport("praxis", praxis_module);
    lib_mod.addImport("resources", resources_module);
    lib_mod.addImport("zstbi", zstbi_module);
    lib_mod.addImport("sdl", sdl_module);
    lib_mod.addImport("mixer", mixer_module);
    lib_mod.addImport("translator", translator_module);
    lib_mod.addIncludePath(b.path("libs/SDL3_mixer.xcframework/macos-arm64_x86_64/SDL3_mixer.framework/Versions/A/Headers/"));
    lib_mod.addIncludePath(b.path("libs/SDL3_ttf.xcframework/macos-arm64_x86_64/SDL3_ttf.framework/Versions/A/Headers/"));
    link_sdl_framework(b, &target, lib_mod);
    addSystemPathsToModule(b, &target, lib_mod);

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
    });
    test_mod.addImport("praxis", praxis_module);
    test_mod.addImport("resources", resources_module);
    test_mod.addImport("zstbi", zstbi_module);
    test_mod.addImport("sdl", sdl_module);
    test_mod.addImport("mixer", mixer_module);
    test_mod.addImport("translator", translator_module);
    test_mod.addIncludePath(b.path("libs/SDL3_mixer.xcframework/macos-arm64_x86_64/SDL3_mixer.framework/Versions/A/Headers/"));
    test_mod.addIncludePath(b.path("libs/SDL3_ttf.xcframework/macos-arm64_x86_64/SDL3_ttf.framework/Versions/A/Headers/"));
    link_sdl_framework(b, &target, test_mod);
    addSystemPathsToModule(b, &target, test_mod);

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
    const sdl_dep = b.dependency("sdl", .{});
    const headers2 = b.addTranslateC(.{
        //.root_source_file = ttf_dep.path("libs/SDL3_mixer/SDL_mixer.h"),
        .root_source_file = b.path("libs/SDL3_mixer.xcframework/macos-arm64_x86_64/SDL3_mixer.framework/Versions/A/Headers/SDL_mixer.h"),
        .target = target.*,
        .optimize = optimize.*,
    });
    headers2.addIncludePath(sdl_dep.path("include"));
    const sdl_mix_mod = headers2.addModule("mixer");
    addSystemPathsToModule(b, target, sdl_mix_mod);
    addSystemPathsToTranslateC(b, target, headers2);

    return sdl_mix_mod;
}

/// Build an SDL module from the SDL3 and SDL3_ttf header files that we
/// import as dependencies from zig packages that contain these headers.
fn define_sdl_module(
    b: *std.Build,
    target: *const std.Build.ResolvedTarget,
    optimize: *const std.builtin.OptimizeMode,
) *std.Build.Module {

    // Use TranslateC to with the SDL and SDL_ttf headers found in
    // zig sdl projects. The `xcframework` folders dont contain a
    // usable `include` folder, only a `Headers` folder which
    // doesnt work here.
    const sdl_dep = b.dependency("sdl", .{});
    const ttf_dep = b.dependency("sdl_ttf", .{});

    const headers = b.addTranslateC(.{
        .root_source_file = ttf_dep.path("include/SDL3_ttf/SDL_ttf.h"),
        .target = target.*,
        .optimize = optimize.*,
    });
    headers.addIncludePath(sdl_dep.path("include"));
    headers.addIncludePath(ttf_dep.path("include"));
    headers.addIncludePath(b.path("libs/SDL3_mixer.xcframework/macos-arm64_x86_64/SDL3_mixer.framework/Versions/A/Headers/SDL_mixer.h"));
    const module = headers.addModule("sdl");
    module.addIncludePath(b.path("libs/SDL3_mixer.xcframework/macos-arm64_x86_64/SDL3_mixer.framework/Versions/A/Headers/SDL_mixer.h"));
    addSystemPathsToModule(b, target, module);
    addSystemPathsToTranslateC(b, target, headers);

    return module;
}

/// Tell a library/exe how to link to the SDL and SDL_ttf libraries
pub fn link_sdl_framework(
    b: *std.Build,
    target: *const std.Build.ResolvedTarget,
    lib: *std.Build.Module,
) void {
    switch (target.result.os.tag) {
        .macos => {
            lib.addFrameworkPath(b.path("libs/SDL3.xcframework/macos-arm64_x86_64/"));
            lib.addFrameworkPath(b.path("libs/SDL3_ttf.xcframework/macos-arm64_x86_64/"));
            lib.addFrameworkPath(b.path("libs/SDL3_mixer.xcframework/macos-arm64_x86_64/"));
            lib.addRPath(b.path("libs/SDL3.xcframework/macos-arm64_x86_64/"));
            lib.addRPath(b.path("libs/SDL3_ttf.xcframework/macos-arm64_x86_64/"));
            lib.addRPath(b.path("libs/SDL3_mixer.xcframework/macos-arm64_x86_64/"));
            lib.linkFramework("SDL3", .{});
            lib.linkFramework("SDL3_ttf", .{});
            lib.linkFramework("SDL3_mixer", .{});
            //lib.addLibraryPath(b.path("libs/vorbis/"));
            //lib.linkSystemLibrary("vorbis.0.4.9", .{});
            //lib.linkSystemLibrary("ogg.0.8.5", .{});
        },
        .ios => {
            if (target.result.abi == .simulator) {
                lib.addFrameworkPath(b.path("libs/SDL3.xcframework/ios-arm64_x86_64-simulator/"));
                lib.addFrameworkPath(b.path("libs/SDL3_ttf.xcframework/ios-arm64_x86_64-simulator/"));
                lib.addFrameworkPath(b.path("libs/SDL3_mixer.xcframework/ios-arm64_x86_64-simulator/"));
                lib.addRPath(b.path("libs/SDL3.xcframework/ios-arm64_x86_64-simulator/"));
                lib.addRPath(b.path("libs/SDL3_ttf.xcframework/ios-arm64_x86_64-simulator/"));
                lib.addRPath(b.path("libs/SDL3_mixer.xcframework/ios-arm64_x86_64-simulator/"));
                lib.linkFramework("SDL3", .{});
                lib.linkFramework("SDL3_ttf", .{});
                lib.linkFramework("SDL3_mixer", .{});
            } else {
                lib.addFrameworkPath(b.path("libs/SDL3.xcframework/ios-arm64/"));
                lib.addFrameworkPath(b.path("libs/SDL3_ttf.xcframework/ios-arm64/"));
                lib.addFrameworkPath(b.path("libs/SDL3_mixer.xcframework/ios-arm64/"));
                lib.addRPath(b.path("libs/SDL3.xcframework/ios-arm64/"));
                lib.addRPath(b.path("libs/SDL3_ttf.xcframework/ios-arm64/"));
                lib.addRPath(b.path("libs/SDL3_mixer.xcframework/ios-arm64/"));
                lib.linkFramework("SDL3", .{});
                lib.linkFramework("SDL3_ttf", .{});
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
                lib.linkSystemLibrary("SDL3_ttf.0.2.2", .{});
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

const FindNDK = @import("build/find_ndk.zig").FindNDK;
const addSystemPathsToModule = @import("build/addSystemPathsToModule.zig").addSystemPathsToModule;
const addSystemPathsToTranslateC = @import("build/addSystemPathsToModule.zig").addSystemPathsToTranslateC;
