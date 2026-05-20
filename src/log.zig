//! Custom logging API that direct messages to SDL or stdout depending
//! on the environment. Adds `trace` and `notice` levels. Use with
//! `std.Options.logFn` in your app to direct zig logging
//! to the engine.
//!
//! If `builtin.abi.isAndroid()` then log messeges are diverted to SDL
//! so that they are sent to the android logging console.

/// A log level enum that adds `trace`, `notice`, and `alert`
///
/// Zig log levels allow `err` but not an error `alert` that requires a
/// more immediate operator response. Zig also does not distinguish
/// between an `info` log message and an info `notice` that might require
/// immediate action.
pub const Level = enum {
    trace,
    debug,
    info,
    notice,
    warn,
    err,
    alert,
};

const max_log_message_size = 5000;

pub fn Log(size: usize) type {
    return struct {
        pub const Self = @This();

        history: [size]Entry,
        start: usize,
        end: usize,

        pub fn init() Self {
            return .{
                .history = undefined,
                .start = 0,
                .end = 0,
            };
        }

        /// A `trace` message can be used liberally and should only be used for
        /// log messages in programs that are under active development. Is never
        /// included in a production ready build of an application.
        pub inline fn trace(self: *Self, comptime format: []const u8, args: anytype) void {
            if (builtin.mode != .Debug)
                self.log(.trace, format, args);
        }

        pub inline fn log(
            self: *Self,
            io: std.Io,
            level: Level,
            comptime format: []const u8,
            args: anytype,
        ) void {
            var current: usize = 0;
            if (self.end == 0 and self.start == 0) {
                self.end = 1;
                current = 0;
            } else if (self.end == self.history.len) {
                self.end = 1;
                self.start = 1;
                current = 0;
            } else {
                current = self.end;
                if (self.start == self.end) self.start += 1;
                self.end += 1;
                if (self.start == self.history.len) self.start = 0;
            }
            self.history[current].level = level;
            self.history[current].time = std.Io.Timestamp.now(io, .real).toMilliseconds();
            const message = std.fmt.bufPrintZ(&self.history[current].message, format, args) catch format;

            const colour = switch (level) {
                .trace => "90",
                .debug => "34",
                .info => "36",
                .notice => "91",
                .warn => "33",
                .err => "31",
                .alert => "31",
            };

            var stderr = std.debug.lockStderr(&.{}).terminal().writer;
            defer std.debug.unlockStderr();
            if (!builtin.abi.isAndroid() and builtin.os.tag != .ios) {
                nosuspend stderr.print("\x1B[{s}m[\x1B[1m{t}\x1B[22m] {s}\x1B[0m\n", .{
                    colour,
                    level,
                    message,
                }) catch return;
            } else {
                nosuspend stderr.print("{t} {s}\r\n", .{ level, message }) catch return;
            }
            stderr.flush() catch {};
        }

        pub const Entry = struct {
            level: Level,
            time: i64,
            message: [max_log_message_size]u8,
        };
    };
}

/// A `trace` message can be used liberally and should only be used for
/// log messages in programs that are under active development. Is never
/// included in a production ready build of an application.
pub inline fn trace(comptime format: []const u8, args: anytype) void {
    if (dev_build and engine.dev_mode)
        formatted_log_output(.trace, .engine, format, args);
}

/// A `debug` message should only be used when it is generally useful for
/// helping track down abnormal program behaviour. A debug message is usually
/// interesting even in a production ready build of an application.
///
/// Examples of this would include: reporting when a user changes their font
/// size or screen resolution to allow support staff to understand what
/// actions might have lead to an unexpected program state.
pub inline fn debug(comptime format: []const u8, args: anytype) void {
    if (dev_build or engine.dev_mode) {
        formatted_log_output(.debug, .engine, format, args);
    }
}

/// Log general information that might be useful for collection or human
/// review at some point in the future.
///
/// Examples of this might include reporting creation of a new user account.
pub inline fn info(comptime format: []const u8, args: anytype) void {
    formatted_log_output(.info, .engine, format, args);
}

/// A `notice` info log message is like a regular `info` log message but
/// it may be particularly important and might need to be brought to the
/// attention of a human at a higher priority than a regular `info` message.
///
/// Examples of this might be reporting the normal activity of creation
/// of a new user account, but with an IP address of a country that is not
/// expected to be accessing the application.
pub inline fn notice(comptime format: []const u8, args: anytype) void {
    formatted_log_output(.notice, .engine, format, args);
}

