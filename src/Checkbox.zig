/// A clickable label that also includes a checkbox to display the
/// checkbox state.
pub const Checkbox = @This();

checked: bool = false,
font: *Font = undefined,
font_name: ?[]const u8 = null,
text_size: TextSize = .normal,
text: []const u8 = "",
translated: []const u8 = "",
elements: ArrayListUnmanaged(TextElement) = .empty,
line_height: f32 = 1,
checkbox_size: Size = .{ .width = 0, .height = 0 },
on_texture: ?*Texture = null,
off_texture: ?*Texture = null,
on_change: Entity.Callback = .empty,

/// Draw a radio box combined with a text label.
pub inline fn draw(
    self: *const Checkbox,
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
    draw_text_elements(self.elements.items, loc, text_colour, display.renderer, parent_clip);

    const checkbox = self.checkbox_size;
    var dest = Rect{
        .x = entity.rect.x + entity.rect.width - checkbox.width - entity.pad.left,
        .y = entity.rect.y + (entity.rect.height / 2) - (checkbox.height / 2),
        .width = checkbox.width,
        .height = checkbox.height,
    };
    dest = dest.move(scroll_offset);
    if (self.checked) {
        if (self.on_texture) |texture| {
            _ = sdl.SDL_RenderTexture(display.renderer, texture.texture, null, @ptrCast(&dest));
        }
    } else {
        if (self.off_texture) |texture| {
            _ = sdl.SDL_RenderTexture(display.renderer, texture.texture, null, @ptrCast(&dest));
        }
    }
}

pub inline fn minimum_needed_width(
    _: *Checkbox,
    display: *Display,
    entity: *Entity,
    max_width: f32,
) f32 {
    const margins = entity.pad.left + entity.pad.right + entity.type.checkbox.checkbox_size.width;

    const allowed_width = engine.directional_clamp(
        entity.layout.x,
        @max(0, entity.minimum.width - margins),
        @max(0, max_width - margins),
        @max(0, @min(
            entity.maximum.width - margins,
            max_width - margins,
        )),
    );

    switch (entity.layout.x) {
        .shrinks, .grows => return @max(
            Label.layout(entity, display.scale, allowed_width).width +
                margins +
                entity.type.checkbox.checkbox_size.width,
            entity.minimum.width,
        ),
        //return entity.rect.width + entity.pad.left + entity.type.checkbox.checkbox_size.width
        .fixed => return entity.rect.width,
    }
}

pub inline fn minimum_needed_height(
    _: *Checkbox,
    display: *Display,
    entity: *Entity,
    parent_inner_width: f32,
) f32 {
    // Simulate a draw of this entity to see how many lines it
    // would take. This is done when the label is created but also
    // needs to be done here as the width of the label may have changed.
    switch (entity.layout.y) {
        .shrinks, .grows => {
            _ = Label.layout(entity, display.scale, parent_inner_width);
            return entity.rect.height;
        },
        .fixed => {
            return entity.rect.height;
        },
    }
}

const std = @import("std");
const ArrayListUnmanaged = std.ArrayListUnmanaged;

const engine = @import("engine.zig");
const sdl = engine.sdl;
const err = engine.err;
const warn = engine.warn;
const info = engine.info;
const debug = engine.debug;
const trace = engine.trace;
const Display = engine.Display;
const Entity = engine.Entity;
const Error = engine.Error;
const Font = engine.Font;
const Texture = engine.Texture;
const TextSize = engine.TextSize;

const Label = @import("Label.zig");

const Clip = Entity.Clip;
const Rect = Entity.Rect;
const Size = Entity.Size;
const TextElement = Entity.TextElement;
const ToggleState = Entity.ToggleState;
const Vector = Entity.Vector;

const draw_text_elements = @import("Label.zig").draw_text_elements;
