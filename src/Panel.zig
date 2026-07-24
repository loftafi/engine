/// An entity that holds other entities and may become scrollable.
pub const Panel = @This();

/// Entities to draw inside this panel.
children: ArrayListUnmanaged(*Entity) = .empty,

/// Vertical or horizontal alignment
direction: LayoutDirection = .centre,

/// Inficate if a panel can grow into the safe area or not.
safe_area: SafeArea = .unspecified,

/// Indicate if a panel is part of the `choosePanel` set.
choosable: Choosable = .unspecified,

/// Empty space to place between entities.
spacing: f32 = 0,

/// Indicates if vertical or horizontal scrolling is allowed.
scrollable: Scroller = .{
    .scroll = .{ .x = false, .y = false },
    .size = .{ .width = 0, .height = 0 },
},

/// Called every iteration of the main app loop.
on_update: Entity.UpdateCallback = .empty,

/// Handle User triggered events. Keyboard, Mouse, Game controller
on_ui_event: Entity.Callback = .empty,

/// Callback event that occurs if the backgroind of this panel is tapped.
on_pressed: Entity.Callback = .empty,

pub inline fn topScrollSpace(self: *const Panel) f32 {
    if (!self.scrollable.scroll.y) return 0;
    // TODO: Calculate the actual value.
    return 9999;
}

pub inline fn bottomScrollSpace(self: *const Panel) f32 {
    if (!self.scrollable.scroll.y) return 0;
    // TODO: Calculate the actual value.
    return 9999;
}

pub inline fn leftScrollSpace(self: *const Panel) f32 {
    if (!self.scrollable.scroll.x) return 0;
    // TODO: Calculate the actual value.
    return 9999;
}

pub inline fn rightScrollSpace(self: *const Panel) f32 {
    if (!self.scrollable.scroll.x) return 0;
    // TODO: Calculate the actual value.
    return 9999;
}

/// Return true if this panel can be interacted with through user
/// driven event handlers..
pub inline fn clickable(self: *const Panel) bool {
    return self.on_ui_event.func != null or self.on_pressed.func != null;
}

/// Draw the contents of a panel.
pub inline fn draw(
    self: *const Panel,
    entity: *Entity,
    display: *Display,
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
                .top = entity.rect.y,
                .left = entity.rect.x,
                .bottom = entity.rect.y + entity.rect.height,
                .right = entity.rect.x + entity.rect.width,
            });
        }
    } else {
        for (self.children.items) |child| {
            child.draw(display, scroll_offset, null);
        }
    }
}

/// Discover the minimum needed for a particular object.
///
/// If the object has children, a `parent` object must check
/// the heights of its children.
///
/// If parent stacks children top-to-bottom, we must add the heights.
/// If parent stacks children left-to-right simply find the tallest item.
pub inline fn minimumNeededHeight(
    self: *const Panel,
    entity: *const Entity,
    _: f32, //parent_inner_width
) f32 {
    return @max(entity.minimum.height, self.calculateMinimumNeededHeight(entity));
}

fn calculateMinimumNeededHeight(
    _: *const Panel,
    entity: *const Entity,
) f32 {
    std.debug.assert(entity.type == .panel);
    if (entity.visible == .hidden) return 0;

    // Even floating objects need to know their neededHeight.
    //if (entity.layout.position == .float) return 0;

    const available_width = entity.inner_width();

    switch (entity.type.panel.direction) {
        .top_to_bottom => {
            // a, above b, above c. (top to bottom)
            var minimum_needed: f32 = entity.pad.top + entity.pad.bottom;
            // Add the size needed for each inline child.
            var first = true;
            for (entity.type.panel.children.items) |child| {
                if (child.layout.position == .float) continue;
                if (child.visible == .hidden) continue;
                if (child.type == .expander) continue;
                if (first) {
                    first = false;
                } else {
                    // Add spacing before next entity, if needed
                    minimum_needed += entity.type.panel.spacing;
                }
                const height = child.minimumNeededHeight(available_width);
                minimum_needed += height;
            }
            // Bound to the minimum/maximum height
            var result = minimum_needed;
            if (entity.maximum.height > 0 and entity.maximum.height < minimum_needed) {
                result = entity.maximum.height;
            }
            result = @max(result, entity.minimum.height);
            return result;
        },

        .left_to_right_wrap => {
            var box: engine.BoxLayout = .init(
                available_width,
                entity.type.panel.spacing,
                entity.type.panel.spacing,
            );

            for (entity.type.panel.children.items) |child| {
                if (child.layout.position == .float) continue;
                if (child.visible == .hidden) continue;
                if (child.type == .expander) continue;

                const width = child.minimumNeededWidth(available_width);
                _ = box.place(width, child.rect.height);
            }
            box.finalise();
            return @max(
                box.final.height + entity.pad.top + entity.pad.bottom,
                entity.minimum.height,
            );
        },

        .centre, .left_to_right, .top_left, .top_right => {
            // centred all together
            // a, next to b, next c.
            //
            // Just need to know the highest/tallest child.
            var minimum_needed: f32 = 0; // Minimum child item height
            for (entity.type.panel.children.items) |child| {
                if (child.layout.position == .float) continue;
                if (child.visible == .hidden) continue;
                if (child.type == .expander) continue;

                minimum_needed = @max(
                    child.minimumNeededHeight(available_width),
                    minimum_needed,
                );
            }
            return @max(
                minimum_needed + entity.pad.top + entity.pad.bottom,
                entity.minimum.height,
            );
        },
    }
}