/// A `warn` indicates something unexpected or unusual that might not
/// be an error.
pub inline fn warn(comptime format: []const u8, args: anytype) void {
    formatted_log_output(.warn, .engine, format, args);
}

/// An `err` indicates abnormal behaviour that requires attention at
/// some point in the future, but might not be urgent. An error would _not_
/// typically be linked to an SMS or pager system for developer review. Use
/// this when you do _not_ need support staff to be immediately notified.
///
/// Examples of this might include: an app that cant find an image resource
/// to display but will continue to function correctly;
pub inline fn err(comptime format: []const u8, args: anytype) void {
    formatted_log_output(.err, .engine, format, args);
}

/// An `alert` is an error that may require immediate or high priority
/// human attention. An alert would typically be linked to an SMS or
/// pager system. Only use this if support staff should be woken up in the
/// middle of the night to resolve this.
///
/// Examples of this might include: a web server unable to contact the
/// database; or actvity that is indicative of a security intrusion.
pub inline fn alert(comptime format: []const u8, args: anytype) void {
    formatted_log_output(.alert, .engine, format, args);
}

/// Use with `std.Options.logFn` in your app to direct zig logging
/// to the engine.
pub fn log_capture(
    comptime level: std.log.Level,
    comptime scope: @EnumLiteral(),
    comptime format: []const u8,
    args: anytype,
) void {

    // Zig built in logging only supports these 4 levels
    formatted_log_output(switch (level) {
        .debug => .debug,
        .info => .info,
        .warn => .warn,
        .err => .err,
    }, scope, format, args);
}

fn formatted_log_output(
    comptime level: Level,
    comptime scope: @EnumLiteral(),
    comptime format: []const u8,
    args: anytype,
) void {
    if (!dev_build) {
        if (level == .trace) return;
        if (level == .debug and engine.dev_mode == false) return;
    }

    var buffer: [max_log_message_size]u8 = undefined;
    const message = std.fmt.bufPrintZ(&buffer, format, args) catch format;

    if (!builtin.abi.isAndroid()) {
        const prefix = switch (level) {
            .trace => "\x1B[90m[\x1B[1mtrace\x1B[22m] ",
            .debug => "\x1B[34m[\x1B[1mdebug\x1B[22m] ",
            .info => "\x1B[36m[\x1B[1minfo\x1B[22m]  ",
            .notice => "\x1B[91m[\x1B[1mnotice\x1B[22m] ",
            .warn => "\x1B[33m[\x1B[1mwarn\x1B[22m]  ",
            .err => "\x1B[31m[\x1B[1merror\x1B[22m] ",
            .alert => "\x1B[31m[\x1B[1malert\x1B[22m] ",
        };
        // Log to terminal in debug mode
        var stderr = std.debug.lockStderr(&.{}).terminal().writer;
        defer std.debug.unlockStderr();
        nosuspend stderr.print("{s}{s}\x1B[0m\n", .{ prefix, message }) catch return;
        stderr.flush() catch {};
    } else {
        const prefix = switch (level) {
            .trace => "[trace] ",
            .debug => "[debug] ",
            .info => "[info] ",
            .notice => "[notice] ",
            .warn => "[warn] ",
            .err => "[error] ",
            .alert => "[alert] ",
        };

        // Log using SDL when in release mode
        if (scope != .term_scope) {
            sdl.SDL_LogInfo(@intFromEnum(SdlLogCategory.application), prefix ++ message);
        }
    }
}

/// SDL provides extra information that is sometimes helpful for debugging, lets print this
/// information when we are in debug mode.
///
/// We don't need enums for this, but here is an example of how it could be handled.
/// https://github.com/Gota7/zig-sdl3/blob/9327bd69d7cbac728486d57bec05d35371a17737/src/log.zig
pub fn sdl_log_callback(
    data: ?*anyopaque,
    category: c_int,
    priority: sdl.SDL_LogPriority,
    message: [*c]const u8,
) callconv(.c) void {
    std.log.scoped(.term_scope).debug("SDL ({s}, {s}) {s}", .{
        @tagName(SdlLogCategory.fromInt(category)),
        @tagName(SdlLogPriority.fromInt(priority)),
        message,
    });
    _ = data;
}

