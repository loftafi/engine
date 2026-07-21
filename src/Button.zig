/// A button with text and or an icon. Attributes of the button may
/// be different in the hover, pressed, and disables state.
pub const Button = @This();

font: *Font = undefined,
font_name: ?[]const u8 = null,

text_size: TextSize = .normal,
text: []const u8 = "",
translated: []const u8 = "",

/// The width of the text including the adjustment for text size.
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
    parent_clip: ?Clip,
    scroll_offset: Vector,
) void {
    var x_scale: f32 = 1;
    var dest = entity.rect.move(scroll_offset);

    if (entity.flip.x) {
        dest.x += dest.width;
        dest.width = 0 - dest.width;
    }
    if (entity.flip.y) {
        dest.y += dest.height;
        dest.height = 0 - dest.height;
    }
    if (parent_clip) |clip| {
        // Individual inner elemements may still need clipping.
        //if (clip.isClipped(dest)) continue;
        clip.applyEdgeClipping(&dest);
        x_scale = dest.height / entity.rect.height;
    }

    // Draw the background matching the current button state
    if (self.current_background(entity)) |background_image| {
        entity.applyBackgroundTint(display, background_image);
        if (entity.background.image_corner_radius == 0) {
            display.renderTexture(background_image, null, &dest);
        } else {
            display.render9GridTexture(
                background_image,
                entity.background.image_corner_radius,
                &dest,
                entity.background.corner_radius,
            );
        }
    }

    const content_width = self.contentWidth();
    var content_x_offset = switch (entity.child_align.x) {
        .start => 0,
        .centre => (entity.inner_width() - content_width) / 2.0,
        .end => entity.inner_width() - content_width,
    } + entity.rect.x + entity.pad.left;
    const icon_y_offset = switch (entity.child_align.y) {
        .start => entity.pad.top,
        .centre => entity.pad.top + ((entity.rect.height - entity.pad.top - entity.pad.bottom) / 2) - (self.icon.size.height / 2),
        .end => entity.rect.height - entity.pad.bottom - self.icon.size.height,
    };

    const text_colour = button_text_colour(entity, display.theme);

    // Place the icon
    if (self.icon.size.width > 0 and self.icon.size.height > 0) {
        if (self.current_icon(entity)) |icon_image| {
            var icon_rect: Rect = .{
                .x = content_x_offset,
                .y = entity.rect.y + icon_y_offset,
                .width = self.icon.size.width,
                .height = self.icon.size.height,
            };
            icon_rect = icon_rect.move(scroll_offset);
            if (entity.flip.x) {
                icon_rect.x += icon_rect.width;
                icon_rect.width = 0 - icon_rect.width;
            }
            if (entity.flip.y) {
                icon_rect.y += icon_rect.height;
                icon_rect.height = 0 - icon_rect.height;
            }
            icon_rect.height *= x_scale;
            _ = sdl.SDL_SetTextureAlphaMod(icon_image, text_colour.a);
            _ = sdl.SDL_SetTextureColorMod(icon_image, text_colour.r, text_colour.g, text_colour.b);
            display.renderTexture(icon_image, null, &icon_rect);
        }

        content_x_offset += self.icon.size.width;
        if (self.translated_text_width > 0)
            content_x_offset += self.spacing;
    }

    // Place the text
    if (self.translated_text_width > 0) {
        const height = self.text_size.size();

        var pos: Vector = .{
            .x = content_x_offset,
            .y = entity.rect.y + ((entity.rect.height - entity.pad.top - entity.pad.bottom) / 2.0) - (height / 2) + entity.pad.top,
        };

        pos = pos.add(scroll_offset);
        _ = self.font.drawText(display, self.translated, pos, text_colour, self.text_size, x_scale) catch {
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

/// Minimum width of a button includes the icon, the text and
/// icon-text spacing if requested.
inline fn contentWidth(
    button: *const Button,
) f32 {
    var width: f32 = button.icon.size.width;

    // If button has icon _and_ text, add button spacing
    if (button.icon.size.width > 0 and button.translated_text_width > 0)
        width += button.spacing;

    if (button.translated_text_width > 0)
        width += button.translated_text_width;

    return width;
}

/// Minimum width of a button includes any requested padding, icon, text and
/// the icon-text spacing parameter.
pub inline fn minimumNeededWidth(
    button: *const Button,
    entity: *const Entity,
    _: f32, //parent_inner_width
) f32 {
    if (entity.layout.x == .fixed) return entity.rect.width;

    return @max(
        button.contentWidth() + entity.pad.left + entity.pad.right,
        entity.minimum.width,
    );
}

pub inline fn minimumNeededHeight(
    button: *Button,
    entity: *Entity,
    _: f32, //parent_inner_width
) f32 {
    if (entity.layout.y == .fixed) return entity.rect.height;

    var height: f32 = 0;
    if (button.text.len > 0) {
        height = button.text_size.size();
    }
    height = @max(button.icon.size.height, height);
    height += (entity.pad.top + entity.pad.bottom);
    return @max(entity.minimum.height, height);
}

test "button_text_size" {
    //button name=cloze.button rect=156x420/70x0
    //  pad=12l5t5b layout=shrinks/shrinks text=Μαρία
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var display = try headless_display(allocator, io, 1024, 720, 2);
    defer display.destroy();

    const panel = try display.addPanel(.{
        .type = .{ .panel = .{ .direction = .centre } },
        .layout = .{ .x = .shrinks, .y = .shrinks },
    });

    const button = try panel.add(.{
        .layout = .{ .x = .shrinks, .y = .shrinks },
        .pad = .{ .left = 12, .top = 5, .bottom = 5 },
        .type = .{ .button = .{} },
    }, display);

    display.need_relayout = true;
    display.relayout();

    try expectEqual(12, button.minimumNeededWidth(200));
    try expectEqual(10, button.minimumNeededHeight(200));
    try expectEqual(12, panel.minimumNeededWidth(200));
    try expectEqual(10, panel.minimumNeededHeight(200));
    try expectEqual(12, button.rect.width);
    try expectEqual(10, button.rect.height);
    try expectEqual(12, panel.rect.width);
    try expectEqual(10, panel.rect.height);

    try button.setText(display, "Μαρία");
    display.need_relayout = true;
    display.relayout();

    try expectEqual(67, button.minimumNeededWidth(200));
    try expectEqual(32, button.minimumNeededHeight(200));
    try expectEqual(67, panel.minimumNeededWidth(200));
    try expectEqual(32, panel.minimumNeededHeight(200));
    try expectEqual(67, button.rect.width);
    try expectEqual(32, button.rect.height);
    try expectEqual(67, panel.rect.width);
    try expectEqual(32, panel.rect.height);

    panel.type.panel.direction = .left_to_right;
    display.need_relayout = true;
    display.relayout();
    try expectEqual(67, button.minimumNeededWidth(200));
    try expectEqual(32, button.minimumNeededHeight(200));
    try expectEqual(67, panel.minimumNeededWidth(200));
    try expectEqual(32, panel.minimumNeededHeight(200));
    try expectEqual(67, button.rect.width);
    try expectEqual(32, button.rect.height);
    try expectEqual(67, panel.rect.width);
    try expectEqual(32, panel.rect.height);

    panel.type.panel.direction = .left_to_right_wrap;
    panel.layout.x = .grows;
    display.need_relayout = true;
    display.relayout();
    display.need_relayout = true;
    display.relayout();
    try expectEqual(67, button.minimumNeededWidth(200));
    try expectEqual(32, button.minimumNeededHeight(200));
    try expectEqual(67, panel.minimumNeededWidth(200));
    try expectEqual(32, panel.minimumNeededHeight(200));
    try expectEqual(67, button.rect.width);
    try expectEqual(32, button.rect.height);
    try expectEqual(1024, panel.rect.width);
    try expectEqual(32, panel.rect.height);
}

test "button_icon_size" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var display = try headless_display(allocator, io, 1024, 720, 2);
    defer display.destroy();

    const panel = try display.addPanel(.{
        .type = .{ .panel = .{ .spacing = 0, .direction = .left_to_right } },
        .layout = .{ .x = .grows, .y = .grows },
    });

    const button = try panel.add(.{
        .minimum = .{ .width = 5, .height = 8 },
        .type = .{ .button = .{ .icon = .{ .size = .{ .width = 20, .height = 20 } } } },
        .layout = .{ .x = .shrinks, .y = .shrinks },
    }, display);

    display.need_relayout = true;
    display.relayout();

    try expectEqual(20, button.minimumNeededWidth(200));
    try expectEqual(20, button.minimumNeededHeight(200));

    button.pad = .{ .top = 3, .bottom = 4, .left = 1, .right = 2 };
    try expectEqual(20 + 1 + 2, button.minimumNeededWidth(200));
    try expectEqual(20 + 3 + 4, button.minimumNeededHeight(200));

    display.need_relayout = true;
    display.relayout();

    panel.layout = .{ .x = .shrinks, .y = .shrinks };

    display.need_relayout = true;
    display.relayout();
    try expectEqual(20 + 1 + 2, button.minimumNeededWidth(200));
    try expectEqual(20 + 3 + 4, button.minimumNeededHeight(200));
    try expectEqual(20 + 1 + 2, panel.rect.width);
    try expectEqual(20 + 3 + 4, panel.rect.height);

    panel.pad = .{ .top = 5, .bottom = 5, .left = 5, .right = 5 };
    display.need_relayout = true;
    display.relayout();
    try expectEqual(20 + 1 + 2 + 5 + 5, panel.rect.width);
    try expectEqual(20 + 3 + 4 + 5 + 5, panel.rect.height);
}

test "button_in_float" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var display = try headless_display(allocator, io, 1024, 720, 2);
    defer display.destroy();

    const panel = try display.addPanel(.{
        .type = .{ .panel = .{ .spacing = 0, .direction = .left_to_right } },
        .layout = .{ .x = .grows, .y = .grows },
    });

    const bar = try panel.add(.{
        .type = .{ .panel = .{ .spacing = 0, .direction = .left_to_right } },
        .layout = .{ .x = .shrinks, .y = .shrinks, .position = .float },
    }, display);

    const button1 = try bar.add(.{
        .name = "button1",
        .minimum = .{ .width = 5, .height = 8 },
        .type = .{ .button = .{ .icon = .{ .size = .{ .width = 20, .height = 20 } } } },
        .layout = .{ .x = .shrinks, .y = .shrinks },
    }, display);

    const button2 = try bar.add(.{
        .name = "button2",
        .minimum = .{ .width = 5, .height = 8 },
        .type = .{ .button = .{ .icon = .{ .size = .{ .width = 20, .height = 20 } } } },
        .layout = .{ .x = .shrinks, .y = .shrinks },
    }, display);

    display.need_relayout = true;
    display.relayout();

    try expectEqual(20, button1.minimumNeededWidth(200));
    try expectEqual(20, button1.rect.width);
    try expectEqual(20, button2.minimumNeededHeight(200));
    try expectEqual(20, button2.rect.height);
    try expectEqual(20, bar.minimumNeededHeight(200));
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
    try expectEqual(5, panel.minimumNeededWidth(500));
    try expectEqual(8, panel.minimumNeededHeight(500));

    const not_quite_one_line = TextSize.normal.size() - 5;
    const not_quite_two_lines = TextSize.normal.size() * 2 - 5;

    var button = try panel.add(.{
        .visible = .visible,
        .rect = .{ .width = 50, .height = 50 },
        .minimum = .{ .width = 30, .height = not_quite_one_line },
        .maximum = .{ .width = 82, .height = not_quite_two_lines },
        .type = .{ .button = .{ .text = "" } },
    }, display);
    display.need_relayout = true;
    display.relayout();
    try expectEqual(50, button.minimumNeededWidth(500));
    try expectEqual(50, button.minimumNeededHeight(500));
    button.layout.x = .shrinks;
    button.layout.y = .shrinks;
    try expectEqual(30, button.minimumNeededWidth(500));
    // The words will overflow the bottom of the box
    try expectEqual(not_quite_one_line, button.minimumNeededHeight(500));

    display.need_relayout = true;
    display.relayout();
    try expectEqual(30, panel.minimumNeededWidth(500));
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
    try expectEqual(100, panel.minimumNeededWidth(500));
    panel.minimum.width = 10;

    // Add test font so we can test label layout
    try std.testing.expect(display.resources.by_uid.count() > 0);
    try display.setDefaultFont("Roboto-Light", .unknown, .{});

    try button.setText(display, "Hello");
    display.need_relayout = true;
    display.relayout();
    try expectEqual(45, @ceil(button.rect.width));
    // Does the width grow more than 10 (minimum) because of the button size.
    try expectEqual(2 + 45 + 3, @round(panel.rect.width));
    // Minimum height was not_quite_one_line, expect it grew to font height.
    try expectEqual(TextSize.normal.size(), button.rect.height);
    try expectEqual(TextSize.normal.size() + 4 + 5, panel.rect.height);

    // Buttons cant wrap, hight will only change with padding.
    button.maximum.height = 500;
    try button.setText(display, "Hello Defragment");
    display.relayout();
    try expectEqual(TextSize.normal.size(), button.rect.height);
    button.pad.top = 4;
    button.pad.bottom = 5;
    display.need_relayout = true;
    display.relayout();
    try expectEqual(TextSize.normal.size(), (button.rect.height - 4 - 5));
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
    try expectEqual(22, button.minimumNeededHeight(500));

    // Button with small height.
    button.type.button.text_size = .small;
    display.need_relayout = true;
    display.relayout();
    try expectEqual(@round(22 * 0.80), button.minimumNeededHeight(500));
}

const std = @import("std");
const ArrayListUnmanaged = std.ArrayListUnmanaged;
const expectEqual = std.testing.expectEqual;

const engine = @import("engine.zig");
const sdl = engine.sdl;
const err = engine.log.err;
const info = engine.log.info;
const Display = engine.Display;
const Colour = engine.Colour;
const Error = engine.Error;
const Font = engine.Font;
const Entity = engine.Entity;
const EntityParser = @import("EntityParser.zig");
const Texture = engine.Texture;
const Theme = engine.Theme;
const TextSize = engine.TextSize;

const Clip = Entity.Clip;
const Rect = Entity.Rect;
const Size = Entity.Size;
const ToggleState = Entity.ToggleState;
const Vector = Entity.Vector;

const headless_display = engine.headless_display;
