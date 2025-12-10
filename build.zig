pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const test_filters = b.option([]const []const u8, "test-filter", "Skip tests that do not match any filter") orelse &[0][]const u8{};

    const resources = b.dependency("resources", .{ .target = target, .optimize = optimize });
    const resources_module = resources.module("resources");
    add_libs(b, &target, resources_module);

    const praxis = resources.builder.dependency("praxis", .{ .target = target, .optimize = optimize });
    const praxis_module = praxis.module("praxis");

    const zigimg = b.dependency("zigimg", .{ .target = target, .optimize = optimize });
    const zigimg_module = zigimg.module("zigimg");
    add_libs(b, &target, zigimg_module);

    const sdl_module = define_sdl_module(b, &target, &optimize);
    const mixer_module = define_mixer_module(b, &target, &optimize);

    const lib_mod = b.addModule("engine", .{
        .root_source_file = b.path("src/engine.zig"),
        .target = target,
        .optimize = optimize,
    });
    lib_mod.addImport("praxis", praxis_module);
    lib_mod.addImport("resources", resources_module);
    lib_mod.addImport("zigimg", zigimg_module);
    lib_mod.addImport("sdl", sdl_module);
    lib_mod.addImport("mixer", mixer_module);

    link_sdl_framework(b, &target, lib_mod);

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "engine",
        .root_module = lib_mod,
    });
    b.installArtifact(lib);

    const lib_unit_tests = b.addTest(.{
        .root_module = lib_mod,
        .filters = test_filters,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const test_step = b.step("test", "Run unit tests");
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
        .root_source_file = b.path("libs/SDL3_mixer/SDL_mixer.h"),
        .target = target.*,
        .optimize = optimize.*,
    });
    headers2.addIncludePath(sdl_dep.path("include"));
    const sdl_mix_mod = headers2.addModule("mixer");
    add_libs(b, target, sdl_mix_mod);
    add_translatec_headers(b, target, headers2);

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
    const module = headers.addModule("sdl");
    add_libs(b, target, module);
    add_translatec_headers(b, target, headers);

    return module;
}

pub fn add_translatec_headers(
    b: *std.Build,
    target: *const std.Build.ResolvedTarget,
    lib: *std.Build.Step.TranslateC,
) void {
    // For TranslateC to work, we need the system library headers
    switch (target.result.os.tag) {
        .macos => {
            //const sdk = std.zig.system.darwin.getSdk(b.allocator, b.graph.host.result) orelse
            const sdk = std.zig.system.darwin.getSdk(b.allocator, &target.result) orelse
                @panic("macOS SDK is missing");
            std.log.info("engine using macos c headers: {s}", .{sdk});
            lib.addSystemIncludePath(.{ .cwd_relative = b.pathJoin(&.{ sdk, "/usr/include" }) });
            lib.addSystemFrameworkPath(.{ .cwd_relative = b.pathJoin(&.{ sdk, "/System/Library/Frameworks" }) });
        },
        .ios => {
            //const sdk = std.zig.system.darwin.getSdk(b.allocator, b.graph.host.result) orelse
            const sdk = std.zig.system.darwin.getSdk(b.allocator, &target.result) orelse
                @panic("iOS SDK is missing");
            std.log.info("engine using iphoneos c headers: {s}", .{sdk});
            lib.addSystemIncludePath(.{ .cwd_relative = b.pathJoin(&.{ sdk, "/usr/include" }) });
            lib.addSystemFrameworkPath(.{ .cwd_relative = b.pathJoin(&.{ sdk, "/System/Library/Frameworks" }) });
        },
        .linux => {
            // When building for android, we need to use the android linux headers
            if (FindNDK.find(b.allocator)) |android_ndk| {
                const ndk_location = android_ndk.realpathAlloc(b.allocator, ".") catch {
                    @panic("printing ndk path failed");
                };
                defer b.allocator.free(ndk_location);
                std.log.info("Using android c headers: {s}", .{ndk_location});
                lib.addSystemIncludePath(.{ .cwd_relative = b.pathJoin(&.{
                    ndk_location,
                    "toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/include/",
                }) });
                lib.addSystemIncludePath(.{ .cwd_relative = b.pathJoin(&.{
                    ndk_location,
                    "toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/include/aarch64-linux-android/",
                }) });
            } else {
                @panic("android/linux build requires ndk. Set ANDROID_NDK_HOME");
            }
        },
        else => {
            debug(
                "add_translatec_headers not supported on {s}",
                .{@tagName(target.result.os.tag)},
            );
            @panic("add_translatec_headers only supports macos and ios");
        },
    }
}

