pub fn Sprite(comptime T: type) type {
    return struct {
        pub const Self = @This();
        on_click: Entity(T).Callback = .empty,
        update: Entity(T).UpdateCallback = .empty,
        scale: Fit = .stretch,

        /// Draw the foreground image `texture` of the sprite loaded from the
        /// `texture_name` string. Does not draw the `background.image` texture.
        /// The background image is drawn in the generic background drawing function.
        pub inline fn draw(
            self: *const Self,
            entity: *Entity(T),
            display: *Display(T),
            _: Vector,
            _: ?Clip,
            scroll_offset: Vector,
        ) void {
            if (entity.texture) |texture| {
                var dest: Rect = .{
                    .x = entity.rect.x + entity.pad.left,
                    .y = entity.rect.y + entity.pad.top,
                    .width = entity.rect.width - entity.pad.left - entity.pad.right,
                    .height = entity.rect.height - entity.pad.top - entity.pad.bottom,
                };
                dest = dest.move(&scroll_offset);

                if (dest.height <= 0 or dest.width <= 0) return;

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

                _ = sdl.SDL_RenderTexture(display.renderer, texture.texture, @ptrCast(&source), @ptrCast(&dest));
            }
        }
    };
}

const std = @import("std");
const ArrayListUnmanaged = std.ArrayListUnmanaged;

const sdl = @import("sdl");

const engine = @import("engine.zig");
const err = engine.err;
const Clip = engine.Clip;
const Display = engine.Display;
const Entity = engine.Entity;
const Error = engine.Error;
const Fit = engine.Fit;
const Font = engine.Font;
const Rect = engine.Rect;
const Size = engine.Size;
const Texture = engine.Texture;
const Vector = engine.Vector;
const Callback = engine.Callback;
const UpdateCallback = engine.UpdateCallback;

const tint_texture = @import("entity.zig").tint_texture;
