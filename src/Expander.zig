/// A simple element that expands inside a panel to fill blank space. If
/// multiple expanders exist in a panel, the `weight` parameter indicates
/// the relative size of each expander.
pub const Expander = @This();

/// Expanders have no content to draw.
pub inline fn draw(
    _: *const Expander,
    _: *Entity,
    _: *Display,
    _: Vector,
    _: ?Clip, //parent_clip
    _: Vector, // scroll_offset
) void {
    //
}

pub inline fn minimumNeededWidth(
    _: *const Expander,
    entity: *const Entity,
    _: f32, //parent_inner_width
) f32 {
    return entity.minimum.width;
}

test "init" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;
    const display = try headless_display(gpa, io, 300, 200, 2);
    defer display.destroy();

    const entity = Entity{
        .rect = .{ .width = 100, .height = 100 },
        .minimum = .{ .width = 100, .height = 100 },
        .maximum = .{ .width = 100, .height = 100 },
        .type = .{ .expander = .{} },
    };
    try std.testing.expectEqual(100.0, entity.type.expander.minimumNeededWidth(&entity, 1000));
}

pub const Empty = struct {};

test "vertical_expanding" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;
    const display = try headless_display(gpa, io, 300, 200, 2);
    defer display.destroy();

    const panel = try display.addPanel(.{
        .layout = .{ .x = .grows, .y = .grows },
        .type = .{ .panel = .{
            .safe_area = .ignore_safe_area,
            .direction = .centre,
        } },
    });

    display.need_relayout = true;
    display.relayout();
    try std.testing.expectEqual(300, panel.rect.width);
    try std.testing.expectEqual(200, panel.rect.height);
    var empty: Empty = .{};

    const box = try panel.append("panel name \"box\" vertical layout fixed fixed rect width=200 height=110", Empty, &empty, display);
    try std.testing.expectEqual(.top_to_bottom, box.type.panel.direction);

    const first = try box.append("sprite name \"first\" layout fixed fixed rect width=20 height=20", Empty, &empty, display);
    const middle = try box.append("expander name \"middle\" weight 1", Empty, &empty, display);
    const last = try box.append("expander name \"last\" weight 1", Empty, &empty, display);

    display.need_relayout = true;
    display.relayout();

    try std.testing.expectEqual(1, middle.layout.weight);
    try std.testing.expectEqual(0.5, middle.layout.weight_percent);
    try std.testing.expectEqual(1, last.layout.weight);
    try std.testing.expectEqual(0.5, last.layout.weight_percent);

    try std.testing.expectEqual(0, middle.type.expander.minimumNeededWidth(middle, 200));

    try std.testing.expectEqual(110, box.rect.height);
    try std.testing.expectEqual(20, first.rect.height);
    try std.testing.expectEqual(45, middle.rect.height);
    try std.testing.expectEqual(45, last.rect.height);

    box.pad.top = 5;
    box.pad.bottom = 15;
    display.need_relayout = true;
    display.relayout();
    try std.testing.expectEqual(35, middle.rect.height);
    try std.testing.expectEqual(35, last.rect.height);

    box.pad.top = 20;
    box.pad.bottom = 0;
    display.need_relayout = true;
    display.relayout();
    try std.testing.expectEqual(35, middle.rect.height);
    try std.testing.expectEqual(35, last.rect.height);

    box.pad.top = 0;
    box.pad.bottom = 20;
    display.need_relayout = true;
    display.relayout();
    try std.testing.expectEqual(35, middle.rect.height);
    try std.testing.expectEqual(35, last.rect.height);
}

test "horizontal_expanding" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;
    const display = try headless_display(gpa, io, 200, 300, 2);
    defer display.destroy();

    const panel = try display.addPanel(.{
        .layout = .{ .x = .grows, .y = .grows },
        .type = .{ .panel = .{
            .safe_area = .ignore_safe_area,
            .direction = .centre,
        } },
    });

    display.need_relayout = true;
    display.relayout();
    try std.testing.expectEqual(200, panel.rect.width);
    try std.testing.expectEqual(300, panel.rect.height);
    var empty: Empty = .{};

    const box = try panel.append("panel name \"box\" horizontal layout fixed fixed rect width=110 height=200", Empty, &empty, display);
    try std.testing.expectEqual(.left_to_right, box.type.panel.direction);

    const first = try box.append("sprite name \"first\" layout fixed fixed rect width=20 height=20", Empty, &empty, display);
    const middle = try box.append("expander name \"middle\" weight 1", Empty, &empty, display);
    const last = try box.append("expander name \"last\" weight 1", Empty, &empty, display);

    display.need_relayout = true;
    display.relayout();

    try std.testing.expectEqual(1, middle.layout.weight);
    try std.testing.expectEqual(0.5, middle.layout.weight_percent);
    try std.testing.expectEqual(1, last.layout.weight);
    try std.testing.expectEqual(0.5, last.layout.weight_percent);

    try std.testing.expectEqual(0, middle.type.expander.minimumNeededWidth(middle, 200));

    try std.testing.expectEqual(110, box.rect.width);
    try std.testing.expectEqual(20, first.rect.width);
    try std.testing.expectEqual(45, middle.rect.width);
    try std.testing.expectEqual(45, last.rect.width);

    box.pad.left = 5;
    box.pad.right = 15;
    display.need_relayout = true;
    display.relayout();
    try std.testing.expectEqual(35, middle.rect.width);
    try std.testing.expectEqual(35, last.rect.width);

    box.pad.left = 20;
    box.pad.right = 0;
    display.need_relayout = true;
    display.relayout();
    try std.testing.expectEqual(35, middle.rect.width);
    try std.testing.expectEqual(35, last.rect.width);

    box.pad.left = 0;
    box.pad.right = 20;
    display.need_relayout = true;
    display.relayout();
    try std.testing.expectEqual(35, middle.rect.width);
    try std.testing.expectEqual(35, last.rect.width);
}

const std = @import("std");
const expectEqual = std.testing.expectEqual;
const ArrayList = std.ArrayList;

const engine = @import("engine.zig");
const headless_display = engine.headless_display;

const Display = engine.Display;
const Entity = engine.Entity;
const TextSize = engine.TextSize;

const Vector = Entity.Vector;
const Clip = Entity.Clip;
