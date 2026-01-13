/// An audio file is held in memory for the entire duration it might be needed.
///
/// If an audio file is in use by more than one element, then the `references`
/// counter keeps track of how many elements are currently depending on
/// this audio file.
name: []const u8,
audio: []const u8,
references: i32,
resource: ?*Resource,
autorelease: Retain,

const Audio = @This();

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

const std = @import("std");
const ArrayListUnmanaged = std.ArrayListUnmanaged;
const Allocator = std.mem.Allocator;
const sdl = @import("sdl");
const builtin = @import("builtin");
const engine = @import("engine.zig");
const debug = engine.debug;
const Retain = engine.Retain;

const Resource = @import("resources").Resource;
