var zig_init: *const std.process.Init = undefined;
var startup_handler: *const fn (*const std.process.Init) error{ OutOfMemory, AppInitFailed }!*Display = undefined;
var shutdown_handler: *const fn (*const std.process.Init) void = undefined;

/// When app/binary is executed, SDL takes over the process and calls back
/// with init, quit, iterate, and event handlers.
pub fn start(
    init: *const std.process.Init,
    startup: *const fn (*const std.process.Init) error{ OutOfMemory, AppInitFailed }!*Display,
    shutdown: *const fn (*const std.process.Init) void,
) void {
    zig_init = init;
    startup_handler = startup;
    shutdown_handler = shutdown;
    var none: [0:null]?[*:0]u8 = .{};
    _ = sdl.SDL_RunApp(0, @ptrCast(&none), runapp_callback, null);
}

pub export fn runapp_callback(argc: c_int, argv: ?[*:null]?[*:0]u8) callconv(.c) c_int {
    return sdl.SDL_EnterAppMainCallbacks(
        argc,
        @ptrCast(argv.?[0..@intCast(argc)]),
        AppInitC,
        AppIterateC,
        AppEventC,
        AppQuitC,
    );
}

//SDL_AppResult SDL_AppInit(void **appstate, int argc, char *argv[]);
//pub export fn AppInit(appstate: **void, argc: c_int, argv: [*:null]const ?[*:0]const u8) callconv(.c) c_int {
pub export fn AppInitC(appstate: ?*?*anyopaque, argc: c_int, argv: ?[*:null]?[*:0]u8) callconv(.c) sdl.SDL_AppResult {
    debug("App Init event recieved.", .{});
    //var display: *Display = @ptrCast(appstate.?);
    appstate.?.* = startup_handler(zig_init) catch return sdl.SDL_APP_FAILURE;
    _ = argc;
    _ = argv;

    return sdl.SDL_APP_CONTINUE;
}

//void SDL_AppQuit(void *appstate, SDL_AppResult result);
//pub export fn AppQuit(appstate: **void, result: c_int) callconv(.c) c_int {
pub export fn AppQuitC(appstate: ?*anyopaque, result: sdl.SDL_AppResult) callconv(.c) void {
    const display: *Display = @ptrCast(@alignCast(appstate.?));

    debug("App Quit event recieved.", .{});

    shutdown_handler(zig_init);

    _ = display;
    _ = result;
}

//SDL_AppResult SDL_AppIterate(void *appstate);
//pub export fn AppIterate(appstate: **void) callconv(.c) c_int {
pub export fn AppIterateC(appstate: ?*anyopaque) callconv(.c) sdl.SDL_AppResult {
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

//SDL_AppResult SDL_AppEvent(void *appstate, SDL_Event *event);
//pub export fn AppEvent(appstate: **void, event: *sdl.SDL_Event) callconv(.c) c_int {
pub export fn AppEventC(appstate: ?*anyopaque, event: ?*sdl.SDL_Event) callconv(.c) sdl.SDL_AppResult {
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

const engine = @import("engine.zig");
const Display = engine.Display;
const sdl = engine.sdl;

const debug = engine.log.debug;
const err = engine.log.err;
