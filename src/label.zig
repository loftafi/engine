pub fn Label(comptime T: type) type {
    return struct {
        pub const Self = @This();

        font: *Font = undefined,
        font_name: ?[]const u8 = null,
        text: []const u8 = "",
        translated: []const u8 = "",
        elements: ArrayListUnmanaged(TextElement) = .empty,
        line_height: f32 = 1,
        text_size: T = .normal,

        on_selected: Entity(T).Callback = .empty,
        on_mouse_down: Entity(T).Callback = .empty,
        on_mouse_up: Entity(T).Callback = .empty,
        on_mouse_enter: Entity(T).Callback = .empty,
        on_mouse_exit: Entity(T).Callback = .empty,

        pub fn setup(
            label: *Self,
            allocator: Allocator,
            display: *Display(T),
            entity: *Entity(T),
        ) (Error || Allocator.Error || Resources.Error)!void {
            entity.texture = null;
            entity.background.image = null;
            label.translated = "";
            label.elements = .empty;
            label.font = try select_font(display.fonts.items, label.font_name);

            if (entity.focus == .unspecified) {
                if (entity.type.label.on_mouse_down.func != null)
                    entity.focus = .can_focus
                else if (entity.type.label.on_mouse_up.func != null)
                    entity.focus = .can_focus
                else if (entity.type.label.on_selected.func != null)
                    entity.focus = .can_focus
                else
                    entity.focus = .accessibility_focus;
            }
            try entity.set_text(allocator, display, entity.type.label.text);

            // Is there a background for this label?
            if (entity.background.image_name) |name| {
                if (try display.load_texture(allocator, name)) |texture|
                    entity.background.image = texture;
            }
        }

        /// Return true if this button can be interacted with.
        pub inline fn clickable(label: *Self) bool {
            return label.on_mouse_up.func != null or
                label.on_mouse_down.func != null or
                label.on_mouse_enter.func != null or
                label.on_mouse_exit.func != null or
                label.on_selected.func != null;
        }

        /// Calculate the layout of all elements, and optionally render every entity.
        ///
        /// Normally text is converted to an image and rendered left to right, starting
        /// at the top left corner of the entity (including padding).
        ///
        /// If the text is centred or right aligned, then each line must be pushed along
        /// by a certain offset amount.
        pub inline fn draw(
            self: *const Self,
            entity: *Entity(T),
            display: *Display(T),
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
        }

        // Return the absolute minimum width needed, even if more space
        // could be used. `.grows`  is ignored for the purpose of finding
        // the minimum width.
        //
        // `parent_inner_width` is the maximum space this entity could
        // theoretically grow to. Text might wrap if wider than this.
        pub inline fn minimum_needed_width(
            _: *const Self,
            display: *const Display(T),
            entity: *const Entity(T),
            max_width: f32,
        ) f32 {
            const padding = entity.pad.left + entity.pad.right;

            const allowed_width = engine.directional_clamp(
                entity.layout.x,
                @max(0, entity.minimum.width - padding),
                @max(0, max_width - padding),
                @max(0, @min(
                    entity.maximum.width - padding,
                    max_width - padding,
                )),
            );

            // How wide does the label text get when laying it out.
            return switch (entity.layout.x) {
                .shrinks, .grows => return @max(
                    entity.layout_label(display.scale, allowed_width).width + padding,
                    entity.minimum.width,
                ),
                .fixed,
                => entity.rect.width,
            };
        }

        // `parent_inner_width` is the maximum space this entity could
        // theoretically grow to. Text might wrap if wider than this.
        pub inline fn minimum_needed_height(
            _: *const Self,
            display: *const Display(T),
            entity: *const Entity(T),
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
                    entity.layout_label(display.scale, allowed_width).height + entity.pad.top + entity.pad.bottom,
                    entity.minimum.height,
                ),
                .fixed => entity.rect.height,
            };
        }
    };
}

pub fn draw_text_elements(
    items: []TextElement,
    loc: Vector,
    current_colour: engine.Colour,
    renderer: *sdl.SDL_Renderer,
    parent_clip: ?Clip,
) void {
    for (items) |*item| {
        const pos = item.location.move(loc);
        if (parent_clip) |clip| {
            if (pos.x + pos.width < clip.left) continue;
            if (pos.y + pos.height + 1 < clip.top) continue;
            if (pos.x > clip.right) continue;
            if (pos.y > clip.bottom) continue;
        }

        // Only render text if display parameter is provided
        _ = sdl.SDL_SetTextureColorMod(
            item.texture,
            current_colour.r,
            current_colour.g,
            current_colour.b,
        );
        _ = sdl.SDL_SetTextureAlphaMod(item.texture, current_colour.a);
        _ = sdl.SDL_RenderTexture(
            renderer,
            item.texture,
            null,
            @ptrCast(&pos),
        );
    }
}

