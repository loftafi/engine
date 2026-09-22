/// Update the android project variables.
pub fn main(init: std.process.Init) !void {
    const args = try init.minimal.args.toSlice(init.arena.allocator());

    if (args.len != 7) {
        std.debug.print("usage: /path/to/template /path/to/libc.txt app_name app_version app_id android_target", .{});
        std.debug.print("\nFound {d} arguments: ", .{args.len});
        for (args) |arg| {
            std.debug.print(" {s} ", .{arg});
        }
        std.debug.print("\n", .{});
        std.process.exit(1);
    }

    const android_template_folder = args[1];
    const libc_file = args[2];
    const app_name = args[3];
    const app_version = args[4];
    const app_id = args[5];
    const android_target = args[6];

    const ndk_path = FindNDK.find(init.io, init.environ_map) catch |e| {
        err("Error while finding NDK. {any}", .{e});
        return;
    };
    if (ndk_path == null) {
        err("Android ndk required. Specify ANDROID_NDK_HOME", .{});
    } else {
        info("Using Android ndk {s}", .{ndk_path.?});
    }

    @import("generate_libc.zig").generateLibC(
        init.gpa,
        init.io,
        android_target,
        libc_file,
        ndk_path.?,
    ) catch |e| {
        err("failed to generate libc.txt file='{s}'. err={t}", .{ libc_file, e });
        @panic("failed to generate libc.txt");
    };

    try updateAndroidMetadata(
        init.gpa,
        init.io,
        android_template_folder,
        "app/src/main/AndroidManifest.xml",
        "app/build.gradle",
        "app/src/main/res/values/strings.xml",
        app_name,
        app_version,
        app_id,
    );
    std.process.exit(0);
}

/// Use to update `AndroidManifest.xml`
pub fn updateAndroidMetadata(
    allocator: std.mem.Allocator,
    io: std.Io,
    android_template_folder: []const u8,
    manifest: []const u8,
    gradle: []const u8,
    strings: []const u8,
    app_name: []const u8,
    app_version: []const u8,
    app_id: []const u8,
) !void {
    var dir = try std.Io.Dir.cwd().openDir(io, android_template_folder, .{});
    defer dir.close(io);

    var version_code = app_version;
    if (std.mem.indexOf(u8, version_code, ".")) |index| {
        version_code = version_code[0..index];
    }

    var buff: [500]u8 = undefined;
    try update_android_strings_variable(allocator, io, &dir, strings, "app_name", app_name);
    try updateAndroidManifestVariable(allocator, io, &dir, manifest, "versionName", app_version);
    try updateAndroidManifestVariable(allocator, io, &dir, manifest, "versionCode", version_code);
    try updateAndroidGradleVariable(allocator, io, &dir, gradle, "versionName", try std.fmt.bufPrint(&buff, "\"{s}\"", .{app_version}));
    try updateAndroidGradleVariable(allocator, io, &dir, gradle, "applicationId", try std.fmt.bufPrint(&buff, "'{s}'", .{app_id}));
}

pub fn updateAndroidManifestVariable(
    allocator: std.mem.Allocator,
    io: std.Io,
    dir: *std.Io.Dir,
    filename: []const u8,
    comptime key: []const u8,
    value: []const u8,
) !void {
    const manifest_variable_start = "android:" ++ key ++ "=\"";
    const manifest_variable_end = "\"";

    if (dir.readFileAlloc(io, filename, allocator, .unlimited)) |data| {
        defer allocator.free(data);
        const new_data = try replaceVariable(
            data,
            manifest_variable_start,
            manifest_variable_end,
            value,
            allocator,
        );
        defer allocator.free(new_data);
        const file = try dir.createFile(io, filename, .{});
        defer file.close(io);
        _ = try file.writeStreamingAll(io, new_data);
        debug("Updated android manifest variable {s} = \"{s}\"", .{ key, value });
    } else |e| {
        warn("Error reading android file='{s}'. {any}", .{ filename, e });
    }
}

pub fn update_android_strings_variable(
    allocator: std.mem.Allocator,
    io: std.Io,
    dir: *std.Io.Dir,
    filename: []const u8,
    comptime key: []const u8,
    value: []const u8,
) !void {
    const manifest_variable_start = "<string name=\"" ++ key ++ "\">";
    const manifest_variable_end = "</string>";
    if (dir.readFileAlloc(io, filename, allocator, .unlimited)) |data| {
        defer allocator.free(data);
        const new_data = try replaceVariable(
            data,
            manifest_variable_start,
            manifest_variable_end,
            value,
            allocator,
        );
        defer allocator.free(new_data);
        const file = try dir.createFile(io, filename, .{});
        defer file.close(io);
        _ = try file.writeStreamingAll(io, new_data);
        debug("Updated android manifest variable {s} = \"{s}\"", .{ key, value });
    } else |e| {
        warn("Error reading android manifest file. {any}", .{e});
    }
}

pub fn updateAndroidGradleVariable(
    allocator: std.mem.Allocator,
    io: std.Io,
    dir: *std.Io.Dir,
    filename: []const u8,
    comptime key: []const u8,
    value: []const u8,
) !void {
    const gradle_variable_start = key ++ " ";
    const gradle_variable_end = "\n";
    if (dir.readFileAlloc(io, filename, allocator, .unlimited)) |data| {
        defer allocator.free(data);
        const new_data = try replaceVariable(
            data,
            gradle_variable_start,
            gradle_variable_end,
            value,
            allocator,
        );
        defer allocator.free(new_data);
        const file = try dir.createFile(io, filename, .{});
        defer file.close(io);
        _ = try file.writeStreamingAll(io, new_data);
        debug("Updated android gradle variable {s} = \"{s}\"", .{ key, value });
    } else |e| {
        warn("Error reading android gradle file. {any}", .{e});
    }
}

pub fn replaceVariable(
    data: []const u8,
    comptime key_start: []const u8,
    comptime key_end: []const u8,
    value: []const u8,
    allocator: std.mem.Allocator,
) ![]const u8 {
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

pub const std_options: std.Options = .{
    .log_level = .warn,
};

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

        const result = try replaceVariable(sample, "android:versionName=\"", "\"", "3.3.3", std.testing.allocator);
        defer std.testing.allocator.free(result);
        const result2 = try replaceVariable(result, "android:versionCode=\"", "\"\n", "333", std.testing.allocator);
        defer std.testing.allocator.free(result2);
        try std.testing.expectEqualStrings(updated, result2);
    }
    try updateAndroidMetadata(
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

        const result = try replaceVariable(sample, "versionName ", "\n", "\"2.2\"", std.testing.allocator);
        defer std.testing.allocator.free(result);
        const result2 = try replaceVariable(result, "versionCode ", "\n", "22", std.testing.allocator);
        defer std.testing.allocator.free(result2);
        try std.testing.expectEqualStrings(updated, result2);
    }
    try updateAndroidMetadata(
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
const debug = std.log.debug;
const info = std.log.info;
const warn = std.log.warn;
const err = std.log.err;

const FindNDK = @import("FindNDK.zig").FindNDK;
