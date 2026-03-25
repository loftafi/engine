/// A simple element that expands inside a panel to fill blank space. If
/// multiple expanders exist in a panel, the `weight` parameter indicates
/// the relative size of each expander.
pub fn Expander(comptime T: type) type {
    return struct {
        pub const Self = @This();

        /// The `Expander` with the higher `weight` grabs more whitespace
        /// than the expander with a lower `weight`.
        weight: f32 = 0,

        /// Expanders have no content to draw.
        pub inline fn draw(
            _: *const Self,
            _: *Entity(T),
            _: *Display(T),
            _: Vector,
            _: ?Clip, //parent_clip
            _: Vector, // scroll_offset
        ) void {
            if (T.normal.pixel_height(1) == 0) {
                //
            }
        }

        pub inline fn minimum_needed_width(
            _: *Self,
            _: *Display(T),
            entity: *Entity(T),
            _: f32,
        ) f32 {
            return entity.minimum.width;
        }
    };
}

const std = @import("std");
const ArrayListUnmanaged = std.ArrayListUnmanaged;

const sdl = @import("sdl");

const engine = @import("engine.zig");
const Display = engine.Display;
const Entity = engine.Entity;
const Error = engine.Error;

const Vector = engine.ent.Vector;
const Clip = engine.ent.Clip;
