pub fn ProgressBar(comptime T: type) type {
    return struct {
        pub const Self = @This();
        progress: f32 = 0,

        pub inline fn draw(
            self: *const Self,
            element: *Element(T),
            display: *Display(T),
            _: Vector,
            _: ?Clip,
            scroll_offset: Vector,
        ) void {

            // Draw the background matching the  current button state
            if (element.texture) |texture| {
                var dest = Rect{
                    .x = element.rect.x + element.pad.left,
                    .y = element.rect.y + element.pad.top,
                    .width = element.rect.width - element.pad.left - element.pad.right,
                    .height = element.rect.height - element.pad.top - element.pad.bottom,
                };
                dest = dest.move(&scroll_offset);
                var corner: f32 = element.background.corner_radius;
                if (corner * 2 > dest.height) corner = dest.height / 2;

                // Progress bar background
                var tint = display.theme.progress_bar_background;
                if (element.style == .custom) tint = element.background.colour;
                _ = sdl.SDL_SetTextureAlphaMod(texture.texture, tint.a);
                _ = sdl.SDL_SetTextureColorMod(texture.texture, tint.r, tint.g, tint.b);
                if (element.background.image_corner_radius == 0) {
                    _ = sdl.SDL_RenderTexture(display.renderer, texture.texture, null, @ptrCast(&dest));
                } else {
                    _ = sdl.SDL_RenderTexture9Grid(
                        display.renderer,
                        texture.texture,
                        null,
                        element.background.image_corner_radius,
                        element.background.image_corner_radius,
                        element.background.image_corner_radius,
                        element.background.image_corner_radius,
                        corner / element.background.image_corner_radius,
                        @ptrCast(&dest),
                    );
                }

                // Progress bar foreground
                if (self.progress > 0.01) {
                    tint = display.theme.progress_bar_foreground;
                    if (element.style == .custom)
                        tint = element.colour;
                    dest.width *= element.type.progress_bar.progress;
                    _ = sdl.SDL_SetTextureAlphaMod(texture.texture, tint.a);
                    _ = sdl.SDL_SetTextureColorMod(texture.texture, tint.r, tint.g, tint.b);
                    if (element.background.image_corner_radius == 0) {
                        _ = sdl.SDL_RenderTexture(display.renderer, texture.texture, null, @ptrCast(&dest));
                    } else {
                        _ = sdl.SDL_RenderTexture9Grid(
                            display.renderer,
                            texture.texture,
                            null,
                            element.background.image_corner_radius,
                            element.background.image_corner_radius,
                            element.background.image_corner_radius,
                            element.background.image_corner_radius,
                            corner / element.background.image_corner_radius,
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
const warn = engine.warn;
const info = engine.info;
const debug = engine.debug;
const trace = engine.trace;
const Clip = engine.Clip;
const Rect = engine.Rect;
const Display = engine.Display;
const Element = engine.Element;
const Scroller = engine.Scroller;
const Vector = engine.Vector;
const Callback = engine.Callback;
const BoolCallback = engine.BoolCallback;
const UpdateCallback = engine.UpdateCallback;
const LayoutDirection = engine.LayoutDirection;
const Error = engine.Error;
const Font = engine.Font;
const Fit = engine.Fit;
const Size = engine.Size;
const Texture = engine.Texture;
const ToggleState = engine.ToggleState;
