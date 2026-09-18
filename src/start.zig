const native_arch = builtin.cpu.arch;
const native_os = builtin.os.tag;
const is_wasm = native_arch.isWasm();

const use_safe_allocator = !is_wasm and switch (builtin.mode) {
    .debug, .safe => true,
    .fast, .small => !builtin.link_libc and builtin.single_threaded, // Also not ideal.
};
var safe_allocator: std.heap.SafeAllocator = .init(std.heap.page_allocator, .{});

const builtin = @import("builtin");

var zig_io: std.Io.Threaded = undefined;

var gpa = if (builtin.mode == .debug)
    safe_allocator.allocator()
else if (builtin.link_libc)
    std.heap.c_allocator
else if (is_wasm)
    std.heap.wasm_allocator
else if (!builtin.single_threaded)
    std.heap.smp_allocator
else
    unreachable;

const arena_backing_allocator = if (is_wasm) gpa else std.heap.page_allocator;
var arena_allocator = std.heap.ArenaAllocator.init(arena_backing_allocator);

pub var startup_handler: *const fn (
    std.mem.Allocator,
    std.mem.Allocator,
    std.Io,
    []const [*:0]const u8, //args: std.process.Args,
) error{ OutOfMemory, AppInitFailed }!*Display = undefined;

pub var shutdown_handler: *const fn (
    std.mem.Allocator,
    std.mem.Allocator,
    std.Io,
) void = undefined;

/// When app/binary is executed, SDL takes over the process and calls back
/// with init, quit, iterate, and event handlers.
pub fn start(
    startup: @TypeOf(startup_handler),
    shutdown: @TypeOf(shutdown_handler),
    args: std.process.Args,
) Allocator.Error!void {
    startup_handler = startup;
    shutdown_handler = shutdown;

    var list: std.ArrayListUnmanaged(?[*:0]const u8) = .empty;
    var iter = try args.iterateAllocator(arena_allocator.allocator());
    while (iter.next()) |arg| {
        try list.append(arena_allocator.allocator(), arg);
    }
    try list.append(arena_allocator.allocator(), null);

    _ = sdl.SDL_RunApp(
        @intCast(list.items.len - 1),
        @ptrCast(&list.items[0]),
        runapp_callback,
        null,
    );
}

pub fn runapp_callback(argc: c_int, argv: [*c][*c]u8) callconv(.c) c_int {
    return sdl.SDL_EnterAppMainCallbacks(
        argc,
        argv,
        AppInitC,
        AppIterateC,
        AppEventC,
        AppQuitC,
    );
}

pub fn AppInitC(
    appstate: [*c]?*anyopaque,
    argc: c_int,
    argv: [*c][*c]u8, // [*:null]?[*:0]u8
) callconv(.c) sdl.SDL_AppResult {
    debug("App Init event recieved.", .{});

    zig_io = .init(gpa, .{
        .argv0 = .empty, //.init(.{ .vector = .empty }),
        .environ = .{ .block = .empty },
    });

    const args = @as([]const [*:0]const u8, @ptrCast(argv[0..@intCast(argc)]));
    appstate.?.* = startup_handler(
        gpa,
        arena_allocator.allocator(),
        zig_io.io(),
        args,
    ) catch return sdl.SDL_APP_FAILURE;

    return sdl.SDL_APP_CONTINUE;
}

pub fn AppQuitC(
    appstate: ?*anyopaque,
    result: sdl.SDL_AppResult,
) callconv(.c) void {
    const display: *Display = @ptrCast(@alignCast(appstate.?));

    debug("App Quit event recieved.", .{});

    shutdown_handler(gpa, arena_allocator.allocator(), zig_io.io());

    zig_io.deinit();
    defer arena_allocator.deinit();
    if (use_safe_allocator) {
        _ = safe_allocator.deinit();
    }

    _ = display;
    _ = result;
}

pub fn AppIterateC(appstate: ?*anyopaque) callconv(.c) sdl.SDL_AppResult {
    var display: *Display = @ptrCast(@alignCast(appstate.?));

    display.iterate() catch |e| {
        err("SDL_AppIterate failed. Error: {any}", .{e});
        return sdl.SDL_APP_FAILURE;
    };
    if (display.state == .ending)
        return sdl.SDL_APP_SUCCESS
    else
        return sdl.SDL_APP_CONTINUE;
}

pub fn AppEventC(appstate: ?*anyopaque, event: ?*sdl.SDL_Event) callconv(.c) sdl.SDL_AppResult {
    var display: *Display = @ptrCast(@alignCast(appstate.?));

    if (event) |e| {
        display.handleEvent(e) catch |f| {
            err("SDL_AppEvent failed. Error: {any}", .{f});
            return sdl.SDL_APP_FAILURE;
        };
    }
    if (display.state == .ending)
        return sdl.SDL_APP_SUCCESS
    else
        return sdl.SDL_APP_CONTINUE;
}

const std = @import("std");
const Allocator = std.mem.Allocator;

const engine = @import("engine.zig");
const Display = engine.Display;
const sdl = engine.sdl;

const debug = engine.log.debug;
const err = engine.log.err;
