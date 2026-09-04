/// Update the android project variables.
pub fn main(init: std.process.Init) !void {
    const args = try init.minimal.args.toSlice(init.arena.allocator());

    if (args.len != 6) {
        std.debug.print("usage: /path/to/project /subfolder/libc.txt app_name app_version android_target", .{});
        std.debug.print("\nFound {d} arguments: ", .{args.len});
        for (args) |arg| {
            std.debug.print(" {s} ", .{arg});
        }
        std.debug.print("\n", .{});
        std.process.exit(1);
    }
    std.debug.print("\nFound {d} arguments: ", .{args.len});
    for (args) |arg| {
        std.debug.print(" {s} ", .{arg});
    }
    std.debug.print("\n", .{});

    const install_path = args[1];
    const libc_file = args[2];
    const app_name = args[3];
    const app_version = args[4];
    const android_target = args[5];

    const ndk_path = FindNDK.find(init.io, init.environ_map) catch |e| {
        std.log.err("Error while finding NDK. {any}", .{e});
        return;
    };
    if (ndk_path == null) {
        std.log.err("Dialectos for android requires the android ndk. Specify ANDROID_NDK_HOME", .{});
    } else {
        std.log.info("Dialectos for android using android ndk in {s}", .{ndk_path.?});
    }

    generateLibC(init.gpa, init.io, android_target, libc_file, ndk_path.?) catch @panic("failed to generate libc.txt");

    try update_android_metadata(
        init.gpa,
        init.io,
        try std.Io.Dir.cwd().openDir(init.io, install_path, .{}),
        "app/src/main/AndroidManifest.xml",
        "app/build.gradle",
        "app/src/main/res/values/strings.xml",
        app_name,
        app_version,
    );
    std.process.exit(0);
}

/// Use to update `AndroidManifest.xml`
pub fn update_android_metadata(
    allocator: std.mem.Allocator,
    io: std.Io,
    dir: std.Io.Dir,
    manifest: []const u8,
    gradle: []const u8,
    strings: []const u8,
    app_name: []const u8,
    app_version: []const u8,
) !void {
    var buff: [100]u8 = undefined;
    try update_android_strings_variable(allocator, io, dir, strings, "app_name", app_name);
    try update_android_manifest_variable(allocator, io, dir, manifest, "versionName", app_version);
    try update_android_manifest_variable(allocator, io, dir, manifest, "versionCode", app_version);
    try update_android_gradle_variable(allocator, io, dir, gradle, "versionName", try std.fmt.bufPrint(&buff, "\"{s}\"", .{app_version}));
    try update_android_gradle_variable(allocator, io, dir, gradle, "versionCode", app_version);
}

pub fn update_android_manifest_variable(
    allocator: std.mem.Allocator,
    io: std.Io,
    dir: std.Io.Dir,
    filename: []const u8,
    comptime key: []const u8,
    value: []const u8,
) !void {
    const manifest_variable_start = "android:" ++ key ++ "=\"";
    const manifest_variable_end = "\"";

    if (dir.readFileAlloc(io, filename, allocator, .unlimited)) |data| {
        defer allocator.free(data);
        const new_data = try replace_variable(data, manifest_variable_start, manifest_variable_end, value, allocator);
        defer allocator.free(new_data);
        const file = try dir.createFile(io, filename, .{});
        defer file.close(io);
        _ = try file.writeStreamingAll(io, new_data);
        std.log.info("Updated android manifest variable {s} = \"{s}\"", .{ key, value });
    } else |e| {
        std.log.warn("Error reading android file='{s}'. {any}", .{ filename, e });
    }
}

pub fn update_android_strings_variable(
    allocator: std.mem.Allocator,
    io: std.Io,
    dir: std.Io.Dir,
    filename: []const u8,
    comptime key: []const u8,
    value: []const u8,
) !void {
    const manifest_variable_start = "<string name=\"" ++ key ++ "\">";
    const manifest_variable_end = "</string>";
    if (dir.readFileAlloc(io, filename, allocator, .unlimited)) |data| {
        defer allocator.free(data);
        const new_data = try replace_variable(data, manifest_variable_start, manifest_variable_end, value, allocator);
        defer allocator.free(new_data);
        const file = try dir.createFile(io, filename, .{});
        defer file.close(io);
        _ = try file.writeStreamingAll(io, new_data);
        std.log.info("Updated android manifest variable {s} = \"{s}\"", .{ key, value });
    } else |e| {
        std.log.warn("Error reading android manifest file. {any}", .{e});
    }
}

