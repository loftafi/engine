//! An audio file is held in memory for the entire duration it might be needed.
//!
//! If an audio file is in use by more than one entity, then the `references`
//! counter keeps track of how many entities are currently depending on
//! this audio file.
pub const Audio = @This();

/// The name or filename of the audio resorce that was used to load the file
/// from the bundle pack or resource folder.
name: []const u8,

/// The contents of the audio file that were loaded from the budle pack
/// or resource folder.
audio: []const u8,

/// The number of dependences on this audio object. When there are no
/// more dependencies on this audio object, the  object may `autorelease`.
references: i32,

/// Indicates that this object should `autorelease` when no more references
/// to this audio exist, or if `retain` is chosen, the object must be
/// manually released.
retained: Retain = .autorelease,

/// Hold a reference to the Resource record metadata.
resource: ?*Resource,

next: ?*@This() = null,
previous: ?*@This() = null,

pub const empty = .{
    .name = "",
    .audio = "",
    .references = 0,
    .resource = null,
    .retained = false,
    .next = null,
    .previous = null,
};

pub fn create(
    allocator: Allocator,
    name: []const u8,
    audio: []const u8,
    retained: Retain,
) Allocator.Error!*Audio {
    std.debug.assert(audio.len > 0);
    const audio_info = try allocator.create(Audio);
    audio_info.* = .{
        .name = if (name.len > 0) try allocator.dupe(u8, name) else "",
        .audio = audio,
        .references = 0,
        .resource = null,
        .retained = retained,
        .next = null,
        .previous = null,
    };
    debug("loaded audio: {s}", .{name});
    return audio_info;
}

pub fn destroy(self: *Audio, allocator: Allocator) void {
    if (self.audio.len > 0) allocator.free(self.audio);
    if (self.name.len > 0) allocator.free(self.name);
    self.* = undefined;
    allocator.destroy(self);
}

/// Return a _copy_ of this Audio data which must be released using
/// releaseAudioResource.
///
/// This does not _copy_ but simply increases the reference count to
/// indicate another dependency on this object exists.
pub fn clone(self: *Audio) *Audio {
    self.references += 1;
    return self;
}

/// When an audio file is finished playing, this `Progress` struct enables
/// cleanup and notification.
pub const Progress = struct {
    gpa: Allocator,
    audio: *Audio,
    audio_cache: *?*Audio,
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

/// When the display loads a resource, it may be retained for as long as
/// there is a reference held to this resource. Alternatively, a resource
/// may be marked as retained, effectively causing it to be cached until a
/// manual release is requested.
pub const Retain = enum {
    autorelease,
    retain,
};

const std = @import("std");
const Allocator = std.mem.Allocator;

const Resource = @import("resources").Resource;

const log = @import("log.zig");
const debug = log.debug;
const trace = log.trace;
