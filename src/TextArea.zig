pub const TextArea = @This();

pub const Paragraph = struct {
    elements: ArrayList(TextElement) = .empty,
    height: f32,

    pub const empty: Paragraph = .{ .elements = .empty, .height = 0 };
};

text: []const u8 = "",
paragraphs: ArrayList(Paragraph) = .empty,

line_height: f32 = 1,
text_size: TextSize = .normal,

// Handle User triggered events. Keyboard, Mouse, Game controller
on_ui_event: Entity.Callback = .empty,
on_pressed: Entity.Callback = .empty,

/// Mouse, cursor, or gamepad entered over a `TextElement`
on_element_hover: Entity.Callback = .empty,
/// Mouse, cursor, or gamepad exited from a `TextElement`
on_element_unhover: Entity.Callback = .empty,
/// Mouse clicked, cursor+enter, gamepad click on `TextElement`
on_element_pressed: Entity.Callback = .empty,

pub fn deinit(self: *TextArea, allocator: Allocator) void {
    for (self.paragraphs.items) |*p|
        p.elements.deinit(allocator);
    self.paragraphs.deinit(allocator);
}

pub fn setup(
    self: *TextArea,
    display: *Display,
    entity: *Entity,
) (Error || Allocator.Error || Resources.Error)!void {
    entity.texture = null;
    entity.background.image = null;
    self.paragraphs = .empty;

    if (entity.focus == .unspecified) {
        if (entity.type.text_area.on_ui_event.func != null)
            entity.focus = .can_focus
        else if (entity.type.text_area.on_pressed.func != null)
            entity.focus = .can_focus
        else
            entity.focus = .accessibility_focus;
    }
    entity.rect.width = directional_clamp(entity.layout.x, entity.minimum.width, entity.rect.width, entity.maximum.width);
    entity.rect.height = directional_clamp(entity.layout.y, entity.minimum.height, entity.rect.height, entity.maximum.height);

    // Is there a background for this text area
    if (entity.background.image_name) |name| {
        if (try display.requireImage(name)) |texture|
            entity.background.image = texture;
    }

    const initial_text = self.text;
    self.text = "";
    try self.setText(display, initial_text, entity);
}

/// Update the text contents of this `Text` entity. A single newline character
/// is ignored. Two newline characters mark a new paragraph.
pub fn setText(
    self: *TextArea,
    display: *Display,
    new_text: []const u8,
    entity: *Entity,
) error{OutOfMemory}!void {
    if (std.mem.eql(u8, self.text, new_text)) return;
    self.text = new_text;

    for (self.paragraphs.items) |*p|
        p.elements.deinit(display.allocator);
    self.paragraphs.clearRetainingCapacity();

    var cr: usize = 0;
    var paragraph: ?*Paragraph = null;
    var data = Chunker.init(self.text);
    while (data.next(&display.font)) |word| {
        if (word.isCR()) {
            cr += 1;
            if (cr == 2) {
                paragraph = try self.paragraphs.addOne(display.allocator);
                paragraph.?.* = .empty;
            }
            continue;
        } else {
            cr = 0;
        }
        if (paragraph == null) {
            paragraph = try self.paragraphs.addOne(display.allocator);
            paragraph.?.* = .empty;
        }
        // Store width as a placeholder until layout function is run.
        const width = try word.font.measureText(
            display,
            self.text_size,
            word.text,
        );
        try paragraph.?.elements.append(display.allocator, .{
            .text = word.text,
            .font = word.font,
            .width = width,
            .data = null,
        });
    }

    const width = if (entity.layout.x == .fixed) entity.rect.width else display.root.rect.width;
    const allowed_width = if (entity.maximum.width == 0)
        width
    else
        @min(entity.maximum.width, width);

    const size = layout(entity, allowed_width);
    if (entity.layout.x != .fixed) entity.rect.width = @max(size.width, entity.minimum.width);
    if (entity.layout.y != .fixed) entity.rect.height = @max(size.height, entity.minimum.height);
    if (entity.visible != .hidden) display.need_relayout = true;
}

