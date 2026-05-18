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
    if (TextSize.normal.pixel_height(1) == 0) {
        //
    }
}

pub inline fn minimum_needed_width(
    _: *const Expander,
    _: *Display,
    entity: *const Entity,
    _: f32, //parent_inner_width
) f32 {
    return entity.minimum.width;
}

test "init" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;
    const display = try headless_display(gpa, io, 300, 200, 2);
    defer display.destroy(gpa);

    const entity = Entity{
        .rect = .{ .width = 100, .height = 100 },
        .minimum = .{ .width = 100, .height = 100 },
        .maximum = .{ .width = 100, .height = 100 },
        .type = .{ .expander = .{} },
    };
    try std.testing.expectEqual(
        100.0,
        entity.type.expander.minimum_needed_width(display, &entity, 1000),
    );
}

const std = @import("std");
const ArrayListUnmanaged = std.ArrayListUnmanaged;

const engine = @import("engine.zig");
const Display = engine.Display;
const Entity = engine.Entity;
const TextSize = engine.TextSize;

const Vector = Entity.Vector;
const Clip = Entity.Clip;

const headless_display = @import("test.zig").headless_display;