test "label_panel_placement" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    // The display takes ownership of the resources object

    var display = try Display(TextSize(10)).create(allocator, io, test_config);
    defer display.destroy(allocator);
    _ = try display.loadFont(allocator, io, "Roboto-Light");
    try eq(1, display.fonts.items.len);
    display.root.rect.width = 300;
    display.root.rect.height = 200;
    display.root.minimum.width = 300;
    display.root.minimum.height = 200;
    display.root.maximum.width = 300;
    display.root.maximum.height = 200;

    const panel = try display.add_panel(allocator, .{
        .type = .{ .panel = .{ .direction = .top_to_bottom } },
        .layout = .{ .x = .grows, .y = .grows },
    });
    display.need_relayout = true;
    display.relayout();

    try eq(300, panel.rect.width);
    try eq(200, panel.rect.height);

    const child = try panel.add(allocator, display, .{
        .type = .{ .label = .{ .text = "Simple" } },
        .layout = .{ .x = .shrinks, .y = .shrinks },
    });
    child.pad = .{ .left = 0, .right = 0, .top = 0, .bottom = 0 };

    // Test alignment without padding
    panel.type.panel.direction = .top_to_bottom;
    display.need_relayout = true;
    display.relayout();
    try eq(51, child.rect.width);
    try eq(20, child.rect.height);
    try eq(0, child.rect.x);
    try eq(0, child.rect.y);

    panel.type.panel.direction = .top_left;
    display.need_relayout = true;
    display.relayout();
    try eq(51, child.rect.width);
    try eq(20, child.rect.height);
    try eq(0, child.rect.x);
    try eq(0, child.rect.y);

    panel.type.panel.direction = .top_right;
    display.need_relayout = true;
    display.relayout();
    try eq(51, child.rect.width);
    try eq(20, child.rect.height);
    try eq(panel.rect.width - child.rect.width, child.rect.x);
    try eq(0, child.rect.y);

    panel.type.panel.direction = .centre;
    display.need_relayout = true;
    display.relayout();
    try eq(51, child.rect.width);
    try eq(20, child.rect.height);
    try eq(@round(panel.rect.width / 2 - child.rect.width / 2), child.rect.x);
    try eq(@round(panel.rect.height / 2 - child.rect.height / 2), child.rect.y);
}

test "label_single_word_alignment" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    // The display takes ownership of the resources object

    var display = try headless_display(allocator, io, TextSize(10), 300, 200, 2);
    defer display.destroy(allocator);

    const panel = try display.add_panel(allocator, .{
        .name = "parent",
        .type = .{ .panel = .{ .direction = .top_to_bottom } },
        .layout = .{ .x = .grows, .y = .grows },
    });
    display.need_relayout = true;
    display.relayout();

    try eq(300, panel.rect.width);
    try eq(200, panel.rect.height);

    const child = try panel.add(allocator, display, .{
        .name = "child",
        .type = .{ .label = .{ .text = "Simple" } },
        .layout = .{ .x = .grows, .y = .shrinks },
    });
    child.pad = .{ .left = 0, .right = 0, .top = 0, .bottom = 0 };

    // Test alignment without padding
    display.need_relayout = true;
    display.relayout();
    try eq(300, child.rect.width);
    try eq(20, child.rect.height);
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
        try eq(51, element.location.width);
        try eq(20, element.location.height);
        try eq(0, element.location.x);
        try eq(0, element.location.y);
    }

    {
        child.child_align.x = .end;
        display.need_relayout = true;
        display.relayout();
        const element = child.type.label.elements.items[0];
        try eq(51, element.location.width);
        try eq(20, element.location.height);
        try eq(panel.rect.width - element.location.width, element.location.x);
        try eq(0, element.location.y);
    }

    {
        child.child_align.x = .centre;
        display.need_relayout = true;
        display.relayout();
        const element = child.type.label.elements.items[0];
        try eq(51, element.location.width);
        try eq(20, element.location.height);
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
        try eq(51, element.location.width);
        try eq(20, element.location.height);
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
        try eq(51, element.location.width);
        try eq(20, element.location.height);
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
        try eq(51, element.location.width);
        try eq(20, element.location.height);
        // `entity.location` is relative to 0x0 not the on screen position, so
        // x is simply how far along from the first top/left drawing position.
        try eq(@round((panel.rect.width - child.pad.left - child.pad.right) / 2 - (element.location.width / 2)), element.location.x);
        try eq(0, element.location.y);
    }
}