pub fn update_android_gradle_variable(
    allocator: std.mem.Allocator,
    io: std.Io,
    dir: std.Io.Dir,
    filename: []const u8,
    comptime key: []const u8,
    value: []const u8,
) !void {
    const gradle_variable_start = key ++ " ";
    const gradle_variable_end = "\n";
    if (dir.readFileAlloc(io, filename, allocator, .unlimited)) |data| {
        defer allocator.free(data);
        const new_data = try replace_variable(data, gradle_variable_start, gradle_variable_end, value, allocator);
        defer allocator.free(new_data);
        const file = try dir.createFile(io, filename, .{});
        defer file.close(io);
        _ = try file.writeStreamingAll(io, new_data);
        std.log.info("Updated android gradle variable {s} = \"{s}\"", .{ key, value });
    } else |e| {
        std.log.warn("Error reading android gradle file. {any}", .{e});
    }
}

pub fn replace_variable(data: []const u8, comptime key_start: []const u8, comptime key_end: []const u8, value: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    var i = std.mem.tokenizeSequence(u8, data, key_start);
    var first = true;
    while (i.next()) |v| {
        var part = v;
        if (!first) {
            if (std.mem.indexOf(u8, v, key_end)) |x| {
                part = v[x..];
            }
        } else {
            first = false;
        }
        try out.appendSlice(allocator, part);
        if (i.peek() != null) {
            try out.appendSlice(allocator, key_start);
            try out.print(allocator, "{s}", .{value});
        }
    }
    return out.toOwnedSlice(allocator);
}

pub fn androidTriple(target: *const std.Target) error{InvalidAndroidTarget}![]const u8 {
    if (target.abi != .android) return error.InvalidAndroidTarget;
    return switch (target.cpu.arch) {
        .aarch64 => "aarch64-linux-android",
        .x86_64 => "x86_64-linux-android",
        .x86 => "i686-linux-android",
        .arm => "arm-linux-androideabi",
        .riscv64 => "riscv64-linux-android",
        else => error.InvalidAndroidTarget,
    };
}

pub fn generateLibC(
    allocator: Allocator,
    io: std.Io,
    android_target: []const u8,
    filename: []const u8,
    ndk_path: []const u8,
) !void {
    var libc_txt: std.Io.Writer.Allocating = .init(allocator);
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
    const crt_dir = "toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/lib";
    try out.print("crt_dir={s}/{s}/{s}/21\n", .{ ndk_path, crt_dir, android_target });

    // These do not need to be set
    try out.writeAll("msvc_lib_dir=\n");
    try out.writeAll("kernel32_lib_dir=\n");
    try out.writeAll("gcc_dir=\n");

    var file = try std.Io.Dir.cwd().createFile(io, filename, .{ .truncate = true });
    defer file.close(io);
    try file.writeStreamingAll(io, libc_txt.written());
}

test "manifest_version_update" {
    {
        const sample =
            \\<manifest xmlns:android="http://schemas.android.com/apk/res/android"
            \\android:versionCode="1"
            \\android:versionName="1.0"
            \\xmlns:tools="http://schemas.android.com/tools"
            \\android:installLocation="auto">
        ;
        const updated =
            \\<manifest xmlns:android="http://schemas.android.com/apk/res/android"
            \\android:versionCode="333"
            \\android:versionName="3.3.3"
            \\xmlns:tools="http://schemas.android.com/tools"
            \\android:installLocation="auto">
        ;

        const result = try replace_variable(sample, "android:versionName=\"", "\"", "3.3.3", std.testing.allocator);
        defer std.testing.allocator.free(result);
        const result2 = try replace_variable(result, "android:versionCode=\"", "\"\n", "333", std.testing.allocator);
        defer std.testing.allocator.free(result2);
        try std.testing.expectEqualStrings(updated, result2);
    }
    try update_android_metadata(
        "android/app/src/main/AndroidManifest.xml",
        "android/app/build.gradle",
        "android/app/src/main/res/values/strings.xml",
        "test App",
        "3.3.3",
        "333",
        std.testing.allocator,
    );
}

test "gradle_version_update" {
    {
        const sample =
            \\defaultConfig {
            \\  minSdkVersion 21
            \\  targetSdkVersion 35
            \\  versionCode 33
            \\  versionName "1.0"
            \\  stuff 99
        ;
        const updated =
            \\defaultConfig {
            \\  minSdkVersion 21
            \\  targetSdkVersion 35
            \\  versionCode 22
            \\  versionName "2.2"
            \\  stuff 99
        ;

        const result = try replace_variable(sample, "versionName ", "\n", "\"2.2\"", std.testing.allocator);
        defer std.testing.allocator.free(result);
        const result2 = try replace_variable(result, "versionCode ", "\n", "22", std.testing.allocator);
        defer std.testing.allocator.free(result2);
        try std.testing.expectEqualStrings(updated, result2);
    }
    try update_android_metadata(
        "android/app/src/main/AndroidManifest.xml",
        "android/app/build.gradle",
        "android/app/src/main/res/values/strings.xml",
        "test App",
        "2.2",
        "22",
        std.testing.allocator,
    );
}

const std = @import("std");
const Allocator = std.mem.Allocator;

const FindNDK = @import("find_ndk.zig").FindNDK;
