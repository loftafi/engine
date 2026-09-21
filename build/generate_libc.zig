const min_android_api = 35;

/// Update the android project variables.
pub fn main(init: std.process.Init) !void {
    const args = try init.minimal.args.toSlice(init.arena.allocator());

    if (args.len != 3) {
        std.debug.print("usage: /path/to/libc.txt android-target", .{});
        std.debug.print("\nFound {d} arguments: ", .{args.len});
        for (args) |arg| {
            std.debug.print(" {s} ", .{arg});
        }
        std.debug.print("\n", .{});
        std.process.exit(1);
    }

    const libc_file = args[1];
    const android_target = args[2];

    const ndk_path = FindNDK.find(init.io, init.environ_map) catch |e| {
        err("Error while finding NDK. {any}", .{e});
        return;
    };
    if (ndk_path == null) {
        err("Android ndk required. Specify ANDROID_NDK_HOME", .{});
    } else {
        info("Using Android ndk {s}", .{ndk_path.?});
    }

    generateLibC(
        init.gpa,
        init.io,
        android_target,
        libc_file,
        ndk_path.?,
    ) catch |e| {
        err("failed to generate libc.txt file='{s}'. err={t}", .{ libc_file, e });
        @panic("failed to generate libc.txt");
    };

    std.process.exit(0);
}

pub fn generateLibC(
    allocator: Allocator,
    io: std.Io,
    android_target: []const u8,
    libc_filename: []const u8,
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
    // i.e. crt_dir=/Users/username/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/lib/aarch64-linux-android/35
    const crt_dir = "toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/lib";
    try out.print("crt_dir={s}/{s}/{s}/{d}\n", .{
        ndk_path,
        crt_dir,
        android_target,
        min_android_api,
    });

    // These do not need to be set
    try out.writeAll("msvc_lib_dir=\n");
    try out.writeAll("kernel32_lib_dir=\n");
    try out.print("gcc_dir={s}/{s}/{s}/{d}\n", .{
        ndk_path,
        crt_dir,
        android_target,
        min_android_api,
    });

    var file = try std.Io.Dir.cwd().createFile(io, libc_filename, .{ .truncate = true });
    defer file.close(io);
    try file.writeStreamingAll(io, libc_txt.written());
}

pub const std_options: std.Options = .{
    .log_level = .warn,
};

const std = @import("std");
const Allocator = std.mem.Allocator;
const debug = std.log.debug;
const info = std.log.info;
const warn = std.log.warn;
const err = std.log.err;

const FindNDK = @import("FindNDK.zig").FindNDK;
