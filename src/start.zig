pub fn start(display: *Display) void {
    var none: [0:null]?[*:0]u8 = .{};
    current_display = display;
    _ = sdl.SDL_RunApp(0, @ptrCast(&none), runapp_callback, null);
}

var current_display: *Display = undefined;

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
    //var display: *Display = @ptrCast(appstate.?);
    appstate.?.* = current_display;

    _ = argc;
    _ = argv;

    debug("App Init event recieved.", .{});

    return sdl.SDL_APP_CONTINUE;
}

//void SDL_AppQuit(void *appstate, SDL_AppResult result);
//pub export fn AppQuit(appstate: **void, result: c_int) callconv(.c) c_int {
pub export fn AppQuitC(appstate: ?*anyopaque, result: sdl.SDL_AppResult) callconv(.c) void {
    const display: *Display = @ptrCast(@alignCast(appstate.?));

    debug("App Quit event recieved.", .{});

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
