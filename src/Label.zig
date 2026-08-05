pub const Label = @This();

font: *Font = undefined,
font_name: ?[]const u8 = null,
text: []const u8 = "",
translated: []const u8 = "",
elements: ArrayListUnmanaged(TextElement) = .empty,
line_height: f32 = 1,
text_size: TextSize = .normal,

// Handle User triggered events. Keyboard, Mouse, Game controller
on_ui_event: Entity.Callback = .empty,
on_pressed: Entity.Callback = .empty,

pub fn setup(
    label: *Label,
    display: *Display,
    entity: *Entity,
) (Error || Allocator.Error || Resources.Error)!void {
    entity.texture = null;
    entity.background.image = null;
    label.translated = "";
    label.elements = .empty;
    if (label.font_name) |name|
        label.font = try select_font(display.fonts.items, name);

    if (entity.focus == .unspecified) {
        if (entity.type.label.on_ui_event.func != null)
            entity.focus = .can_focus
        else if (entity.type.label.on_pressed.func != null)
            entity.focus = .can_focus
        else
            entity.focus = .accessibility_focus;
    }
    try entity.setText(display, entity.type.label.text);

    // Is there a background for this label?
    if (entity.background.image_name) |name| {
        if (try display.requireImage(name)) |texture|
            entity.background.image = texture;
    }
}

/// A label is considered clickable if it has a user driven event
/// handler, or if it has text and  we are in blind accessibility mode.
pub inline fn clickable(label: *const Label) bool {
    // TODO: should accessibility check be pulled in here
    return label.on_ui_event.func != null or label.on_pressed.func != null;
}

/// Calculate the layout of all elements, and optionally render every entity.
///
/// Normally text is converted to an image and rendered left to right, starting
/// at the top left corner of the entity (including padding).
///
/// If the text is centred or right aligned, then each line must be pushed along
/// by a certain offset amount.
pub inline fn draw(
    self: *const Label,
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
    drawTextElements(
        self.elements.items,
        loc,
        text_colour,
        display,
        parent_clip,
        self.text_size,
    );
}

