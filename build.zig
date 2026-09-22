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

    // If we might be building for android, create a libc.txt for the
    // android library, and for the SDL/SDL_mixer libraries.
    var libc_file: ?std.Build.LazyPath = undefined;
    var generate_libc: *std.Build.Step.Run = undefined;
    if (b.graph.environ_map.contains("ANDROID_NDK_HOME") or b.graph.environ_map.contains("ANDROID_SDK_ROOT")) {
        const run_generate_libc = b.addExecutable(.{
            .name = "generate_libc",
            .root_module = b.createModule(.{
                .root_source_file = b.path("build/generate_libc.zig"),
                .target = b.graph.host,
                .optimize = optimize,
            }),
        });
        generate_libc = b.addRunArtifact(run_generate_libc);
        libc_file = generate_libc.addOutputFileArg2("libc.txt", .{});
        const libc_target = b.resolveTargetQuery(.{ .os_tag = .linux, .cpu_arch = .aarch64, .abi = .android });
        generate_libc.addArg(try androidTriple(&libc_target.result));
    }

    const sdl_module = try define_sdl_module(b, &target, &optimize, libc_file);
    const mixer_module = try define_mixer_module(b, &target, &optimize, libc_file);

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

    if (b.graph.environ_map.contains("ANDROID_NDK_HOME") or b.graph.environ_map.contains("ANDROID_SDK_ROOT")) {
        lib.step.dependOn(&generate_libc.step);
    }

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
        const ios_app_bundle = b.option(std.Build.LazyPath, "ios_app_bundle", "Default app resource bundle filename");
        const ios_app_id = b.option([]const u8, "ios_app_id", "iOS the app id");
        const ios_resources_required = b.option(bool, "ios_resources_required", "If true, build aborts if template resource is missing.");
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
                .target = b.graph.host,
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
            copyStep(b, export_xcode_template, &run_xcode_update.step, name, "xcode/Dialectos/app_bundle.bd");
        } else {
            //std.log.warn("No ios_app_bundle set", .{});
        }
        if (ios_splash_screen) |jpg| {
            copyStep(b, export_xcode_template, &run_xcode_update.step, jpg, "xcode/startup-screen.jpg");
        } else {
            if (ios_resources_required) |check| {
                if (check) {
                    export_xcode_template.dependOn(&b.addFail("missing " ++ "startup screen image").step);
                }
            }
        }

        if (ios_icon) |png| {
            copyStep(b, export_xcode_template, &run_xcode_update.step, png, "xcode/Dialectos/Assets.xcassets/AppIcon.appiconset/app-icon-3-full.png");
            copyStep(b, export_xcode_template, &run_xcode_update.step, png, "xcode/Dialectos/Assets.xcassets/AppIcon.appiconset/app-icon-3-full 1.png");
            copyStep(b, export_xcode_template, &run_xcode_update.step, png, "xcode/Dialectos/Assets.xcassets/AppIcon.appiconset/app-icon-3-full 2.png");
        } else {
            if (ios_resources_required) |check| {
                if (check) {
                    export_xcode_template.dependOn(&b.addFail("missing " ++ "ios_icon").step);
                }
            }
        }

        if (ios_icon_light) |png| {
            copyStep(b, export_xcode_template, &run_xcode_update.step, png, "xcode/Dialectos/Assets.xcassets/AppIcon.appiconset/app-icon-3-full 1.png");
        } else {
            if (ios_resources_required) |check| {
                if (check) {
                    export_xcode_template.dependOn(&b.addFail("missing " ++ " light ios icon").step);
                }
            }
        }

        if (ios_icon_dark) |png| {
            copyStep(b, export_xcode_template, &run_xcode_update.step, png, "xcode/Dialectos/Assets.xcassets/AppIcon.appiconset/app-icon-3-full 2.png");
        } else {
            if (ios_resources_required) |check| {
                if (check) {
                    export_xcode_template.dependOn(&b.addFail("missing " ++ " dark ios icon").step);
                }
            }
        }
    }

    {
        const export_android_template = b.step("export_android_template", "Build template for android studio");

        //
        // Android
        //
        const android_target = b.resolveTargetQuery(.{ .os_tag = .linux, .cpu_arch = .aarch64, .abi = .android });
        const android_app_name = b.option([]const u8, "android_app_name", "Android app name.");
        const android_app_id = b.option([]const u8, "android_app_id", "Android app id.");
        const android_app_version = b.option([]const u8, "android_app_version", "Android app version.");
        const android_app_bundle = b.option(std.Build.LazyPath, "android_app_bundle", "Default app resource bundle filename.");
        const android_resources_required = b.option(bool, "android_resources_required", "If true, missing android resource causes build fail.");
        const android_icon_playstore = b.option(std.Build.LazyPath, "android_icon_playstore", "The android google play store icon png.");
        const android_icon_circle_192 = b.option(std.Build.LazyPath, "android_icon_circle_192", "Circle 192px android icon png.");
        const android_icon_circle_144 = b.option(std.Build.LazyPath, "android_icon_circle_144", "Circle 144px android icon png.");
        const android_icon_circle_96 = b.option(std.Build.LazyPath, "android_icon_circle_96", "Circle 96px android icon png.");
        const android_icon_circle_72 = b.option(std.Build.LazyPath, "android_icon_circle_72", "Circle 72px android icon png.");
        const android_icon_circle_48 = b.option(std.Build.LazyPath, "android_icon_circle_48", "Circle 48px android icon png.");
        const android_icon_rounded_192 = b.option(std.Build.LazyPath, "android_icon_rounded_192", "Rounded 192px android icon png.");
        const android_icon_rounded_144 = b.option(std.Build.LazyPath, "android_icon_rounded_144", "Rounded 144px android icon png.");
        const android_icon_rounded_96 = b.option(std.Build.LazyPath, "android_icon_rounded_96", "Rounded 96px android icon png.");
        const android_icon_rounded_72 = b.option(std.Build.LazyPath, "android_icon_rounded_72", "Rounded 72px android icon png.");
        const android_icon_rounded_48 = b.option(std.Build.LazyPath, "android_icon_rounded_48", "Rounded 48px android icon png.");
        const android_icon_foreground_432 = b.option(std.Build.LazyPath, "android_icon_foreground_432", "Foreground 432px android icon png.");
        const android_icon_foreground_324 = b.option(std.Build.LazyPath, "android_icon_foreground_324", "Foreground 324px android icon png.");
        const android_icon_foreground_216 = b.option(std.Build.LazyPath, "android_icon_foreground_216", "Foreground 216px android icon png.");
        const android_icon_foreground_162 = b.option(std.Build.LazyPath, "android_icon_foreground_162", "Foreground 162px android icon png.");
        const android_icon_foreground_108 = b.option(std.Build.LazyPath, "android_icon_foreground_108", "Foreground 108px android icon png.");
        const android_icon_background_432 = b.option(std.Build.LazyPath, "android_icon_background_432", "Android background icon 432px webp.");
        const android_icon_background_324 = b.option(std.Build.LazyPath, "android_icon_background_324", "Android background icon 324px webp.");
        const android_icon_background_216 = b.option(std.Build.LazyPath, "android_icon_background_216", "Android background icon 216px webp.");
        const android_icon_background_162 = b.option(std.Build.LazyPath, "android_icon_background_162", "Android background icon 162px webp.");
        const android_icon_background_108 = b.option(std.Build.LazyPath, "android_icon_background_108", "Android background icon 108px webp.");

        if (android_app_name == null) {
            export_android_template.dependOn(&b.addFail("Specify -Dandroid_app_name to build ios package.").step);
        }
        if (android_app_version == null) {
            export_android_template.dependOn(&b.addFail("Specify -Dandroid_app_version to build ios package.").step);
        }
        if (android_app_id == null) {
            export_android_template.dependOn(&b.addFail("Specify -Dandroid_app_id to build ios package.").step);
        }

        // Copy the android template
        var copy_android_template = b.step("android_template_copy", "Copy android template");
        const template_path = b.path("templates/android/");
        const do_copy_template = b.addInstallDirectory(.{
            .source_dir = template_path,
            .install_dir = .{ .custom = "android/" },
            .install_subdir = "",
        });
        copy_android_template.dependOn(&do_copy_template.step);

        // Copy SDL into the android template
        //const sdl_pkg = b.dependency("sdl", .{});
        //const do_copy_sdl = b.addInstallDirectory(.{
        //    .source_dir = sdl_pkg.path(""),
        //    .install_dir = .{ .custom = "android/app/jni/SDL" },
        //    .install_subdir = "",
        //});
        //copy_android_template.dependOn(&do_copy_sdl.step);

        // Copy SDL mixer into the android template
        const sdl_mixer_pkg = b.dependency("sdl_mixer", .{});
        const do_copy_sdl_mixer = b.addInstallDirectory(.{
            .source_dir = sdl_mixer_pkg.path(""),
            .install_dir = .{ .custom = "android/app/jni/SDL_mixer" },
            .install_subdir = "",
        });
        copy_android_template.dependOn(&do_copy_sdl_mixer.step);

        const text_replace_util = b.addExecutable(.{
            .name = "text_replacement",
            .root_module = b.createModule(.{
                .root_source_file = b.path("build/text_replace.zig"),
                .target = b.graph.host,
                .optimize = optimize,
            }),
        });
        var run_sdl_mixer_patch = b.addRunArtifact(text_replace_util);
        run_sdl_mixer_patch.addFileArg(b.graph.path(.install_prefix, "android/app/jni/SDL_mixer/Android.mk"));
        run_sdl_mixer_patch.addArg("SUPPORT_FLAC_DRFLAC ?= true");
        run_sdl_mixer_patch.addArg("SUPPORT_FLAC_DRFLAC ?= false");
        run_sdl_mixer_patch.addArg("SUPPORT_WAVPACK ?= true");
        run_sdl_mixer_patch.addArg("SUPPORT_WAVPACK ?= false");
        run_sdl_mixer_patch.addArg("SUPPORT_MP3_DRMP3 ?= true");
        run_sdl_mixer_patch.addArg("SUPPORT_MP3_DRMP3 ?= false");
        //run_sdl_mixer_patch.addArg("LOCAL_LDFLAGS := ");
        //run_sdl_mixer_patch.addArg("LOCAL_LDFLAGS := -z,max-page-size=16384 -Wl,-z,common-page-size=16384 ");

        run_sdl_mixer_patch.has_side_effects = true;
        run_sdl_mixer_patch.step.dependOn(&do_copy_sdl_mixer.step);

        // Ammend the android template with project information
        const android_update_exe = b.addExecutable(.{
            .name = "android_template_update",
            .root_module = b.createModule(.{
                .root_source_file = b.path("build/android_template_update.zig"),
                .target = b.graph.host,
                .optimize = optimize,
            }),
        });
        var run_android_update = b.addRunArtifact(android_update_exe);
        run_android_update.addFileArg(b.graph.path(.install_prefix, "android/"));
        const generated_libc = run_android_update.addOutputFileArg2("libc.txt", .{});
        run_android_update.addArg(android_app_name orelse "Example");
        run_android_update.addArg(android_app_version orelse "1");
        run_android_update.addArg(android_app_id orelse "org.example.app");
        run_android_update.addArg(try androidTriple(&android_target.result));
        run_android_update.has_side_effects = true;
        run_android_update.step.dependOn(copy_android_template);
        run_android_update.step.dependOn(&run_sdl_mixer_patch.step);

        if (!b.graph.environ_map.contains("ANDROID_NDK_HOME") and !b.graph.environ_map.contains("ANDROID_SDK_ROOT")) {
            run_android_update.step.dependOn(&b.addFail("The `android` build step requires ANDROID_NDK_HOME or ANDROID_SDK_ROOT to be set.").step);
        }

        if (android_app_bundle) |name| {
            copyStep(b, &run_android_update.step, &do_copy_template.step, name, "android/app/src/main/assets/app_bundle.bd");
        } else {
            //std.log.warn("No ios_app_bundle set", .{});
        }

        const copy = .{
            .{ android_icon_playstore, "android/app/src/main/ic_launcher-playstore.png" },
            .{ android_icon_rounded_192, "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.webp" },
            .{ android_icon_rounded_192, "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.webp" },
            .{ android_icon_rounded_144, "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.webp" },
            .{ android_icon_rounded_96, "android/app/src/main/res/mipmap-xhdpi/ic_launcher.webp" },
            .{ android_icon_rounded_72, "android/app/src/main/res/mipmap-hdpi/ic_launcher.webp" },
            .{ android_icon_rounded_48, "android/app/src/main/res/mipmap-mdpi/ic_launcher.webp" },
            .{ android_icon_circle_48, "android/app/src/main/res/mipmap-mdpi/ic_launcher_round.webp" },
            .{ android_icon_circle_96, "android/app/src/main/res/mipmap-xhdpi/ic_launcher_round.webp" },
            .{ android_icon_circle_72, "android/app/src/main/res/mipmap-hdpi/ic_launcher_round.webp" },
            .{ android_icon_circle_192, "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.webp" },
            .{ android_icon_circle_192, "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.webp" },
            .{ android_icon_circle_144, "android/app/src/main/res/mipmap-xxhdpi/ic_launcher_round.webp" },
            .{ android_icon_foreground_432, "android/app/src/main/res/mipmap/ic_launcher_foreground.webp" },
            .{ android_icon_foreground_432, "android/app/src/main/res/mipmap/icon_foreground.webp" },
            .{ android_icon_foreground_432, "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.webp" },
            .{ android_icon_foreground_324, "android/app/src/main/res/mipmap-xxhdpi/ic_launcher_foreground.webp" },
            .{ android_icon_foreground_216, "android/app/src/main/res/mipmap-xhdpi/ic_launcher_foreground.webp" },
            .{ android_icon_foreground_162, "android/app/src/main/res/mipmap-hdpi/ic_launcher_foreground.webp" },
            .{ android_icon_foreground_108, "android/app/src/main/res/mipmap-mdpi/ic_launcher_foreground.webp" },
            .{ android_icon_background_432, "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.webp" },
            .{ android_icon_background_432, "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_background.webp" },
            .{ android_icon_background_432, "android/app/src/main/res/mipmap/ic_launcher_background.webp" },
            .{ android_icon_background_432, "android/app/src/main/res/mipmap/icon_background.webp" },
            .{ android_icon_background_324, "android/app/src/main/res/mipmap-xxhdpi/ic_launcher_background.webp" },
            .{ android_icon_background_216, "android/app/src/main/res/mipmap-xhdpi/ic_launcher_background.webp" },
            .{ android_icon_background_162, "android/app/src/main/res/mipmap-hdpi/ic_launcher_background.webp" },
            .{ android_icon_background_108, "android/app/src/main/res/mipmap-mdpi/ic_launcher_background.webp" },
        };

        inline for (copy) |cp| {
            if (cp[0]) |src| {
                const copy_step = &b.addInstallFile(src, cp[1]).step;
                export_android_template.dependOn(copy_step);
                copy_step.dependOn(&run_android_update.step);
            } else {
                if (android_resources_required) |check| {
                    if (check) {
                        run_android_update.step.dependOn(&b.addFail("missing " ++ cp[1]).step);
                    }
                }
            }
        }

        const copy_libc2 = &b.addInstallFile(generated_libc, "android/libc.txt").step;
        copy_libc2.dependOn(&run_android_update.step);
        export_android_template.dependOn(copy_libc2);
        export_android_template.dependOn(&generate_libc.step);
    }
}

