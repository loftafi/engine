/// A button with text and or an icon. Attributes of the button may
/// be different in the hover, pressed, and disables state.
pub const Button = @This();

font: *Font = undefined,
font_name: ?[]const u8 = null,

text_size: TextSize = .normal,
text: []const u8 = "",
translated: []const u8 = "",
/// The width of the text including the adjustment for text size
translated_text_width: f32 = 0,

spacing: f32 = 0,
icon: struct {
    size: Size = .{ .width = 0, .height = 0 },
    default_name: ?[]const u8 = null,
    hover: ?*Texture = null,
    hover_name: ?[]const u8 = null,
    pressed: ?*Texture = null,
    pressed_name: ?[]const u8 = null,
    disabled: ?*Texture = null,
    disabled_name: ?[]const u8 = null,
} = .{},

button: struct {
    default_name: ?[]const u8 = null,
    hover: ?*Texture = null,
    hover_name: ?[]const u8 = null,
    pressed: ?*Texture = null,
    pressed_name: ?[]const u8 = null,
    disabled: ?*Texture = null,
    disabled_name: ?[]const u8 = null,
} = .{},

toggle: ToggleState = .no_toggle,

// Handle User triggered events. Keyboard, Mouse, Game controller
on_ui_event: Entity.Callback = .empty,
on_pressed: Entity.Callback = .empty,

