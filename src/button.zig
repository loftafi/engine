/// A button with text and or an icon. Attributes of the button may
/// be different in the hover, pressed, and disables state.
pub fn Button(comptime T: type) type {
    return struct {
        pub const Self = @This();
        font: *Font = undefined,
        font_name: ?[]const u8 = null,
        text_size: T = .normal,
        text: []const u8 = "",
        translated: []const u8 = "",
        text_texture: ?*sdl.SDL_Texture = null,
        icon_size: Size = .{ .width = 0, .height = 0 },
        spacing: f32 = 0,
        icon_default_name: ?[]const u8 = null,
        icon_hover: ?*Texture = null,
        icon_hover_name: ?[]const u8 = null,
        icon_pressed: ?*Texture = null,
        icon_pressed_name: ?[]const u8 = null,
        icon_disabled: ?*Texture = null,
        icon_disabled_name: ?[]const u8 = null,
        background_default_name: ?[]const u8 = null,
        background_hover: ?*Texture = null,
        background_hover_name: ?[]const u8 = null,
        background_pressed: ?*Texture = null,
        background_pressed_name: ?[]const u8 = null,
        background_disabled: ?*Texture = null,
        background_disabled_name: ?[]const u8 = null,
        toggle: ToggleState = .no_toggle,

        on_selected: Entity(T).Callback = .empty,
        on_mouse_down: Entity(T).Callback = .empty,
        on_mouse_up: Entity(T).Callback = .empty,
        on_mouse_enter: Entity(T).Callback = .empty,
        on_mouse_exit: Entity(T).Callback = .empty,

        /// Draw a button with its text and/or icon. Mouse hover, mouse click
        /// and the disabled status may change the picture or icon
        /// displayed in the button.
        pub inline fn draw(
            self: *const Self,
            entity: *Entity(T),
            display: *Display(T),
            _: Vector,
            _: ?Clip, // parent_clip
            scroll_offset: Vector,
        ) void {
            // Draw the background matching the  current button state
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

            // The inner content can contain a button and/or text texture.
            var content_width = self.icon_size.width;
            if (self.text_texture) |texture| {
                const size = self.text_size.pixel_size(display.scale, texture);

                // Do we need space between text and icon?
                if (content_width > 0)
                    content_width += entity.type.button.spacing;

                content_width += size.width;
            }
            content_width += entity.pad.left + entity.pad.right;

            const content_x_offset = switch (entity.child_align.x) {
                .start => 0,
                .centre => (entity.rect.width - content_width) / 2.0,
                .end => entity.rect.width - content_width,
            };
            const icon_y_offset = switch (entity.child_align.y) {
                .start => entity.pad.top,
                .centre => (entity.rect.height / 2) - (self.icon_size.height / 2),
                .end => entity.rect.height - entity.pad.bottom - self.icon_size.height,
            };

            const text_colour = button_text_colour(entity, display.theme);
            var has_icon = false;

            // Place the icon
            if (self.current_icon(entity)) |icon_image| {
                has_icon = true;
                var dest: Rect = .{
                    .x = entity.rect.x + entity.pad.left + content_x_offset,
                    .y = entity.rect.y + icon_y_offset,
                    .width = self.icon_size.width,
                    .height = self.icon_size.height,
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
            if (entity.type.button.text_texture) |texture| {
                const size = entity.type.button.text_size.pixel_size(display.scale, texture);
                var dest: Rect = .{
                    .x = entity.rect.x + entity.type.button.icon_size.width + entity.pad.left + content_x_offset,
                    .y = entity.rect.y + (entity.rect.height / 2.0) - (size.height / 2),
                    .width = size.width,
                    .height = size.height,
                };
                if (entity.type.button.icon_size.width == 0 or entity.type.button.icon_size.height == 0) {
                    dest.x = entity.rect.x + entity.rect.width / 2 - size.width / 2;
                }
                dest = dest.move(scroll_offset);
                if (has_icon or entity.type.button.icon_size.width > 0) {
                    dest.x += entity.type.button.spacing;
                }
                _ = sdl.SDL_SetTextureAlphaMod(texture, text_colour.a);
                _ = sdl.SDL_SetTextureColorMod(texture, text_colour.r, text_colour.g, text_colour.b);
                _ = sdl.SDL_RenderTexture(display.renderer, texture, null, @ptrCast(&dest));
            }
        }

        /// Return true if this button can be interacted with.
        pub inline fn clickable(
            button: *const Self,
        ) bool {
            return button.toggle == .no_toggle or
                button.toggle == .on or
                button.toggle == .off or
                button.toggle == .disabled;
        }

        /// An icon may have different background textures for hovered,
        /// pressed and normal state. Return the background that is valid
        /// for the current state.
        pub inline fn current_background(
            button: *const Self,
            entity: *const Entity(T),
        ) ?*sdl.SDL_Texture {
            if (button.toggle == .disabled)
                return button.background_disabled.?.texture;
            if (entity.pressed and button.background_pressed != null)
                return button.background_pressed.?.texture;
            if (entity.hovered and button.background_hover != null)
                return button.background_hover.?.texture;

            if (entity.background.image != null)
                return entity.background.image.?.texture;
            return null;
        }

        /// By default, button text is uses the default theme `text_colour`
        /// unless a style is applied, or the button is altered by its
        /// `hovered` or `pressed` status.
        inline fn button_text_colour(entity: *const Entity(T), theme: *const Theme) Colour {
            if (entity.style == .success) return theme.success_text_colour;
            if (entity.style == .failed) return theme.failed_text_colour;
            if (entity.style == .custom) return entity.colour;
            if (entity.pressed) return theme.tinted_text_colour;
            if (entity.hovered) return theme.tinted_text_colour;
            return theme.text_colour;
        }

        /// An icon may have different image textures for hovered, pressed
        /// and normal state. Return the image that is valid for the current state.
        inline fn current_icon(self: *const Self, entity: *const Entity(T)) ?*sdl.SDL_Texture {
            if (entity.pressed and self.icon_pressed != null)
                return self.icon_pressed.?.texture;
            if (entity.hovered and self.icon_hover != null)
                return self.icon_hover.?.texture;

            if (entity.texture != null)
                return entity.texture.?.texture;
            return null;
        }

        pub inline fn minimum_needed_width(
            button: *Self,
            display: *Display(T),
            entity: *Entity(T),
            _: f32, //parent_inner_width
        ) f32 {
            // Buttons may contain padding, icon, text, and icon-text spacing.
            var needed_width: f32 = entity.pad.left + entity.pad.right;

            needed_width += entity.type.button.icon_size.width;

            // If button has icon _and_ text, add button spacing
            if (button.icon_size.width > 0 and button.text.len > 0) {
                needed_width += entity.type.button.spacing;
            }

            // Add the width of the button text
            if (entity.type.button.text_texture) |t| {
                const size = button.text_size.pixel_size(display.scale, t);
                needed_width += size.width;
            }
            return @max(entity.minimum.width, needed_width);
        }

        pub inline fn minimum_needed_height(
            button: *Self,
            display: *Display(T),
            entity: *Entity(T),
            _: f32, //parent_inner_width
        ) f32 {
            var height: f32 = 0;
            if (button.text_texture) |_| {
                height = display.text_height.pixel_height(display.scale);
            }
            height = @max(button.icon_size.height, height);
            height += (entity.pad.top + entity.pad.bottom);
            return @max(entity.minimum.height, height);
        }
    };
}

const std = @import("std");
const ArrayListUnmanaged = std.ArrayListUnmanaged;

const sdl = @import("sdl");

const engine = @import("engine.zig");
const err = engine.err;
const Display = engine.Display;
const Colour = engine.Colour;
const Error = engine.Error;
const Font = engine.Font;
const Entity = engine.Entity;
const Texture = engine.Texture;
const Theme = engine.Theme;

const Clip = engine.ent.Clip;
const Rect = engine.ent.Rect;
const Size = engine.ent.Size;
const ToggleState = engine.ent.ToggleState;
const Vector = engine.ent.Vector;
