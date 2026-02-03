pub fn Panel(comptime T: type) type {
    return struct {
        pub const Self = @This();
        children: ArrayListUnmanaged(*Element(T)) = .empty,
        direction: LayoutDirection = .centre,
        spacing: f32 = 0,
        on_click: Element(T).Callback = .empty,
        update: Element(T).UpdateCallback = .empty,
        scrollable: Scroller = .{
            .scroll = .{ .x = false, .y = false },
            .size = .{ .width = 0, .height = 0 },
        },
        overflow: Vector = .{ .x = 0, .y = 0 },
    };
}

const std = @import("std");
const ArrayListUnmanaged = std.ArrayListUnmanaged;

const engine = @import("engine.zig");
const err = engine.err;
const warn = engine.warn;
const info = engine.info;
const debug = engine.debug;
const trace = engine.trace;
const Display = engine.Display;
const Element = engine.Element;
const Scroller = engine.Scroller;
const Size = engine.Size;
const Vector = engine.Vector;
const BoolCallback = engine.BoolCallback;
const Callback = engine.Callback;
const UpdateCallback = engine.UpdateCallback;
const LayoutDirection = engine.LayoutDirection;
const Error = engine.Error;
const Font = engine.Font;