/// Draw a button with its text and/or icon. Mouse hover, mouse click
/// and the disabled status may change the picture or icon
/// displayed in the button.
pub inline fn draw(
    self: *const Button,
    entity: *Entity,
    display: *Display,
    _: Vector,
    _: ?Clip, // parent_clip
    scroll_offset: Vector,
) void {
    // Draw the background matching the current button state
    if (self.current_background(entity)) |background_image| {
        var dest = entity.rect.move(scroll_offset);
        if (entity.flip.x) {
            dest.x += dest.width;
            dest.width = 0 - dest.width;
        }
        if (entity.flip.y) {
            dest.y += dest.height;
            dest.height = 0 - dest.height;
        }
        entity.applyBackgroundTint(display, background_image);
        if (entity.background.image_corner_radius == 0) {
            _ = sdl.SDL_RenderTexture(display.renderer, background_image, null, @ptrCast(&dest));
        } else {
            var corner: f32 = entity.background.corner_radius;
            if (corner * 2 > dest.height) corner = dest.height / 2;
            _ = sdl.SDL_RenderTexture9Grid(
                display.renderer,
                background_image,
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

    const content_width = self.contentWidth(display, entity);
    const content_x_offset = switch (entity.child_align.x) {
        .start => 0,
        .centre => (entity.rect.width - content_width) / 2.0,
        .end => entity.rect.width - content_width,
    };
    const icon_y_offset = switch (entity.child_align.y) {
        .start => entity.pad.top,
        .centre => entity.pad.top + ((entity.rect.height - entity.pad.top - entity.pad.bottom) / 2) - (self.icon.size.height / 2),
        .end => entity.rect.height - entity.pad.bottom - self.icon.size.height,
    };

    const text_colour = button_text_colour(entity, display.theme);
    var has_icon = false;

    // Place the icon
    if (self.current_icon(entity)) |icon_image| {
        has_icon = true;
        var dest: Rect = .{
            .x = entity.rect.x + entity.pad.left + content_x_offset,
            .y = entity.rect.y + icon_y_offset,
            .width = self.icon.size.width,
            .height = self.icon.size.height,
        };
        dest = dest.move(scroll_offset);
        if (entity.flip.x) {
            dest.x += dest.width;
            dest.width = 0 - dest.width;
        }
        if (entity.flip.y) {
            dest.y += dest.height;
            dest.height = 0 - dest.height;
        }
        _ = sdl.SDL_SetTextureAlphaMod(icon_image, text_colour.a);
        _ = sdl.SDL_SetTextureColorMod(icon_image, text_colour.r, text_colour.g, text_colour.b);
        _ = sdl.SDL_RenderTexture(display.renderer, icon_image, null, @ptrCast(&dest));
    }

    // Place the text
    if (self.text.len > 0) {
        const height = self.text_size.pixel_height(display.scale);
        var pos: Vector = .{
            .x = entity.rect.x + entity.type.button.icon.size.width + entity.pad.left + content_x_offset,
            .y = entity.rect.y + ((entity.rect.height - entity.pad.top - entity.pad.bottom) / 2.0) - (height / 2) + entity.pad.top,
        };
        if (entity.type.button.icon.size.width == 0 or entity.type.button.icon.size.height == 0) {
            pos.x = entity.rect.x + entity.rect.width / 2 - (self.translated_text_width * display.scale * self.text_size.height()) / 2;
        }
        if (has_icon or entity.type.button.icon.size.width > 0) {
            pos.x += entity.type.button.spacing;
        }
        _ = self.font.drawText(display, self.translated, pos.add(scroll_offset), text_colour, self.text_size) catch {
            // Memory allocations should not be occuring during drawText.
            // If OutOfMemory is thrown it is because drawText(.., measure)
            // was not yet called on this string.
        };
    }
}

/// Return true if this button can be interacted with.
pub inline fn clickable(
    button: *const Button,
) bool {
    // A button is interactable if it has an event handler
    // or if it can be toggled.
    if (button.on_pressed.func != null) return true;
    if (button.on_ui_event.func != null) return true;
    return button.toggle == .on or button.toggle == .off;
}

/// An icon may have different background textures for hovered,
/// pressed and normal state. Return the background that is valid
/// for the current state.
pub inline fn current_background(
    button: *const Button,
    entity: *const Entity,
) ?*sdl.SDL_Texture {
    if (button.toggle == .disabled) if (button.button.disabled) |value| return value.texture;
    if (entity.pressed) if (button.button.pressed) |value| return value.texture;
    if (entity.hovered) if (button.button.hover) |value| return value.texture;
    return if (entity.background.image) |value| value.texture else null;
}

/// By default, button text is uses the default theme `text_colour`
/// unless a style is applied, or the button is altered by its
/// `hovered` or `pressed` status.
inline fn button_text_colour(entity: *const Entity, theme: *const Theme) Colour {
    if (entity.style == .success) return theme.success_text_colour;
    if (entity.style == .failed) return theme.failed_text_colour;
    if (entity.style == .custom) return entity.colour;
    if (entity.pressed) return theme.tinted_text_colour;
    if (entity.hovered) return theme.tinted_text_colour;
    return theme.text_colour;
}

/// An icon may have different image textures for hovered, pressed
/// and normal state. Return the image that is valid for the current state.
inline fn current_icon(self: *const Button, entity: *const Entity) ?*sdl.SDL_Texture {
    if (entity.pressed) if (self.icon.pressed) |value| return value.texture;
    if (entity.hovered) if (self.icon.hover) |value| return value.texture;
    return if (entity.texture) |value| value.texture else null;
}

/// Minimum width of a button includes any requested padding, icon, text and
/// the icon-text spacing parameter.
inline fn contentWidth(
    button: *const Button,
    display: *const Display,
    entity: *const Entity,
) f32 {
    var width: f32 = 0;

    width += entity.pad.left;
    width += entity.pad.right;
    width += entity.type.button.icon.size.width;

    // If button has icon _and_ text, add button spacing
    if (button.icon.size.width > 0 and button.text.len > 0)
        width += entity.type.button.spacing;

    if (button.text.len > 0)
        width += button.translated_text_width * display.scale * button.text_size.height();

    return width;
}

/// Minimum width of a button includes any requested padding, icon, text and
/// the icon-text spacing parameter.
pub inline fn minimumNeededWidth(
    button: *const Button,
    display: *const Display,
    entity: *const Entity,
    _: f32, //parent_inner_width
) f32 {
    return @max(entity.minimum.width, button.contentWidth(display, entity));
}

pub inline fn minimumNeededHeight(
    button: *Button,
    display: *Display,
    entity: *Entity,
    _: f32, //parent_inner_width
) f32 {
    var height: f32 = 0;
    if (button.text.len > 0) {
        height = button.text_size.pixel_height(display.scale);
    }
    height = @max(button.icon.size.height, height);
    height += (entity.pad.top + entity.pad.bottom);
    return @max(entity.minimum.height, height);
}

test "normal_use" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var display = try headless_display(allocator, io, 1024, 720, 2);
    defer display.destroy();

    const panel = try display.addPanel(.{
        .minimum = .{ .width = 5, .height = 8 },
        .type = .{ .panel = .{ .spacing = 0, .direction = .left_to_right } },
        .layout = .{ .x = .shrinks, .y = .shrinks },
    });
    try expectEqual(5, panel.minimumNeededWidth(display, 500));
    try expectEqual(8, panel.minimumNeededHeight(display, 500));

    const not_quite_one_line = TextSize.normal.pixel_height(display.scale) - 5;
    const not_quite_two_lines = TextSize.normal.pixel_height(display.scale) * 2 - 5;

    var button = try panel.add(.{
        .visible = .visible,
        .rect = .{ .width = 50, .height = 50 },
        .minimum = .{ .width = 30, .height = not_quite_one_line },
        .maximum = .{ .width = 82, .height = not_quite_two_lines },
        .type = .{ .button = .{ .text = "" } },
    }, display);
    display.need_relayout = true;
    display.relayout();
    try expectEqual(50, button.minimumNeededWidth(display, 500));
    try expectEqual(50, button.minimumNeededHeight(display, 500));
    button.layout.x = .shrinks;
    button.layout.y = .shrinks;
    try expectEqual(30, button.minimumNeededWidth(display, 500));
    // The words will overflow the bottom of the box
    try expectEqual(not_quite_one_line, button.minimumNeededHeight(display, 500));

    display.need_relayout = true;
    display.relayout();
    try expectEqual(30, panel.minimumNeededWidth(display, 500));
    try expectEqual(30, button.rect.width);
    // panel has min width 5, but button pushes it out to 30
    try expectEqual(30, panel.rect.width);
    try expectEqual(not_quite_one_line, button.rect.height);
    try expectEqual(not_quite_one_line, panel.rect.height);

    panel.pad.left = 2;
    panel.pad.right = 3;
    panel.pad.top = 4;
    panel.pad.bottom = 5;
    display.relayout();
    try expectEqual(30, button.rect.width);
    try expectEqual(30, panel.rect.width);
    try expectEqual(not_quite_one_line, button.rect.height);
    try expectEqual(not_quite_one_line, panel.rect.height);

    panel.minimum.width = 100;
    display.relayout();
    try expectEqual(100, panel.minimumNeededWidth(display, 500));
    panel.minimum.width = 10;

    // Add test font so we can test label layout
    try std.testing.expect(display.resources.by_uid.count() > 0);
    try display.setDefaultFont("Roboto-Light", .unknown, .{});

    try button.setText(display, "Hello");
    display.need_relayout = true;
    display.relayout();
    try expectEqual(90, @ceil(button.rect.width));
    // Does the width grow more than 10 (minimum) because of the button size.
    try expectEqual(95, @round(panel.rect.width));
    // Minimum height was not_quite_one_line, expect it grew to font height.
    try expectEqual(TextSize.normal.pixel_height(1) * display.pixel_scale, button.rect.height);
    try expectEqual(TextSize.normal.pixel_height(2) + 4 + 5, panel.rect.height);

    // Buttons cant wrap, hight will only change with padding.
    button.maximum.height = 500;
    try button.setText(display, "Hello Defragment");
    display.relayout();
    try expectEqual(TextSize.normal.pixel_height(1) * display.pixel_scale, button.rect.height);
    button.pad.top = 4;
    button.pad.bottom = 5;
    display.need_relayout = true;
    display.relayout();
    try expectEqual(TextSize.normal.pixel_height(1) * display.pixel_scale, (button.rect.height - 4 - 5));
}

test "button_sizing" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var display = try headless_display(allocator, io, 1024, 720, 2);
    defer display.destroy();

    const panel = try display.addPanel(.{
        .minimum = .{ .width = 500, .height = 500 },
        .type = .{ .panel = .{ .spacing = 0, .direction = .top_to_bottom } },
        .layout = .{ .x = .shrinks, .y = .shrinks },
    });

    // Button with normal height.
    var button = try panel.add(.{
        .minimum = .{ .width = 0, .height = 0 },
        .layout = .{ .x = .shrinks, .y = .shrinks },
        .type = .{ .button = .{
            .text = "Simple Text",
            .text_size = .normal,
        } },
    }, display);
    display.need_relayout = true;
    display.relayout();
    try expectEqual(44, button.minimumNeededHeight(display, 500));

    // Button with small height.
    button.type.button.text_size = .small;
    display.need_relayout = true;
    display.relayout();
    try expectEqual(44 * 0.75, button.minimumNeededHeight(display, 500));
}

const std = @import("std");
const ArrayListUnmanaged = std.ArrayListUnmanaged;
const expectEqual = std.testing.expectEqual;

const engine = @import("engine.zig");
const sdl = engine.sdl;
const err = engine.err;
const Display = engine.Display;
const Colour = engine.Colour;
const Error = engine.Error;
const Font = engine.Font;
const Entity = engine.Entity;
const Texture = engine.Texture;
const Theme = engine.Theme;
const TextSize = engine.TextSize;

const Clip = Entity.Clip;
const Rect = Entity.Rect;
const Size = Entity.Size;
const ToggleState = Entity.ToggleState;
const Vector = Entity.Vector;

const headless_display = @import("test.zig").headless_display;
