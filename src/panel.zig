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

        /// Draw the contents of a panel.
        pub inline fn draw(
            self: *const Self,
            element: *Element(T),
            display: *Display(T),
            _: Vector, // parent_scroll_offset
            parent_clip: ?Clip,
            scroll_offset: Vector,
        ) void {
            if (parent_clip) |clip| {
                for (self.children.items) |child| {
                    child.draw(display, scroll_offset, clip);
                }
            } else if (self.scrollable.scroll.x or self.scrollable.scroll.y) {
                for (self.children.items) |child| {
                    child.draw(display, scroll_offset, Clip{
                        .top = element.rect.y,
                        .left = element.rect.x,
                        .bottom = element.rect.y + element.rect.height,
                        .right = element.rect.x + element.rect.width,
                    });
                }
            } else {
                for (self.children.items) |child| {
                    child.draw(display, scroll_offset, null);
                }
            }
        }
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
const Clip = engine.Clip;
const Display = engine.Display;
const Element = engine.Element;
const Error = engine.Error;
const Font = engine.Font;
const LayoutDirection = engine.LayoutDirection;
const Scroller = engine.Scroller;
const Size = engine.Size;
const Vector = engine.Vector;
const BoolCallback = engine.BoolCallback;
const Callback = engine.Callback;
const UpdateCallback = engine.UpdateCallback;
