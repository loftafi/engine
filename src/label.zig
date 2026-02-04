pub fn Label(comptime T: type) type {
    return struct {
        pub const Self = @This();

        font: *Font = undefined,
        font_name: ?[]const u8 = null,
        text: []const u8 = "",
        translated: []const u8 = "",
        elements: ArrayListUnmanaged(TextElement) = .empty,
        line_height: f32 = 1,
        text_size: T = .normal,
        on_click: Element(T).Callback = .empty,

        /// Calculate the layout of all elements, and optionally render every element.
        ///
        /// Normally text is converted to an image and rendered left to right, starting
        /// at the top left corner of the element (including padding).
        ///
        /// If the text is centred or right aligned, then each line must be pushed along
        /// by a certain offset amount.
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
        }

        pub inline fn minimum_needed_width(
            _: *Self,
            display: *Display(T),
            element: *Element(T),
            parent_inner_width: f32,
        ) f32 {
            switch (element.layout.x) {
                .shrinks, .grows => {
                    // Growing or shrinking, our task here is to find
                    // the minimum that would be needed.
                    element.layout_label(display.scale, parent_inner_width);
                    return element.rect.width;
                },
                .fixed => {
                    return element.rect.width;
                },
            }
        }

        pub inline fn minimum_needed_height(
            _: *Self,
            display: *Display(T),
            element: *Element(T),
            parent_inner_width: f32,
        ) f32 {
            // Simulate a draw of this element to see how many lines it
            // would take. This is done when the label is created but also
            // needs to be done here as the width of the label may have changed.
            switch (element.layout.y) {
                .shrinks, .grows => {
                    element.layout_label(display.scale, parent_inner_width);
                    //err("{s} {s} use grows height {d} (parent_width={d})", .{ self.name, @tagName(self.type), mm.max_height, parent_width });
                    return element.rect.height;
                },
                .fixed => {
                    //err("{s} {s} use fixed height {d} (parent_width={d})", .{ self.name, @tagName(self.type), self.height, parent_width });
                    return element.rect.height;
                },
            }
        }
    };
}

pub fn draw_text_elements(
    items: []TextElement,
    loc: Vector,
    current_colour: engine.Colour,
    renderer: *sdl.SDL_Renderer,
    parent_clip: ?Clip,
) void {
    for (items) |*item| {
        const pos = item.location.move(&loc);
        if (parent_clip) |clip| {
            if (pos.x + pos.width < clip.left) continue;
            if (pos.y + pos.height + 1 < clip.top) continue;
            if (pos.x > clip.right) continue;
            if (pos.y > clip.bottom) continue;
        }

        // Only render text if display parameter is provided
        _ = sdl.SDL_SetTextureColorMod(
            item.texture,
            current_colour.r,
            current_colour.g,
            current_colour.b,
        );
        _ = sdl.SDL_SetTextureAlphaMod(item.texture, current_colour.a);
        _ = sdl.SDL_RenderTexture(
            renderer,
            item.texture,
            null,
            @ptrCast(&pos),
        );
    }
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
const Scroller = engine.Scroller;
const Size = engine.Size;
const TextElement = engine.TextElement;
const Texture = engine.Texture;
const ToggleState = engine.ToggleState;
const Vector = engine.Vector;
const Callback = engine.Callback;
const BoolCallback = engine.BoolCallback;
const UpdateCallback = engine.UpdateCallback;