pub fn add_libs(
    b: *std.Build,
    target: *const std.Build.ResolvedTarget,
    lib: *std.Build.Module,
) void {
    // For TranslateC to work, we need the system library headers
    switch (target.result.os.tag) {
        .macos => {
            const sdk = std.zig.system.darwin.getSdk(b.allocator, &target.result) orelse
                @panic("macOS SDK is missing");
            std.log.info("engine using macos c headers: {s}", .{sdk});
            lib.addSystemIncludePath(.{ .cwd_relative = b.pathJoin(&.{ sdk, "/usr/include" }) });
            lib.addSystemFrameworkPath(.{ .cwd_relative = b.pathJoin(&.{ sdk, "/System/Library/Frameworks" }) });
        },
        .ios => {
            const sdk = std.zig.system.darwin.getSdk(b.allocator, &target.result) orelse
                @panic("iOS SDK is missing");
            std.log.info("engine using iphoneos c headers: {s}", .{sdk});
            lib.addSystemIncludePath(.{ .cwd_relative = b.pathJoin(&.{ sdk, "/usr/include" }) });
            lib.addSystemFrameworkPath(.{ .cwd_relative = b.pathJoin(&.{ sdk, "/System/Library/Frameworks" }) });
        },
        .linux => {
            // When building for android, we need to use the android linux headers
            if (FindNDK.find(b.allocator)) |android_ndk| {
                const ndk_location = android_ndk.realpathAlloc(b.allocator, ".") catch {
                    @panic("printing ndk path failed");
                };
                defer b.allocator.free(ndk_location);
                std.log.info("Using android c headers: {s}", .{ndk_location});
                lib.addSystemIncludePath(.{ .cwd_relative = b.pathJoin(&.{
                    ndk_location,
                    "toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/include/",
                }) });
                lib.addSystemIncludePath(.{ .cwd_relative = b.pathJoin(&.{
                    ndk_location,
                    "toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/include/aarch64-linux-android/",
                }) });
            } else {
                @panic("android/linux build requires ndk. Set ANDROID_NDK_HOME");
            }
        },
        else => {
            debug(
                "add_libs not supported on {s}",
                .{@tagName(target.result.os.tag)},
            );
            @panic("add_libs only supports macos and ios");
        },
    }
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
            lib.addRPath(b.path("libs/SDL3.xcframework/macos-arm64_x86_64/"));
            lib.addRPath(b.path("libs/SDL3_ttf.xcframework/macos-arm64_x86_64/"));
            lib.linkFramework("SDL3", .{});
            lib.linkFramework("SDL3_ttf", .{});
            //lib.addSystemIncludePath(b.path("libs/SDL3_mixer/"));
            //lib.addSystemFrameworkPath(b.path("libs/SDL3_mixer/"));
            lib.addLibraryPath(b.path("libs/SDL3_mixer/"));
            lib.linkSystemLibrary("SDL3_mixer.0.1.0", .{});
            lib.linkSystemLibrary("vorbis.0.4.9", .{});
            lib.linkSystemLibrary("ogg.0.8.5", .{});
            lib.linkSystemLibrary("vorbisfile.3.3.8", .{});
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
            debug("link_sdl_framework not configured for {s}", .{@tagName(target.result.os.tag)});
            //@panic("link_sdl_framework not configured for this platform");
        },
    }
}

