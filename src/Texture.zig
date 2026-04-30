//! A texture is held in memory for the entire duration it might be needed.
//!
//! If a texture is in use by more than one entity, then the `references`
//! counter keeps track of how many entities are currently depending on
//! this texture.
const Texture = @This();

uid: u64,

texture: *sdl.SDL_Texture,

resource: *Resource,

/// The number of dependences on this audio object. When there are no
/// more dependencies on this audio object, the  object may `autorelease`.
references: i32,

pub fn create(
    allocator: Allocator,
    uid: u64,
    texture: *sdl.SDL_Texture,
    resource: *Resource,
) !*Texture {
    const texture_info = try allocator.create(Texture);
    texture_info.* = .{
        .uid = uid,
        .texture = texture,
        .references = 0,
        .resource = resource,
    };
    trace("loaded texture: {d}", .{uid});
    return texture_info;
}

pub fn destroy(self: *Texture, allocator: Allocator) void {
    sdl.SDL_DestroyTexture(self.texture);
    self.* = undefined;
    allocator.destroy(self);
}

/// Return a _copy_ of this Texture data which must be released using
/// releaseTextureResource.
///
/// This does not _copy_ but simply increases the reference count to
/// indicate another dependency on this object exists.
pub fn clone(self: *Texture) *Texture {
    self.references += 1;
    return self;
}

const builtin = @import("builtin");
const std = @import("std");
const ArrayListUnmanaged = std.ArrayListUnmanaged;
const Allocator = std.mem.Allocator;

const engine = @import("engine.zig");
const sdl = engine.sdl;
const trace = engine.log.trace;

const Resource = @import("resources").Resource;
