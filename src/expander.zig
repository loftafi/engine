pub fn Expander(comptime T: type) type {
    return struct {
        pub const Self = @This();
        weight: f32 = 0,

        pub inline fn draw(
            _: *const Self,
            _: *Element(T),
            _: *Display(T),
            _: Vector,
            _: ?Clip, //parent_clip
            _: Vector, // scroll_offset
        ) void {
            if (T.normal.pixel_height(1) == 0) {
                //
            }
        }

        pub inline fn minimum_needed_width(
            _: *Self,
            _: *Display(T),
            element: *Element(T),
            _: f32,
        ) f32 {
            return element.minimum.width;
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
const Scroller = engine.Scroller;
const Vector = engine.Vector;
const Callback = engine.Callback;
const BoolCallback = engine.BoolCallback;
const UpdateCallback = engine.UpdateCallback;
const LayoutDirection = engine.LayoutDirection;
const Error = engine.Error;
const Font = engine.Font;
const Fit = engine.Fit;
const Size = engine.Size;
const Texture = engine.Texture;
const ToggleState = engine.ToggleState;