/// Discover the minimum needed for a particular object.
///
/// If the object has children, a `parent` object must check
/// the widths of its children.
///
/// If parent fills children left-to-right, we must add the heights.
/// If parent fills children top-to-bottom simply find the widest item.
pub inline fn minimumNeededWidth(
    self: *const Panel,
    entity: *const Entity,
    _: f32, //parent_inner_width
) f32 {
    return @max(entity.minimum.width, self.calculateMinimumNeededWidth(entity));
}

fn calculateMinimumNeededWidth(
    panel: *const Panel,
    entity: *const Entity,
) f32 {
    std.debug.assert(entity.type == .panel);
    if (entity.visible == .hidden) return 0;
    //if (parent.layout.position == .float) return 0;

    const available_width = entity.inner_width();

    switch (panel.direction) {
        .left_to_right, .left_to_right_wrap => {
            // Place each element left to right with possible
            // inner spacing and possible wrapping.
            var box: engine.BoxLayout = .init(
                if (panel.direction == .left_to_right_wrap) available_width else std.math.floatMax(f32),
                entity.type.panel.spacing,
                entity.type.panel.spacing,
            );

            for (panel.children.items) |child| {
                if (child.layout.position == .float) continue;
                if (child.visible == .hidden) continue;
                if (child.type == .expander) continue;

                const width = child.minimumNeededWidth(available_width);
                _ = box.place(width, child.rect.height);
            }
            box.finalise();
            return @max(
                box.final.width + entity.pad.left + entity.pad.right,
                entity.minimum.width,
            );
        },
        .centre, .top_to_bottom, .top_left, .top_right => {
            // a, centred upon b, centred upon c
            // a, then b underneath, thn c underneath...
            //
            // Need to just find maximum width item
            var minimum_needed: f32 = entity.pad.left + entity.pad.right;
            for (panel.children.items) |child| {
                if (child.layout.position == .float) continue;
                if (child.visible == .hidden) continue;
                if (child.type == .expander) continue;

                const child_width = child.minimumNeededWidth(available_width);
                if (false) {
                    trace("seek min width {s}->{s}/{t} curent_min={d} child_min={d} parent_inner={d}", .{
                        entity.name,
                        child.name,
                        child.type,
                        minimum_needed,
                        child_width,
                        available_width,
                    });
                }
                minimum_needed = @max(minimum_needed, child_width);
            }
            return @max(
                minimum_needed + entity.pad.left + entity.pad.right,
                entity.minimum.width,
            );
        },
    }
}

