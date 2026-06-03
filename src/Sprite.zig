/// An entity that displays a simple image texture.
pub const Sprite = @This();

/// Request a callback every iteration of the main app loop.
update: Entity.UpdateCallback = .empty,
scale: Fit = .stretch,

/// A callback when the user triggers an event using a Keyboard, Mouse, or
/// Game controller
on_ui_event: Entity.Callback = .empty,

/// A callback when this sprite is tapped.
on_pressed: Entity.Callback = .empty,

/// A sprite is clickable if it has a user driven event handler.
pub inline fn clickable(self: *const Sprite) bool {
    return self.on_ui_event.func != null or self.on_pressed.func != null;
}

/// Draw the foreground image `texture` of the sprite loaded from the
/// `texture_name` string. Does not draw the `background.image` texture.
/// The background image is drawn in the generic background drawing function.
pub inline fn draw(
    self: *const Sprite,
    entity: *Entity,
    display: *Display,
    _: Vector,
    parent_clip: ?Clip,
    scroll_offset: Vector,
) void {
    if (entity.texture) |texture| {
        var dest = entity.rect.removePadding(entity.pad);
        const original_height = dest.height;
        dest = dest.move(scroll_offset);

        if (parent_clip) |clip|
            clip.applyEdgeClipping(&dest);

        if (dest.height <= 0 or dest.width <= 0) return;
        const x_scale = dest.height / original_height;

        if (entity.flip.x) {
            dest.x += dest.width;
            dest.width = 0 - dest.width;
        }
        if (entity.flip.y) {
            dest.y += dest.height;
            dest.height = 0 - dest.height;
        }

        // TODO: Sprites might have frames

        // Stretch the full image onto the drawing area
        const image_width = @as(f32, @floatFromInt(texture.texture.w));
        const image_height = @as(f32, @floatFromInt(texture.texture.h));
        var source: sdl.SDL_FRect = undefined;
        switch (self.scale) {
            .stretch => {
                source = .{
                    .x = 0,
                    .y = 0,
                    .w = image_width,
                    .h = image_height,
                };
            },
            .fit => {
                source = .{
                    .x = 0,
                    .y = 0,
                    .w = image_width,
                    .h = image_height,
                };
                // Don't fill the destination area. Slice off
                // some of the destination area.
                const dst_scale: f32 = entity.rect.width / entity.rect.height;
                const src_scale: f32 = image_width / image_height;
                if (src_scale >= dst_scale) {
                    // image too wide, hight will have blank space
                    dest.height = dest.width / src_scale;
                    // sprite is drawn at top of its rect, unless a
                    // different child alignment is chosen.
                    switch (entity.child_align.y) {
                        .start => {}, // already at top
                        .centre => dest.y += ((entity.rect.height - dest.height) / 2) - entity.pad.top,
                        .end => dest.y += (entity.rect.height - dest.height),
                    }
                } else {
                    // image too tall/high, width will have blank space
                    dest.width = dest.height * src_scale;
                    // sprite is drawn at start/left of its rect, unless
                    // a different child alignment is chosen.
                    switch (entity.child_align.x) {
                        .start => {}, // already at top
                        .centre => dest.x += ((entity.rect.width - dest.width) / 2) - entity.pad.left,
                        .end => dest.x += (entity.rect.width - dest.width),
                    }
                }
            },
            .fill => {
                // We need a slice of the source image that fits the
                // ratio of the destination area.
                const dst_scale: f32 = entity.rect.width / entity.rect.height;
                const src_scale: f32 = image_width / image_height;
                if (src_scale >= dst_scale) {
                    // Slice off some width
                    source = .{
                        .x = 0,
                        .y = 0,
                        .h = image_height,
                        .w = image_height * dst_scale,
                    };
                    source.x = (image_width - source.w) / 2;
                } else {
                    // Slice off some height
                    source = .{
                        .x = 0,
                        .y = 0,
                        .w = image_width,
                        .h = image_width / dst_scale,
                    };
                    source.y = (image_height - source.h) / 2;
                }
            },
        }

        if (entity.style == .custom)
            tint_texture(texture.texture, entity.colour);

        dest.height *= x_scale;
        _ = sdl.SDL_RenderTexture(display.renderer, texture.texture, @ptrCast(&source), @ptrCast(&dest));
    }
}

test "clickable" {
    var entity: Entity = .{
        .name = "test",
        .type = .{ .sprite = .{
            .on_pressed = .{},
        } },
    };
    try std.testing.expectEqual(false, entity.type.sprite.clickable());
}

const std = @import("std");
const ArrayListUnmanaged = std.ArrayListUnmanaged;

const engine = @import("engine.zig");
const sdl = engine.sdl;
const err = engine.err;
const Display = engine.Display;
const Entity = engine.Entity;
const Error = engine.Error;
const Font = engine.Font;
const Texture = engine.Texture;

const Clip = Entity.Clip;
const Fit = Entity.Fit;
const Rect = Entity.Rect;
const Size = Entity.Size;
const Vector = Entity.Vector;

const tint_texture = Entity.tint_texture;
