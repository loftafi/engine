pub fn ProgressBar(comptime T: type) type {
    return struct {
        pub const Self = @This();
        progress: f32 = 0,

        pub inline fn draw(
            self: *const Self,
            entity: *Entity(T),
            display: *Display(T),
            _: Vector,
            _: ?Clip,
            scroll_offset: Vector,
        ) void {

            // Draw the background matching the  current button state
            if (entity.texture) |texture| {
                var dest = Rect{
                    .x = entity.rect.x + entity.pad.left,
                    .y = entity.rect.y + entity.pad.top,
                    .width = entity.rect.width - entity.pad.left - entity.pad.right,
                    .height = entity.rect.height - entity.pad.top - entity.pad.bottom,
                };
                dest = dest.move(&scroll_offset);
                var corner: f32 = entity.background.corner_radius;
                if (corner * 2 > dest.height) corner = dest.height / 2;

                // Progress bar background
                var tint = display.theme.progress_bar_background;
                if (entity.style == .custom) tint = entity.background.colour;
                _ = sdl.SDL_SetTextureAlphaMod(texture.texture, tint.a);
                _ = sdl.SDL_SetTextureColorMod(texture.texture, tint.r, tint.g, tint.b);
                if (entity.background.image_corner_radius == 0) {
                    _ = sdl.SDL_RenderTexture(display.renderer, texture.texture, null, @ptrCast(&dest));
                } else {
                    _ = sdl.SDL_RenderTexture9Grid(
                        display.renderer,
                        texture.texture,
                        null,
                        entity.background.image_corner_radius,
                        entity.background.image_corner_radius,
                        entity.background.image_corner_radius,
                        entity.background.image_corner_radius,
                        corner / entity.background.image_corner_radius,
                        @ptrCast(&dest),
                    );
                }

                // Progress bar foreground
                if (self.progress > 0.01) {
                    tint = display.theme.progress_bar_foreground;
                    if (entity.style == .custom)
                        tint = entity.colour;
                    dest.width *= entity.type.progress_bar.progress;
                    _ = sdl.SDL_SetTextureAlphaMod(texture.texture, tint.a);
                    _ = sdl.SDL_SetTextureColorMod(texture.texture, tint.r, tint.g, tint.b);
                    if (entity.background.image_corner_radius == 0) {
                        _ = sdl.SDL_RenderTexture(display.renderer, texture.texture, null, @ptrCast(&dest));
                    } else {
                        _ = sdl.SDL_RenderTexture9Grid(
                            display.renderer,
                            texture.texture,
                            null,
                            entity.background.image_corner_radius,
                            entity.background.image_corner_radius,
                            entity.background.image_corner_radius,
                            entity.background.image_corner_radius,
                            corner / entity.background.image_corner_radius,
                            @ptrCast(&dest),
                        );
                    }
                }
            } else {
                err("progress bar image missing.", .{});
            }
        }
    };
}

const std = @import("std");
const ArrayListUnmanaged = std.ArrayListUnmanaged;

const sdl = @import("sdl");

const engine = @import("engine.zig");
const err = engine.err;
const Clip = engine.Clip;
const Rect = engine.Rect;
const Display = engine.Display;
const Entity = engine.Entity;
const Vector = engine.Vector;
const Texture = engine.Texture;