// Return the absolute minimum width needed, even if more space
// could be used. `.grows`  is ignored for the purpose of finding
// the minimum width.
//
// `parent_inner_width` is the maximum space this entity could
// theoretically grow to. Text might wrap if wider than this.
pub inline fn minimumNeededWidth(
    _: *const Label,
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
/// `parent_inner_width`. Returns the `width` this label will use, and the
/// `minimum_width` the element _could_ be squished into.
/// `entity.layout` determinse if the label will `grows` to use all space
///  or `shrinks` to the minimum width.
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
    std.debug.assert(entity.type == .label or entity.type == .checkbox);

    const empty: SizeInfo = .{ .width = 0, .minimum_width = 0, .height = 0 };
    switch (entity.type) {
        .label => if (entity.type.label.text.len == 0) return empty,
        .checkbox => if (entity.type.checkbox.text.len == 0) return empty,
        else => unreachable,
    }

    const children = switch (entity.type) {
        .label => entity.type.label.elements.items,
        .checkbox => entity.type.checkbox.elements.items,
        else => unreachable,
    };
    if (children.len == 0) return empty;

    const text_height = switch (entity.type) {
        .label => entity.type.label.text_size,
        .checkbox => entity.type.checkbox.text_size,
        else => unreachable,
    };

    const word_spacing = children[0].font.space_width;
    const maximum_total_width = clamp(entity.minimum.width, parent_inner_width, entity.maximum.width);
    const maximum_text_width = @max(0, maximum_total_width - (entity.pad.left + entity.pad.right));

    var box: BoxLayout = .init(maximum_text_width, word_spacing, 0);

    // Lay down each word one by one and wrap before we hit the
    // `wrap_at` boundary.
    for (children) |*word| {
        if (word.text.len == 1 and word.text[0] == '\n') {
            word.location = .{ .x = 0, .y = 0, .width = 0, .height = 0 };
            box.finalise();
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
    box.finalise();

    const minimum_without_padding = @max(0, entity.minimum.width - entity.pad.left - entity.pad.right);

    const used_text_width = switch (entity.layout.x) {
        .shrinks => @max(minimum_without_padding, @ceil(box.final.width)),
        .grows => maximum_text_width,
        .fixed => @max(0, entity.rect.width - (entity.pad.left - entity.pad.right)),
    };

    //err("finalize final.width={d} requested_min={d} [{t}] chosen_min={d}", .{
    //    @ceil(box.final.width),
    //    minimum_without_padding,
    //    entity.layout.x,
    //    used_text_width,
    //});

    // Align words to centre or right if requested.
    // centre and end alignment might need the `grows`
    // full width, or the `shrinks` minimum width.
    if (entity.child_align.x == .centre or entity.child_align.x == .end) {
        var start: usize = 0;
        var end: usize = 0;
        while (true) : (end += 1) {
            if (end + 1 == children.len) {
                applyLineJustification(
                    entity,
                    children[end].location.x + children[end].location.width,
                    used_text_width,
                    children[start .. end + 1],
                );
                break;
            }
            if (children[end].location.x >= children[end + 1].location.x) {
                applyLineJustification(
                    entity,
                    children[end].location.x + children[end].location.width,
                    used_text_width,
                    children[start .. end + 1],
                );
                start = end + 1;
                continue;
            }
        }
    }

    return .{
        .width = @round(used_text_width) + entity.pad.left + entity.pad.right,
        .minimum_width = @round(used_text_width) + entity.pad.left + entity.pad.right,
        .height = @round(box.final.height) + entity.pad.top + entity.pad.bottom,
    };
}

/// Align a single line of TextElement's belonging to a label or a checkbox.
inline fn applyLineJustification(
    entity: *const Entity,
    line_width: f32,
    usable_width: f32,
    children: []TextElement,
) void {
    // How much whitespace was left over at the end of this line.
    const trailing_whitespace = usable_width - line_width;

    if (trailing_whitespace <= 0) return;

    switch (entity.child_align.x) {
        .start => {
            // No adjustment needed
            return;
        },
        .centre => {
            // Shuffle words into centre
            const adjust_by = @round(trailing_whitespace / 2);
            for (children) |*child| child.location.x += adjust_by;
        },
        .end => {
            // Shuffle words to the end
            const adjust_by = trailing_whitespace;
            for (children) |*child| child.location.x += adjust_by;
        },
    }
}

// `parent_inner_width` is the maximum space this entity could
// theoretically grow to. Text might wrap if wider than this.
pub inline fn minimumNeededHeight(
    _: *const Label,
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

    // How high does the label text get when laying it out.
    return switch (entity.layout.y) {
        .shrinks, .grows => @max(
            layout(entity, allowed_width).height + entity.pad.top + entity.pad.bottom,
            entity.minimum.height,
        ),
        .fixed => entity.rect.height,
    };
}

pub fn drawTextElements(
    items: []TextElement,
    loc: Vector,
    current_colour: engine.Colour,
    display: *Display,
    parent_clip: ?Clip,
    text_size: TextSize,
) void {
    for (items) |*word| {
        var pos = word.location.move(loc);
        if (parent_clip) |clip| {
            // Individual inner elemements may still need clipping.
            if (clip.isClipped(pos)) continue;
            clip.applyEdgeClipping(&pos);
        }
        const x_scale = pos.height / word.location.height;

        word.font.drawText(
            display,
            word.text,
            pos.location(),
            current_colour,
            text_size,
            x_scale,
        ) catch {
            // OutOfMemory should never occur, unless the developer has forgotten
            // to measureText(...);
        };
    }
}

test "label_panel_placement" {
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
        .type = .{ .label = .{ .text = "Simple" } },
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

test "label_single_word_alignment" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    // The display takes ownership of the resources object

    // TODO: 10->22
    var display = try headless_display(allocator, io, 300, 200, 2);
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

    try eq(300, panel.rect.width);
    try eq(200, panel.rect.height);

    const child = try panel.add(.{
        .name = "child",
        .type = .{ .label = .{ .text = "Simple" } },
        .layout = .{ .x = .grows, .y = .shrinks },
    }, display);
    child.pad = .{ .left = 0, .right = 0, .top = 0, .bottom = 0 };

    // Test alignment without padding
    display.need_relayout = true;
    display.relayout();
    try eq(300, child.rect.width);
    try eq(22, child.rect.height);
    //try eq(52, child.rect.width);
    //try eq(20, child.rect.height);
    try eq(0, child.rect.x);
    try eq(0, child.rect.y);

    // Alignment of a single word with no padding
    {
        child.child_align.x = .start;
        display.need_relayout = true;
        display.relayout();
        const element = child.type.label.elements.items[0];
        try std.testing.expectApproxEqAbs(59, element.location.width, 0.1);
        try eq(22, element.location.height);
        try eq(0, element.location.x);
        try eq(0, element.location.y);
    }

    {
        child.child_align.x = .end;
        display.need_relayout = true;
        display.relayout();
        const element = child.type.label.elements.items[0];
        try std.testing.expectApproxEqAbs(59, element.location.width, 0.1);
        try eq(22, element.location.height);
        try eq(panel.rect.width - element.location.width, element.location.x);
        try eq(0, element.location.y);
    }

    {
        child.child_align.x = .centre;
        display.need_relayout = true;
        display.relayout();
        const element = child.type.label.elements.items[0];
        try std.testing.expectApproxEqAbs(59, element.location.width, 0.1);
        try eq(22, element.location.height);
        try eq(@round(panel.rect.width / 2 - element.location.width / 2), element.location.x);
        try eq(0, element.location.y);
    }

    // Alignment of a single word with padding
    child.pad.left = 4;
    child.pad.right = 8;
    {
        child.child_align.x = .start;
        display.need_relayout = true;
        display.relayout();
        const element = child.type.label.elements.items[0];
        try std.testing.expectApproxEqAbs(59, element.location.width, 0.1);
        try eq(22, element.location.height);
        try eq(0, element.location.x);
        try eq(0, element.location.y);
    }

    {
        child.child_align.x = .end;
        display.need_relayout = true;
        display.relayout();
        try eq(300, panel.rect.width);
        try eq(300, child.rect.width);
        try eq(panel.rect.width - child.pad.left - child.pad.right, child.inner_width());
        try eq(300 - 8 - 4, child.inner_width());
        const element = child.type.label.elements.items[0];
        try std.testing.expectApproxEqAbs(59, element.location.width, 0.1);
        try eq(22, element.location.height);
        // `element.location` is relative to 0x0 not the on screen position, so
        // x is simply how far along from the first top/left drawing position.
        // 300 - 51 - 8 - 4
        try eq(panel.rect.width - element.location.width - child.pad.right - child.pad.left, element.location.x);
        try eq(0, element.location.y);
    }

    {
        child.child_align.x = .centre;
        display.need_relayout = true;
        display.relayout();
        const element = child.type.label.elements.items[0];
        try std.testing.expectApproxEqAbs(59, element.location.width, 0.1);
        try eq(22, element.location.height);
        // `entity.location` is relative to 0x0 not the on screen position, so
        // x is simply how far along from the first top/left drawing position.
        try eq(@round((panel.rect.width - child.pad.left - child.pad.right) / 2 - (element.location.width / 2)), element.location.x);
        try eq(0, element.location.y);
    }
}

test "label_multiword_align" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var display = try headless_display(allocator, io, 150, 200, 2);
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

    try eq(150, panel.rect.width);
    try eq(200, panel.rect.height);

    const text_size = TextSize.normal;
    const child = try panel.add(.{
        .name = "child",
        .type = .{ .label = .{
            .text = "Officially Simple Readingology",
            .text_size = text_size,
        } },
        .layout = .{ .x = .grows, .y = .shrinks },
    }, display);
    child.pad = .{ .left = 0, .right = 0, .top = 0, .bottom = 0 };

    // Test alignment without padding
    display.need_relayout = true;
    display.relayout();
    try eq(150, child.rect.width);
    try eq(22 + 22, child.rect.height); // Two lines wrapped
    //try eq(52, child.rect.width);
    //try eq(20, child.rect.height);
    try eq(0, child.rect.x);
    try eq(0, child.rect.y);

    // Alignment of a single word with no padding
    {
        child.child_align.x = .start;
        display.need_relayout = true;
        display.relayout();
        const element1 = child.type.label.elements.items[0];
        const element2 = child.type.label.elements.items[1];
        const element3 = child.type.label.elements.items[2];
        try std.testing.expectApproxEqAbs(77, element1.location.width, 0.5);
        try eq(22, element1.location.height);
        try eq(0, element1.location.x);
        try eq(0, element1.location.y);

        try std.testing.expectApproxEqAbs(59, element2.location.width, 0.1);
        try eq(22, element2.location.height);
        const spacing = child.type.label.elements.items[0].font.space_width;
        try std.testing.expectApproxEqAbs(77 + spacing, element2.location.x, 1);
        try eq(0, element2.location.y);

        // Wrap to next line
        try std.testing.expectApproxEqAbs(116, element3.location.width, 0.5);
        try eq(22, element3.location.height);
        try eq(0, element3.location.x);
        try eq(22, element3.location.y);
    }

    {
        // Align both lines to right
        child.child_align.x = .end;
        display.need_relayout = true;
        display.relayout();
        const element1 = child.type.label.elements.items[0];
        const element2 = child.type.label.elements.items[1];
        const element3 = child.type.label.elements.items[2];
        try std.testing.expectApproxEqAbs(77, element1.location.width, 0.5);
        try eq(22, element1.location.height);
        try eq(panel.rect.width - element2.location.width, element2.location.x);
        try eq(0, element1.location.y);
        try eq(panel.rect.width - element3.location.width, element3.location.x);
        try eq(22, element3.location.y);
    }

    {
        child.child_align.x = .centre;
        display.need_relayout = true;
        display.relayout();
        const element1 = child.type.label.elements.items[0];
        const element2 = child.type.label.elements.items[1];
        const element3 = child.type.label.elements.items[2];
        try std.testing.expectApproxEqAbs(77, element1.location.width, 0.5);
        try eq(22, element1.location.height);
        const spacing = child.type.label.elements.items[0].font.space_width;
        try eq(@round((panel.rect.width - element2.location.width - element1.location.width - spacing) / 2), element1.location.x);
        try eq(0, element1.location.y);
        try eq(@round((panel.rect.width - element3.location.width) / 2), element3.location.x);
        try eq(22, element3.location.y);
    }
}

test "shrunk_label_in_panel" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    // TODO: 10->22
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
        .type = .{ .label = .{ .text = "Simple" } },
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
    const would_draw_at = child.type.label.elements.items[0].location.move(loc);
    try eq(@round((panel.rect.width - panel.pad.left - panel.pad.right) / 2 - (child.rect.width / 2)) + panel.pad.left, would_draw_at.x);
    try eq(2, would_draw_at.y);
}

const std = @import("std");
const Allocator = std.mem.Allocator;
const eq = std.testing.expectEqual;
const ArrayListUnmanaged = std.ArrayListUnmanaged;

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
const Vector = Entity.Vector;

const BoxLayout = @import("BoxLayout.zig");

const select_font = Entity.select_font;
const test_config = engine.test_config;
const headless_display = engine.headless_display;
