pub const std = @import("std");

pub fn addSystemPathsToModule(
    b: *std.Build,
    target: *const std.Build.ResolvedTarget,
    lib: *std.Build.Module,
) void {
    // For TranslateC to work, we need the system library headers
    switch (target.result.os.tag) {
        .macos => {
            const sdk = std.zig.system.darwin.getSdk(b.allocator, b.graph.io, &target.result) orelse
                @panic("macOS SDK is missing");
            lib.addSystemIncludePath(.{ .cwd_relative = b.pathJoin(&.{
                sdk,
                "/usr/include",
            }) });
            lib.addSystemFrameworkPath(.{ .cwd_relative = b.pathJoin(&.{
                sdk,
                "/System/Library/Frameworks",
            }) });
        },
        .ios => {
            const sdk = std.zig.system.darwin.getSdk(b.allocator, b.graph.io, &target.result) orelse
                @panic("macOS SDK is missing");
            lib.addSystemIncludePath(.{ .cwd_relative = b.pathJoin(&.{
                sdk,
                "/usr/include",
            }) });
            lib.addSystemFrameworkPath(.{ .cwd_relative = b.pathJoin(&.{
                sdk,
                "/System/Library/Frameworks",
            }) });
        },
        .linux => {
            if (target.result.abi == .android) {
                // When building for android, we need to use the android linux headers
                if (FindNDK.find(b.graph.io, b.graph.environ_map)) |android_ndk| {
                    if (android_ndk) |ndk| {
                        lib.addSystemIncludePath(.{ .cwd_relative = b.pathJoin(&.{
                            ndk,
                            "toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/include/",
                        }) });
                        lib.addSystemIncludePath(.{ .cwd_relative = b.pathJoin(&.{
                            ndk,
                            "toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/include/aarch64-linux-android/",
                        }) });
                    } else {
                        std.log.err("Can't find android ndk. Set ANDROID_NDK_HOME.", .{});
                        @panic("android/linux build requires ndk. Set ANDROID_NDK_HOME");
                    }
                } else |err| {
                    std.log.err("Error searching for android ndk. Set ANDROID_NDK_HOME. {any}", .{err});
                    @panic("Error searching for android ndk. Set ANDROID_NDK_HOME");
                }
            } else {
                @panic("add_imports currently supports macos, ios, and android.");
            }
        },
        else => {
            std.log.debug(
                "add_imports not supported on {s}",
                .{@tagName(target.result.os.tag)},
            );
            @panic("add_imports only supports macos, ios, and android.");
        },
    }
}

pub fn addSystemPathsToTranslateC(
    b: *std.Build,
    target: *const std.Build.ResolvedTarget,
    lib: *std.Build.Step.TranslateC,
) void {
    // For TranslateC to work, we need the system library headers
    switch (target.result.os.tag) {
        .macos => {
            const sdk = std.zig.system.darwin.getSdk(b.allocator, b.graph.io, &target.result) orelse
                @panic("macOS SDK is missing");
            //std.log.info("engine using macos c headers: {s}", .{sdk});
            lib.addSystemIncludePath(.{ .cwd_relative = b.pathJoin(&.{ sdk, "/usr/include" }) });
            lib.addSystemFrameworkPath(.{ .cwd_relative = b.pathJoin(&.{ sdk, "/System/Library/Frameworks" }) });
        },
        .ios => {
            const sdk = std.zig.system.darwin.getSdk(b.allocator, b.graph.io, &target.result) orelse
                @panic("iOS SDK is missing");
            //std.log.info("engine using iphoneos c headers: {s}", .{sdk});
            lib.addSystemIncludePath(.{ .cwd_relative = b.pathJoin(&.{ sdk, "/usr/include" }) });
            lib.addSystemFrameworkPath(.{ .cwd_relative = b.pathJoin(&.{ sdk, "/System/Library/Frameworks" }) });
        },
        .linux => {
            if (target.result.abi.isAndroid()) {
                // When building for android, we need to use the android linux headers
                if (FindNDK.find(b.graph.io, b.graph.environ_map) catch null) |android_ndk| {
                    //std.log.info("Using android c headers: {any}", .{android_ndk});
                    lib.addSystemIncludePath(.{ .cwd_relative = b.pathJoin(&.{
                        android_ndk,
                        "toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/include/",
                    }) });
                    lib.addSystemIncludePath(.{ .cwd_relative = b.pathJoin(&.{
                        android_ndk,
                        "toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/include/aarch64-linux-android/",
                    }) });
                } else {
                    @panic("android/linux build requires ndk. Set ANDROID_NDK_HOME");
                }
            }
        },
        else => {
            debug(
                "addSystemPathsToTranslateC not supported on {s}",
                .{@tagName(target.result.os.tag)},
            );
            @panic("addSystemPathsToTranslateC only supports macos and ios");
        },
    }
}

pub fn generate_libc_txt(
    b: *const std.Build,
    ndk_path: []const u8,
) !void {
    const io = b.graph.io;

    var libc_txt: std.Io.Writer.Allocating = .init(b.allocator);
    defer libc_txt.deinit();
    var out = &libc_txt.writer;

    // i.e. include_dir=/Users/username/Library/Android/sdk/ndk27.3.13750724/27.0.12077973/toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/include
    const include_dir = "toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/include";
    try out.print("include_dir={s}/{s}\n", .{ ndk_path, include_dir });

    // The system-specific include directory. May be the same as `include_dir`.
    // On Windows it's the directory that includes `vcruntime.h`.
    // On POSIX it's the directory that includes `sys/errno.h`.
    //
    // i.e. sys_include_dir=/Users/username/Library/Android/sdk/ndk27.3.13750724/27.0.12077973/toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/include
    const sys_include_dir = "toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/include";
    try out.print("sys_include_dir={s}/{s}\n", .{ ndk_path, sys_include_dir });

    // The directory that contains `crt1.o` or `crt2.o`.
    // On POSIX, can be found with `cc -print-file-name=crt1.o`.
    // Not needed when targeting MacOS.
    //
    // i.e. crt_dir=/Users/username/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/lib/aarch64-linux-android/21
    const crt_dir = "toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/lib/aarch64-linux-android/21";
    try out.print("crt_dir={s}/{s}\n", .{ ndk_path, crt_dir });

    // These do not need to be set
    try out.writeAll("msvc_lib_dir=\n");
    try out.writeAll("kernel32_lib_dir=\n");
    try out.writeAll("gcc_dir=\n");

    var loc = try std.Io.Dir.cwd().openDir(io, b.build_root.path.?, .{});
    var file = try loc.createFile(io, "android_libc.txt", .{ .truncate = true });
    defer file.close(io);
    try file.writeStreamingAll(io, libc_txt.written());
}

const FindNDK = @import("find_ndk.zig").FindNDK;
const debug = @import("std").log.debug;
