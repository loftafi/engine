pub fn Expander(comptime T: type) type {
    return struct {
        pub const Self = @This();
        weight: f32 = 0,

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
const Clip = engine.Clip;
const Display = engine.Display;
const Entity = engine.Entity;
const Vector = engine.Vector;
const Error = engine.Error;