test setText {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var display = try headless_display(allocator, io, 1000, 1600, 2);
    defer display.destroy();
    try display.setDefaultFont("Roboto-Light", .unknown, .{});

    const panel = try display.addPanel(.{
        .name = "parent",
        .type = .{ .panel = .{
            .direction = .top_to_bottom,
            .safe_area = .ignore_safe_area,
        } },
        .layout = .{ .x = .grows, .y = .grows },
    });
    display.relayout();

    var t = try panel.add(.{
        .type = .{ .text_area = .{} },
    }, display);

    try eq(0, t.type.text_area.paragraphs.items.len);
    try t.setText(display, "A fish.");
    try eq(1, t.type.text_area.paragraphs.items.len);
    try t.setText(display, "A fish.\n\nThe cat.");
    try eq(2, t.type.text_area.paragraphs.items.len);
}

/// A text area is considered clickable if it has user driven event
/// handlers, or if it has text and we are in blind accessibility mode.
pub inline fn clickable(text: *const TextArea) bool {
    // TODO: should accessibility check be pulled in here
    return text.on_ui_event.func != null or
        text.on_pressed.func != null or
        text.on_element_hover.func != null or
        text.on_element_unhover.func != null or
        text.on_element_pressed.func != null;
}

/// Calculate the layout of all elements, and optionally render every entity.
///
/// Normally text is converted to an image and rendered left to right, starting
/// at the top left corner of the entity (including padding).
///
/// If the text is centred or right aligned, then each line must be pushed along
/// by a certain offset amount.
pub inline fn draw(
    self: *const TextArea,
    entity: *Entity,
    display: *Display,
    _: Vector, //parent_scroll_offset: Vector,
    parent_clip: ?Clip,
    scroll_offset: Vector,
) void {
    const loc = Vector{
        .x = entity.rect.x + entity.pad.left + scroll_offset.x,
        .y = entity.rect.y + entity.pad.top + scroll_offset.y,
    };
    const text_colour = entity.style.text(display.theme, entity.colour);
    for (self.paragraphs.items) |*paragraph| {
        drawTextElements(
            paragraph.elements.items,
            loc,
            text_colour,
            display,
            parent_clip,
            self.text_size,
        );
    }
}

// Return the absolute minimum width needed, even if more space
// could be used. `.grows`  is ignored for the purpose of finding
// the minimum width.
//
// `parent_inner_width` is the maximum space this entity could
// theoretically grow to. Text might wrap if wider than this.
pub inline fn minimumNeededWidth(
    _: *const TextArea,
    entity: *const Entity,
    parent_inner_width: f32,
) f32 {
    const min = @max(
        layout(entity, parent_inner_width).minimum_width,
        entity.minimum.width,
    );
    if (entity.maximum.width == 0) return @ceil(min);
    return @min(min, entity.maximum.width);
}

