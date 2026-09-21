//! Can be used during or post build to check that no encryption or
//! https related symbols appear in any `.so` file.

pub fn main(init: std.process.Init) !void {
    var dir = try std.Io.Dir.cwd().openDir(init.io, ".", .{ .access_sub_paths = false, .iterate = true });
    defer dir.close(init.io);

    var walker = try dir.walk(std.heap.smp_allocator);
    defer walker.deinit();

    while (try walker.next(init.io)) |entry| {
        if (std.ascii.endsWithIgnoreCase(entry.basename, ".so")) {
            //std.debug.print("File Name: {s}\n", .{entry.basename});
            //std.debug.print("File Name: {s}\n", .{entry.path});
            try checkLib(init.io, entry.basename, entry.path);
        }
        if (std.ascii.endsWithIgnoreCase(entry.basename, ".a")) {
            //std.debug.print("File Name: {s}\n", .{entry.basename});
            //std.debug.print("File Name: {s}\n", .{entry.path});
            try checkLib(init.io, entry.basename, entry.path);
        }
    }
}

/// Call `nm` command to get a list of symbols.
pub fn checkLib(io: std.Io, name: []const u8, path: []const u8) !void {
    const argv = &[_][]const u8{ "nm", path };
    const child = try std.process.run(std.heap.smp_allocator, io, .{
        .argv = argv,
        //.stdin = .ignore,
        //.stdout = .pipe,
        //.stderr = .pipe,
    });
    defer std.heap.smp_allocator.free(child.stdout);
    var i = std.mem.tokenizeAny(u8, child.stdout, "\n\r");
    var count: usize = 0;
    var flagged: usize = 0;
    while (i.next()) |line| {
        count += 1;
        if (stringContains(line, &search_for)) |find| {
            if (stringContains(line, &ignores) == null) {
                std.debug.print("flag: {s} {s} {s}\n", .{ name, find, line });
                flagged += 1;
            }
        }
    }
    if (flagged == 0) {
        std.log.info("{s}: checked {d} symbols.", .{ path, count });
    } else {
        std.log.err("{s}: found {d} symbols and flagged {d} symbols.", .{ path, count, flagged });
    }
}

pub fn stringContains(line: []const u8, items: []const []const u8) ?[]const u8 {
    for (items) |keyword| {
        if (std.ascii.findIgnoreCase(line, keyword)) |_| {
            return keyword;
        }
    }
    return null;
}

/// Symbols that we dont expect to appear
const search_for = [_][]const u8{
    "http",
    "aes",
    "crypt",
    "tls",
};

/// Symbols that are related th threading and non encryption
/// related symbols.
const ignores = [_][]const u8{
    "emutls_get_address",
    "emutls_unregister",
    "emutls_init",
    "emutls_key_create",
    "emutls_key_destruct",
    "emutls_mutex",
    "emutls_num_object",
    "emutls_pthread_key",
    "emutls.current_thread",
    "emutls_control.mutex",
    "emutls_control.next_index",
    "t1_decrypt", // decode freetype t1 font data
    "tls_thread_id",
    "SDL_generic_TLS", // sdl thread local code
    "SDL_GetTLS",
    "SDL_InitTLSData",
    "SDL_QuitTLSData",
    "SDL_Generic_GetTLSData",
    "SDL_Generic_InitTLSData",
    "SDL_Generic_QuitTLSData",
    "SDL_Generic_QuitTLSData",
    "SDL_Generic_SetTLSData",
    "SDL_SYS_GetTLSData",
    "SDL_SYS_InitTLSData",
    "SDL_SYS_QuitTLSData",
    "SDL_SYS_SetTLSData",
    "SDL_SetTLS",
    "SDL_CleanupTLS",
    "SDL_tls_allocated",
    "SDL_tls_id",
    "SDL_GetErrBuf",
    "emutls_v.stbi", // What exactly is this, doesnt look crypto related.
    "emutls_t.stbi", // What exactly is this, doesnt look crypto related.
    "set_tlsEj", // something in SDL TTF font reading code
};

const std = @import("std");
const Child = std.process.Child;
