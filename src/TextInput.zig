/// A basic single line text input boxf
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

pub fn keypress(
    self: *TextInput,
    entity: *Entity,
    display: *Display,
    key: u21,
    slice: []const u8,
    event: *const Event,
) Allocator.Error!void {

    // Update the text line
    trace("text_input recieved {t} {s}", .{ event.type, slice });
    switch (key) {
        @intFromEnum(Key.line_feed), @intFromEnum(Key.@"return") => {
            _ = sdl.SDL_StopTextInput(display.window);
            if (self.on_submit.func != null) {
                try self.on_submit.call(display, entity, event);
            }
            return;
        },
        @intFromEnum(Key.backspace) => {
            if (self.runes.items.len == 0) {
                return;
            }
            _ = self.runes.pop();
            self.text_runes_to_data(display.allocator);
            self.cursor_character -= 1;
        },
        else => {
            const max_chars = @as(usize, self.max_length orelse TextInput.default_max_length);
            if (self.runes.items.len >= max_chars) {
                debug("Ignoring {u} {t}. {s} limited to {d} characters", .{
                    key,
                    event.type,
                    entity.name,
                    max_chars,
                });
                return;
            }
            self.text.appendSlice(display.allocator, slice) catch {};
            self.runes.append(display.allocator, key) catch {};
            self.cursor_character += 1;
        },
    }
    self.text_data_to_runes(display.allocator);

    if (self.text.items.len > 0) {
        // For now, the cursor position is simply the end of the text.
        self.cursor_pixels = try self.font.measureText(
            display,
            self.text_size,
            self.text.items,
        );
    } else {
        self.cursor_pixels = 0;
    }

    // Optionally, a text_input may have an `on_change` callback function.
    if (self.on_change.func != null) {
        trace("text_input calling on_change", .{});
        try self.on_change.call(display, entity, event);
        trace("text_input called on_change", .{});
    }
}

fn text_runes_to_data(self: *TextInput, allocator: Allocator) void {
    self.text.clearRetainingCapacity();
    for (self.runes.items) |rune| {
        var buff: [4]u8 = undefined;
        const len = std.unicode.utf8Encode(rune, &buff) catch return;
        self.text.appendSlice(allocator, buff[0..len]) catch return;
    }
}

pub fn text_data_to_runes(self: *TextInput, allocator: Allocator) void {
    self.runes.clearRetainingCapacity();
    var v = std.unicode.Utf8View.init(self.text.items) catch {
        return;
    };
    var i = v.iterator();
    var cursor_slice: usize = 0; // utf8 index of cursor position
    var count: usize = 0;
    while (i.nextCodepoint()) |rune| {
        if (count == self.cursor_character)
            cursor_slice = i.i;
        self.runes.append(allocator, rune) catch return;
        count += 1;
    }
    if (count == self.cursor_character)
        cursor_slice = i.i;
    if (self.cursor_character > self.runes.items.len) {
        self.cursor_character = self.runes.items.len;
        cursor_slice = self.text.items.len;
    }
}

/// Draw a text input box along with any text or cursor that
/// may appear inside the text input box.
pub inline fn draw(
    self: *const TextInput,
    entity: *const Entity,
    display: *Display,
    _: Vector,
    _: ?Clip, // parent_clip
    _: Vector, // scroll offset
) void {
    const word_spacing = self.text_size.word_spacing();
    const text_height = self.text_size.size();

    // Draw cursor around the text input if it is selected.
    if (display.selected != null and entity == display.selected.?) {
        var cursor_box: Rect = .{
            .x = @round(entity.rect.x + entity.pad.left + self.cursor_pixels),
            .y = @round(entity.rect.y + entity.pad.top),
            .width = self.text_size.size() / 8.0,
            .height = text_height,
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

    // Draw the icon if one was specified
    var icon_offset: f32 = 0;
    if (entity.texture) |icon_texture| {
        const icon_size = text_height;
        icon_offset = icon_size + word_spacing;
        const dest: Rect = .{
            .x = @round(entity.rect.x + entity.pad.left),
            .y = @round(entity.rect.y + entity.pad.top),
            .width = icon_size,
            .height = icon_size,
        };
        _ = sdl.SDL_SetRenderDrawColor(
            display.renderer,
            display.theme.placeholder_text_colour.r,
            display.theme.placeholder_text_colour.g,
            display.theme.placeholder_text_colour.b,
            display.theme.placeholder_text_colour.a,
        );
        display.renderTexture(icon_texture.texture, null, &dest);
    }

    // Draw either the user text or the placeholder text if set.
    if (self.text.items.len > 0) {
        self.font.drawText(
            display,
            self.text.items,
            .{
                .x = entity.rect.x + entity.pad.left + icon_offset,
                .y = entity.rect.y + entity.pad.top,
            },
            display.theme.text_colour,
            self.text_size,
            1,
        ) catch {
            // Text should be valid utf8 at this point, and OutOfMemory
            // should not occur if measureText(); was first
            // used (which is should be)
        };
    } else {
        if (self.placeholder_text) |placeholder_text| {
            if (placeholder_text.len > 0) {
                self.font.drawText(
                    display,
                    placeholder_text,
                    .{
                        .x = entity.rect.x + entity.pad.left,
                        .y = entity.rect.y + entity.pad.top,
                    },
                    display.theme.placeholder_text_colour,
                    self.text_size,
                    1,
                ) catch {
                    // Text should be valid utf8 at this point, and OutOfMemory
                    // should not occur if measureText(); was first
                    // used (which is should be)
                };
            }
        }
    }
}
pub inline fn minimumNeededHeight(
    self: *TextInput,
    entity: *Entity,
    parent_inner_width: f32,
) f32 {
    _ = parent_inner_width;
    const height = (self.text_size.size()) + (entity.pad.top + entity.pad.bottom);
    return height;
}

// Return the absolute minimum width needed, even if more space
// could be used. `.grows`  is ignored for the purpose of finding
// the minimum width.
//
// `parent_inner_width` is the maximum space this entity could
// theoretically grow to. Text might wrap if wider than this.
pub inline fn minimumNeededWidth(
    _: *const TextInput,
    entity: *const Entity,
    _: f32,
) f32 {
    if (entity.layout.x == .fixed) return entity.rect.width;
    return @max(0, entity.minimum.width);
}

const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayListUnmanaged = std.ArrayListUnmanaged;

const engine = @import("engine.zig");
const sdl = engine.sdl;
const err = engine.log.err;
const warn = engine.log.warn;
const info = engine.log.info;
const debug = engine.log.debug;
const trace = engine.log.trace;
const Display = engine.Display;
const Entity = engine.Entity;
const Error = engine.Error;
const Font = engine.Font;
const Key = engine.Key;
const Texture = engine.Texture;
const TextSize = engine.TextSize;
const Event = @import("Event.zig");

const Clip = Entity.Clip;
const Rect = Entity.Rect;
const Size = Entity.Size;
const Vector = Entity.Vector;