/// Position each each word (text element) within the space allowed by
/// `parent_inner_width`. Returns the `width` this text area  will use,
/// and the `minimum_width` the element _could_ be squished into.
/// `entity.layout` determinse if the text area will `grows` to use
/// all space or `shrinks` to the minimum width.
///
/// If `entity.child_align` requests `centred` or `right` aligned text, then the
/// words are aligned to the  full `width` (not the `minimum_width`).
///
/// `parent_inner_width` is maximum number of pixels that the parent can
/// give to this element. Usually this is the parent width, minus any parent
/// padding.
pub inline fn layout(
    entity: *const Entity,
    parent_inner_width: f32,
) SizeInfo {
    std.debug.assert(entity.type == .text_area);

    const empty: SizeInfo = .{ .width = 0, .minimum_width = 0, .height = 0 };
    if (entity.type.text_area.text.len == 0) return empty;

    const text_height = entity.type.text_area.text_size;

    const default_font = entity.type.text_area.paragraphs.items[0].elements.items[0].font;
    const word_spacing = default_font.space_width;
    const maximum_total_width = clamp(entity.minimum.width, parent_inner_width, entity.maximum.width);
    const maximum_text_width = @max(0, maximum_total_width - (entity.pad.left + entity.pad.right));

    var box: BoxLayout = .init(maximum_text_width, word_spacing, 0);

    for (entity.type.text_area.paragraphs.items, 0..) |paragraph, count| {
        const children = paragraph.elements.items;
        if (children.len == 0) continue;

        if (count > 0) {
            box.newline(entity.type.text_area.text_size.size());
        }

        // Lay down each word one by one and wrap before we hit the
        // `wrap_at` boundary.
        for (children) |*word| {
            // CR should not appear.
            if (word.isCR()) {
                word.location = .{ .x = 0, .y = 0, .width = 0, .height = 0 };
                box.finalise();
                warn("TextArea entity should not contain CR.", .{});
                continue;
            }

            const height = text_height.size();
            const width = word.width;

            const location = box.place(width, height);

            word.location = .{
                .x = @round(location.x),
                .y = @round(location.y),
                .width = width,
                .height = height,
            };
        }
    }
    box.finalise();

    const minimum_without_padding = @max(0, entity.minimum.width - entity.pad.left - entity.pad.right);

    const used_text_width = switch (entity.layout.x) {
        .shrinks => @max(minimum_without_padding, @ceil(box.final.width)),
        .grows => maximum_text_width,
        .fixed => @max(0, entity.rect.width - (entity.pad.left - entity.pad.right)),
    };

    debug("finalize final.width={d} requested_min={d} [{t}] chosen_min={d}. Do align {s}={t}", .{
        @ceil(box.final.width),
        minimum_without_padding,
        entity.layout.x,
        used_text_width,
        entity.name,
        entity.child_align.x,
    });

    if (entity.child_align.x == .centre or entity.child_align.x == .end) {
        // Apply alignment to each paragraph
        for (entity.type.text_area.paragraphs.items) |paragraph| {
            const children = paragraph.elements.items;
            if (children.len == 0) continue;
            var line: struct { start: usize, end: usize } = .{ .start = 0, .end = 0 };
            // Break paragraph into lines to be aligned.
            while (true) : (line.end += 1) {
                if (line.end + 1 == children.len) {
                    applyLineJustification(
                        entity,
                        children[line.end].location.x + children[line.end].location.width,
                        used_text_width,
                        children[line.start .. line.end + 1],
                    );
                    break;
                } else if (children[line.end].location.x >= children[line.end + 1].location.x) {
                    applyLineJustification(
                        entity,
                        children[line.end].location.x + children[line.end].location.width,
                        used_text_width,
                        children[line.start .. line.end + 1],
                    );
                    line.start = line.end + 1;
                    continue;
                }
            }
        }
    }

    return .{
        .width = @round(used_text_width) + entity.pad.left + entity.pad.right,
        .minimum_width = @round(used_text_width) + entity.pad.left + entity.pad.right,
        .height = @round(box.final.height) + entity.pad.top + entity.pad.bottom,
    };
}

// `parent_inner_width` is the maximum space this entity could
// theoretically grow to. Text might wrap if wider than this.
pub inline fn minimumNeededHeight(
    _: *const TextArea,
    entity: *const Entity,
    parent_inner_width: f32,
) f32 {
    const padding = entity.pad.left + entity.pad.right;
    const allowed_width = engine.directional_clamp(
        entity.layout.x,
        @max(0, entity.minimum.width - padding),
        @max(0, parent_inner_width - padding),
        @max(0, entity.maximum.width - padding),
    );

    // How high does the text area text get when laying it out.
    return switch (entity.layout.y) {
        .shrinks, .grows => @max(
            layout(entity, allowed_width).height + entity.pad.top + entity.pad.bottom,
            entity.minimum.height,
        ),
        .fixed => entity.rect.height,
    };
}

const drawTextElements = Label.drawTextElements;
const applyLineJustification = Label.applyLineJustification;

