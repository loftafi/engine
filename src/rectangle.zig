pub fn Rectangle(comptime T: type) type {
    return struct {
        pub const Self = @This();

        /// Draw a basic rectangle.
        pub inline fn draw(
            _: *const Self,
            element: *Element(T),
            display: *Display(T),
            _: Vector,
            _: ?Clip,
            scroll_offset: Vector,
        ) void {
            const colour = element.style.panel(display.theme, element.background.colour);
            _ = sdl.SDL_SetRenderDrawColor(
                display.renderer,
                colour.r,
                colour.g,
                colour.b,
                colour.a,
            );
            var dest = element.rect.move(&scroll_offset);
            _ = sdl.SDL_RenderFillRect(display.renderer, @ptrCast(&dest));
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
const Fit = engine.Fit;
const Font = engine.Font;
const LayoutDirection = engine.LayoutDirection;
const Size = engine.Size;
const Scroller = engine.Scroller;
const Texture = engine.Texture;
const ToggleState = engine.ToggleState;
const Vector = engine.Vector;
const Callback = engine.Callback;
const BoolCallback = engine.BoolCallback;
const UpdateCallback = engine.UpdateCallback;
