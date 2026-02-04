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

        pub inline fn minimum_needed_width(
            self: *Self,
            display: *Display(T),
            element: *Element(T),
            _: f32, //parent_inner_width
        ) f32 {
            return @max(element.minimum.width, self.find_minimum_panel_width(element, display));
        }

        /// Discover the minimum needed for a particular object.
        ///
        /// If the object has children, a `parent` object must check
        /// the widths of its children.
        ///
        /// If parent fills children left-to-right, we must add the heights.
        /// If parent fills children top-to-bottom simply find the widest item.
        fn find_minimum_panel_width(panel: *Self, parent: *const Element(T), display: *Display(T)) f32 {
            std.debug.assert(parent.type == .panel);
            if (parent.visible == .hidden) return 0;
            if (parent.layout.position == .float) return 0;

            const available_width = parent.inner_width();

            switch (panel.direction) {
                .left_to_right => {
                    // a, next to b, next to c. (left to right)
                    //
                    // Need to add up the min width of all items
                    var minimum_needed: f32 = parent.pad.left + parent.pad.right;
                    var first = true;
                    for (panel.children.items) |element| {
                        if (element.layout.position == .float) continue;
                        if (element.visible == .hidden) continue;

                        // Add space between each element.
                        if (first)
                            first = false
                        else
                            minimum_needed += panel.spacing;

                        const width = element.minimum_needed_width(display, available_width);
                        minimum_needed += width;
                    }
                    // Bound to the minimum/maximum width
                    if (parent.maximum.width > 0)
                        minimum_needed = @min(parent.maximum.width, minimum_needed);

                    return @max(minimum_needed, parent.minimum.width);
                },
                .left_to_right_wrap => {
                    var minimum_needed: f32 = parent.pad.left + parent.pad.right;
                    var first = true;
                    for (panel.children.items) |element| {
                        if (element.layout.position == .float) continue;
                        if (element.visible == .hidden) continue;

                        // Add space between each element.
                        if (first)
                            first = false
                        else
                            minimum_needed += panel.spacing;

                        const width = element.minimum_needed_width(display, available_width);
                        minimum_needed = @max(minimum_needed, width);
                    }
                    // Bound to the minimum/maximum width
                    if (parent.maximum.width > 0)
                        minimum_needed = @min(parent.maximum.width, minimum_needed);
                    return @max(minimum_needed, parent.minimum.width);
                },
                .centre, .top_to_bottom, .top_left, .top_right => {
                    // a, centred upon b, centred upon c
                    // a, then b underneath, thn c underneath...
                    //
                    // Need to just find maximum width item
                    var minimum_needed: f32 = 0;
                    for (panel.children.items) |element| {
                        if (element.layout.position == .float) continue;
                        if (element.visible == .hidden) continue;

                        const child_width = element.minimum_needed_width(display, available_width);
                        if (false) {
                            debug("seek min width {s}->{s}/{t} curent_min={d} child_min={d} parent_inner={d}", .{
                                parent.name,
                                element.name,
                                element.type,
                                minimum_needed,
                                child_width,
                                available_width,
                            });
                        }
                        minimum_needed = @max(minimum_needed, child_width);
                    }
                    return @max(parent.minimum.width, minimum_needed + (parent.pad.left + parent.pad.right));
                },
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