test "text_panel_placement" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var display = try headless_display(allocator, io, 1000, 1600, 2);
    defer display.destroy();

    // TODO: 10->22
    //var display = try Display.create(allocator, io, test_config);
    //defer display.destroy();

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
            .safe_area = .ignore_safe_area,
        } },
        .layout = .{ .x = .grows, .y = .grows },
    });
    display.need_relayout = true;
    display.relayout();

    try eq(300, panel.rect.width);
    try eq(200, panel.rect.height);

    const child = try panel.add(.{
        .type = .{ .text_area = .{ .text = "Simple" } },
        .layout = .{ .x = .shrinks, .y = .shrinks },
    }, display);
    child.pad = .{ .left = 0, .right = 0, .top = 0, .bottom = 0 };

    // Test alignment without padding
    panel.type.panel.direction = .top_to_bottom;
    display.need_relayout = true;
    display.relayout();
    try eq(60, child.rect.width);
    try eq(22, child.rect.height);
    try eq(0, child.rect.x);
    try eq(0, child.rect.y);

    panel.type.panel.direction = .top_left;
    display.need_relayout = true;
    display.relayout();
    try eq(60, child.rect.width);
    try eq(22, child.rect.height);
    try eq(0, child.rect.x);
    try eq(0, child.rect.y);

    panel.type.panel.direction = .top_right;
    display.need_relayout = true;
    display.relayout();
    try eq(60, child.rect.width);
    try eq(22, child.rect.height);
    try eq(panel.rect.width - child.rect.width, child.rect.x);
    try eq(0, child.rect.y);

    panel.type.panel.direction = .centre;
    display.need_relayout = true;
    display.relayout();
    try eq(60, child.rect.width);
    try eq(22, child.rect.height);
    try eq(@round(panel.rect.width / 2 - child.rect.width / 2), child.rect.x);
    try eq(@round(panel.rect.height / 2 - child.rect.height / 2), child.rect.y);
}

test "single_word_layout" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    // The display takes ownership of the resources object

    const display_width = 300;
    var display = try headless_display(allocator, io, display_width, 200, 2);
    defer display.destroy();

    const panel = try display.addPanel(.{
        .name = "parent",
        .type = .{ .panel = .{
            .direction = .top_to_bottom,
            .safe_area = .ignore_safe_area,
        } },
        .layout = .{ .x = .grows, .y = .grows },
    });
    display.need_relayout = true;
    display.relayout();

    try eq(display_width, panel.rect.width);
    try eq(200, panel.rect.height);

    const child = try panel.add(.{
        .name = "child",
        .type = .{ .text_area = .{ .text = "Simple" } },
        .layout = .{ .x = .grows, .y = .shrinks },
    }, display);
    child.pad = .{ .left = 0, .right = 0, .top = 0, .bottom = 0 };

    const paragraph = &child.type.text_area.paragraphs.items[0];
    const element = &paragraph.elements.items[0];

    // Test alignment without padding
    display.need_relayout = true;
    display.relayout();
    try eq(display_width, child.rect.width);
    try eq(22, child.rect.height);
    try eq(0, child.rect.x);
    try eq(0, child.rect.y);

    // TextArea shrinks to text hight
    try eq(element.location.height, child.rect.height);

    // Alignment of a single word with no padding
    {
        child.setAlign(.start, .start);
        try std.testing.expectApproxEqAbs(59, element.location.width, 0.1);
        try eq(display_width, child.rect.width);
        try eq(22, element.location.height);
        try eq(0, element.location.x);
        try eq(0, element.location.y);
    }

    {
        child.setAlign(.end, .start);
        try std.testing.expectApproxEqAbs(59, element.location.width, 0.1);
        try eq(display_width, child.rect.width);
        try eq(display_width, panel.rect.width);
        try eq(59, @round(element.location.width));
        try std.testing.expectApproxEqAbs(element.location.x, display_width - element.location.width, 0.1);
        try eq(22, element.location.height);
        try eq(0, element.location.y);
    }

    {
        child.setAlign(.centre, .start);
        try std.testing.expectApproxEqAbs(59, element.location.width, 0.1);
        try eq(display_width, child.rect.width);
        try eq(22, element.location.height);
        try eq(@round(panel.rect.width / 2 - element.location.width / 2), element.location.x);
        try eq(0, element.location.y);
    }

    // Alignment of a single word with padding
    child.pad.left = 4;
    child.pad.right = 8;
    {
        child.setAlign(.start, .start);
        display.need_relayout = true;
        display.relayout();
        try std.testing.expectApproxEqAbs(59, element.location.width, 0.1);
        try eq(22, element.location.height);
        try eq(0, element.location.x);
        try eq(0, element.location.y);
    }

    {
        child.setAlign(.end, .start);
        display.need_relayout = true;
        display.relayout();
        try eq(300, panel.rect.width);
        try eq(300, child.rect.width);
        try eq(panel.rect.width - child.pad.left - child.pad.right, child.inner_width());
        try eq(300 - 8 - 4, child.inner_width());
        try std.testing.expectApproxEqAbs(59, element.location.width, 0.1);
        try eq(22, element.location.height);
        // `element.location` is relative to 0x0 not the on screen position, so
        // x is simply how far along from the first top/left drawing position.
        // 300 - 51 - 8 - 4
        try eq(panel.rect.width - element.location.width - child.pad.right - child.pad.left, element.location.x);
        try eq(0, element.location.y);
    }

    {
        child.setAlign(.centre, .start);
        display.need_relayout = true;
        display.relayout();
        try std.testing.expectApproxEqAbs(59, element.location.width, 0.1);
        try eq(22, element.location.height);
        // `entity.location` is relative to 0x0 not the on screen position, so
        // x is simply how far along from the first top/left drawing position.
        try eq(@round((panel.rect.width - child.pad.left - child.pad.right) / 2 - (element.location.width / 2)), element.location.x);
        try eq(0, element.location.y);
    }
}

