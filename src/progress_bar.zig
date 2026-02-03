pub fn ProgressBar(comptime T: type) type {
    return struct {
        pub const Self = @This();
        progress: f32 = 0,

        pub fn draw() void {
            if (T.normal.pixel_height(1) == 0) {
                //
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
