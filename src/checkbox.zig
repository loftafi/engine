pub fn Checkbox(comptime T: type) type {
    return struct {
        pub const Self = @This();
        checked: bool = false,
        font: *Font = undefined,
        font_name: ?[]const u8 = null,
        text_size: T = .normal,
        text: []const u8 = "",
        translated: []const u8 = "",
        elements: ArrayListUnmanaged(TextElement) = .empty,
        line_height: f32 = 1,
        checkbox_size: Size = .{ .width = 0, .height = 0 },
        on_texture: ?*Texture = null,
        off_texture: ?*Texture = null,
        on_change: Element(T).Callback = .empty,

        /// Draw a radio box combined with a text label.
        pub inline fn draw(
            self: *const Self,
            element: *Element(T),
            display: *Display(T),
            _: Vector, //parent_scroll_offset: Vector,
            parent_clip: ?Clip,
            scroll_offset: Vector,
        ) void {
            const loc = Vector{
                .x = element.rect.x + element.pad.left + scroll_offset.x,
                .y = element.rect.y + element.pad.top + scroll_offset.y,
            };
            const text_colour = element.style.text(display.theme, element.colour);
            draw_text_elements(self.elements.items, loc, text_colour, display.renderer, parent_clip);

            const checkbox = self.checkbox_size;
            var dest = Rect{
                .x = element.rect.x + element.rect.width - checkbox.width - element.pad.left,
                .y = element.rect.y + (element.rect.height / 2) - (checkbox.height / 2),
                .width = checkbox.width,
                .height = checkbox.height,
            };
            dest = dest.move(&scroll_offset);
            if (self.checked) {
                if (self.on_texture) |texture| {
                    _ = sdl.SDL_RenderTexture(display.renderer, texture.texture, null, @ptrCast(&dest));
                }
            } else {
                if (self.off_texture) |texture| {
                    _ = sdl.SDL_RenderTexture(display.renderer, texture.texture, null, @ptrCast(&dest));
                }
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
const Display = engine.Display;
const Element = engine.Element;
const Error = engine.Error;
const Font = engine.Font;
const LayoutDirection = engine.LayoutDirection;
const Rect = engine.Rect;
const Scroller = engine.Scroller;
const Size = engine.Size;
const Texture = engine.Texture;
const TextElement = engine.TextElement;
const ToggleState = engine.ToggleState;
const Vector = engine.Vector;
const Callback = engine.Callback;
const BoolCallback = engine.BoolCallback;
const UpdateCallback = engine.UpdateCallback;
const draw_text_elements = @import("label.zig").draw_text_elements;
