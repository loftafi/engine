/// A simple image entity.
pub const Sprite = @This();

scale: Fit = .stretch,

/// Request a callback every iteration of the main app loop.
on_update: Entity.UpdateCallback = .empty,

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

        // TODO: Sprites might have frames
        // Stretch the full image onto the drawing area
        var source: engine.Rect = .{
            .x = 0,
            .y = 0,
            .width = @as(f32, @floatFromInt(texture.texture.w)),
            .height = @as(f32, @floatFromInt(texture.texture.h)),
        };
        applyContentScale(self.scale, &source, &dest, entity.child_align);

        switch (entity.style) {
            .normal => tint_texture(texture.texture, engine.Colour.WHITE),
            .custom => tint_texture(texture.texture, entity.colour),
            .emphasised => tint_texture(texture.texture, display.theme.emphasised_text_colour),
            .success => tint_texture(texture.texture, display.theme.success_text_colour),
            .failed => tint_texture(texture.texture, display.theme.failed_text_colour),
            .faded => tint_texture(texture.texture, display.theme.faded_text_colour),
            .tinted => tint_texture(texture.texture, display.theme.tinted_text_colour),
            .background => tint_texture(texture.texture, engine.Colour.WHITE),
        }

        dest.height *= x_scale;

        if (entity.flip.x) {
            dest.x += dest.width;
            dest.width = 0 - dest.width;
        }
        if (entity.flip.y) {
            dest.y += dest.height;
            dest.height = 0 - dest.height;
        }

        display.renderTexture(texture.texture, &source, &dest);
    }
}

/// Calculate the slice of the source image and the slice of the target drawing
/// area based on the scaling and alignment setting.
pub fn applyContentScale(
    scale: Fit,
    source: *Rect,
    dest: *Rect,
    child_align: engine.Entity.ChildLayout,
) void {
    //if (scale == .fit and child_align.x == .centre)
    //    engine.log.warn("from {any}", .{dest});

    switch (scale) {
        .stretch => {
            // One to one mapping. No ajustment needed
        },
        .fit => {
            // Partially fill the target area leaving margins.
            // Slice a section of the destination image to place the source.
            // some of the destination area.
            const dst_scale: f32 = dest.width / dest.height;
            const src_scale: f32 = source.width / source.height;
            if (src_scale >= dst_scale) {
                // image too wide, hight will have blank space
                const dest_height = dest.height;
                dest.height = dest.width / src_scale;
                // sprite is drawn at top of its rect, unless a
                // different child alignment is chosen.
                switch (child_align.y) {
                    .start => {}, // already at top
                    .centre => dest.y += ((dest_height - dest.height) / 2),
                    .end => dest.y += (dest_height - dest.height),
                }
            } else {
                // image too tall/high, width will have blank space
                const dest_width = dest.width;
                dest.width = dest.height * src_scale;
                // sprite is drawn at start/left of its rect, unless
                // a different child alignment is chosen.
                switch (child_align.x) {
                    .start => {}, // already at top
                    .centre => dest.x += ((dest_width - dest.width) / 2),
                    .end => dest.x += (dest_width - dest.width),
                }
            }
        },
        .fill => {
            // Completely fill the target area.
            // Slice a section of the source image to fill the destination.
            const dst_scale: f32 = dest.width / dest.height;
            const src_scale: f32 = source.width / source.height;
            if (src_scale >= dst_scale) {
                // Slice off some width
                const source_width = source.width;
                source.width = source.height * dst_scale;
                switch (child_align.x) {
                    .start => {},
                    .centre => source.x = (source_width - source.width) / 2,
                    .end => source.x = (source_width - source.width),
                }
            } else {
                // Slice off some height
                const source_height = source.height;
                source.height = source.width / dst_scale;
                switch (child_align.y) {
                    .start => {},
                    .centre => source.y = (source_height - source.height) / 2,
                    .end => source.y = (source_height - source.height),
                }
            }
        },
    }
    //if (scale == .fit and child_align.x == .centre)
    //    engine.log.warn("to {any}", .{dest});
}

test "scale_horizontal_fit" {
    const initial_source: Rect = .{ .x = 0, .y = 0, .width = 60, .height = 30 };
    const initial_dest: Rect = .{ .x = 10, .y = 20, .width = 100, .height = 40 };

    {
        var source: Rect = initial_source;
        var dest: Rect = initial_dest;
        applyContentScale(.stretch, &source, &dest, .{ .x = .centre, .y = .centre });
        try expectEqual(source, initial_source);
        try expectEqual(dest, initial_dest);
    }

    {
        // Fit to left
        var source = initial_source;
        var dest = initial_dest;
        applyContentScale(.fit, &source, &dest, .{ .x = .start, .y = .start });
        try expectEqual(initial_source, source);
        try expectEqual(10, dest.x);
        try expectEqual(20, dest.y);
        try expectEqual((initial_source.width / initial_source.height) * initial_dest.height, dest.width);
        try expectEqual(initial_dest.height, dest.height);
    }

    {
        // Fit to horizontal right
        var source = initial_source;
        var dest = initial_dest;
        applyContentScale(.fit, &source, &dest, .{ .x = .end, .y = .start });
        try expectEqual(source, initial_source);
        const width = (initial_source.width / initial_source.height) * initial_dest.height;
        try expectEqual(initial_dest.x + initial_dest.width - width, dest.x);
        try expectEqual(20, dest.y);
        try expectEqual(width, dest.width);
        try expectEqual(initial_dest.height, dest.height);
    }

    {
        // Fit to horizontal centre
        var source = initial_source;
        var dest = initial_dest;
        applyContentScale(.fit, &source, &dest, .{ .x = .centre, .y = .start });
        try expectEqual(source, initial_source);
        const width = (initial_source.width / initial_source.height) * initial_dest.height;
        try expectEqual(initial_dest.x + (initial_dest.width - width) / 2, dest.x);
        try expectEqual(20, dest.y);
        try expectEqual(width, dest.width);
        try expectEqual(initial_dest.height, dest.height);
    }
}

