/// A simple element that expands inside a panel to fill blank space. If
/// multiple expanders exist in a panel, the `weight` parameter indicates
/// the relative size of each expander.
pub const Expander = @This();

/// The `Expander` with the higher `weight` grabs more whitespace
/// than the expander with a lower `weight`.
weight: f32 = 0,

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

test "padding" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;
    const display = try headless_display(gpa, io, 300, 200, 2);
    defer display.destroy();

    const panel = try display.addPanel(.{
        .layout = .{ .x = .grows, .y = .grows },
        .type = .{ .panel = .{ .safe_area = .ignore_safe_area } },
    });

    display.need_relayout = true;
    display.relayout();
    try std.testing.expectEqual(300, panel.rect.width);
    try std.testing.expectEqual(200, panel.rect.height);

    var empty: Empty = .{};
    const box = try panel.append("panel vertical layout fixed fixed rect width=200 height=100", Empty, &empty, display);
    const item1 = try box.append("sprite layout fixed fixed rect width=20 height=20", Empty, &empty, display);
    const first = try box.append("expander weight 1", Empty, &empty, display);
    const second = try box.append("expander weight 1", Empty, &empty, display);

    display.need_relayout = true;
    display.relayout();

    try std.testing.expectEqual(100, box.rect.height);
    try std.testing.expectEqual(20, item1.rect.height);
    try std.testing.expectEqual(40, first.rect.height);
    try std.testing.expectEqual(40, second.rect.height);

    box.pad.top = 5;
    box.pad.bottom = 15;
    display.need_relayout = true;
    display.relayout();
    try std.testing.expectEqual(30, first.rect.height);
    try std.testing.expectEqual(30, second.rect.height);

    box.pad.top = 20;
    box.pad.bottom = 0;
    display.need_relayout = true;
    display.relayout();
    try std.testing.expectEqual(30, first.rect.height);
    try std.testing.expectEqual(30, second.rect.height);

    box.pad.top = 0;
    box.pad.bottom = 20;
    display.need_relayout = true;
    display.relayout();
    try std.testing.expectEqual(30, first.rect.height);
    try std.testing.expectEqual(30, second.rect.height);
}

const std = @import("std");
const expectEqual = std.testing.expectEqual;
const ArrayListUnmanaged = std.ArrayListUnmanaged;

const engine = @import("engine.zig");
const headless_display = engine.headless_display;

const Display = engine.Display;
const Entity = engine.Entity;
const TextSize = engine.TextSize;

const Vector = Entity.Vector;
const Clip = Entity.Clip;
