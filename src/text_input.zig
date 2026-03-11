pub fn TextInput(comptime T: type) type {
    return struct {
        pub const Self = @This();
        font: *Font = undefined,
        font_name: ?[]const u8 = null,
        texture: ?*sdl.SDL_Texture = null,
        initial_text: ?[]const u8 = "",
        icon_texture_name: ?[]const u8 = "",
        text: ArrayListUnmanaged(u8) = .empty,
        runes: ArrayListUnmanaged(u21) = .empty,
        max_runes: usize = 0,
        cursor_character: usize = 0,
        cursor_pixels: f32 = 0,
        on_change: Entity(T).Callback = .empty,
        on_submit: Entity(T).Callback = .empty,
        placeholder_texture: ?*sdl.SDL_Texture = null,
        placeholder_text: ?[]const u8 = "",
        placeholder_translate: []const u8 = "",

        /// Draw a text input box along with any text or cursor that
        /// may appear inside the text input box.
        pub inline fn draw(
            self: *const Self,
            entity: *Entity(T),
            display: *Display(T),
            _: Vector,
            _: ?Clip, // parent_clip
            _: Vector, // scroll offset
        ) void {
            var x = entity.rect.x + entity.pad.left;
            const y = entity.rect.y + entity.pad.top;
            const word_spacing = display.text_height.word_spacing(display.scale);

            if (display.selected != null and entity == display.selected.?) {
                // Draw cursor
                var cursor_box: Rect = .{
                    .x = @round(x + self.cursor_pixels),
                    .y = @round(y),
                    .width = display.text_height.pixel_height(display.scale / 8.0),
                    .height = display.text_height.pixel_height(display.scale),
                };
                if (entity.texture) |_| {
                    // Add the icon width
                    cursor_box.x += (entity.rect.height - entity.pad.top - entity.pad.bottom);
                    cursor_box.x += word_spacing;
                }
                _ = sdl.SDL_SetRenderDrawColor(
                    display.renderer,
                    display.theme.cursor_colour.r,
                    display.theme.cursor_colour.g,
                    display.theme.cursor_colour.b,
                    display.theme.cursor_colour.a,
                );
                _ = sdl.SDL_RenderFillRect(display.renderer, @ptrCast(&cursor_box));
            }

            if (entity.texture) |texture| {
                const icon_size = entity.rect.height - entity.pad.top - entity.pad.bottom;
                // Draw the text
                var dest: Rect = .{
                    .x = @round(x),
                    .y = @round(y),
                    .width = icon_size,
                    .height = icon_size,
                };
                x += icon_size + word_spacing;
                _ = sdl.SDL_SetTextureColorMod(
                    texture.texture,
                    display.theme.placeholder_text_colour.r,
                    display.theme.placeholder_text_colour.g,
                    display.theme.placeholder_text_colour.b,
                );
                _ = sdl.SDL_RenderTexture(
                    display.renderer,
                    texture.texture,
                    null,
                    @ptrCast(&dest),
                );
            }

            // Font baseline offset
            //y -= display.text_height * display.scale / 3.5;

            if (self.text.items.len > 0) {
                if (self.texture) |texture| {
                    const size = T.normal.pixel_size(display.scale, texture);
                    // Draw the text
                    var dest: Rect = .{
                        .x = @round(x),
                        .y = @round(y),
                        .width = size.width,
                        .height = size.height,
                    };
                    x += size.height + word_spacing;
                    _ = sdl.SDL_SetTextureColorMod(
                        texture,
                        display.theme.text_colour.r,
                        display.theme.text_colour.g,
                        display.theme.text_colour.b,
                    );
                    _ = sdl.SDL_RenderTexture(
                        display.renderer,
                        texture,
                        null,
                        @ptrCast(&dest),
                    );
                }
            } else {
                if (self.placeholder_texture) |texture| {
                    const size = T.normal.pixel_size(display.scale, texture);
                    // Draw the placeholder text
                    var dest: Rect = .{
                        .x = @round(x),
                        .y = @round(y),
                        .width = size.width,
                        .height = size.height,
                    };
                    x += size.width + word_spacing;
                    _ = sdl.SDL_SetTextureColorMod(
                        texture,
                        display.theme.placeholder_text_colour.r,
                        display.theme.placeholder_text_colour.g,
                        display.theme.placeholder_text_colour.b,
                    );
                    _ = sdl.SDL_RenderTexture(
                        display.renderer,
                        texture,
                        null,
                        @ptrCast(&dest),
                    );
                }
            }
        }
        pub inline fn minimum_needed_height(
            _: *Self,
            display: *Display(T),
            entity: *Entity(T),
            parent_inner_width: f32,
        ) f32 {
            _ = parent_inner_width;
            const height = (display.text_height.pixel_height(display.scale)) + (entity.pad.top + entity.pad.bottom);
            return height;
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
const Display = engine.Display;
const Entity = engine.Entity;
const Error = engine.Error;
const Font = engine.Font;
const Texture = engine.Texture;

const Clip = engine.ent.Clip;
const Rect = engine.ent.Rect;
const Size = engine.ent.Size;
const Vector = engine.ent.Vector;