test "scale_vertical_fit" {
    const initial_source: Rect = .{ .x = 0, .y = 0, .width = 30, .height = 60 };
    const initial_dest: Rect = .{ .x = 10, .y = 20, .width = 40, .height = 100 };

    {
        var source: Rect = initial_source;
        var dest: Rect = initial_dest;
        applyContentScale(.stretch, &source, &dest, .{ .x = .centre, .y = .centre });
        try expectEqual(source, initial_source);
        try expectEqual(dest, initial_dest);
    }

    {
        // Fit to top
        var source = initial_source;
        var dest = initial_dest;
        applyContentScale(.fit, &source, &dest, .{ .x = .start, .y = .start });
        try expectEqual(source, initial_source);
        try expectEqual(10, dest.x);
        try expectEqual(20, dest.y);
        try expectEqual(initial_dest.width, dest.width);
        try expectEqual((initial_source.height / initial_source.width) * initial_dest.width, dest.height);
    }

    {
        // Fit to bottom
        var source = initial_source;
        var dest = initial_dest;
        applyContentScale(.fit, &source, &dest, .{ .x = .start, .y = .end });
        try expectEqual(source, initial_source);
        const height = (initial_source.height / initial_source.width) * initial_dest.width;
        try expectEqual(80, height);
        try expectEqual(10, dest.x);
        try expectEqual(initial_dest.y + initial_dest.height - height, dest.y);
        try expectEqual(initial_dest.width, dest.width);
        try expectEqual(height, dest.height);
    }

    {
        // Fit to centre
        var source = initial_source;
        var dest = initial_dest;
        applyContentScale(.fit, &source, &dest, .{ .x = .start, .y = .centre });
        try expectEqual(source, initial_source);
        const height = (initial_source.height / initial_source.width) * initial_dest.width;
        try expectEqual(10, dest.x);
        try expectEqual(initial_dest.y + (initial_dest.height - height) / 2, dest.y);
        try expectEqual(initial_dest.width, dest.width);
        try expectEqual(height, dest.height);
    }
}

test "scale_horizontal_fill" {
    // Some height will be removed from the source image to fill the target.
    // Source image height will be sliced to 24 pixels.
    const initial_source: Rect = .{ .x = 0, .y = 0, .width = 60, .height = 30 };
    const initial_dest: Rect = .{ .x = 10, .y = 20, .width = 100, .height = 40 };

    const height = initial_source.width * (initial_dest.height / initial_dest.width);

    {
        // Fill to left
        var source = initial_source;
        var dest = initial_dest;
        applyContentScale(.fill, &source, &dest, .{ .x = .start, .y = .start });
        try expectEqual(initial_dest, dest);
        try expectEqual(10, dest.x);
        try expectEqual(20, dest.y);
        try expectEqual(initial_dest.width, dest.width);
        try expectEqual(initial_dest.height, dest.height);
        try expectEqual(0, source.x);
        try expectEqual(0, source.y);
        try expectEqual(initial_source.width, source.width);
        try expectEqual(height, source.height);
    }

    {
        // Fit to horizontal right
        var source = initial_source;
        var dest = initial_dest;
        applyContentScale(.fill, &source, &dest, .{ .x = .end, .y = .start });
        try expectEqual(initial_dest, dest);
        try expectEqual(10, dest.x);
        try expectEqual(20, dest.y);
        try expectEqual(initial_dest.width, dest.width);
        try expectEqual(initial_dest.height, dest.height);
        try expectEqual(0, source.x);
        try expectEqual(source.height - height, source.y);
        try expectEqual(initial_source.width, source.width);
        try expectEqual(height, source.height);
    }

    {
        // Fit to horizontal centre
        var source = initial_source;
        var dest = initial_dest;
        applyContentScale(.fill, &source, &dest, .{ .x = .centre, .y = .start });
        try expectEqual(initial_dest, dest);
        try expectEqual(10, dest.x);
        try expectEqual(20, dest.y);
        try expectEqual(initial_dest.width, dest.width);
        try expectEqual(initial_dest.height, dest.height);
        try expectEqual(0, source.x);
        try expectEqual((source.height - height) / 2, source.y);
        try expectEqual(initial_source.width, source.width);
        try expectEqual(height, source.height);
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
const expectEqual = std.testing.expectEqual;
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