/// Attempt to find the location of the NDK by searching ANDROID_NDK_HOME,
/// ANDROID_SDK_ROOT, and fallback to searching known locations inside the
/// user home folder.
const FindNDK = struct {
    const ndk_versions = [_][]const u8{
        "29.0.13846066", // Pre-release
        "28.2.13676358", // Stable
        "27.3.13750724", // LTS
        "27.0.12077973",
        "25.1.8937393",
        "23.2.8568313",
        "23.1.7779620",
        "21.0.6113669",
        "20.1.5948944",
    };

    pub fn find(gpa: std.mem.Allocator) ?std.fs.Dir {
        const android_ndk_home = find_android_ndk_home(gpa) catch |e| {
            std.log.err("error while searching for ndk: {any}", .{e});
            return null;
        };
        if (android_ndk_home != null) return android_ndk_home.?;

        const android_sdk_root = find_android_sdk_root(gpa) catch |e| {
            std.log.err("error while searching for sdk: {any}", .{e});
            return null;
        };
        if (android_sdk_root != null) {
            if (android_sdk_root.?.openDir("ndk", .{})) |dir| {
                std.log.debug("searching inside ANDROID_SDK_ROOT/ndk", .{});
                const found = search_ndk_folder(gpa, dir);
                if (found != null) return found.?;
            } else |_| {
                std.log.debug("no ndk in ANDROID_SDK_ROOT", .{});
            }
        }

        const home = find_user_home(gpa) catch |e| {
            std.log.err("error while searching for ndk: {any}", .{e});
            return null;
        };
        if (home == null) {
            std.log.err("ndk not found. No HOME or USERPROFILE set.", .{});
            return null;
        }
        const ndk_base = home.?.openDir("Library/Android/sdk/ndk/", .{}) catch |e| {
            std.log.err("ndk not found. Error {any} reading HOME/Library/Android/sdk/ndk/", .{e});
            return null;
        };
        return search_ndk_folder(gpa, ndk_base);
    }

    pub fn search_ndk_folder(_: std.mem.Allocator, ndk_base: std.fs.Dir) ?std.fs.Dir {
        for (ndk_versions) |version| {
            const folder = ndk_base.openDir(version, .{}) catch {
                std.log.debug("ndk version {s} not found", .{version});
                continue;
            };
            std.log.debug("ndk version found: {any}", .{folder});
            return folder;
        }
        return null;
    }

    /// If ANDROID_NDK_HOME is set, just use that
    pub fn find_android_ndk_home(gpa: std.mem.Allocator) !?std.fs.Dir {
        var env_map = try std.process.getEnvMap(gpa);
        defer env_map.deinit();
        var iter = env_map.iterator();
        var home: ?[]const u8 = null;
        while (iter.next()) |entry| {
            if (std.ascii.eqlIgnoreCase("ANDROID_NDK_HOME", entry.key_ptr.*)) {
                home = entry.value_ptr.*;
                break;
            }
        }
        if (home == null) {
            std.log.warn("ANDROID_NDK_HOME not set.", .{});
            return null;
        }
        const d = std.fs.openDirAbsolute(home.?, .{}) catch {
            std.log.warn("Failed to read ANDROID_NDK_HOME directory {any}", .{home.?});
            return null;
        };
        return d;
    }

    /// If ANDROID_SDK_ROOT is set, just use that
    pub fn find_android_sdk_root(gpa: std.mem.Allocator) !?std.fs.Dir {
        var env_map = try std.process.getEnvMap(gpa);
        defer env_map.deinit();
        var iter = env_map.iterator();
        var home: ?[]const u8 = null;
        while (iter.next()) |entry| {
            if (std.ascii.eqlIgnoreCase("ANDROID_SDK_ROOT", entry.key_ptr.*)) {
                home = entry.value_ptr.*;
                break;
            }
        }
        if (home == null) {
            std.log.info("ANDROID_SDK_ROOT not set.", .{});
            return null;
        }
        const d = std.fs.openDirAbsolute(home.?, .{}) catch {
            std.log.warn("Failed to read ANDROID_SDK_ROOT directory {any}", .{home.?});
            return null;
        };
        return d;
    }

    /// Sometimes, the NDK is in the users home folder
    pub fn find_user_home(gpa: std.mem.Allocator) !?std.fs.Dir {
        var env_map = try std.process.getEnvMap(gpa);
        defer env_map.deinit();
        var iter = env_map.iterator();
        var home: ?[]const u8 = null;
        while (iter.next()) |entry| {
            if (std.ascii.eqlIgnoreCase("HOME", entry.key_ptr.*)) {
                home = entry.value_ptr.*;
            }
            if (std.ascii.eqlIgnoreCase("UserProfile", entry.key_ptr.*)) {
                home = entry.value_ptr.*;
            }
        }
        if (home != null) {
            const d = std.fs.openDirAbsolute(home.?, .{}) catch {
                std.log.warn("Failed to read directory {any}", .{home.?});
                return null;
            };
            return d;
        }
        return null;
    }
};

const std = @import("std");
const debug = std.log.debug;
