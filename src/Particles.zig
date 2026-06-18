/// A simple image entity.
pub const Particles = @This();

/// How the particle moves.
movement: enum { fireworks, spin, linear } = .linear,

linear: struct {
    direction: Vector = .zero,
    velocity: Vector = .zero,
    velocity_x_range: struct { min: i16, max: i16 } = .{ .min = 0, .max = 0 },
    velocity_y_range: struct { min: i16, max: i16 } = .{ .min = 0, .max = 0 },
    width_range: struct { min: u16, max: u16 } = .{ .min = 0, .max = 0 },
    height_range: struct { min: u16, max: u16 } = .{ .min = 0, .max = 0 },
},

/// Request a callback every iteration of the main app loop.
on_update: Entity.UpdateCallback = .empty,

particles: []Particle = undefined,
count: usize = 0,

pub const Particle = struct {
    /// Current on screen position of the particle (relative to the Entity.
    rect: Rect = .zero,

    velocity: Vector = .zero,

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
            .rect = .zero,
            .travel = 0,
            .end = 100000,
            .rotation = 0,
            .texture_index = 0,
        };
        self.particles[i].rect = self.particles[i].rect.move(.{
            .x = @as(f32, @floatFromInt(i)) * 2,
            .y = @as(f32, @floatFromInt(i)) * 2,
        });
        if (self.movement == .linear) {
            const x_max = self.linear.velocity_x_range.max;
            const x_min = self.linear.velocity_x_range.min;
            const vx = @as(f32, (random.random_u16())) / @as(f32, std.math.maxInt(u16)) * (x_max - x_min);
            self.particles[i].velocity.x = vx + x_min;

            const y_max = self.linear.velocity_y_range.max;
            const y_min = self.linear.velocity_y_range.min;
            const vy = @as(f32, (random.random_u16())) / @as(f32, std.math.maxInt(u16)) * (y_max - y_min);
            self.particles[i].velocity.y = vy + y_min;

            const width_max = self.linear.width_range.max;
            const width_min = self.linear.width_range.min;
            const width = @as(f32, (random.random_u16())) / @as(f32, std.math.maxInt(u16)) * (width_max - width_min);
            self.particles[i].rect.width = width + width_min;

            const height_max = self.linear.height_range.max;
            const height_min = self.linear.height_range.min;
            const height = @as(f32, (random.random_u16())) / @as(f32, std.math.maxInt(u16)) * (height_max - height_min);
            self.particles[i].rect.height = height + height_min;
        }
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

        for (self.particles) |*particle| {
            var dest = entity.rect.move(scroll_offset);
            dest.width = particle.rect.width;
            dest.height = particle.rect.height;
            const current = dest.move(particle.rect.location());
            display.renderTexture(texture.texture, &source, &current);
            particle.rect.x += particle.velocity.x;
            particle.rect.y += particle.velocity.y;
        }
    }
}

const std = @import("std");
const Allocator = std.mem.Allocator;
const expectEqual = std.testing.expectEqual;
const ArrayListUnmanaged = std.ArrayListUnmanaged;

const resources = @import("resources");
const Resources = resources.Resources;
const random = resources.random;

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