/// The parent has a known fixed width and height. Each of the child
/// objects can grow or shrink to fit in what the parent is providing.
pub fn layout(self: *Panel, display: *Display, parent: *Entity) bool {
    var resized = false;
    //trace("layout on {s}", .{parent.name});

    // Keep track of each expander in the panel. At the end, expand
    // each expander according to the leftover space.
    var expanders = BoundedArray(*Entity, 10){};
    var expander_weights: f32 = 0;

    // The parent panel now has its final/fixed size for this layout
    // pass. Child entities must work within what they are given here.

    // Growing child entities are simple, each child entity just takes
    // the maximum it is allowed.
    //
    // Shrinking child entities are harder, each child entity
    // must work out what is the minimum space it can work with.

    // # Step 1 - Size calculation (width/height)
    //
    // Children of this panel are either fixed positioned, growing,
    // or shrinking.
    //
    // - `.fixed` entities keep their requested rect `width` and `height` size.
    // - `.grows` entities take the width and height provided by the parent `rect`.
    // - `.shrinks` entities shrink to the `minimum` space they need.
    //

    const available_width = parent.inner_width();
    const available_height = parent.inner_height();
    const in_root = parent == &display.root;

    for (self.children.items) |entity| {
        if (entity.visible == .hidden) continue;

        const ignore_safe_area = entity.type == .panel and entity.type.panel.safe_area == .ignore_safe_area;

        // Top level panels may have safe area avoidance
        var height = available_height;
        var width = available_width;
        if (in_root and !ignore_safe_area) {
            width -= (display.safe_area.left + display.safe_area.right);
            height -= (display.safe_area.top + display.safe_area.bottom);
            if (width < 0) width = 0;
            if (height < 0) height = 0;
        }

        const child_resized = self.updateChildSize(
            entity,
            width,
            height,
        );

        if (child_resized) {
            resized = true;

            if (entity.on_resized.func != null) {
                trace("entity {s} resized. callback = {any}", .{
                    entity.name,
                    entity.on_resized.func != null,
                });
                _ = entity.on_resized.call(display, entity);
            }
        }

        if (entity.type == .expander) {
            if (entity.type.expander.weight <= 0) continue;
            expanders.appendAssumeCapacity(entity);
            expander_weights += entity.type.expander.weight;
        }
    }

    // Now that label entity sizes are known, do actual
    // layout of label text.
    for (self.children.items) |entity| {
        if (entity.visible == .hidden) continue;
        if (entity.type != .label) continue;

        const size = Label.layout(entity, available_width);
        if (entity.layout.x != .fixed) entity.rect.width = size.width;
        if (entity.layout.y != .fixed) entity.rect.height = size.height;
    }

    // Step 2 - Entity placement
    //
    // The parent panel dictates if the children align to start,
    // centre, or end. Growing/Shrinking children must be aligned
    // to the start, centre, or end. The parent panel decides if
    // the entities are left-to-right or top-to-bottom.

    self.scrollable.size.width = parent.minimum.width;
    self.scrollable.size.height = parent.minimum.height;
    switch (self.direction) {
        .left_to_right => self.placeChildrenLeftToRight(parent, expanders.slice(), expander_weights),
        .left_to_right_wrap => self.placeChildrenLeftToRightWrap(parent),
        .top_to_bottom => self.placeChildrenTopToBottom(parent, expanders.slice(), expander_weights),
        .centre => self.placeChildrenCentred(parent, if (in_root) .{ .x = display.safe_area.left, .y = display.safe_area.top } else null),
        .top_left => self.placeChildrenTopLeft(parent, if (in_root) .{ .x = display.safe_area.left, .y = display.safe_area.top } else null),
        .top_right => self.placeChildrenTopRight(parent, if (in_root) .{ .x = -display.safe_area.right, .y = display.safe_area.top } else null),
    }

    // Descend into child entities to allow child panels to also resize.
    for (self.children.items) |child| {
        if (child.visible == .hidden) continue;
        if (child.type == .panel) {
            //trace("parent({s}).layout() calling child({s}).layout()", .{ parent.name, child.name });
            if (child.type.panel.layout(display, child))
                resized = true;
        }
    }

    return resized;
}

/// Set the width and height of an entity. Check for invalid
/// entity configurations that cause confusing on screen effects.
inline fn updateChildSize(
    _: *Panel,
    entity: *Entity,
    available_width: f32,
    available_height: f32,
) bool {
    var child_resized = false;

    switch (entity.layout.x) {
        .grows => {
            //trace("do grow {s}. parent width={d}", .{ entity.name, parent.rect.width });
            // Grow to the parent width, not including padding.
            var new_width = available_width;
            if (entity.maximum.width > 0)
                new_width = @min(new_width, entity.maximum.width);

            if (entity.rect.width != new_width) {
                entity.rect.width = new_width;
                child_resized = true;
            }
        },
        .shrinks => {
            // Shrink to the smallest the children will allow.
            const new_width = entity.minimumNeededWidth(available_width);
            if (entity.rect.width != new_width) {
                entity.rect.width = new_width;
                child_resized = true;
            }
        },
        .fixed => {
            // No shrinking or growing applies.
        },
    }

    switch (entity.layout.y) {
        .grows => {
            // Grow to the parent height, not including padding.
            var new_height = available_height;
            if (entity.maximum.height > 0)
                new_height = @min(new_height, entity.maximum.height);

            if (entity.rect.height != new_height) {
                entity.rect.height = new_height;
                child_resized = true;
            }
        },
        .shrinks => {
            // Shrink to the smallest the children will allow.
            const new_height = entity.minimumNeededHeight(available_width);
            if (entity.rect.height != new_height) {
                entity.rect.height = new_height;
                child_resized = true;
            }
        },
        .fixed => {
            // No shrinking or growing applies.
        },
    }

    return child_resized;
}

