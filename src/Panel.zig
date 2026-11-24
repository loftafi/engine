/// An entity that holds other entities and may become scrollable.
pub const Panel = @This();

/// Entities to draw inside this panel.
children: ArrayList(*Entity) = .empty,

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

pub fn firstChild(self: *const Panel) ?*Entity {
    return if (self.children.items.len > 0) self.children.items[0] else null;
}

pub fn lastChild(self: *const Panel) ?*Entity {
    return if (self.children.items.len > 0) self.children.items[self.children.items.len - 1] else null;
}

/// Return true if this panel can be interacted with through user
/// driven event handlers..
pub inline fn clickable(self: *const Panel) bool {
    return self.on_ui_event.func != null or self.on_pressed.func != null;
}

pub inline fn format(
    self: *const Panel,
    out: *std.Io.Writer,
) std.Io.Writer.Error!void {
    if (self.choosable != .unspecified) {
        _ = try out.write(" ");
        _ = try out.write(@tagName(self.choosable));
    }
    if (self.safe_area != .unspecified) {
        _ = try out.write(" ");
        _ = try out.write(@tagName(self.safe_area));
    }
    _ = try out.write(" direction=");
    _ = try out.write(@tagName(self.direction));

    if (self.scrollable.scroll.x or self.scrollable.scroll.y) {
        if (self.scrollable.scroll.x)
            _ = try out.print(" scroll.x={any}", .{ self.scrollable.scroll.x });
        if (self.scrollable.scroll.y)
            _ = try out.print(" scroll.y={any}", .{ self.scrollable.scroll.y });
        _ = try out.print(" scroll.inner={d}x{d}", .{ self.scrollable.size.width, self.scrollable.size.height });
    }
    if (self.spacing > 0) {
        _ = try out.print(" spacing={d}", .{self.spacing});
    }
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
    var clip = parent_clip;
    if (self.scrollable.scroll.x or self.scrollable.scroll.y) {
        clip = if (clip == null)
            entity.rect.bounds()
        else
            clip.?.intersect(entity.rect.bounds());
    }

    for (self.children.items) |child| {
        child.draw(display, scroll_offset, clip);
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
        .vertical => {
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

        .horizontal_wrap => {
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

        .centre, .horizontal, .top_left, .bottom_left, .top_right => {
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
        .horizontal, .horizontal_wrap => {
            // Place each element left to right with possible
            // inner spacing and possible wrapping.
            var box: engine.BoxLayout = .init(
                if (panel.direction == .horizontal_wrap) available_width else std.math.floatMax(f32),
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
        .centre, .vertical, .top_left, .bottom_left, .top_right => {
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

pub const Flexible = struct {
    percent: f32,
    size: *f32, // width or height
    initial_size: f32, // width or height
};
pub const max_expandables = 30;

/// The parent has a known fixed width and height. Each of the child
/// objects can grow or shrink to fit in what the parent is providing.
pub fn layout(self: *Panel, display: *Display, parent: *Entity) void {
    //trace("layout on {s}", .{parent.name});

    // Keep track of each expander in the panel. At the end, expand
    // each expander according to the leftover space.
    var expandables: [max_expandables]Flexible = undefined;
    var expandable_count: usize = 0;
    var scrollables: [max_expandables]Flexible = undefined;
    var scrollable_count: usize = 0;

    // The parent panel now has its final/fixed size for this layout.
    // Place child entities inside this space.

    // # Step 1 - Size calculation (width/height)
    //
    // - `.fixed` entities keep their requested rect `width` and `height` size.
    // - `.shrinks` entities shrink to the `minimum` space they need.
    // - `.grows` entities shrink to `mimimum` space they need. At the end
    //   they may grow to use remaining space.

    const available_width = parent.inner_width();
    const available_height = parent.inner_height();
    const in_root = parent == &display.root;

    // Within the parent inner area, reserve space for fixed entities,
    // shrinks entities, and inter-entity `spacing`.
    var reserved_space: f32 = 0;

    var previous_type: Entity.Type = .expander;

    for (self.children.items) |entity| {
        if (entity.visible == .hidden) continue;
        const ignore_safe_area = entity.type == .panel and entity.type.panel.safe_area == .ignore_safe_area;
        if (entity.layout.position == .float) {
            floatLayout(display, entity, in_root and ignore_safe_area);
            continue;
        }

        if (entity.type != .expander and previous_type != .expander) {
            reserved_space += parent.type.panel.spacing;
        }
        previous_type = entity.type;

        // Top level panels may have safe area avoidance
        var inner_height = available_height;
        var inner_width = available_width;
        if (in_root and !ignore_safe_area) {
            inner_width -= (display.safe_area.left + display.safe_area.right);
            inner_height -= (display.safe_area.top + display.safe_area.bottom);
            if (inner_width < 0) inner_width = 0;
            if (inner_height < 0) inner_height = 0;
        }

        // Cacluate the initial/placeholder widths for each child.
        switch (entity.layout.x) {
            .shrinks => {
                const new_width = entity.minimumNeededWidth(inner_width);
                if (new_width != entity.rect.width) {
                    entity.rect.width = new_width;
                    if (entity.on_resized.func != null)
                        _ = entity.on_resized.call(display, entity);
                }
                reserved_space += entity.rect.width;
            },
            .grows => {
                var new_width = entity.minimumNeededWidth(inner_width);
                if (in_root) new_width = inner_width;

                if (self.direction == .horizontal) {
                    expandables[expandable_count] = .{
                        .percent = entity.layout.weight_percent,
                        .size = &entity.rect.width,
                        .initial_size = entity.rect.width,
                    };
                    expandable_count += 1;
                    //err("expandable width={d} -> {d} ec+>{d}", .{ entity.rect.width, new_width, expandable_count});
                } else if (self.direction == .horizontal_wrap) {
                    // Not expandable
                } else {
                    new_width = inner_width;
                }
                new_width = engine.clamp(entity.minimum.width, new_width, entity.maximum.width);

                if (new_width != entity.rect.width) {
                    entity.rect.width = new_width;
                    if (self.direction != .horizontal and entity.on_resized.func != null)
                        _ = entity.on_resized.call(display, entity);
                }

                // Collect scrollables that can be shrunk
                if (new_width > 0) switch (entity.type) {
                    inline .panel, .text_area => |*s| {
                        if (s.scrollable.scroll.x) {
                            scrollables[scrollable_count] = .{
                                .percent = entity.layout.weight_percent,
                                .size = &entity.rect.width,
                                .initial_size = entity.rect.width,
                            };
                            scrollable_count += 1;
                            s.scrollable.size.width = entity.rect.width;
                            s.scrollable.size.height = entity.rect.height;
                        } else if (s.scrollable.scroll.y) {
                            scrollables[scrollable_count] = .{
                                .percent = entity.layout.weight_percent,
                                .size = &entity.rect.height,
                                .initial_size = entity.rect.height,
                            };
                            scrollable_count += 1;
                            s.scrollable.size.width = entity.rect.width;
                            s.scrollable.size.height = entity.rect.height;
                        }
                    },
                    else => {},
                };
            },
            .fixed => {
                reserved_space += entity.rect.width;
            },
        }

        // Cacluate the initial/placeholder heights for each child.
        switch (entity.layout.y) {
            .shrinks => {
                const new_height = entity.minimumNeededHeight(available_width);
                if (new_height != entity.rect.height) {
                    entity.rect.height = new_height;
                    if (entity.on_resized.func != null)
                        _ = entity.on_resized.call(display, entity);
                }
                reserved_space += entity.rect.height;
            },
            .grows => {
                var new_height = entity.minimumNeededHeight(inner_width);
                if (in_root) new_height = inner_height;

                if (self.direction == .vertical) {
                    expandables[expandable_count] = .{
                        .percent = entity.layout.weight_percent,
                        .size = &entity.rect.height,
                        .initial_size = entity.rect.height,
                    };
                    expandable_count += 1;
                    //err("expandable height={d} -> {d} ec+>{d}", .{ entity.rect.height, new_height, expandable_count});
                } else {
                    new_height = inner_height;
                }
                new_height = engine.clamp(entity.minimum.height, new_height, entity.maximum.height);

                if (new_height != entity.rect.height) {
                    entity.rect.height = new_height;
                    if (self.direction != .vertical and entity.on_resized.func != null)
                        _ = entity.on_resized.call(display, entity);
                }

                // Collect scrollables that can be shrunk
                if (new_height > 0) switch (entity.type) {
                    inline .panel, .text_area => |*s| {
                        if (s.scrollable.scroll.x) {
                            scrollables[scrollable_count] = .{
                                .percent = entity.layout.weight_percent,
                                .size = &entity.rect.width,
                                .initial_size = entity.rect.width,
                            };
                            scrollable_count += 1;
                            s.scrollable.size.width = entity.rect.width;
                            s.scrollable.size.height = entity.rect.height;
                        } else if (s.scrollable.scroll.y) {
                            scrollables[scrollable_count] = .{
                                .percent = entity.layout.weight_percent,
                                .size = &entity.rect.height,
                                .initial_size = entity.rect.height,
                            };
                            scrollable_count += 1;
                            s.scrollable.size.width = entity.rect.width;
                            s.scrollable.size.height = entity.rect.height;
                        }
                    },
                    else => {},
                };
            },
            .fixed => {
                reserved_space += entity.rect.height;
            },
        }
    }

    if (expandable_count > 0 and (self.direction == .horizontal or self.direction == .vertical)) {
        trace("parent name={s} has expandables reserved={d}", .{
            parent.name,
            reserved_space,
        });
    }

    // At this point, everything is sized and placed according
    // to the absolute minimum space it desires. Depending on the
    // panels layout algorithm, flexible items may grow or shrink.

    // Step 2 - Entity placement
    //
    // The parent panel dictates if the children align to start,
    // centre, or end. Growing/Shrinking children must be aligned
    // to the start, centre, or end. The parent panel decides if
    // the entities are left-to-right or top-to-bottom.

    switch (self.direction) {
        .horizontal_wrap => self.placeHorizontalWrap(parent),
        .horizontal => self.placeHorizontal(
            parent,
            reserved_space,
            scrollables[0..scrollable_count],
            expandables[0..expandable_count],
        ),
        .vertical => self.placeVertical(
            parent,
            reserved_space,
            scrollables[0..scrollable_count],
            expandables[0..expandable_count],
        ),
        .centre => self.placeCentred(
            parent,
            if (in_root) .{ .x = display.safe_area.left, .y = display.safe_area.top } else null,
            scrollables[0..scrollable_count],
        ),
        .top_left => self.placeTopLeft(
            parent,
            if (in_root) .{ .x = display.safe_area.left, .y = display.safe_area.top } else null,
            scrollables[0..scrollable_count],
        ),
        .top_right => self.placeTopRight(
            parent,
            if (in_root) .{ .x = -display.safe_area.right, .y = display.safe_area.top } else null,
            scrollables[0..scrollable_count],
        ),
        .bottom_left => self.placeBottomLeft(
            parent,
            if (in_root) .{ .x = -display.safe_area.right, .y = display.safe_area.top } else null,
            scrollables[0..scrollable_count],
        ),
    }

    // Now that label entity sizes are known, do actual
    // layout of label text.
    for (self.children.items) |entity| {
        if (entity.visible == .hidden) continue;
        if (entity.layout.position == .float) continue;
        switch (entity.type) {
            .label => {
                const size = Label.layout(entity, available_width);
                if (entity.layout.x != .fixed) entity.rect.width = @max(size.width, entity.minimum.width);
                if (entity.layout.y != .fixed) entity.rect.height = @max(size.height, entity.minimum.height);
            },
            .text_area => {
                const size = TextArea.layout(entity, available_width);
                if (entity.layout.x != .fixed) entity.rect.width = @max(size.width, entity.minimum.width);
                if (entity.layout.y != .fixed) entity.rect.height = @max(size.height, entity.minimum.height);
            },
            .panel => {
                entity.type.panel.layout(display, entity);
            },
            else => {},
        }
    }
}

/// If a float is found inside a panel, it is drawn out of the
/// entity tree.
fn floatLayout(display: *Display, entity: *Entity, avoid_safe_area: bool) void {
    if (entity.type == .panel) {
        entity.type.panel.layout(display, entity);
        //return;
    }
    _ = avoid_safe_area;
    switch (entity.layout.x) {
        .shrinks => {
            const new_width = entity.minimumNeededWidth(display.root.rect.width);
            if (new_width != entity.rect.width) {
                entity.rect.width = new_width;
            }
        },
        .grows => {
            const new_width = clamp(
                entity.minimum.width,
                display.root.rect.width,
                entity.minimum.height,
            );
            if (new_width != entity.rect.width) {
                entity.rect.width = new_width;
            }
        },
        .fixed => {},
    }
    switch (entity.layout.y) {
        .shrinks => {
            const new_height = entity.minimumNeededHeight(display.root.rect.width);
            if (new_height != entity.rect.height) {
                entity.rect.height = new_height;
            }
        },
        .grows => {
            const new_height = clamp(
                entity.minimum.width,
                display.root.rect.width,
                entity.minimum.height,
            );
            if (new_height != entity.rect.height) {
                entity.rect.height = new_height;
            }
        },
        .fixed => {},
    }
}

inline fn placeCentred(
    panel: *Panel,
    parent: *Entity,
    safe_offset: ?Vector,
    scrollables: []Flexible,
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
                child.rect = child.rect.move(.{
                    .x = offset.x / 2,
                    .y = offset.y / 2,
                });
            }
        }
    }

    // Scrollable children may need to become scrollable or non scrollable.
    _ = scrollables;

    //const needed_height = current.y - parent.y;
    //const overflow_height = (parent.y + parent.height) - current.y;
    //parent.type.panel.scrollable.size.height = @max(needed_height, parent.height);
}

inline fn placeTopLeft(
    _: *Panel,
    parent: *Entity,
    safe_offset: ?Vector,
    scrollables: []Flexible,
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

    // Scrollable children may need to become scrollable or non scrollable.
    _ = scrollables;
}

inline fn placeBottomLeft(
    _: *Panel,
    parent: *Entity,
    safe_offset: ?Vector,
    scrollables: []Flexible,
) void {
    const corner: Vector = .{
        .x = parent.rect.x + parent.pad.left,
        .y = parent.rect.y + parent.rect.height - parent.pad.bottom,
    };
    for (parent.type.panel.children.items) |child| {
        if (child.layout.position == .float) continue;
        if (child.visible == .hidden) continue;
        if (child.type == .expander) {
            warn("expander panel '{s}' ignored due to bottom_left layout.", .{parent.name});
            continue;
        }
        child.rect.x = corner.x;
        child.rect.y = corner.y - child.rect.height;
        if (safe_offset) |offset| {
            if (child.type == .panel and child.type.panel.safe_area != .ignore_safe_area) {
                child.rect = child.rect.move(offset);
            }
        }
    }

    // Scrollable children may need to become scrollable or non scrollable.
    _ = scrollables;
}

inline fn placeTopRight(
    _: *Panel,
    parent: *Entity,
    safe_offset: ?Vector,
    scrollables: []Flexible,
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

    // Scrollable children may need to become scrollable or non scrollable.
    _ = scrollables;
}

inline fn placeVertical(
    _: *Panel,
    parent: *Entity,
    reserved_space: f32,
    scrollables: []Flexible,
    expandables: []Flexible,
) void {
    var current: Vector = .{
        .x = parent.rect.x + parent.pad.left,
        .y = parent.rect.y + parent.pad.top,
    };

    // Do an initial layout not including expansion or shrinking of scrollers
    // to discover if extra spaces is needed or if we are overflowing.
    var previous_type: Entity.Type = .expander;
    for (parent.type.panel.children.items) |child| {
        if (child.visible == .hidden) continue;
        if (child.layout.position == .float) continue;
        if (previous_type != .expander and child.type != .expander)
            current.y += parent.type.panel.spacing;
        previous_type = child.type;
        child.rect.x = current.x;
        child.rect.y = current.y;
        if (child.type != .expander) current.y += child.rect.height;
    }
    const needed_space = current.y - parent.rect.y - parent.pad.top;
    const trailing_space = (parent.rect.y + parent.rect.height - parent.pad.bottom) - current.y;
    parent.type.panel.scrollable.size.height = @max(needed_space, parent.rect.height);

    if (expandables.len > 0) {
        trace("placeVertical expandables={d} trailing_space={d} reserved={d}", .{ expandables.len, trailing_space, reserved_space });
    }

    // Child entities have been now been placed, so handle alignment:
    // Do we need to push them apart with expanders?
    // Do we need to start, centre or end align them?

    if (trailing_space > 0 and expandables.len > 0) {
        // Need to expand, Give each expandable a percentage of spare space
        for (expandables) |expandable| {
            expandable.size.* += @trunc(trailing_space * expandable.percent);
        }
        // Revise each child's y position due to expandables resizing.
        var new_y: f32 = parent.rect.y + parent.pad.top;
        previous_type = .expander;
        for (parent.type.panel.children.items) |child| {
            // Relayout start to end using expander sizes
            if (child.visible == .hidden) continue;
            if (child.layout.position == .float) continue;
            if (previous_type != .expander and child.type != .expander)
                new_y += parent.type.panel.spacing;
            previous_type = child.type;
            child.rect.y = new_y;
            new_y += child.rect.height;
        }
    } else if (trailing_space > 0) {
        // There is spare space, but no expandables to fill the spare space.
        // Align the items inside the spare space.
        switch (parent.child_align.y) {
            .start => {},
            .centre => {
                // Align from top to work out how much space is left
                var new_y: f32 = parent.rect.y + parent.pad.top + (trailing_space / 2.0);
                previous_type = .expander;
                for (parent.type.panel.children.items) |child| {
                    if (child.visible == .hidden) continue;
                    if (child.layout.position == .float) continue;
                    if (previous_type != .expander and child.type != .expander)
                        new_y += parent.type.panel.spacing;
                    previous_type = child.type;
                    child.rect.y = new_y;
                    new_y += child.rect.height;
                }
            },
            .end => {
                // Workout the offset between the initial draw position
                // and the overflow (underflow) to adjust for.
                var new_y: f32 = parent.rect.y + parent.pad.top + trailing_space;
                previous_type = .expander;
                for (parent.type.panel.children.items) |child| {
                    if (child.visible == .hidden) continue;
                    if (child.layout.position == .float) continue;
                    if (previous_type != .expander and child.type != .expander)
                        new_y += parent.type.panel.spacing;
                    previous_type = child.type;
                    child.rect.y = new_y;
                    new_y += child.rect.height;
                }
                parent.type.panel.scrollable.size.width = @max(
                    needed_space,
                    parent.rect.width,
                );
            },
        }
    } else if (trailing_space < 0) {
        // Content does not fit. Can we shrink anything?
        //info("vertical {s} {s} - needed={d} available={d} unused_space={d}", .{
        //    parent.name,
        //    @tagName(parent.type),
        //    needed_space, // Not including padding
        //    parent.inner_height(),
        //    trailing_space,
        //});
        // There is no spare space, are there scrollables that can shrink?
        if (scrollables.len > 0) {
            var total_weights: f32 = 0;
            for (scrollables) |scrollable|
                total_weights += scrollable.percent;
            for (scrollables) |scrollable| {
                const percent = scrollable.percent / total_weights;
                scrollable.size.* += @trunc(trailing_space * percent);
            }
            // Revise each child's y position because of scrollable resizing.
            var new_y: f32 = parent.rect.y + parent.pad.top;
            previous_type = .expander;
            for (parent.type.panel.children.items) |child| {
                // Relayout top to bottom using expander sizes
                if (child.visible == .hidden) continue;
                if (child.layout.position == .float) continue;
                if (previous_type != .expander and child.type != .expander)
                    new_y += parent.type.panel.spacing;
                previous_type = child.type;
                child.rect.y = new_y;
                new_y += child.rect.height;
            }
        }
    }
}

pub inline fn floatFromIntDiv(a: u8, b: usize) f32 {
    return @as(f32, @floatFromInt(a)) / @as(f32, @floatFromInt(b));
}

/// Draw panel children from top left corner of the panel
/// assuming no scrolling of the child entities. Offsets
/// applied at runtime.
inline fn placeHorizontal(
    _: *Panel,
    parent: *Entity,
    reserved_space: f32,
    scrollables: []Flexible,
    expandables: []Flexible,
) void {
    var current: Vector = .{
        .x = parent.rect.x + parent.pad.left,
        .y = parent.rect.y + parent.pad.top,
    };

    // Do an initial layout not including expansion or shrinking of scrollers
    // to discover if extra spaces is needed or if we are overflowing.
    var previous_type: Entity.Type = .expander;
    for (parent.type.panel.children.items) |child| {
        if (child.visible == .hidden) continue;
        if (child.layout.position == .float) continue;
        if (previous_type != .expander and child.type != .expander)
            current.x += parent.type.panel.spacing;
        previous_type = child.type;
        child.rect.x = current.x;
        child.rect.y = current.y;
        if (child.type != .expander) current.x += child.rect.width;
    }
    const needed_space = current.x - parent.rect.x - parent.pad.left;
    const trailing_space = (parent.rect.x + parent.rect.width - parent.pad.right) - current.x;
    parent.type.panel.scrollable.size.width = @max(needed_space, parent.rect.width);

    if (expandables.len > 0) {
        trace("placeHorizontal expandables={d} trailing_space={d} reserved={d}", .{ expandables.len, trailing_space, reserved_space });
    }

    // Child entities have been now been placed, so handle alignment:
    // Do we need to push them apart with expanders?
    // Do we need to start, centre or end align them?

    if (trailing_space > 0 and expandables.len > 0) {
        // Need to expand, Give each expandable a percentage of spare space
        for (expandables) |expandable| {
            expandable.size.* += @trunc(trailing_space * expandable.percent);
        }
        // Revise each child's x position due to expandables resizing.
        var new_x: f32 = parent.rect.x + parent.pad.left;
        previous_type = .expander;
        for (parent.type.panel.children.items) |child| {
            // Relayout start to end using expander sizes
            if (child.visible == .hidden) continue;
            if (child.layout.position == .float) continue;
            if (previous_type != .expander and child.type != .expander)
                new_x += parent.type.panel.spacing;
            previous_type = child.type;
            child.rect.x = new_x;
            new_x += child.rect.width;
        }
    } else if (trailing_space > 0) {
        // There is spare space, but no expandables to fill the spare space.
        // Align the items inside the spare space.
        switch (parent.child_align.x) {
            .start => {},
            .centre => {
                // Align from top to work out how much space is left
                var new_x: f32 = parent.rect.x + parent.pad.left + @round(trailing_space / 2.0);
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
                var new_x: f32 = parent.rect.x + parent.pad.left + trailing_space;
                for (parent.type.panel.children.items) |child| {
                    if (child.visible == .hidden) continue;
                    if (child.layout.position == .float) continue;
                    child.rect.x = new_x;
                    new_x += child.rect.width + parent.type.panel.spacing;
                }
                parent.type.panel.scrollable.size.width = @max(
                    needed_space,
                    parent.rect.width,
                );
            },
        }
    } else if (trailing_space < 0) {
        // Content does not fit. Can we shrink anything?
        if (scrollables.len > 0) {
            var total_weights: f32 = 0;
            for (scrollables) |scrollable|
                total_weights += scrollable.percent;
            for (scrollables) |scrollable| {
                const percent = scrollable.percent / total_weights;
                scrollable.size.* += @trunc(trailing_space * percent);
                //trace("fix scrollable weight={d} percent={d} size={d}", .{ scrollable.weight, percent, scrollable.size.* });
            }
            // Revise each child's x position because of scrollable resizing.
            var new_x: f32 = parent.rect.x + parent.pad.left;
            previous_type = .expander;
            for (parent.type.panel.children.items) |child| {
                // Relayout left to right using expander sizes
                if (child.visible == .hidden) continue;
                if (child.layout.position == .float) continue;
                if (previous_type != .expander and child.type != .expander)
                    new_x += parent.type.panel.spacing;
                previous_type = child.type;
                child.rect.x = new_x;
                new_x += child.rect.width;
            }
        }
    }
}

// Draw panel children from top left corner of the panel
// assuming no scrolling of the child entities. Offsets
// applied at runtime. Track the height of each entity
// so wrapping can occur down to the next line.
inline fn placeHorizontalWrap(
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

    panel.type.panel.direction = .horizontal;
    display.need_relayout = true;
    display.relayout();
    try eq(1, b1.rect.x);
    try eq(2, b1.rect.y);
    try eq(1 + b1.rect.width + panel.type.panel.spacing, b2.rect.x);
    try eq(2, b2.rect.y);
    try eq(1 + b1.rect.width * 2 + panel.type.panel.spacing * 2, b3.rect.x);
    try eq(2, b3.rect.y);

    panel.type.panel.direction = .horizontal_wrap;
    display.need_relayout = true;
    display.relayout();
    try eq(1, b1.rect.x);
    try eq(2, b1.rect.y);
    try eq(1 + b1.rect.width + panel.type.panel.spacing, b2.rect.x);
    try eq(2, b2.rect.y);
    try eq(1, b3.rect.x);
    try eq(2 + panel.type.panel.spacing + b1.rect.height, b3.rect.y);

    panel.type.panel.direction = .vertical;
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

    panel.type.panel.direction = .horizontal;
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
        .type = .{ .panel = .{ .direction = .vertical } },
        .minimum = .{ .width = 100, .height = 120 },
        .maximum = .{ .width = 200, .height = 160 },
        .layout = .{ .x = .grows, .y = .grows },
    });

    panel.layout = .{ .x = .grows, .y = .grows };
    display.need_relayout = true;
    display.relayout();
    try eq(300, display.root.rect.width);
    try eq(200, display.root.rect.height);
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
            .direction = .vertical,
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
        .type = .{ .panel = .{ .direction = .vertical } },
        .rect = .{ .width = 120, .height = 80 },
        .layout = .{ .x = .fixed, .y = .fixed },
    }, display);

    // Test alignment without padding
    panel.type.panel.direction = .vertical;
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

    panel.type.panel.direction = .horizontal;
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

    panel.type.panel.direction = .vertical;
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

    panel.type.panel.direction = .horizontal;
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

    const screen_width = 600;
    const screen_height = 800;
    var display = try headless_display(allocator, io, screen_width, screen_height, 2);
    defer display.destroy();

    // Create a parent horizontal panel to hold a sub-panel "row"
    // of items. Check that the sub-panel "row" is correctly centred.

    const panel = try display.addPanel(.{
        .name = "main_panel",
        .type = .{
            .panel = .{
                .direction = .horizontal,
                .spacing = 5,
                .safe_area = .ignore_safe_area,
                .choosable = .choosable,
            },
        },
        .layout = .{ .x = .grows, .y = .grows, .weight = 1 },
    });
    display.need_relayout = true;
    display.relayout();

    try eq(1, panel.layout.weight);

    try eq(80, display.safe_area.top);
    try eq(0, display.safe_area.left);
    try eq(0, display.safe_area.right);
    try eq(0, display.safe_area.bottom);
    try eq(screen_width, display.root.rect.width);
    try eq(screen_width, display.root.inner_width());
    try eq(screen_height, display.root.inner_height());
    try eq(screen_width, panel.rect.width);
    try eq(screen_height, panel.rect.height);

    // Include an icon and lable into the row.
    var row = try panel.add(.{
        .name = "row",
        .focus = .never_focus,
        .minimum = .{ .width = 180 },
        .maximum = .{ .width = 400 },
        .pad = .{ .left = 15, .right = 15, .top = 15, .bottom = 11 },
        .layout = .{ .x = .shrinks, .y = .shrinks },
        .child_align = .{ .x = .centre, .y = .start },
        .type = .{ .panel = .{
            .direction = .horizontal,
            .spacing = 12,
        } },
    }, display);
    display.need_relayout = true;
    display.relayout();
    try eq(180, row.rect.width);
    // No children yet, so height should be padding only
    try eq(15 + 11, row.rect.height);

    const icon = try row.add(.{
        .name = "row.icon",
        .focus = .never_focus,
        .child_align = .{ .x = .centre },
        .rect = .{ .width = 50, .height = 50 },
        .layout = .{ .x = .fixed, .y = .fixed },
        .type = .{ .sprite = .{} },
        .pad = .{ .left = 15, .right = 15, .top = 25, .bottom = 0 },
    }, display);
    display.need_relayout = true;
    display.relayout();
    try eq(50, icon.rect.width);
    try eq(50, icon.rect.height);

    // The text is just a little smaller than the minmum width, so
    // we can test child start, centre, end align in child panels.
    const label = try row.add(.{
        .name = "row.label",
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
        const row_width = 15 + 50 + 12 + 250 + 15;
        {
            panel.child_align.x = .start;
            display.need_relayout = true;
            display.relayout();

            try eq(250, label.minimumNeededWidth(1000));
            try eq(250, Label.layout(label, 1000).minimum_width);
            try eq(250, Label.layout(label, 1000).width);
            try eq(250, label.rect.width); // text smaller than minimum
            try eq(22, label.rect.height);

            try eq(row_width, row.rect.width);

            // Check items are offset correctly from panel/row start.
            try eq(0, row.rect.x);
            try eq(icon.rect.x, row.rect.x + row.pad.left);
            try eq(icon.rect.y, row.rect.y + row.pad.top);
            try eq(label.rect.x, row.rect.x + row.pad.left + 12 + icon.rect.width);
            try eq(label.rect.y, row.rect.y + row.pad.top);
            const word1 = &label.type.label.elements.items[0];
            const word2 = &label.type.label.elements.items[1];
            const word3 = &label.type.label.elements.items[2];
            const space = label.type.label.elements.items[0].font.space_width;
            const text_width = word1.location.width + space + word2.location.width + space + word3.location.width;
            // Text is centred, so it doesnt start at the start
            try eq(80, word1.location.x);
            try eq(0, word1.location.y);
            // Text is left aligned, so does start at the start
            label.setAlign(.start, .start);
            display.need_relayout = true;
            display.relayout();
            try eq(0, word1.location.x);
            try eq(0, word1.location.y);
            try std.testing.expectApproxEqAbs(text_width, word3.location.x + word3.location.width, 0.1);
        }

        {
            panel.child_align.x = .end;
            display.need_relayout = true;
            display.relayout();
            try eq(row_width, row.rect.width);
            try eq(panel.rect.width - row_width, row.rect.x);
            try eq(label.rect.x, row.rect.x + row.rect.width - row.pad.right - label.rect.width);
            try eq(label.rect.y, row.rect.y + row.pad.top);
            try eq(icon.rect.x, row.rect.x + row.rect.width - row.pad.right - label.rect.width - 12 - icon.rect.width);
            try eq(icon.rect.y, row.rect.y + row.pad.top);
            const entity = label.type.label.elements.items[0];
            try eq(0, entity.location.x);
            try eq(0, entity.location.y);
        }

        {
            panel.child_align.x = .centre;
            display.need_relayout = true;
            display.relayout();
            try eq(row_width, row.rect.width);
            try eq(panel.rect.width / 2 - row_width / 2, row.rect.x);
            try eq(label.rect.x, row.rect.x + row.rect.width - row.pad.right - label.rect.width);
            try eq(label.rect.y, row.rect.y + row.pad.top);
            try eq(icon.rect.x, row.rect.x + row.rect.width - row.pad.right - label.rect.width - 12 - icon.rect.width);
            try eq(icon.rect.y, row.rect.y + row.pad.top);
            const entity = label.type.label.elements.items[0];
            try eq(0, entity.location.x);
            try eq(0, entity.location.y);
        }
    }
}

const std = @import("std");
const ArrayList = std.ArrayList;
const eq = std.testing.expectEqual;

const praxis = @import("praxis");

const engine = @import("engine.zig");
const err = engine.log.err;
const warn = engine.log.warn;
const info = engine.log.info;
const debug = engine.log.debug;
const trace = engine.log.trace;
const Clip = engine.Clip;
const Display = engine.Display;
const Entity = engine.Entity;
const Error = engine.Error;
const Font = engine.Font;
const Label = @import("Label.zig");
const TextArea = @import("TextArea.zig");

const LayoutDirection = Entity.LayoutDirection;
const Scroller = Entity.Scroller;
const Size = Entity.Size;
const TextSize = Entity.TextSize;
const Vector = Entity.Vector;

const clamp = engine.clamp;
const test_config = engine.test_config;
const headless_display = engine.headless_display;
