/// Draw a basic rectangle with a basic colour background.
pub const Rectangle = @This();

/// Draw a basic rectangle.
pub inline fn draw(
    _: *const Rectangle,
    entity: *Entity,
    display: *Display,
    _: Vector,
    _: ?Clip,
    scroll_offset: Vector,
) void {
    const colour = entity.style.panel(display.theme, entity.background.colour);
    const dest = entity.rect.move(scroll_offset);
    display.renderSolidRectangle(colour, &dest);
}

test "init" {
    _ = Entity{
        .type = .{ .rectangle = .{} },
    };
}

const std = @import("std");
const ArrayListUnmanaged = std.ArrayListUnmanaged;

const engine = @import("engine.zig");
const Display = engine.Display;
const Entity = engine.Entity;
const Texture = engine.Texture;

const Clip = Entity.Clip;
const Vector = Entity.Vector;
