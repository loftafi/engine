pub const TextInput = @This();

pub const default_max_length: u16 = 1000;

font: *Font = undefined,
font_name: ?[]const u8 = null,
texture: ?*sdl.SDL_Texture = null,
initial_text: ?[]const u8 = "",
icon_texture_name: ?[]const u8 = "",
text_size: TextSize = .normal,
text: ArrayListUnmanaged(u8) = .empty,
runes: ArrayListUnmanaged(u21) = .empty,
max_length: ?u16 = null,
cursor_character: usize = 0,
cursor_pixels: f32 = 0,
on_change: Entity.Callback = .empty,
on_submit: Entity.Callback = .empty,
placeholder_texture: ?*sdl.SDL_Texture = null,
placeholder_text: ?[]const u8 = "",
placeholder_translate: []const u8 = "",

/// Draw a text input box along with any text or cursor that
/// may appear inside the text input box.
pub inline fn draw(
    self: *const TextInput,
    entity: *Entity,
    display: *Display,
    _: Vector,
    _: ?Clip, // parent_clip
    _: Vector, // scroll offset
) void {
    var x = entity.rect.x + entity.pad.left;
    const y = entity.rect.y + entity.pad.top;
    const word_spacing = self.text_size.word_spacing(display.scale);

    if (display.selected != null and entity == display.selected.?) {
        // Draw cursor
        var cursor_box: Rect = .{
            .x = @round(x + self.cursor_pixels),
            .y = @round(y),
            .width = self.text_size.pixel_height(display.scale / 8.0),
            .height = self.text_size.pixel_height(display.scale),
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
    //y -= self.text_size * display.scale / 3.5;

    if (self.text.items.len > 0) {
        if (self.texture) |texture| {
            const size = self.text_size.pixel_size(display.scale, texture);
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
            const size = self.text_size.pixel_size(display.scale, texture);
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
    self: *TextInput,
    display: *Display,
    entity: *Entity,
    parent_inner_width: f32,
) f32 {
    _ = parent_inner_width;
    const height = (self.text_size.pixel_height(display.scale)) + (entity.pad.top + entity.pad.bottom);
    return height;
}

// Return the absolute minimum width needed, even if more space
// could be used. `.grows`  is ignored for the purpose of finding
// the minimum width.
//
// `parent_inner_width` is the maximum space this entity could
// theoretically grow to. Text might wrap if wider than this.
pub inline fn minimum_needed_width(
    _: *const TextInput,
    _: *const Display,
    entity: *const Entity,
    _: f32,
) f32 {
    if (entity.layout.x == .fixed) return entity.rect.width;
    return @max(0, entity.minimum.width);
}

const std = @import("std");
const ArrayListUnmanaged = std.ArrayListUnmanaged;

const engine = @import("engine.zig");
const sdl = engine.sdl;
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
const TextSize = engine.TextSize;

const Clip = Entity.Clip;
const Rect = Entity.Rect;
const Size = Entity.Size;
const Vector = Entity.Vector;
