pub fn Rectangle(comptime T: type) type {
    return struct {
        pub const Self = @This();

        /// Draw a basic rectangle.
        pub inline fn draw(
            _: *const Self,
            entity: *Entity(T),
            display: *Display(T),
            _: Vector,
            _: ?Clip,
            scroll_offset: Vector,
        ) void {
            const colour = entity.style.panel(display.theme, entity.background.colour);
            _ = sdl.SDL_SetRenderDrawColor(
                display.renderer,
                colour.r,
                colour.g,
                colour.b,
                colour.a,
            );
            var dest = entity.rect.move(&scroll_offset);
            _ = sdl.SDL_RenderFillRect(display.renderer, @ptrCast(&dest));
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
const Texture = engine.Texture;
const Vector = engine.Vector;