fn copyStep(
    b: *std.Build,
    runBefore: *std.Build.Step,
    runAfter: *std.Build.Step,
    src: std.Build.LazyPath,
    dst: []const u8,
) void {
    var cp = b.addInstallFile(src, dst);
    runBefore.dependOn(&cp.step);
    cp.step.dependOn(runAfter);
}

fn define_mixer_module(
    b: *std.Build,
    target: *const std.Build.ResolvedTarget,
    optimize: *const std.builtin.OptimizeMode,
    libc_file: ?std.Build.LazyPath, // Android needs a libc file for translate_c
) error{OutOfMemory}!*std.Build.Module {
    const translate_c_dep = b.dependency("translate_c", .{});

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
    libc_file: ?std.Build.LazyPath, // Android needs a libc file for translate_c
) error{OutOfMemory}!*std.Build.Module {
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
            lib.addFrameworkPath(b.path("libs/SDL3.xcframework/macos-arm64_x86_64"));
            lib.addFrameworkPath(b.path("libs/SDL3_mixer.xcframework/macos-arm64_x86_64"));
            lib.addRPath(b.path("libs/SDL3.xcframework/macos-arm64_x86_64"));
            lib.addRPath(b.path("libs/SDL3_mixer.xcframework/macos-arm64_x86_64"));
            lib.linkFramework("SDL3", .{});
            lib.linkFramework("SDL3_mixer", .{});
        },
        .ios => {
            if (target.result.abi == .simulator) {
                lib.addFrameworkPath(b.path("libs/SDL3.xcframework/ios-arm64_x86_64-simulator"));
                lib.addFrameworkPath(b.path("libs/SDL3_mixer.xcframework/ios-arm64_x86_64-simulator"));
                lib.addRPath(b.path("libs/SDL3.xcframework/ios-arm64_x86_64-simulator"));
                lib.addRPath(b.path("libs/SDL3_mixer.xcframework/ios-arm64_x86_64-simulator"));
                lib.linkFramework("SDL3", .{});
                lib.linkFramework("SDL3_mixer", .{});
            } else {
                lib.addFrameworkPath(b.path("libs/SDL3.xcframework/ios-arm64"));
                lib.addFrameworkPath(b.path("libs/SDL3_mixer.xcframework/ios-arm64"));
                lib.addRPath(b.path("libs/SDL3.xcframework/ios-arm64"));
                lib.addRPath(b.path("libs/SDL3_mixer.xcframework/ios-arm64"));
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
const androidTriple = @import("build/android_template_update.zig").androidTriple;
