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
        on_click: Element(T).Callback = .empty,
        toggle: ToggleState = .no_toggle,

        /// Draw a button with its text and/or icon. Mouse hover, mouse click
        /// and the disabled status may change the picture or icon
        /// displayed in the button.
        pub inline fn draw(
            self: *const Self,
            element: *Element(T),
            display: *Display(T),
            _: Vector,
            _: ?Clip,
            scroll_offset: Vector,
        ) void {
            // Draw the background matching the  current button state
            if (self.current_background(element)) |background_image| {
                var dest: Rect = .{
                    .x = element.rect.x + scroll_offset.x,
                    .y = element.rect.y + scroll_offset.y,
                    .width = element.rect.width,
                    .height = element.rect.height,
                };
                if (element.flip.x) {
                    dest.x += dest.width;
                    dest.width = 0 - dest.width;
                }
                if (element.flip.y) {
                    dest.y += dest.height;
                    dest.height = 0 - dest.height;
                }
                element.apply_background_tint(display, background_image);
                if (element.background.image_corner_radius == 0) {
                    _ = sdl.SDL_RenderTexture(display.renderer, background_image, null, @ptrCast(&dest));
                } else {
                    var corner: f32 = element.background.corner_radius;
                    if (corner * 2 > dest.height) corner = dest.height / 2;
                    _ = sdl.SDL_RenderTexture9Grid(
                        display.renderer,
                        background_image,
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

            // The inner content can contain a button and/or text texture.
            var content_width = self.icon_size.width;
            if (self.text_texture) |texture| {
                const size = self.text_size.pixel_size(display.scale, texture);

                // Do we need space between text and icon?
                if (content_width > 0)
                    content_width += element.type.button.spacing;

                content_width += size.width;
            }
            content_width += element.pad.left + element.pad.right;

            const content_x_offset = switch (element.child_align.x) {
                .start => 0,
                .centre => (element.rect.width - content_width) / 2.0,
                .end => element.rect.width - content_width,
            };
            const icon_y_offset = switch (element.child_align.y) {
                .start => element.pad.top,
                .centre => (element.rect.height / 2) - (self.icon_size.height / 2),
                .end => element.rect.height - element.pad.bottom - self.icon_size.height,
            };

            const text_colour = button_text_colour(element, display.theme);
            var has_icon = false;

            // Place the icon
            if (self.current_icon(element)) |icon_image| {
                has_icon = true;
                var dest: Rect = .{
                    .x = element.rect.x + element.pad.left + content_x_offset,
                    .y = element.rect.y + icon_y_offset,
                    .width = self.icon_size.width,
                    .height = self.icon_size.height,
                };
                dest = dest.move(&scroll_offset);
                if (element.flip.x) {
                    dest.x += dest.width;
                    dest.width = 0 - dest.width;
                }
                if (element.flip.y) {
                    dest.y += dest.height;
                    dest.height = 0 - dest.height;
                }
                _ = sdl.SDL_SetTextureAlphaMod(icon_image, text_colour.a);
                _ = sdl.SDL_SetTextureColorMod(icon_image, text_colour.r, text_colour.g, text_colour.b);
                _ = sdl.SDL_RenderTexture(display.renderer, icon_image, null, @ptrCast(&dest));
            }

            // Place the text
            if (element.type.button.text_texture) |texture| {
                const size = element.type.button.text_size.pixel_size(display.scale, texture);
                var dest: Rect = .{
                    .x = element.rect.x + element.type.button.icon_size.width + element.pad.left + content_x_offset,
                    .y = element.rect.y + (element.rect.height / 2.0) - (size.height / 2),
                    .width = size.width,
                    .height = size.height,
                };
                if (element.type.button.icon_size.width == 0 or element.type.button.icon_size.height == 0) {
                    dest.x = element.rect.x + element.rect.width / 2 - size.width / 2;
                }
                dest = dest.move(&scroll_offset);
                if (has_icon or element.type.button.icon_size.width > 0) {
                    dest.x += element.type.button.spacing;
                }
                _ = sdl.SDL_SetTextureAlphaMod(texture, text_colour.a);
                _ = sdl.SDL_SetTextureColorMod(texture, text_colour.r, text_colour.g, text_colour.b);
                _ = sdl.SDL_RenderTexture(display.renderer, texture, null, @ptrCast(&dest));
            }
        }

        /// An icon may have different background textures for hovered,
        /// pressed and normal state. Return the background that is valid
        /// for the current state.
        pub inline fn current_background(button: *const Self, element: *Element(T)) ?*sdl.SDL_Texture {
            if (button.toggle == .disabled)
                return button.background_disabled.?.texture;
            if (element.pressed and button.background_pressed != null)
                return button.background_pressed.?.texture;
            if (element.hovered and button.background_hover != null)
                return button.background_hover.?.texture;

            if (element.background.image != null)
                return element.background.image.?.texture;
            return null;
        }

        /// By default, button text is uses the default theme `text_colour`
        /// unless a style is applied, or the button is altered by its
        /// `hovered` or `pressed` status.
        inline fn button_text_colour(element: *const Element(T), theme: *Theme) Colour {
            if (element.style == .success) return theme.success_text_colour;
            if (element.style == .failed) return theme.failed_text_colour;
            if (element.style == .custom) return element.colour;
            if (element.pressed) return theme.tinted_text_colour;
            if (element.hovered) return theme.tinted_text_colour;
            return theme.text_colour;
        }

        /// An icon may have different image textures for hovered, pressed
        /// and normal state. Return the image that is valid for the current state.
        inline fn current_icon(self: *const Self, element: *const Element(T)) ?*sdl.SDL_Texture {
            if (element.pressed and self.icon_pressed != null)
                return self.icon_pressed.?.texture;
            if (element.hovered and self.icon_hover != null)
                return self.icon_hover.?.texture;

            if (element.texture != null)
                return element.texture.?.texture;
            return null;
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
const Clip = engine.Clip;
const Colour = engine.Colour;
const Error = engine.Error;
const Font = engine.Font;
const Element = engine.Element;
const LayoutDirection = engine.LayoutDirection;
const Rect = engine.Rect;
const Scroller = engine.Scroller;
const Size = engine.Size;
const Texture = engine.Texture;
const Theme = engine.Theme;
const ToggleState = engine.ToggleState;
const Vector = engine.Vector;
const Callback = engine.Callback;
const BoolCallback = engine.BoolCallback;
const UpdateCallback = engine.UpdateCallback;
