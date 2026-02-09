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

        pub inline fn minimum_needed_height(
            self: *Self,
            display: *Display(T),
            element: *Element(T),
            _: f32, //parent_inner_width
        ) f32 {
            return @max(element.minimum.height, self.find_minimum_panel_height(element, display));
        }

        /// Discover the minimum needed for a particular object.
        ///
        /// If the object has children, a `parent` object must check
        /// the heights of its children.
        ///
        /// If parent stacks children top-to-bottom, we must add the heights.
        /// If parent stacks children left-to-right simply find the tallest item.
        fn find_minimum_panel_height(_: *Self, parent: *Element(T), display: *Display(T)) f32 {
            std.debug.assert(parent.type == .panel);
            if (parent.visible == .hidden) return 0;
            if (parent.layout.position == .float) return 0;

            const available_width = parent.inner_width();

            switch (parent.type.panel.direction) {
                .top_to_bottom => {
                    // a, above b, above c. (top to bottom)
                    var minimum_needed: f32 = parent.pad.top + parent.pad.bottom;
                    // Add the size needed for each inline child.
                    var first = true;
                    for (parent.type.panel.children.items) |element| {
                        if (element.layout.position == .float) continue;
                        if (element.visible == .hidden) continue;
                        if (element.type == .expander) continue;
                        if (first) {
                            first = false;
                        } else {
                            // Add spacing before next element, if needed
                            minimum_needed += parent.type.panel.spacing;
                        }
                        const height = element.minimum_needed_height(display, available_width);
                        minimum_needed += height;
                    }
                    // Bound to the minimum/maximum height
                    var result = minimum_needed;
                    if (parent.maximum.height > 0 and parent.maximum.height < minimum_needed) {
                        result = parent.maximum.height;
                    }
                    result = @max(result, parent.minimum.height);
                    return result;
                },

                .centre, .left_to_right, .left_to_right_wrap, .top_left, .top_right => {
                    // centred all together
                    // a, next to b, next c.
                    //
                    // Just need to know the highest/tallest child.
                    var minimum_needed: f32 = 0;
                    for (parent.type.panel.children.items) |element| {
                        if (element.layout.position == .float) continue;

                        const height = element.minimum_needed_height(display, available_width);
                        if (height > minimum_needed)
                            minimum_needed = height;
                    }
                    return minimum_needed + (parent.pad.top + parent.pad.bottom);
                },
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

        /// Relayout the contents of an individual panel that is sitting
        /// somewhere n the tree below the root panel (scene).
        /// self becomes display
        pub fn relayout(panel: *Panel, display: *Display(T), parent: *Element(T)) void {
            std.debug.assert(parent.type == .panel);

            // Keep track of each expander in the panel. At the end, expand
            // each expander according to the leftover space.
            var expanders = BoundedArray(*Element(T), 10){};
            var expander_weights: f32 = 0;

            // Make sure this element never exceeds its maximum.
            var panel_resized = false;
            if (parent.layout.x == .grows and parent.maximum.width > 0) {
                const new_width = @min(parent.rect.width, parent.maximum.width);
                if (parent.rect.width != new_width) {
                    parent.rect.width = new_width;
                    panel_resized = true;
                }
            }
            if (parent.layout.y == .grows and parent.maximum.height > 0) {
                const new_height = @min(parent.rect.height, parent.maximum.height);
                if (parent.rect.height != new_height) {
                    parent.rect.height = new_height;
                    panel_resized = true;
                }
            }

            // # Step 1
            //
            // Children of this panel are either fixed positioned, growing, or shrinking.
            //
            // - `.fixed` elements are not altered, keep retain their requested `rect` size.
            // - `.shrinks` elements shrink to the `minimum` space they need.
            // - `.grows` enlarges the width or height of the parent `rect`.
            //
            for (parent.type.panel.children.items) |element| {
                if (element.visible == .hidden) continue;

                const available_width = parent.inner_width();

                var child_resized = false;
                if ((engine.dev_build or display.dev_mode) and element.layout.position == .float) {
                    if (element.layout.x == .grows) {
                        err("floating items cant grow. {s} {s}", .{ element.name, @tagName(element.type) });
                        element.layout.x = .fixed;
                    }
                    if (element.layout.x == .shrinks) {
                        err("floating items cant shrink. {s} {s}", .{ element.name, @tagName(element.type) });
                        element.layout.x = .fixed;
                    }
                }
                switch (element.layout.x) {
                    .grows => {
                        // Grow to the parent width, not including padding.
                        element.rect.x = 0;
                        var new_width = parent.rect.width - (parent.pad.left + parent.pad.right);
                        if (element.maximum.width > 0 and new_width > element.maximum.width) {
                            new_width = element.maximum.width;
                        }
                        if (element.rect.width != new_width) {
                            element.rect.width = new_width;
                            child_resized = true;
                        }
                    },
                    .shrinks => {
                        // Shrink to the smallest the children will allow.
                        const new_width = element.minimum_needed_width(display, available_width);
                        if (element.rect.width != new_width) {
                            element.rect.width = new_width;
                            child_resized = true;
                        }
                        // Shrink to the left, centre, or right.
                        switch (element.child_align.x) {
                            .start => element.rect.x = 0,
                            .end => element.rect.x = parent.rect.width - element.rect.width,
                            .centre => element.rect.x = (parent.rect.width / 2.0) - (element.rect.width / 2.0),
                        }
                    },
                    .fixed => {
                        // No shrinking or growing applies.
                    },
                }

                switch (element.layout.y) {
                    .grows => {
                        // Grow to the parent height, not including padding.
                        element.rect.y = 0;
                        element.rect.height = parent.rect.height - (parent.pad.top + parent.pad.bottom);
                        if (element.maximum.height > 0 and element.rect.height > element.maximum.height) {
                            element.rect.height = element.maximum.height;
                        }
                    },
                    .shrinks => {
                        // Shrink to the smallest the children will allow
                        const new_height = element.minimum_needed_height(display, available_width);
                        if (element.rect.height != new_height) {
                            element.rect.height = new_height;
                            child_resized = true;
                        }
                        switch (element.child_align.y) {
                            .start => element.rect.y = 0,
                            .end => element.rect.y = parent.rect.height - element.rect.height,
                            .centre => element.rect.y = (parent.rect.height / 2.0) - (element.rect.height / 2.0),
                        }
                    },
                    .fixed => {
                        // No shrinking or growing applies.
                    },
                }

                if (child_resized and element.on_resized.func != null) {
                    trace("element {s} resized. callback = {any}", .{
                        element.name,
                        element.on_resized.func != null,
                    });
                    _ = element.on_resized.call(display, element);
                }

                if (element.type == .expander) {
                    expanders.appendAssumeCapacity(element);
                    expander_weights += element.type.expander.weight;
                }
            }

            // Step 2
            //
            // The parent panel dictates if the children align to start,
            // centre, or end. Growing/Shrinking children must be aligned
            // to the start, centre, or end. The parent panel decides if
            // the elements are left-to-right or top-to-bottom.

            //debug("layout elements {s} {s}", .{
            //    parent.name,
            //    @tagName(parent.child_direction),
            //});
            parent.type.panel.scrollable.size.width = parent.minimum.width;
            parent.type.panel.scrollable.size.height = parent.minimum.height;
            switch (parent.type.panel.direction) {
                .left_to_right => place_children_left_to_right(self, parent, expanders.slice(), expander_weights),
                .left_to_right_wrap => place_children_left_to_right_wrap(self, parent),
                .top_to_bottom => place_children_top_to_bottom(self, parent, expanders.slice(), expander_weights),
                .centre => place_children_centred(self, parent),
                .top_left => place_children_top_left(self, parent),
                .top_right => place_children_top_right(self, parent),
            }

            // Descend into child elements to allow child panels to also resize.
            for (parent.type.panel.children.items) |child| {
                if (child.type == .panel)
                    self.relayout_panel(child);
            }

            if (panel_resized and parent.on_resized.func != null) {
                _ = parent.on_resized.call(self, parent);
            }
        }
    };
}

