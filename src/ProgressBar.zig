/// Display a progress bar entity.
pub const ProgressBar = @This();

/// A number between 0 and 1 indicating progress of an activity or timer.
progress: f32 = 0,

pub inline fn draw(
    self: *const ProgressBar,
    entity: *Entity,
    display: *Display,
    _: Vector,
    _: ?Clip,
    scroll_offset: Vector,
) void {

    // Draw the background matching the  current button state
    if (entity.texture) |texture| {
        var dest = entity.rect.removePadding(entity.pad);
        dest = dest.move(scroll_offset);

        // Progress bar background
        var tint = display.theme.progress_bar_background;
        if (entity.style == .custom) tint = entity.background.colour;
        _ = sdl.SDL_SetTextureAlphaMod(texture.texture, tint.a);
        _ = sdl.SDL_SetTextureColorMod(texture.texture, tint.r, tint.g, tint.b);
        if (entity.background.image_corner_radius == 0) {
            display.renderTexture(texture.texture, null, &dest);
        } else {
            display.render9GridTexture(
                texture.texture,
                entity.background.image_corner_radius,
                &dest,
                entity.background.corner_radius,
            );
        }

        // Progress bar foreground
        if (self.progress > 0.01) {
            tint = display.theme.progress_bar_foreground;
            if (entity.style == .custom)
                tint = entity.colour;
            dest.width *= @min(entity.type.progress_bar.progress, 1);
            _ = sdl.SDL_SetTextureAlphaMod(texture.texture, tint.a);
            _ = sdl.SDL_SetTextureColorMod(texture.texture, tint.r, tint.g, tint.b);
            if (entity.background.image_corner_radius == 0) {
                display.renderTexture(texture.texture, null, &dest);
            } else {
                display.render9GridTexture(
                    texture.texture,
                    entity.background.image_corner_radius,
                    &dest,
                    entity.background.corner_radius,
                );
            }
        }
    } else {
        err("progress bar image missing.", .{});
    }
}

const std = @import("std");
const ArrayListUnmanaged = std.ArrayListUnmanaged;

const engine = @import("engine.zig");
const sdl = engine.sdl;
const err = engine.log.err;
const Display = engine.Display;
const Entity = engine.Entity;
const Texture = engine.Texture;

const Clip = Entity.Clip;
const Rect = Entity.Rect;
const Vector = Entity.Vector;