inline fn placeChildrenCentred(
    panel: *Panel,
    parent: *Entity,
    safe_offset: ?Vector,
) void {
    const corner: Vector = .{
        .x = parent.rect.x + parent.pad.left,
        .y = parent.rect.y + parent.pad.top,
    };
    const inner_width = parent.inner_width();
    const inner_height = parent.inner_height();

    // Place every child entity in the centre of this panel.
    for (panel.children.items) |child| {
        if (child.layout.position == .float) continue;
        if (child.visible == .hidden) continue;
        if (child.type == .expander) {
            warn("expander panel '{s}' ignored due to centre layout.", .{parent.name});
            continue;
        }
        child.rect.x = corner.x + @round(inner_width / 2 - child.rect.width / 2);
        child.rect.y = corner.y + @round(inner_height / 2 - child.rect.height / 2);
        if (safe_offset) |offset| {
            if (child.type == .panel and child.type.panel.safe_area != .ignore_safe_area) {
                child.rect = child.rect.move(offset);
            }
        }
    }
    //TODO: Im not sure scroller detection is needed here or not

    //const needed_height = current.y - parent.y;
    //const overflow_height = (parent.y + parent.height) - current.y;
    //parent.type.panel.scrollable.size.height = @max(needed_height, parent.height);
}

inline fn placeChildrenTopLeft(
    _: *Panel,
    parent: *Entity,
    safe_offset: ?Vector,
) void {
    const corner: Vector = .{
        .x = parent.rect.x + parent.pad.left,
        .y = parent.rect.y + parent.pad.top,
    };
    for (parent.type.panel.children.items) |child| {
        if (child.layout.position == .float) continue;
        if (child.visible == .hidden) continue;
        if (child.type == .expander) {
            warn("expander panel '{s}' ignored due to top_left layout.", .{parent.name});
            continue;
        }
        child.rect.x = corner.x;
        child.rect.y = corner.y;
        if (safe_offset) |offset| {
            if (child.type == .panel and child.type.panel.safe_area != .ignore_safe_area) {
                child.rect = child.rect.move(offset);
            }
        }
    }
}

inline fn placeChildrenTopRight(
    _: *Panel,
    parent: *Entity,
    safe_offset: ?Vector,
) void {
    const corner: Vector = .{
        .x = parent.rect.x + parent.rect.width - parent.pad.right,
        .y = parent.rect.y + parent.pad.top,
    };
    for (parent.type.panel.children.items) |child| {
        if (child.layout.position == .float) continue;
        if (child.visible == .hidden) continue;
        if (child.type == .expander) {
            warn("expander panel '{s}' ignored due to top_right layout.", .{parent.name});
            continue;
        }

        child.rect.x = corner.x - child.rect.width;
        child.rect.y = corner.y;
        if (safe_offset) |offset| {
            if (child.type == .panel and child.type.panel.safe_area != .ignore_safe_area) {
                child.rect = child.rect.move(offset);
            }
        }
    }
}