test "panel_padding" {
    const allocator = std.testing.allocator;
    // The display takes ownership of the resources object

    var display = try Display(TextSize(10)).create(allocator, test_config);
    defer display.destroy(allocator);
    _ = try display.load_font(allocator, "Roboto-Light");
    try eq(1, display.fonts.items.len);
    display.root.rect.width = 300;
    display.root.rect.height = 200;

    const panel = try display.add_panel(allocator, .{
        .type = .{ .panel = .{ .direction = .top_to_bottom } },
        .layout = .{ .x = .grows, .y = .grows },
    });
    display.need_relayout = true;
    display.relayout();

    try eq(300, panel.rect.width);
    try eq(200, panel.rect.height);

    const child = try panel.add(allocator, display, .{
        .type = .{ .panel = .{ .direction = .top_to_bottom } },
        .rect = .{ .width = 120, .height = 80 },
        .layout = .{ .x = .fixed, .y = .fixed },
    });

    // Test alignment without padding
    panel.type.panel.direction = .top_to_bottom;
    display.need_relayout = true;
    display.relayout();
    try eq(120, child.rect.width);
    try eq(80, child.rect.height);
    try eq(0, child.rect.x);
    try eq(0, child.rect.y);

    panel.type.panel.direction = .top_left;
    display.need_relayout = true;
    display.relayout();
    try eq(0, child.rect.x);
    try eq(0, child.rect.y);

    panel.type.panel.direction = .top_right;
    display.need_relayout = true;
    display.relayout();
    try eq(panel.rect.width - child.rect.width, child.rect.x);
    try eq(0, child.rect.y);

    panel.type.panel.direction = .left_to_right;
    display.need_relayout = true;
    display.relayout();
    try eq(0, child.rect.x);
    try eq(0, child.rect.y);

    panel.type.panel.direction = .centre;
    display.need_relayout = true;
    display.relayout();
    try eq(panel.rect.width / 2 - child.rect.width / 2, child.rect.x);
    try eq(panel.rect.height / 2 - child.rect.height / 2, child.rect.y);

    // Retest alignment with padding
    panel.pad = .{ .left = 2, .right = 4, .top = 8, .bottom = 16 };

    panel.type.panel.direction = .top_to_bottom;
    display.need_relayout = true;
    display.relayout();
    try eq(120, child.rect.width);
    try eq(80, child.rect.height);
    try eq(2, child.rect.x);
    try eq(8, child.rect.y);

    panel.type.panel.direction = .top_left;
    display.need_relayout = true;
    display.relayout();
    try eq(2, child.rect.x);
    try eq(8, child.rect.y);

    panel.type.panel.direction = .left_to_right;
    display.need_relayout = true;
    display.relayout();
    try eq(2, child.rect.x);
    try eq(8, child.rect.y);

    panel.type.panel.direction = .centre;
    display.need_relayout = true;
    display.relayout();
    try eq(panel.rect.height / 2 - child.rect.height / 2, child.rect.y);
    try eq(panel.rect.width / 2 - child.rect.width / 2, child.rect.x);

    err("fish", .{});
}

const std = @import("std");
const ArrayListUnmanaged = std.ArrayListUnmanaged;
const eq = std.testing.expectEqual;

const praxis = @import("praxis");
const BoundedArray = praxis.BoundedArray;

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
const TextSize = engine.TextSize;
const Vector = engine.Vector;
const BoolCallback = engine.BoolCallback;
const Callback = engine.Callback;
const UpdateCallback = engine.UpdateCallback;

const test_config = @import("test.zig").test_config;
