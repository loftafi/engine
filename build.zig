pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const praxis = b.dependency("praxis", .{});
    const praxis_module = praxis.module("praxis");

    const resources = b.dependency("resources", .{});
    const resources_module = resources.module("resources");

    const zigimg = b.dependency("zigimg", .{});
    const zigimg_module = zigimg.module("zigimg");

    const sdl_module = build_sdl_module(b, &target, &optimize);

    const lib_mod = b.addModule("engine", .{
        .root_source_file = b.path("src/engine.zig"),
        .target = target,
        .optimize = optimize,
    });
    lib_mod.addImport("praxis", praxis_module);
    lib_mod.addImport("resources", resources_module);
    lib_mod.addImport("zigimg", zigimg_module);

    import_sdl_module(b, &target, lib_mod, sdl_module);

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "engine",
        .root_module = lib_mod,
    });
    b.installArtifact(lib);

    const lib_unit_tests = b.addTest(.{
        .root_module = lib_mod,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}

/// Build an SDL module from the SDL3 and SDL3_ttf header files that we
/// import as dependencies from zig packages that contain these headers.
fn build_sdl_module(
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

    // For TranslateC to work, we need the system library headers
    switch (target.result.os.tag) {
        .macos => {
            const sdk = std.zig.system.darwin.getSdk(b.allocator, b.graph.host.result) orelse
                @panic("macOS SDK is missing");
            headers.addSystemIncludePath(.{ .cwd_relative = b.pathJoin(&.{
                sdk,
                "/usr/include",
            }) });
            headers.addSystemFrameworkPath(.{ .cwd_relative = b.pathJoin(&.{
                sdk,
                "/System/Library/Frameworks",
            }) });
        },
        .ios => {
            const sdk = std.zig.system.darwin.getSdk(b.allocator, b.graph.host.result) orelse
                @panic("macOS SDK is missing");
            headers.addSystemIncludePath(.{ .cwd_relative = b.pathJoin(&.{
                sdk,
                "/usr/include",
            }) });
            headers.addSystemFrameworkPath(.{ .cwd_relative = b.pathJoin(&.{
                sdk,
                "/System/Library/Frameworks",
            }) });
        },
        .linux => {
            // When building for android, we need to use the android linux headers
            const android_ndk = "/Users/macuser/Library/Android/sdk/ndk/27.0.12077973/";
            headers.addSystemIncludePath(.{ .cwd_relative = b.pathJoin(&.{
                android_ndk,
                "toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/include/",
            }) });
            headers.addSystemIncludePath(.{ .cwd_relative = b.pathJoin(&.{
                android_ndk,
                "toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/include/aarch64-linux-android/",
            }) });
        },
        else => {
            debug(
                "build_sdl_module not supported on {s}",
                .{@tagName(target.result.os.tag)},
            );
            @panic("build_sdl_module only supports macos and ios");
        },
    }

    return headers.addModule("sdl");
}

/// Tell a library/exe how to link to the SDL and SDL_ttf libraries
pub fn import_sdl_module(
    b: *std.Build,
    target: *const std.Build.ResolvedTarget,
    lib: *std.Build.Module,
    sdl_module: *std.Build.Module,
) void {
    lib.addImport("sdl", sdl_module);
    switch (target.result.os.tag) {
        .macos => {
            lib.addFrameworkPath(b.path("libs/SDL3.xcframework/macos-arm64_x86_64/"));
            lib.addFrameworkPath(b.path("libs/SDL3_ttf.xcframework/macos-arm64_x86_64/"));
            lib.addRPath(b.path("libs/SDL3.xcframework/macos-arm64_x86_64/"));
            lib.addRPath(b.path("libs/SDL3_ttf.xcframework/macos-arm64_x86_64/"));
            lib.linkFramework("SDL3", .{});
            lib.linkFramework("SDL3_ttf", .{});
        },
        .ios => {
            if (target.result.abi == .simulator) {
                lib.addFrameworkPath(b.path("libs/SDL3.xcframework/ios-arm64_x86_64-simulator/"));
                lib.addFrameworkPath(b.path("libs/SDL3_ttf.xcframework/ios-arm64_x86_64-simulator/"));
                lib.addRPath(b.path("libs/SDL3.xcframework/ios-arm64_x86_64-simulator/"));
                lib.addRPath(b.path("libs/SDL3_ttf.xcframework/ios-arm64_x86_64-simulator/"));
                lib.linkFramework("SDL3", .{});
                lib.linkFramework("SDL3_ttf", .{});
            } else {
                lib.addFrameworkPath(b.path("libs/SDL3.xcframework/ios-arm64/"));
                lib.addFrameworkPath(b.path("libs/SDL3_ttf.xcframework/ios-arm64/"));
                lib.addRPath(b.path("libs/SDL3.xcframework/ios-arm64/"));
                lib.addRPath(b.path("libs/SDL3_ttf.xcframework/ios-arm64/"));
                lib.linkFramework("SDL3", .{});
                lib.linkFramework("SDL3_ttf", .{});
            }
        },
        else => {
            debug("import_sdl_module not configured for {s}", .{@tagName(target.result.os.tag)});
            @panic("import_sdl_module not configured for this platform");
        },
    }
}

const std = @import("std");
const debug = std.log.debug;