test "word_wrap_layout" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    const display_width = 150;
    var display = try headless_display(allocator, io, display_width, 200, 2);
    defer display.destroy();

    const panel: *Entity = try display.addPanel(.{
        .name = "parent",
        .type = .{ .panel = .{
            .direction = .top_to_bottom,
            .safe_area = .ignore_safe_area,
        } },
        .layout = .{ .x = .grows, .y = .grows },
    });
    display.need_relayout = true;
    display.relayout();

    try eq(display_width, panel.rect.width);
    try eq(200, panel.rect.height);

    const string = "Officially Simple Readingology";
    const text_size = TextSize.normal;
    const child: *Entity = try panel.add(.{
        .name = "text_area",
        .type = .{ .text_area = .{
            .text = string,
            .text_size = text_size,
        } },
        .layout = .{ .x = .grows, .y = .shrinks },
        .pad = .{ .left = 0, .right = 0, .top = 0, .bottom = 0 },
    }, display);

    try std.testing.expectEqualStrings(string, child.type.text_area.text);
    try eq(display_width, child.rect.width);
    try eq(22 + 22, child.rect.height); // Two lines wrapped

    // Paragraph has three words (elements)
    const paragraph = &child.type.text_area.paragraphs.items[0];
    const element1 = &paragraph.elements.items[0];
    const element2 = &paragraph.elements.items[1];
    const element3 = &paragraph.elements.items[2];

    try eq(0, child.rect.x);
    try eq(0, child.rect.y);
    try eq(element1.location.height + element3.location.height, child.rect.height);

    // Check both lines align correctly to the left.
    {
        child.setAlign(.start, .start);
        display.need_relayout = true;
        display.relayout();
        try std.testing.expectApproxEqAbs(77, element1.location.width, 0.5);
        try eq(22, element1.location.height);
        try eq(0, element1.location.x);
        try eq(0, element1.location.y);

        try std.testing.expectApproxEqAbs(59, element2.location.width, 0.1);
        try eq(22, element2.location.height);
        const spacing = paragraph.elements.items[0].font.space_width;
        try std.testing.expectApproxEqAbs(77 + spacing, element2.location.x, 1);
        try eq(0, element2.location.y);

        // Wrap to next line
        try std.testing.expectApproxEqAbs(116, element3.location.width, 0.5);
        try eq(22, element3.location.height);
        try eq(0, element3.location.x);
        try eq(22, element3.location.y);
    }

    // Check both lines align correctly to the right.
    {
        child.setAlign(.end, .start);
        try std.testing.expectApproxEqAbs(77, element1.location.width, 0.5);
        try eq(22, element1.location.height);
        try std.testing.expectApproxEqAbs(59, element2.location.width, 0.1);
        try eq(display_width - element2.location.width, element2.location.x);
        try eq(0, element1.location.y);
        try eq(panel.rect.width - element3.location.width, element3.location.x);
        try eq(22, element3.location.y);
    }

    // Check both lines centre correctly.
    {
        child.setAlign(.centre, .start);
        try std.testing.expectApproxEqAbs(77, element1.location.width, 0.5);
        try eq(22, element1.location.height);
        const spacing = paragraph.elements.items[0].font.space_width;
        try eq(
            @round((panel.rect.width - element2.location.width - element1.location.width - spacing) / 2),
            element1.location.x,
        );
        try eq(0, element1.location.y);
        try eq(@round((panel.rect.width - element3.location.width) / 2), element3.location.x);
        try eq(22, element3.location.y);
    }
}

