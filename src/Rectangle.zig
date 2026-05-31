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
    _ = sdl.SDL_SetRenderDrawColor(
        display.renderer,
        colour.r,
        colour.g,
        colour.b,
        colour.a,
    );
    var dest = entity.rect.move(scroll_offset);
    _ = sdl.SDL_RenderFillRect(display.renderer, @ptrCast(&dest));
}

test "init" {
    _ = Entity{
        .type = .{ .rectangle = .{} },
    };
}

const std = @import("std");
const ArrayListUnmanaged = std.ArrayListUnmanaged;

const engine = @import("engine.zig");
const sdl = engine.sdl;
const Display = engine.Display;
const Entity = engine.Entity;
const Texture = engine.Texture;

const Clip = Entity.Clip;
const Vector = Entity.Vector;