/// Convert the SDL LogPriority into a zig enum. See:
/// https://wiki.libsdl.org/SDL3/SDL_LogCategory
const SdlLogPriority = enum(c_uint) {
    invalid = sdl.SDL_LOG_PRIORITY_INVALID,
    trace = sdl.SDL_LOG_PRIORITY_TRACE,
    verbose = sdl.SDL_LOG_PRIORITY_VERBOSE,
    debug = sdl.SDL_LOG_PRIORITY_DEBUG,
    info = sdl.SDL_LOG_PRIORITY_INFO,
    warn = sdl.SDL_LOG_PRIORITY_WARN,
    err = sdl.SDL_LOG_PRIORITY_ERROR,
    critical = sdl.SDL_LOG_PRIORITY_CRITICAL,
    count = sdl.SDL_LOG_PRIORITY_COUNT,
    unknown = 9999,

    fn fromInt(priority: c_uint) SdlLogPriority {
        return std.enums.fromInt(SdlLogPriority, priority) orelse .unknown;
    }
};

/// Convert the SDL LogCategory into a zig enum. See:
/// https://wiki.libsdl.org/SDL3/SDL_LogCategory
const SdlLogCategory = enum(c_int) {
    application = sdl.SDL_LOG_CATEGORY_APPLICATION,
    @"error" = sdl.SDL_LOG_CATEGORY_ERROR,
    assert = sdl.SDL_LOG_CATEGORY_ASSERT,
    system = sdl.SDL_LOG_CATEGORY_SYSTEM,
    audio = sdl.SDL_LOG_CATEGORY_AUDIO,
    video = sdl.SDL_LOG_CATEGORY_VIDEO,
    render = sdl.SDL_LOG_CATEGORY_RENDER,
    input = sdl.SDL_LOG_CATEGORY_INPUT,
    @"test" = sdl.SDL_LOG_CATEGORY_TEST,
    gpu = sdl.SDL_LOG_CATEGORY_GPU,
    custom = sdl.SDL_LOG_CATEGORY_CUSTOM,
    unknown = 9999,

    fn fromInt(category: c_int) SdlLogCategory {
        return std.enums.fromInt(SdlLogCategory, category) orelse .unknown;
    }
};

test "sdl_log_priority" {
    try std.testing.expectEqual(.info, SdlLogPriority.fromInt(sdl.SDL_LOG_PRIORITY_INFO));
    try std.testing.expectEqual(.unknown, SdlLogPriority.fromInt(999));
}

test "sdl_log_category" {
    try std.testing.expectEqual(.info, SdlLogPriority.fromInt(sdl.SDL_LOG_PRIORITY_INFO));
    try std.testing.expectEqual(.unknown, SdlLogPriority.fromInt(999));
}

test "log" {
    const io = std.testing.io;
    var l = Log(3).init();
    try expectEqual(0, l.start);
    try expectEqual(0, l.end);

    l.log(io, .info, "message {d}", .{1});
    try expectEqual(0, l.start);
    try expectEqual(1, l.end);
    l.log(io, .info, "message {d}", .{2});
    try expectEqual(0, l.start);
    try expectEqual(2, l.end);
    l.log(io, .info, "message {d}", .{3});
    try expectEqual(0, l.start);
    try expectEqual(3, l.end);

    l.log(io, .info, "message {d}", .{4});
    try expectEqual(1, l.start);
    try expectEqual(1, l.end);
    l.log(io, .info, "message {d}", .{5});
    try expectEqual(2, l.start);
    try expectEqual(2, l.end);
    l.log(io, .info, "message {d}", .{6});
    try expectEqual(0, l.start);
    try expectEqual(3, l.end);

    l.log(io, .info, "message {d}", .{7});
    try expectEqual(1, l.start);
    try expectEqual(1, l.end);
    l.log(io, .info, "message {d}", .{8});
    try expectEqual(2, l.start);
    try expectEqual(2, l.end);
    l.log(io, .info, "message {d}", .{9});
    try expectEqual(0, l.start);
    try expectEqual(3, l.end);
}

const std = @import("std");
const expectEqual = std.testing.expectEqual;
const builtin = @import("builtin");

const engine = @import("engine.zig");
const sdl = engine.sdl;
const dev_build = engine.dev_build;