test "label_multiword_align" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var display = try headless_display(allocator, io, TextSize(10), 200, 200, 2);
    defer display.destroy(allocator);

    const panel = try display.add_panel(allocator, .{
        .name = "parent",
        .type = .{ .panel = .{ .direction = .top_to_bottom } },
        .layout = .{ .x = .grows, .y = .grows },
    });
    display.need_relayout = true;
    display.relayout();

    try eq(200, panel.rect.width);
    try eq(200, panel.rect.height);

    const child = try panel.add(allocator, display, .{
        .name = "child",
        .type = .{ .label = .{ .text = "Officially Simple Readingology" } },
        .layout = .{ .x = .grows, .y = .shrinks },
    });
    child.pad = .{ .left = 0, .right = 0, .top = 0, .bottom = 0 };

    // Test alignment without padding
    display.need_relayout = true;
    display.relayout();
    try eq(200, child.rect.width);
    try eq(40, child.rect.height);
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
        try eq(63, element1.location.width);
        try eq(20, element1.location.height);
        try eq(0, element1.location.x);
        try eq(0, element1.location.y);

        try eq(51, element2.location.width);
        try eq(20, element2.location.height);
        try eq(63 + display.text_height.word_spacing(display.scale), element2.location.x);
        try eq(0, element2.location.y);

        // Wrap to next line
        try eq(100, element3.location.width);
        try eq(20, element3.location.height);
        try eq(0, element3.location.x);
        try eq(20, element3.location.y);
    }

    {
        // Align both lines to right
        child.child_align.x = .end;
        display.need_relayout = true;
        display.relayout();
        const element1 = child.type.label.elements.items[0];
        const element2 = child.type.label.elements.items[1];
        const element3 = child.type.label.elements.items[2];
        try eq(63, element1.location.width);
        try eq(20, element1.location.height);
        try eq(panel.rect.width - element2.location.width, element2.location.x);
        try eq(0, element1.location.y);
        try eq(panel.rect.width - element3.location.width, element3.location.x);
        try eq(20, element3.location.y);
    }

    {
        child.child_align.x = .centre;
        display.need_relayout = true;
        display.relayout();
        const element1 = child.type.label.elements.items[0];
        const element2 = child.type.label.elements.items[1];
        const element3 = child.type.label.elements.items[2];
        try eq(63, element1.location.width);
        try eq(20, element1.location.height);
        const space = display.text_height.word_spacing(display.scale);
        try eq((panel.rect.width - element2.location.width - element1.location.width - space) / 2, element1.location.x);
        try eq(0, element1.location.y);
        try eq((panel.rect.width - element3.location.width) / 2, element3.location.x);
        try eq(20, element3.location.y);
    }
}

test "shrunk_label_in_panel" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var display = try headless_display(allocator, io, TextSize(10), 200, 100, 2);
    defer display.destroy(allocator);

    const panel = try display.add_panel(allocator, .{
        .layout = .{ .x = .grows, .y = .grows },
        .type = .{ .panel = .{ .direction = .centre } },
        .pad = .{ .left = 4, .right = 6, .top = 2, .bottom = 8 },
    });
    display.need_relayout = true;
    display.relayout();

    try eq(200, panel.rect.width);
    try eq(100, panel.rect.height);

    const child = try panel.add(allocator, display, .{
        .type = .{ .label = .{ .text = "Simple" } },
        .layout = .{ .x = .shrinks, .y = .shrinks },
    });
    child.pad = .{ .left = 0, .right = 0, .top = 0, .bottom = 0 };

    panel.child_align.x = .start;
    panel.type.panel.direction = .left_to_right;
    display.need_relayout = true;
    display.relayout();
    try eq(51, child.rect.width);
    try eq(20, child.rect.height);
    try eq(4, child.rect.x);
    try eq(2, child.rect.y);

    panel.child_align.x = .end;
    panel.type.panel.direction = .left_to_right;
    display.need_relayout = true;
    display.relayout();
    try eq(51, child.rect.width);
    try eq(20, child.rect.height);
    try eq(panel.rect.width - panel.pad.right - child.rect.width, child.rect.x);
    try eq(2, child.rect.y);

    panel.child_align.x = .centre;
    panel.type.panel.direction = .left_to_right;
    display.need_relayout = true;
    display.relayout();
    try eq(51, child.rect.width);
    try eq(20, child.rect.height);
    try eq(@round((panel.rect.width - panel.pad.left - panel.pad.right) / 2 - (child.rect.width / 2)) + panel.pad.left, child.rect.x);
    try eq(74, child.rect.x);
    try eq(2, child.rect.y);

    // Where would the draw function theoretically put this element
    const loc = Vector{ .x = child.rect.x, .y = child.rect.y };
    const would_draw_at = child.type.label.elements.items[0].location.move(loc);
    try eq(74, would_draw_at.x);
    try eq(2, would_draw_at.y);
}

const std = @import("std");
const Allocator = std.mem.Allocator;
const eq = std.testing.expectEqual;
const ArrayListUnmanaged = std.ArrayListUnmanaged;

const sdl = @import("sdl");

const resources = @import("resources");
const Resources = resources.Resources;

const engine = @import("engine.zig");
const err = engine.err;
const warn = engine.warn;
const info = engine.info;
const debug = engine.debug;
const trace = engine.trace;
const clamp = engine.clamp;
const Clip = engine.Clip;
const Display = engine.Display;
const Entity = engine.Entity;
const Error = engine.Error;
const Font = engine.Font;
const Size = engine.Size;
const TextSize = engine.TextSize;
const Texture = engine.Texture;
const ToggleState = engine.ToggleState;

const TextElement = @import("entity.zig").TextElement;
const Vector = @import("entity.zig").Vector;

const select_font = @import("entity.zig").select_font;
const test_config = @import("test.zig").test_config;
const headless_display = @import("test.zig").headless_display;
