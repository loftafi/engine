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
        pub fn relayout(self: *Self, display: *Display(T), parent: *Element(T)) void {

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
            for (self.children.items) |element| {
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
                            .centre => element.rect.x = @round((parent.rect.width / 2.0) - (element.rect.width / 2.0)),
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
                            .centre => element.rect.y = @round((parent.rect.height / 2.0) - (element.rect.height / 2.0)),
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
            self.scrollable.size.width = parent.minimum.width;
            self.scrollable.size.height = parent.minimum.height;
            switch (self.direction) {
                .left_to_right => self.place_children_left_to_right(parent, expanders.slice(), expander_weights),
                .left_to_right_wrap => self.place_children_left_to_right_wrap(parent),
                .top_to_bottom => self.place_children_top_to_bottom(parent, expanders.slice(), expander_weights),
                .centre => self.place_children_centred(parent),
                .top_left => self.place_children_top_left(parent),
                .top_right => self.place_children_top_right(parent),
            }

            // Descend into child elements to allow child panels to also resize.
            for (self.children.items) |child| {
                if (child.type == .panel)
                    child.type.panel.relayout(display, child);
            }

            if (panel_resized and parent.on_resized.func != null) {
                _ = parent.on_resized.call(display, parent);
            }
        }

        // self == display
        inline fn place_children_centred(
            panel: *Self,
            element: *Element(T),
        ) void {
            const inner_width = element.inner_width();
            const inner_height = element.inner_height();

            // Place every child element in the centre of this panel.
            for (panel.children.items) |child| {
                if (child.layout.position == .float) continue;
                if (child.visible == .hidden) continue;
                if (child.type == .expander) {
                    warn("expander panel '{s}' ignored due to centre layout.", .{element.name});
                    continue;
                }

                switch (child.layout.x) {
                    .grows => {
                        child.rect.width = element.rect.width - element.pad.left - element.pad.right;
                        if (child.maximum.width > 0)
                            child.rect.width = @min(child.maximum.width, child.rect.width);
                        child.rect.x = element.rect.x + element.pad.left;
                    },
                    else => {
                        child.rect.x = element.rect.x + element.pad.left + @round(inner_width / 2 - child.rect.width / 2);
                    },
                }

                switch (child.layout.y) {
                    .grows => {
                        child.rect.height = element.rect.height - element.pad.top - element.pad.bottom;
                        if (child.maximum.height > 0)
                            child.rect.height = @min(child.maximum.height, child.rect.height);
                        child.rect.y = element.rect.y + element.pad.top;
                    },
                    else => {
                        child.rect.y = element.rect.y + element.pad.top + @round(inner_height / 2 - child.rect.height / 2);
                    },
                }
            }
            //TODO: Im not sure scroller detection is needed here or not

            //const needed_height = current.y - parent.y;
            //const overflow_height = (parent.y + parent.height) - current.y;
            //parent.type.panel.scrollable.size.height = @max(needed_height, parent.height);
        }

        inline fn place_children_top_left(
            _: *Self,
            parent: *Element(T),
        ) void {
            for (parent.type.panel.children.items) |child| {
                if (child.layout.position == .float) continue;
                if (child.visible == .hidden) continue;
                if (child.type == .expander) {
                    warn("expander panel '{s}' ignored due to top_left layout.", .{parent.name});
                    continue;
                }

                switch (child.layout.x) {
                    .grows => {
                        child.rect.width = parent.rect.width - parent.pad.left - parent.pad.right;
                        if (child.maximum.width > 0)
                            child.rect.width = @min(child.maximum.width, child.rect.width);
                    },
                    else => {},
                }
                child.rect.x = parent.rect.x + parent.pad.left;

                switch (child.layout.y) {
                    .grows => {
                        child.rect.height = parent.rect.height - parent.pad.top - parent.pad.bottom;
                        if (child.maximum.width > 0)
                            child.rect.height = @min(child.maximum.height, child.rect.height);
                    },
                    else => {},
                }
                child.rect.y = parent.rect.y + parent.pad.top;
            }
        }

        inline fn place_children_top_right(
            _: *Self,
            parent: *Element(T),
        ) void {
            for (parent.type.panel.children.items) |child| {
                if (child.layout.position == .float) continue;
                if (child.visible == .hidden) continue;
                if (child.type == .expander) {
                    warn("expander panel '{s}' ignored due to top_right layout.", .{parent.name});
                    continue;
                }

                switch (child.layout.x) {
                    .grows => {
                        child.rect.width = parent.rect.width - parent.pad.left - parent.pad.right;
                        if (child.maximum.width > 0)
                            child.rect.width = @min(child.maximum.width, child.rect.width);
                    },
                    else => {},
                }
                child.rect.x = parent.rect.x + parent.rect.width - parent.pad.right - child.rect.width;

                switch (child.layout.y) {
                    .grows => {
                        child.rect.height = parent.rect.height - parent.pad.top - parent.pad.bottom;
                        if (child.maximum.width > 0)
                            child.rect.height = @min(child.maximum.height, child.rect.height);
                    },
                    else => {},
                }
                child.rect.y = parent.rect.y + parent.pad.top;
            }
        }

        inline fn place_children_top_to_bottom(
            _: *Self,
            parent: *Element(T),
            expanders: []*Element(T),
            expander_weights: f32,
        ) void {
            // Layout each item from top to bottom, initially ignoring
            // the need to centre the items or expand any expanders.
            var current: Vector = .{
                .x = parent.rect.x + parent.pad.left,
                .y = parent.rect.y + parent.pad.top,
            };
            var first = true;
            for (parent.type.panel.children.items) |child| {
                // Layout the clipped and visible items, but not the hidden items.
                if (child.visible == .hidden) continue;
                if (child.layout.position == .float) continue;

                // Only apply spacing in-between items
                if (!first and child.type != .expander)
                    current.y += parent.type.panel.spacing;

                child.rect.x = current.x;
                child.rect.y = current.y;

                if (child.type != .expander)
                    current.y += child.rect.height;

                if (child.type != .expander) first = false;

                if (child.layout.x == .grows) {
                    child.rect.width = parent.rect.width - parent.pad.left - parent.pad.right;
                    if (child.maximum.width > 0)
                        child.rect.width = @min(child.maximum.width, child.rect.width);
                }
            }
            const needed_height = current.y - parent.rect.y - parent.pad.top;
            const overflow_height = (parent.rect.y + parent.rect.height - parent.pad.bottom) - current.y;
            parent.type.panel.scrollable.size.height = @max(needed_height, parent.rect.height);

            //info(" top to bottom layout {s} {s} - need {d} overflow {d}", .{ parent.name, @tagName(parent.type), needed_height, overflow_height });

            // If there are expanders, expand them, otherwise,
            // do start/centre/end alignment.
            if (expanders.len > 0 or expander_weights > 0) {
                // Relayout the children with expanders
                trace("expanders: {s} has {any}.  needed_height: {d} available_height: {d}", .{
                    parent.name,
                    expanders.len,
                    needed_height,
                    parent.rect.height,
                });
                if (parent.rect.height > needed_height) {
                    // Give each expander a percentage of the spare height area
                    const spare_height = parent.rect.height - needed_height;
                    for (expanders) |expander| {
                        if (expander.type.expander.weight <= 0) continue;

                        const percent = expander.type.expander.weight / expander_weights;
                        expander.rect.height = @trunc(spare_height * percent);
                        trace("   expander: weight {d} given: {d}", .{
                            percent,
                            expander.rect.height,
                        });
                    }
                    // Re-update each child panels y position based on the
                    // update to each expanders size.
                    var new_y: f32 = parent.rect.y + parent.pad.top;
                    first = true;
                    for (parent.type.panel.children.items) |child| {
                        // Relayout top to bottom using expander sizes
                        if (child.visible == .hidden) continue;
                        if (child.layout.position == .float) continue;
                        if (!first and child.type != .expander)
                            new_y += parent.type.panel.spacing;
                        child.rect.y = new_y;
                        new_y += child.rect.height;
                        if (child.type != .expander) first = false;
                        trace("expanding. {t} {s} y={d} height={d}", .{
                            child.type,
                            child.name,
                            child.rect.y,
                            child.rect.height,
                        });
                    }
                }
            } else {
                // If there is remaining space at end of children, maybe we
                // need to centre or right align.
                switch (parent.child_align.y) {
                    .start => {},
                    .centre => {
                        // Align from top to work out how much space is left
                        var new_y: f32 = parent.rect.y + parent.pad.top + (overflow_height / 2.0);
                        first = true;
                        for (parent.type.panel.children.items) |child| {
                            if (child.visible == .hidden) continue;
                            if (child.layout.position == .float) continue;
                            if (!first and child.type != .expander)
                                new_y += parent.type.panel.spacing;
                            child.rect.y = new_y;
                            new_y += child.rect.height;
                            if (child.type != .expander) first = false;
                        }
                    },
                    .end => {
                        // Workout the offset between the initial draw position
                        // and the overflow (underflow) to adjust for.
                        var new_y: f32 = parent.rect.y + parent.pad.top + overflow_height;
                        first = true;
                        for (parent.type.panel.children.items) |child| {
                            if (child.visible == .hidden) continue;
                            if (child.layout.position == .float) continue;
                            if (!first and child.type != .expander)
                                new_y += parent.type.panel.spacing;
                            child.rect.y = new_y;
                            new_y += child.rect.height;
                            if (child.type != .expander) first = false;
                        }
                        parent.type.panel.scrollable.size.width = @max(
                            needed_height,
                            parent.rect.height,
                        );
                    },
                }
            }
        }

        /// Draw panel children from top left corner of the panel
        /// assuming no scrolling of the child elements. Offsets
        /// applied at runtime.
        inline fn place_children_left_to_right(
            _: *Self,
            parent: *Element(T),
            expanders: []*Element(T),
            expander_weights: f32,
        ) void {
            var current: Vector = .{
                .x = parent.rect.x + parent.pad.left,
                .y = parent.rect.y + parent.pad.top,
            };
            // On first pass, we don't know the stretch size of the
            // expanders so first pass ignores expander width to find
            // only the "needed" space.
            var first = true;
            for (parent.type.panel.children.items) |child| {
                if (child.visible == .hidden) continue;
                if (child.layout.position == .float) continue;
                if (!first and child.type != .expander)
                    current.x += parent.type.panel.spacing;

                child.rect.x = current.x;
                child.rect.y = current.y;

                if (child.type != .expander)
                    current.x += child.rect.width;

                if (child.type != .expander) first = false;

                if (child.layout.y == .grows) {
                    child.rect.height = parent.rect.height - parent.pad.top - parent.pad.bottom;
                    if (child.maximum.height > 0)
                        child.rect.height = @min(child.maximum.height, child.rect.height);
                }
            }
            const needed_width = current.x - parent.rect.x - parent.pad.left;
            const overflow_width = (parent.rect.x + parent.rect.width - parent.pad.right) - current.x;
            parent.type.panel.scrollable.size.width = @max(needed_width, parent.rect.width);

            // On second pass, we can add in the expanders.
            if (expanders.len > 0 or expander_weights > 0) {
                trace("expanders: {s} has {any} expanders.  needed_width={d} available_width={d}", .{
                    parent.name,
                    expanders.len,
                    needed_width,
                    parent.rect.width,
                });
                if (parent.rect.width > needed_width) {
                    // Give each expander a percentage of the spare width area
                    const spare_width = parent.rect.width - needed_width;
                    for (expanders) |expander| {
                        if (expander.type.expander.weight <= 0) continue;

                        const percent = expander.type.expander.weight / expander_weights;
                        expander.rect.width = @trunc(spare_width * percent);
                        trace("   expander: weight {d} given: {d}", .{
                            percent,
                            expander.rect.width,
                        });
                    }
                    // Re-update each child panels x position based on the
                    // update to each expanders size.
                    var new_x: f32 = parent.rect.x + parent.pad.left;
                    first = true;
                    for (parent.type.panel.children.items) |child| {
                        // Relayout left to right using expander sizes
                        if (child.visible == .hidden) continue;
                        if (child.layout.position == .float) continue;
                        if (!first and child.type != .expander)
                            new_x += parent.type.panel.spacing;
                        child.rect.x = new_x;
                        new_x += child.rect.width;
                        if (child.type != .expander) first = false;

                        trace("expanding. {t} {s} x={d} width={d}", .{
                            child.type,
                            child.name,
                            child.rect.x,
                            child.rect.width,
                        });
                    }
                }
            } else {
                // Alternatively, if there are no expanders, we can align
                // the children.
                //
                // If there is remaining space at end of children, maybe we
                // need to centre or right align.
                switch (parent.child_align.x) {
                    .start => {},
                    .centre => {
                        // Align from top to work out how much space is left
                        var new_x: f32 = parent.rect.x + parent.pad.left + @round(overflow_width / 2.0);
                        for (parent.type.panel.children.items) |child| {
                            if (child.visible == .hidden) continue;
                            if (child.layout.position == .float) continue;
                            child.rect.x = new_x;
                            new_x += child.rect.width + parent.type.panel.spacing;
                        }
                    },
                    .end => {
                        // Workout the offset between the initial draw position
                        // and the overflow (underflow) to adjust for.
                        var new_x: f32 = parent.rect.x + parent.pad.left + overflow_width;
                        for (parent.type.panel.children.items) |child| {
                            if (child.visible == .hidden) continue;
                            if (child.layout.position == .float) continue;
                            child.rect.x = new_x;
                            new_x += child.rect.width + parent.type.panel.spacing;
                        }
                        parent.type.panel.scrollable.size.width = @max(
                            needed_width,
                            parent.rect.width,
                        );
                    },
                }
            }
        }

        // Draw panel children from top left corner of the panel
        // assuming no scrolling of the child elements. Offsets
        // applied at runtime. Track the height of each element
        // so wrapping can occur down to the next line.
        inline fn place_children_left_to_right_wrap(
            _: *Self,
            parent: *Element(T),
        ) void {
            var current: Vector = .{
                .x = parent.rect.x + parent.pad.left,
                .y = parent.rect.y + parent.pad.top,
            };

            // Track how much hight the current line needs
            var line_height: f32 = 0;

            // Draw along the line, and wrap when we hit the end of the line
            const line_end: f32 = parent.rect.x + parent.rect.width - parent.pad.right;

            var first = true;
            for (parent.type.panel.children.items) |child| {
                if (child.visible == .hidden) continue;
                if (child.layout.position == .float) continue;

                if (!first and child.type != .expander)
                    current.x += parent.type.panel.spacing;

                if (child.type != .expander) first = false;

                if (current.x + child.rect.width > line_end) {
                    current.x = parent.rect.x + parent.pad.left;
                    current.y += line_height + parent.type.panel.spacing;
                    line_height = 0;
                    first = true;
                    //TODO: We could y grow the elements that want grow.
                    //TODO We could centre the items on this line `parent.child_align.x`
                }

                child.rect.x = current.x;
                child.rect.y = current.y;
                current.x += child.rect.width;
                const item_height = @max(child.rect.height, child.minimum.height);
                line_height = @max(item_height, line_height);
            }
            current.y += parent.pad.bottom;
            const needed_height = current.y - parent.rect.y;
            parent.type.panel.scrollable.size.height = @max(needed_height, parent.rect.height);
            //const overflow_height = parent.rect.height - needed_height;
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
    try eq(panel.pad.top + ((panel.rect.height - panel.pad.top - panel.pad.bottom) / 2 - child.rect.height / 2), child.rect.y);
    try eq(panel.pad.left + ((panel.rect.width - panel.pad.left - panel.pad.right) / 2 - child.rect.width / 2), child.rect.x);

    err("fish", .{});
}

test "centre_text_bug" {
    const allocator = std.testing.allocator;
    // The display takes ownership of the resources object

    var display = try Display(TextSize(10)).create(allocator, test_config);
    defer display.destroy(allocator);
    _ = try display.load_font(allocator, "Roboto-Light");
    try eq(1, display.fonts.items.len);
    display.root.rect.width = 600;
    display.root.rect.height = 800;

    const panel = try display.add_panel(allocator, .{
        .type = .{ .panel = .{ .direction = .left_to_right, .spacing = 5 } },
        .layout = .{ .x = .grows, .y = .grows },
    });
    display.need_relayout = true;
    display.relayout();

    try eq(600, panel.rect.width);
    try eq(800, panel.rect.height);

    var footer = try panel.add(allocator, display, .{
        .name = "footer",
        .focus = .never_focus,
        .minimum = .{ .width = 180 },
        .maximum = .{ .width = 400 },
        .pad = .{ .left = 15, .right = 15, .top = 15, .bottom = 11 },
        .layout = .{ .x = .shrinks, .y = .shrinks },
        .child_align = .{ .x = .centre, .y = .start },
        .type = .{ .panel = .{
            .direction = .left_to_right,
            .spacing = 12,
        } },
    });
    display.need_relayout = true;
    display.relayout();
    try eq(180, footer.rect.width);
    try eq(15 + 11, footer.rect.height);

    const icon = try footer.add(allocator, display, .{
        .name = "question.icon",
        .focus = .never_focus,
        .child_align = .{ .x = .centre },
        .rect = .{ .width = 50, .height = 50 },
        .minimum = .{ .width = 50, .height = 50 },
        .maximum = .{ .width = 50, .height = 50 },
        .layout = .{ .x = .shrinks, .y = .shrinks },
        .type = .{ .sprite = .{} },
        .pad = .{ .left = 15, .right = 15, .top = 25, .bottom = 0 },
    });
    display.need_relayout = true;
    display.relayout();
    try eq(50, icon.rect.width);
    try eq(50, icon.rect.height);

    // The text is just a little smaller than the minmum width, so we can
    // test child start, centre, end align in child panels.
    const label = try footer.add(allocator, display, .{
        .name = "unit.question",
        .focus = .accessibility_focus,
        .style = .tinted,
        .minimum = .{ .width = 150 },
        .layout = .{ .x = .shrinks, .y = .shrinks },
        .child_align = .{ .x = .centre },
        .type = .{ .label = .{
            .text = "Yes or no?",
            .text_size = .normal,
        } },
        .pad = .{ .left = 0, .right = 1, .top = 0, .bottom = 0 },
    });

    {
        const full_width = 15 + 50 + 12 + 150 + 15;
        {
            panel.child_align.x = .start;
            display.need_relayout = true;
            display.relayout();
            try eq(150, label.rect.width); // text smaller than minimum
            try eq(20, label.rect.height);
            try eq(full_width, footer.rect.width);
            try eq(icon.rect.x, footer.rect.x + footer.pad.left);
            try eq(icon.rect.y, footer.rect.y + footer.pad.top);
            try eq(label.rect.x, footer.rect.x + footer.pad.left + 12 + icon.rect.width);
            try eq(label.rect.y, footer.rect.y + footer.pad.top);
            const element1 = label.type.label.elements.items[0];
            const element2 = label.type.label.elements.items[1];
            const element3 = label.type.label.elements.items[2];
            const space = label.type.label.text_size.word_spacing(display.scale);
            const text_width = element1.location.width + space + element2.location.width + space + element3.location.width;
            err("{d} {d} {d} space={d} text_width = {d}", .{ element1.location.width, element2.location.width, element3.location.width, space, text_width });
            try eq(0, element1.location.x);
            try eq(0, element1.location.y);
        }

        {
            panel.child_align.x = .end;
            display.need_relayout = true;
            display.relayout();
            try eq(full_width, footer.rect.width);
            try eq(panel.rect.width - full_width, footer.rect.x);
            try eq(label.rect.x, footer.rect.x + footer.rect.width - footer.pad.right - label.rect.width);
            try eq(label.rect.y, footer.rect.y + footer.pad.top);
            try eq(icon.rect.x, footer.rect.x + footer.rect.width - footer.pad.right - label.rect.width - 12 - icon.rect.width);
            try eq(icon.rect.y, footer.rect.y + footer.pad.top);
            const element = label.type.label.elements.items[0];
            try eq(0, element.location.x);
            try eq(0, element.location.y);
        }

        {
            panel.child_align.x = .centre;
            display.need_relayout = true;
            display.relayout();
            try eq(full_width, footer.rect.width);
            try eq(panel.rect.width / 2 - full_width / 2, footer.rect.x);
            try eq(label.rect.x, footer.rect.x + footer.rect.width - footer.pad.right - label.rect.width);
            try eq(label.rect.y, footer.rect.y + footer.pad.top);
            try eq(icon.rect.x, footer.rect.x + footer.rect.width - footer.pad.right - label.rect.width - 12 - icon.rect.width);
            try eq(icon.rect.y, footer.rect.y + footer.pad.top);
            const element = label.type.label.elements.items[0];
            try eq(0, element.location.x);
            try eq(0, element.location.y);
        }
    }
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