test "paragraph_spacing" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    const display_width = 300;
    var display = try headless_display(allocator, io, display_width, 200, 2);
    defer display.destroy();

    const panel: *Entity = try display.addPanel(.{
        .name = "parent",
        .type = .{ .panel = .{
            .direction = .top_to_bottom,
            .safe_area = .ignore_safe_area,
        } },
        .layout = .{ .x = .grows, .y = .grows },
    });
    display.need_relayout = true;
    display.relayout();

    try eq(display_width, panel.rect.width);
    try eq(200, panel.rect.height);

    const string = "First line\n\nAnoter line";
    const text_size = TextSize.normal;
    const child: *Entity = try panel.add(.{
        .name = "text_area",
        .type = .{ .text_area = .{
            .text = string,
            .text_size = text_size,
        } },
        .layout = .{ .x = .grows, .y = .shrinks },
        .pad = .{ .left = 0, .right = 0, .top = 0, .bottom = 0 },
    }, display);

    // Paragraph has three words (elements)
    const paragraph1 = &child.type.text_area.paragraphs.items[0];
    const paragraph2 = &child.type.text_area.paragraphs.items[1];
    const element1 = &paragraph1.elements.items[0];
    const element2 = &paragraph2.elements.items[0];

    try eq(0, child.rect.x);
    try eq(0, child.rect.y);
    try eq(0, element1.location.x);
    try eq(0, element2.location.x);
    try eq(element1.location.height + element2.location.height + child.type.text_area.text_size.size(), child.rect.height);
}

test "minimum_textarea_height" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var display = try headless_display(allocator, io, 200, 100, 2);
    defer display.destroy();

    const panel = try display.addPanel(.{
        .layout = .{ .x = .grows, .y = .grows },
        .visible = .visible,
        .type = .{ .panel = .{
            .direction = .top_to_bottom,
            .safe_area = .ignore_safe_area,
        } },
        .pad = .{ .left = 4, .right = 6, .top = 2, .bottom = 8 },
    });
    display.need_relayout = true;
    display.relayout();

    try eq(200, panel.rect.width);
    try eq(100, panel.rect.height);

    // An empty text area should allow a minimum height
    const child = try panel.add(.{
        .type = .{ .text_area = .{} },
        .visible = .visible,
        .layout = .{ .x = .shrinks, .y = .shrinks },
        .rect = .{ .width = 3, .height = 4 },
        .minimum = .{ .width = 10, .height = 15 },
    }, display);
    try std.testing.expectApproxEqAbs(10, child.rect.width, 0.5);
    try std.testing.expectApproxEqAbs(15, child.rect.height, 0.5);

    display.need_relayout = true;
    display.relayout();

    try std.testing.expectApproxEqAbs(10, child.rect.width, 0.5);
    try std.testing.expectApproxEqAbs(15, child.rect.height, 0.5);
}