inline fn placeChildrenTopToBottom(
    _: *Panel,
    parent: *Entity,
    expanders: []*Entity,
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
        const needed_space = needed_height + parent.pad.top + parent.pad.bottom;
        if (parent.rect.height > needed_space) {
            // Give each expander a percentage of the spare height area
            const spare_height = parent.rect.height - needed_space;
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
/// assuming no scrolling of the child entities. Offsets
/// applied at runtime.
inline fn placeChildrenLeftToRight(
    _: *Panel,
    parent: *Entity,
    expanders: []*Entity,
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
        //trace("drop {s} at position {d}x{d} size:{d}x{d}", .{
        //    child.name,
        //    child.rect.x,
        //    child.rect.y,
        //    child.rect.width,
        //    child.rect.height,
        //});

        if (child.type != .expander)
            current.x += child.rect.width;

        if (child.type != .expander) first = false;
    }
    const needed_width = current.x - parent.rect.x - parent.pad.left;
    const overflow_width = (parent.rect.x + parent.rect.width - parent.pad.right) - current.x;
    parent.type.panel.scrollable.size.width = @max(needed_width, parent.rect.width);

    // Child entities have been now been placed.
    // Do we need to push them apart with expanders?
    // Do we need to centre or right align them?

    if (expanders.len > 0 or expander_weights > 0) {
        // Expanders detected, push entities apart.
        trace("expanders: {s} has {any} expanders.  needed_width={d} available_width={d}", .{
            parent.name,
            expanders.len,
            needed_width,
            parent.rect.width,
        });
        const needed_space = needed_width + parent.pad.left + parent.pad.right;
        if (parent.rect.width > needed_width) {
            // Give each expander a percentage of the spare width area
            const spare_width = parent.rect.width - needed_space;
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
// assuming no scrolling of the child entities. Offsets
// applied at runtime. Track the height of each entity
// so wrapping can occur down to the next line.
inline fn placeChildrenLeftToRightWrap(
    panel: *Panel,
    entity: *Entity,
) void {
    var current: Vector = .{
        .x = entity.rect.x + entity.pad.left,
        .y = entity.rect.y + entity.pad.top,
    };

    var box: engine.BoxLayout = .init(
        entity.rect.width - entity.pad.left - entity.pad.right,
        entity.type.panel.spacing,
        entity.type.panel.spacing,
    );

    var line_start: usize = 0;
    var line_end: usize = 0;
    var current_y: f32 = current.y;
    for (entity.type.panel.children.items, 0..) |child, i| {
        if (child.layout.position == .float) continue;
        if (child.visible == .hidden) continue;
        if (child.type == .expander) continue;

        const item = box.place(child.rect.width, child.rect.height);
        child.rect.x = current.x + item.x;
        child.rect.y = current.y + item.y;
        if (child.rect.y != current_y) {
            current_y = child.rect.y;
            if (line_end >= line_start) {
                alignChildRow(
                    entity.type.panel.children.items[line_start .. line_end + 1],
                    entity.child_align.x,
                    panel.children.items[line_end].rect.x + panel.children.items[line_end].rect.width - panel.children.items[line_start].rect.x,
                    entity.inner_width(),
                );
            }
            line_start = i;
            line_end = i;
        } else {
            line_end = i;
        }
    }
    box.finalise();
    if (line_end >= line_start and line_start < panel.children.items.len) {
        alignChildRow(
            entity.type.panel.children.items[line_start .. line_end + 1],
            entity.child_align.x,
            panel.children.items[line_end].rect.x + panel.children.items[line_end].rect.width - panel.children.items[line_start].rect.x,
            entity.inner_width(),
        );
    }

    current.y += entity.pad.bottom;
    const needed_height = current.y - entity.rect.y;
    entity.type.panel.scrollable.size.height = @max(needed_height, entity.rect.height);
    //const overflow_height = parent.rect.height - needed_height;
}

/// Adjust the horizontal position of a line of entities based on
/// the `child_align` parameter.
pub fn alignChildRow(
    items: []*Entity,
    child_align: engine.Entity.LayoutAlign,
    width: f32,
    available_width: f32,
) void {
    switch (child_align) {
        .start => {},
        .centre => {
            // Align from top to work out how much space is left
            const adjust = (available_width - width) / 2;
            for (items) |child| {
                if (child.visible == .hidden) continue;
                if (child.layout.position == .float) continue;
                if (child.type == .expander) continue;
                child.rect.x += adjust;
            }
        },
        .end => {
            // Align from top to work out how much space is left
            const adjust = available_width - width;
            for (items) |child| {
                if (child.visible == .hidden) continue;
                if (child.layout.position == .float) continue;
                if (child.type == .expander) continue;
                child.rect.x += adjust;
            }
        },
    }
}

/// Inficate if a panel can grow into the safe area or not.
pub const SafeArea = enum { unspecified, ignore_safe_area, avoid_safe_area };

/// Indicate if a panel is part of the `choosePanel` set.
pub const Choosable = enum { unspecified, choosable, not_choosable };

pub const NullHandler = struct {};

test "safe_area" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var display = try headless_display(allocator, io, 200, 300, 2);
    defer display.destroy();

    const panel = try display.addPanel(.{
        .layout = .{ .x = .grows, .y = .grows },
        .pad = .{ .left = 1, .top = 2, .right = 3, .bottom = 4 },
        .child_align = .{ .x = .start, .y = .start },
        .type = .{ .panel = .{
            .direction = .top_left,
            .spacing = 5,
            .safe_area = .ignore_safe_area,
        } },
    });
    display.need_relayout = true;
    display.relayout();

    try eq(200, panel.rect.width);
    try eq(300, panel.rect.height);

    panel.type.panel.safe_area = .avoid_safe_area;
    display.safe_area.top = 6;
    display.safe_area.bottom = 7;
    display.safe_area.left = 8;
    display.safe_area.right = 9;
    display.need_relayout = true;
    display.relayout();

    try eq(200 - 8 - 9, panel.rect.width);
    try eq(300 - 6 - 7, panel.rect.height);
}

test "panel_button_layout" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var display = try headless_display(allocator, io, 200, 200, 2);
    defer display.destroy();

    //Test top to bottom, left to right, wrap and no wrap with simple boxes

    var handler: NullHandler = .{};
    const panel = try display.addPanel(.{
        .layout = .{ .x = .grows, .y = .grows },
        .pad = .{ .left = 1, .top = 2, .right = 3, .bottom = 4 },
        .child_align = .{ .x = .start, .y = .start },
        .type = .{ .panel = .{
            .direction = .top_left,
            .spacing = 5,
            .safe_area = .ignore_safe_area,
        } },
    });
    const b1 = try panel.append("button size width=90 height=90", NullHandler, &handler, display);
    const b2 = try panel.append("button size width=90 height=90", NullHandler, &handler, display);
    const b3 = try panel.append("button size width=90 height=90", NullHandler, &handler, display);

    panel.type.panel.direction = .top_left;
    display.need_relayout = true;
    display.relayout();
    try eq(.visible, panel.visible);
    try eq(.visible, panel.visible);
    try eq(1, b1.rect.x);
    try eq(2, b1.rect.y);
    try eq(1, b2.rect.x);
    try eq(2, b2.rect.y);
    try eq(1, b3.rect.x);
    try eq(2, b3.rect.y);

    panel.type.panel.direction = .top_right;
    display.need_relayout = true;
    display.relayout();
    try eq(.visible, panel.visible);
    try eq(.visible, panel.visible);
    try eq(display.root.rect.width - b1.rect.width - 3, b1.rect.x);
    try eq(2, b1.rect.y);
    try eq(display.root.rect.width - b2.rect.width - 3, b2.rect.x);
    try eq(2, b2.rect.y);
    try eq(display.root.rect.width - b3.rect.width - 3, b3.rect.x);
    try eq(2, b3.rect.y);

    panel.type.panel.direction = .centre;
    display.need_relayout = true;
    display.relayout();
    try eq(1 + ((display.root.rect.width - 1 - 3) / 2) - (b1.rect.width / 2), b1.rect.x);
    try eq(2 + (display.root.rect.height - 2 - 4) / 2 - b1.rect.height / 2, b1.rect.y);
    try eq(1 + (display.root.rect.width - 1 - 3) / 2 - b1.rect.width / 2, b2.rect.x);
    try eq(2 + (display.root.rect.height - 2 - 4) / 2 - b1.rect.height / 2, b2.rect.y);
    try eq(1 + (display.root.rect.width - 1 - 3) / 2 - b1.rect.width / 2, b3.rect.x);
    try eq(2 + (display.root.rect.height - 2 - 4) / 2 - b1.rect.height / 2, b3.rect.y);

    panel.type.panel.direction = .left_to_right;
    display.need_relayout = true;
    display.relayout();
    try eq(1, b1.rect.x);
    try eq(2, b1.rect.y);
    try eq(1 + b1.rect.width + panel.type.panel.spacing, b2.rect.x);
    try eq(2, b2.rect.y);
    try eq(1 + b1.rect.width * 2 + panel.type.panel.spacing * 2, b3.rect.x);
    try eq(2, b3.rect.y);

    panel.type.panel.direction = .left_to_right_wrap;
    display.need_relayout = true;
    display.relayout();
    try eq(1, b1.rect.x);
    try eq(2, b1.rect.y);
    try eq(1 + b1.rect.width + panel.type.panel.spacing, b2.rect.x);
    try eq(2, b2.rect.y);
    try eq(1, b3.rect.x);
    try eq(2 + panel.type.panel.spacing + b1.rect.height, b3.rect.y);

    panel.type.panel.direction = .top_to_bottom;
    display.need_relayout = true;
    display.relayout();
    try eq(1, b1.rect.x);
    try eq(2, b1.rect.y);
    try eq(1, b2.rect.x);
    try eq(2 + panel.type.panel.spacing + b1.rect.height, b2.rect.y);
    try eq(1, b3.rect.x);
    try eq(2 + panel.type.panel.spacing * 2 + b1.rect.height * 2, b3.rect.y);
}

test "panel_label_layout" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var display = try headless_display(allocator, io, 200, 200, 2);
    defer display.destroy();

    //Test top to bottom, left to right, wrap and no wrap with simple boxes

    const spacing = 5;
    var handler: NullHandler = .{};
    const panel = try display.addPanel(.{
        .layout = .{ .x = .grows, .y = .grows },
        .pad = .{ .left = 1, .top = 2, .right = 3, .bottom = 4 },
        .child_align = .{ .x = .start, .y = .start },
        .type = .{ .panel = .{
            .direction = .top_left,
            .spacing = spacing,
            .safe_area = .ignore_safe_area,
        } },
    });
    const b1 = try panel.append("label text \"This\" layout shrinks shrinks", NullHandler, &handler, display);
    const b2 = try panel.append("label text \"word\" layout shrinks shrinks", NullHandler, &handler, display);
    const b3 = try panel.append("label text \"fish\" layout shrinks shrinks", NullHandler, &handler, display);

    panel.type.panel.direction = .left_to_right;
    display.need_relayout = true;
    display.relayout();
    try eq(1, b1.rect.x);
    try eq(2, b1.rect.y);
    try std.testing.expectEqualStrings("This", b1.type.label.text);
    try eq(38, b1.rect.width);

    try eq(1 + b1.rect.width + panel.type.panel.spacing, b2.rect.x);
    try eq(2, b2.rect.y);
    try eq(1 + b1.rect.width + spacing, b2.rect.x);
    try eq(42, b2.rect.width);

    try eq(1 + b1.rect.width + b2.rect.width + spacing * 2, b3.rect.x);
    try eq(2, b3.rect.y);
    try eq(33, b3.rect.width);
}

test "root_panel_alignment" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    // TODO: 10->22
    //var display = try Display.create(allocator, io, test_config);
    //defer display.destroy();

    var display = try headless_display(allocator, io, 1000, 1600, 2);
    defer display.destroy();

    try display.setDefaultFont("Roboto-Light", .unknown, .{});
    try eq(4, display.fonts.items.len);
    display.root.rect.width = 300;
    display.root.rect.height = 200;

    const panel = try display.addPanel(.{
        .type = .{ .panel = .{ .direction = .top_to_bottom } },
        .minimum = .{ .width = 100, .height = 120 },
        .maximum = .{ .width = 200, .height = 160 },
        .layout = .{ .x = .grows, .y = .grows },
    });

    panel.layout = .{ .x = .grows, .y = .grows };
    display.need_relayout = true;
    display.relayout();
    try eq(200, panel.rect.width);
    try eq(160, panel.rect.height);

    panel.layout = .{ .x = .shrinks, .y = .shrinks };
    display.need_relayout = true;
    display.relayout();
    try eq(100, panel.rect.width);
    try eq(120, panel.rect.height);

    // Will adding a child stretch it correctly
    const child = try panel.add(.{
        .name = "picture",
        .rect = .{ .width = 110, .height = 130 },
        .layout = .{ .x = .fixed, .y = .fixed },
        .type = .{ .sprite = .{} },
    }, display);
    display.need_relayout = true;
    display.relayout();
    try eq(110, child.rect.width);
    try eq(130, child.rect.height);
    try eq(110, panel.rect.width);
    try eq(130, panel.rect.height);

    try std.testing.expect(display.root.getChild(0) != null);
    try std.testing.expect(display.root.getChild(100) == null);
    try std.testing.expect(panel.getChildByName("picture") != null);
    try std.testing.expect(panel.getChildByName("microprocessor") == null);
}

