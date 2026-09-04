pub const std = @import("std");

pub fn getFrameworkPath(
    b: *std.Build,
    target: *const std.Build.ResolvedTarget,
) ?std.Build.LazyPath {
    switch (target.result.os.tag) {
        .macos, .ios => {
            const sdk = std.zig.system.darwin.getSdk(
                b.allocator,
                b.graph.io,
                &target.result,
            ) orelse @panic("SDK is missing");
            return .{ .cwd_relative = b.pathJoin(&.{ sdk, "/System/Library/Frameworks" }) };
        },
        else => return null,
    }
}

var systemPaths: [2]std.Build.LazyPath = undefined;

pub fn getSystemPaths(
    b: *std.Build,
    target: *const std.Build.ResolvedTarget,
) []std.Build.LazyPath {
    // For TranslateC to work, we need the system library headers
    switch (target.result.os.tag) {
        .macos, .ios => {
            const sdk = std.zig.system.darwin.getSdk(
                b.allocator,
                b.graph.io,
                &target.result,
            ) orelse @panic("SDK is missing");
            systemPaths[0] = .{ .cwd_relative = b.pathJoin(&.{ sdk, "/usr/include" }) };
            return systemPaths[0..1];
        },
        .linux => {
            if (target.result.abi.isAndroid()) {
                if (FindNDK.find(b.graph.io, b.graph.environ_map) catch null) |android_ndk| {
                    systemPaths[0] = .{ .cwd_relative = b.pathJoin(&.{
                        android_ndk,
                        "toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/include/",
                    }) };
                    systemPaths[1] = .{ .cwd_relative = b.pathJoin(&.{
                        android_ndk,
                        "toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/include/aarch64-linux-android/",
                    }) };
                    return systemPaths[0..2];
                } else {
                    @panic("android/linux build requires ndk. Set ANDROID_NDK_HOME");
                }
            }
            return &.{};
        },
        else => return &.{},
    }
}

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
                if (false) {
                    if (FindNDK.find(b.graph.io, b.graph.environ_map)) |android_ndk| {
                        if (android_ndk) |ndk| {
                            lib.addSystemIncludePath(.{ .cwd_relative = b.pathJoin(&.{
                                ndk,
                                "toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/include/",
                            }) });
                            const path = try std.fs.path.join(b.graph.arena.allocator(), &.{
                                ndk,
                                "toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/include/aarch64-linux-android/",
                                "aarch64-linux-android",
                                "/",
                            });
                            lib.addSystemIncludePath(.{ .cwd_relative = b.path(path) });
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

const FindNDK = @import("find_ndk.zig").FindNDK;