test "shrunk_textarea_in_panel" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var display = try headless_display(allocator, io, 200, 100, 2);
    defer display.destroy();

    const panel = try display.addPanel(.{
        .layout = .{ .x = .grows, .y = .grows },
        .type = .{ .panel = .{
            .direction = .centre,
            .safe_area = .ignore_safe_area,
        } },
        .pad = .{ .left = 4, .right = 6, .top = 2, .bottom = 8 },
    });
    display.need_relayout = true;
    display.relayout();

    try eq(200, panel.rect.width);
    try eq(100, panel.rect.height);

    const child = try panel.add(.{
        .type = .{ .text_area = .{ .text = "Simple" } },
        .layout = .{ .x = .shrinks, .y = .shrinks },
    }, display);
    child.pad = .{ .left = 0, .right = 0, .top = 0, .bottom = 0 };

    panel.child_align.x = .start;
    panel.type.panel.direction = .left_to_right;
    display.need_relayout = true;
    display.relayout();
    try eq(60, child.rect.width);
    try eq(22, child.rect.height);
    try eq(4, child.rect.x);
    try eq(2, child.rect.y);

    panel.child_align.x = .end;
    panel.type.panel.direction = .left_to_right;
    display.need_relayout = true;
    display.relayout();
    try eq(60, child.rect.width);
    try eq(22, child.rect.height);
    try eq(panel.rect.width - panel.pad.right - child.rect.width, child.rect.x);
    try eq(2, child.rect.y);

    panel.child_align.x = .centre;
    panel.type.panel.direction = .left_to_right;
    display.need_relayout = true;
    display.relayout();
    try eq(60, child.rect.width);
    try eq(22, child.rect.height);
    // Check child is centred. Accommodate all padding.
    try eq(@round((panel.rect.width - panel.pad.left - panel.pad.right) / 2 - (child.rect.width / 2)) + panel.pad.left, child.rect.x);
    try eq(2, child.rect.y);

    // Where would the draw function theoretically put this element
    const loc = Vector{ .x = child.rect.x, .y = child.rect.y };
    const paragraph = child.type.text_area.paragraphs.items[0];
    const would_draw_at = paragraph.elements.items[0].location.move(loc);
    try eq(@round((panel.rect.width - panel.pad.left - panel.pad.right) / 2 - (child.rect.width / 2)) + panel.pad.left, would_draw_at.x);
    try eq(2, would_draw_at.y);
}

const std = @import("std");
const Allocator = std.mem.Allocator;
const eq = std.testing.expectEqual;
const ArrayList = std.ArrayList;

const resources = @import("resources");
const Resources = resources.Resources;

const engine = @import("engine.zig");
const sdl = engine.sdl;
const err = engine.log.err;
const warn = engine.log.warn;
const info = engine.log.info;
const debug = engine.log.debug;
const trace = engine.log.trace;
const clamp = engine.clamp;
const directional_clamp = engine.directional_clamp;
const Display = engine.Display;
const Entity = engine.Entity;
const Error = engine.Error;
const Font = engine.Font;

const Clip = Entity.Clip;
const SizeInfo = Entity.SizeInfo;
const TextSize = Entity.TextSize;
const Texture = Entity.Texture;
const ToggleState = Entity.ToggleState;
const TextElement = Entity.TextElement;
const Label = Entity.Label;
const Vector = Entity.Vector;

const BoxLayout = @import("BoxLayout.zig");
const Chunker = @import("Chunker.zig");

const select_font = Entity.select_font;
const test_config = engine.test_config;
const headless_display = engine.headless_display;