test "panel_padding" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    // TODO: 10->22
    //var display = try Display.create(allocator, io, test_config);
    //defer display.destroy();

    var display = try headless_display(allocator, io, 1000, 1600, 2);
    defer display.destroy();

    try display.setDefaultFont("Roboto-Light", .unknown, .{});
    try eq(4, display.fonts.items.len);
    display.root.rect.width = 300;
    display.root.rect.height = 200;
    display.root.minimum.width = 300;
    display.root.minimum.height = 200;
    display.root.maximum.width = 300;
    display.root.maximum.height = 200;

    const panel = try display.addPanel(.{
        .type = .{ .panel = .{
            .direction = .top_to_bottom,
            .choosable = .choosable,
            .safe_area = .ignore_safe_area,
        } },
        .layout = .{ .x = .grows, .y = .grows },
    });
    display.need_relayout = true;
    display.relayout();

    try eq(300, panel.rect.width);
    try eq(200, panel.rect.height);

    const child = try panel.add(.{
        .type = .{ .panel = .{ .direction = .top_to_bottom } },
        .rect = .{ .width = 120, .height = 80 },
        .layout = .{ .x = .fixed, .y = .fixed },
    }, display);

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
}

test "centre_text_bug" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var display = try headless_display(allocator, io, 600, 800, 2);
    defer display.destroy();

    const panel = try display.addPanel(.{
        .type = .{
            .panel = .{
                .direction = .left_to_right,
                .spacing = 5,
                .safe_area = .ignore_safe_area,
                .choosable = .choosable,
            },
        },
        .layout = .{ .x = .grows, .y = .grows },
    });
    display.need_relayout = true;
    display.relayout();

    try eq(80, display.safe_area.top);
    try eq(0, display.safe_area.left);
    try eq(0, display.safe_area.right);
    try eq(0, display.safe_area.bottom);
    try eq(600, display.root.rect.width);
    try eq(600, display.root.inner_width());
    try eq(600, panel.rect.width);
    try eq(800, panel.rect.height);

    var footer = try panel.add(.{
        .name = "panel_left_to_right",
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
    }, display);
    display.need_relayout = true;
    display.relayout();
    try eq(180, footer.rect.width);
    // No children yet, so height should be padding only
    try eq(15 + 11, footer.rect.height);

    const icon = try footer.add(.{
        .name = "test.icon",
        .focus = .never_focus,
        .child_align = .{ .x = .centre },
        .rect = .{ .width = 50, .height = 50 },
        .minimum = .{ .width = 50, .height = 50 },
        .maximum = .{ .width = 50, .height = 50 },
        .layout = .{ .x = .shrinks, .y = .shrinks },
        .type = .{ .sprite = .{} },
        .pad = .{ .left = 15, .right = 15, .top = 25, .bottom = 0 },
    }, display);
    display.need_relayout = true;
    display.relayout();
    try eq(50, icon.rect.width);
    try eq(50, icon.rect.height);

    // The text is just a little smaller than the minmum width, so we can
    // test child start, centre, end align in child panels.
    const label = try footer.add(.{
        .name = "test.label",
        .focus = .accessibility_focus,
        .style = .tinted,
        .minimum = .{ .width = 250 },
        .layout = .{ .x = .shrinks, .y = .shrinks },
        .child_align = .{ .x = .centre },
        .type = .{ .label = .{
            .text = "Yes or no?",
            .text_size = .normal,
        } },
        .pad = .{ .left = 0, .right = 1, .top = 0, .bottom = 0 },
    }, display);

    {
        const full_width = 15 + 50 + 12 + 250 + 15;
        {
            panel.child_align.x = .start;
            display.need_relayout = true;
            display.relayout();
            try eq(250, label.minimumNeededWidth(1000));
            try eq(250, Label.layout(label, 1000).minimum_width);
            try eq(250, Label.layout(label, 1000).width);
            try eq(250, label.rect.width); // text smaller than minimum
            try eq(22, label.rect.height);
            try eq(full_width, footer.rect.width);
            try eq(icon.rect.x, footer.rect.x + footer.pad.left);
            try eq(icon.rect.y, footer.rect.y + footer.pad.top);
            try eq(label.rect.x, footer.rect.x + footer.pad.left + 12 + icon.rect.width);
            try eq(label.rect.y, footer.rect.y + footer.pad.top);
            const word1 = &label.type.label.elements.items[0];
            const word2 = &label.type.label.elements.items[1];
            const word3 = &label.type.label.elements.items[2];
            const space = label.type.label.text_size.word_spacing();
            const text_width = word1.location.width + space + word2.location.width + space + word3.location.width;
            // Text is centred, so it doesnt start at the start
            try eq(78, word1.location.x);
            try eq(0, word1.location.y);
            // Text is left aligned, so does start at the start
            label.setAlign(.start, .start);
            display.need_relayout = true;
            display.relayout();
            try eq(0, word1.location.x);
            try eq(0, word1.location.y);
            try eq(text_width, word3.location.x + word3.location.width);
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
            const entity = label.type.label.elements.items[0];
            try eq(0, entity.location.x);
            try eq(0, entity.location.y);
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
            const entity = label.type.label.elements.items[0];
            try eq(0, entity.location.x);
            try eq(0, entity.location.y);
        }
    }
}

const std = @import("std");
const ArrayListUnmanaged = std.ArrayListUnmanaged;
const eq = std.testing.expectEqual;

const praxis = @import("praxis");
const BoundedArray = praxis.BoundedArray;

const engine = @import("engine.zig");
const err = engine.log.err;
const warn = engine.log.warn;
const info = engine.log.info;
const debug = engine.log.debug;
const trace = engine.log.trace;
const Display = engine.Display;
const Entity = engine.Entity;
const Error = engine.Error;
const Font = engine.Font;
const Label = @import("Label.zig");

const Clip = Entity.Clip;
const LayoutDirection = Entity.LayoutDirection;
const Scroller = Entity.Scroller;
const Size = Entity.Size;
const TextSize = Entity.TextSize;
const Vector = Entity.Vector;

const test_config = engine.test_config;
const headless_display = engine.headless_display;
