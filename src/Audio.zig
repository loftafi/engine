/// An audio file is held in memory for the entire duration it might be needed.
///
/// If an audio file is in use by more than one entity, then the `references`
/// counter keeps track of how many entities are currently depending on
/// this audio file.
const Audio = @This();

name: []const u8,
audio: []const u8,
references: i32,
resource: ?*Resource,
autorelease: Retain,

pub const empty = .{
    .name = "",
    .audio = "",
    .references = 0,
    .resource = null,
    .autorelease = .autorelease,
};

pub fn create(
    allocator: Allocator,
    name: []const u8,
    audio: []const u8,
    autorelease: Retain,
) Allocator.Error!*Audio {
    std.debug.assert(audio.len > 0);
    const audio_info = try allocator.create(Audio);
    audio_info.* = .{
        .name = if (name.len > 0) try allocator.dupe(u8, name) else "",
        .audio = audio,
        .references = if (autorelease == .autorelease) 0 else 1,
        .resource = null,
        .autorelease = autorelease,
    };
    debug("loaded audio: {s}", .{name});
    return audio_info;
}

pub fn destroy(self: *Audio, allocator: Allocator) void {
    if (self.audio.len > 0) allocator.free(self.audio);
    if (self.name.len > 0) allocator.free(self.name);
    allocator.destroy(self);
}

pub fn clone(self: *Audio) *Audio {
    self.references += 1;
    return self;
}

/// When an audio file is finished playing,  this `Progress` struct enables
/// cleanup and notification.
pub const Progress = struct {
    gpa: Allocator,
    audio: *Audio,
    callback: ?Callback,
};

/// Information about what callback handler to trigger when an audio file
/// is finished playing.
pub const Callback = struct {
    func: ?*const fn (ptr: *anyopaque, allocator: Allocator, audio: *Audio) Allocator.Error!void = null,
    ptr: *anyopaque = undefined,

    pub const empty = .{ .func = null };

    pub fn call(
        self: Callback,
        allocator: Allocator,
        audio: *Audio,
    ) Allocator.Error!void {
        if (self.func) |f| return f(self.ptr, allocator, audio);
    }
};

const std = @import("std");
const ArrayListUnmanaged = std.ArrayListUnmanaged;
const Allocator = std.mem.Allocator;
const sdl = @import("sdl");
const builtin = @import("builtin");
const engine = @import("engine.zig");
const debug = engine.debug;
const Retain = engine.Retain;

const Display = @import("engine.zig").Display;
const Resource = @import("resources").Resource;
