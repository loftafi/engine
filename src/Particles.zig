/// A simple image entity.
pub const Particles = @This();

/// How the particle moves.
movement: enum { fireworks, spin, linear } = .linear,

linear: struct {
    direction: Vector = .zero,
    velocity: Vector = .zero,
},

/// Request a callback every iteration of the main app loop.
on_update: Entity.UpdateCallback = .empty,

particles: []Particle = undefined,
count: usize = 0,

pub const Particle = struct {
    /// Current on screen position of the particle (relative to the Entity.
    position: Vector = .zero,
    /// How far along the equation we are.
    travel: f32 = 0,
    /// What time does this particle disappear.
    end: i64 = 0,
    /// Draw this particle with a rotated.
    rotation: u8 = 0,

    /// Which particle/sprite inside the texture.
    texture_index: u8 = 0,
};

pub fn setup(
    self: *Particles,
    display: *Display,
    entity: *Entity,
) (Error || Allocator.Error || Resources.Error)!void {
    entity.focus = .never_focus;

    if (entity.texture_name) |name| {
        if (try display.requireImage(name)) |texture|
            entity.texture = texture;
    }

    self.particles = try display.allocator.alloc(Particle, self.count);
    for (0..self.count) |i| {
        if (i >= self.particles.len) break;
        self.particles[i] = .{
            .position = .zero,
            .travel = 0,
            .end = 100000,
            .rotation = 0,
            .texture_index = 0,
        };
        self.particles[i].position = self.particles[i].position.move(
            @as(f32, @floatFromInt(i)) * 2,
            @as(f32, @floatFromInt(i)) * 2,
        );
    }
}

pub fn deinit(self: *Particles, display: *Display) void {
    display.allocator.free(self.particles);
}

/// Draw the foreground image `texture` of the sprite loaded from the
/// `texture_name` string. Does not draw the `background.image` texture.
/// The background image is drawn in the generic background drawing function.
pub inline fn draw(
    self: *const Particles,
    entity: *Entity,
    display: *Display,
    _: Vector,
    parent_clip: ?Clip,
    scroll_offset: Vector,
) void {
    _ = parent_clip;

    if (self.movement != .linear) return;

    if (entity.texture) |texture| {
        var source: engine.Rect = .{
            .x = 0,
            .y = 0,
            .width = @as(f32, @floatFromInt(texture.texture.w)),
            .height = @as(f32, @floatFromInt(texture.texture.h)),
        };

        var dest = entity.rect.move(scroll_offset);

        if (entity.flip.x) {
            dest.x += dest.width;
            dest.width = 0 - dest.width;
        }
        if (entity.flip.y) {
            dest.y += dest.height;
            dest.height = 0 - dest.height;
        }

        for (self.particles) |particle| {
            var current = dest.move(particle.position);
            display.renderTexture(texture.texture, &source, &current);
        }
    }
}

const std = @import("std");
const Allocator = std.mem.Allocator;
const expectEqual = std.testing.expectEqual;
const ArrayListUnmanaged = std.ArrayListUnmanaged;

const resources = @import("resources");
const Resources = resources.Resources;

const engine = @import("engine.zig");
const sdl = engine.sdl;
const err = engine.err;
const Display = engine.Display;
const Entity = engine.Entity;
const Error = engine.Error;
const Font = engine.Font;
const Texture = engine.Texture;

const Clip = Entity.Clip;
const Fit = Entity.Fit;
const Rect = Entity.Rect;
const Size = Entity.Size;
const Vector = Entity.Vector;

const tint_texture = Entity.tint_texture;
