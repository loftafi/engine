/// Describe an entity that will be rendered on the screen during a draw
/// loop. See `Type` for the types of entities that may be rendered.
pub const Entity = @This();

pub const default = Entity{
    .name = "",
    .aria_label = null,
    .visible = .hidden,
    .type = .{ .panel = .{} },
};

/// The `name` is not intended to be shown to the user. This name can
/// be used by log and debug code to describe the entity.
name: []const u8 = "",

/// Text for screen reader to read when a user tabs into or
/// selects this entity.
aria_label: ?[]const u8 = null,

/// Usually the `visibie` value is `.hidden` or `.visible`. If the
/// entity is inside a scroll panel, `.visible` entities may become
/// `.clipped` when they are _visible_ do not need to be drawn.
visible: Visibility = .visible,

/// The size and posiiton if this entity. If this entity is
/// inside the entity heirachy, the position and size is automatically
/// updated when the window is updated or resized. The `layout` variable
/// determins if these values are automatically updated or remain fixed.
rect: Rect = .{ .x = 0, .y = 0, .width = 0, .height = 0 },

/// If this entity is inside the entity heirachy, this is a hard
/// limit on how small the `rect` may be.
minimum: Size = .{ .width = 0, .height = 0 },

/// If this entity is inside the entity heirachy, this is a hard
/// limit on how large the `rect` may be.
maximum: Size = .{ .width = 0, .height = 0 },

/// The `layout` settings determine if the `rect` is a fixed size
/// and position, or if the `rect` size and position is autoatically
/// updated inside the entity heirachy.
layout: Layout = .{ .x = .fixed, .y = .fixed },

/// Panels contain child entities, and text elmeents contain words, and
/// sprites contain an image. the `child_align` setting indicates if the
/// child contents are drawn at the start, centre or end of this entity.
child_align: ChildLayout = .{ .x = .start, .y = .start },

/// Scroll panels use 'offset` to track how far it has scrolled.
offset: Vector = .{ .x = 0, .y = 0 },

/// Padding is used to add space _inside_ the `rect` of this entity.
pad: Clip = .{ .top = 0, .left = 0, .right = 0, .bottom = 0 },

/// Sprites that don't move have zero velocity. Sprites with a velocity
/// move every frame according to the current velocity.
velocity: Vector = .{ .x = 0, .y = 0 },

/// Flip foreground and background images if they are set.
flip: Flip = .{ .x = false, .y = false },

pressed: bool = false,
focussed: bool = false,
hovered: bool = false,
focus: FocusOption = .unspecified,

texture: ?*Texture = null,
texture_name: ?[]const u8 = null,

style: Theme.Style = .normal,
colour: Colour = Colour.WHITE,

background: Background = .{
    .colour = Colour.TRANSPARENT,
    .image = null,
    .image_name = null,
    .corner_radius = 0,
    .image_corner_radius = 0,
},

border_colour: Colour = Colour.TRANSPARENT,
border_width: f32 = 0,

on_resized: BoolCallback = .empty,
on_visibility: StateCallback = .empty,

type: union(Type) {
    button: Button,
    checkbox: Checkbox,
    expander: Expander,
    label: Label,
    panel: Panel,
    progress_bar: ProgressBar,
    rectangle: Rectangle,
    sprite: Sprite,
    text_input: TextInput,
},

pub fn setup(
    entity: *Entity,
    display: *Display,
) (Error || Allocator.Error || Resources.Error)!void {
    switch (entity.type) {
        .panel => try entity.setup_panel(display),
        .button => try entity.setup_button(display),
        .label => try entity.type.label.setup(display, entity),
        .rectangle => try entity.setup_rect(display),
        .checkbox => try entity.setup_checkbox(display),
        .sprite => try entity.setup_sprite(display),
        .progress_bar => try entity.setup_progress_bar(display),
        .expander => try entity.setup_expander(display),
        .text_input => try entity.setup_text_input(display),
    }

    // Warn about invalid layout configurations
    if (entity.layout.x == .fixed and entity.rect.width < entity.minimum.width)
        warn("{t} `{s}` has fixed width {d} but minimum width {d}.", .{
            entity.type,
            entity.name,
            entity.rect.width,
            entity.minimum.width,
        });

    if (entity.layout.y == .fixed and entity.rect.height < entity.minimum.height)
        warn("{t} `{s}` has fixed height {d} but minimum height {d}.", .{
            entity.type,
            entity.name,
            entity.rect.height,
            entity.minimum.height,
        });

    var float_error = false;
    switch (entity.layout.x) {
        .grows => if (entity.layout.position == .float) {
            entity.layout.x = .fixed;
            float_error = true;
        },
        .shrinks => if (entity.layout.position == .float) {
            entity.layout.x = .fixed;
            float_error = true;
        },
        .fixed => {},
    }
    switch (entity.layout.y) {
        .grows => if (entity.layout.position == .float) {
            entity.layout.y = .fixed;
            float_error = true;
        },
        .shrinks => if (entity.layout.position == .float) {
            entity.layout.y = .fixed;
            float_error = true;
        },
        .fixed => {},
    }
    if (float_error)
        err("floating items cant grow or shrink. {s} {s}", .{
            entity.name,
            @tagName(entity.type),
        });
}

/// Cleanup memory associated with this entity. This is automatically
/// called on all entities inside the display when the display is destroyed.
///
/// Never call `destroy()` unless you know the entity is not inside the
/// display tree.
pub fn destroy(self: *Entity, display: *Display) void {
    self.deinit(display.allocator, display);
    display.allocator.destroy(self);
}

/// Cleanup memory associated with this entity. This is automatically
/// called on all entities inside the display when the display is destroyed.
///
/// Never call `deinit()` unless you know the entity is not inside the
/// display tree.
pub fn deinit(self: *Entity, allocator: Allocator, display: *Display) void {
    // Cleanup shared attributes

    if (self.texture) |texture| {
        display.releaseTextureResource(texture);
        self.texture = null;
    }

    if (self.background.image) |texture| {
        display.releaseTextureResource(texture);
        self.background.image = null;
    }

    // Cleanup entity type specific attributes
    switch (self.type) {
        .panel => |*i| {
            for (i.*.children.items) |child| {
                child.destroy(display);
            }
            i.*.children.deinit(allocator);
        },
        .progress_bar => {
            //
        },
        .expander => {
            //
        },
        .text_input => |*i| {
            i.*.runes.deinit(allocator);
            i.*.text.deinit(allocator);
        },
        .label => |*i| {
            i.*.elements.deinit(allocator);
        },
        .checkbox => |*i| {
            if (i.*.on_texture) |texture| {
                display.releaseTextureResource(texture);
                i.*.on_texture = null;
            }
            if (i.*.off_texture) |texture| {
                display.releaseTextureResource(texture);
                i.*.off_texture = null;
            }
            i.*.elements.deinit(allocator);
        },
        .rectangle => {},
        .sprite => {},
        .button => |*i| {
            if (i.*.icon.hover) |texture| {
                display.releaseTextureResource(texture);
            }
            if (i.*.icon.pressed) |texture| {
                display.releaseTextureResource(texture);
            }
            if (i.*.button.hover) |texture| {
                display.releaseTextureResource(texture);
            }
            if (i.*.button.pressed) |texture| {
                display.releaseTextureResource(texture);
            }
        },
    }
    self.* = undefined;
}

/// Find a direct child of this entity by the name attached to
/// the entity.
pub fn getChildByName(self: *Entity, name: []const u8) ?*Entity {
    trace("searching for {s} in {s}", .{ name, self.name });
    for (self.type.panel.children.items) |entity| {
        if (std.mem.eql(u8, name, entity.name)) {
            trace("searching for {s} in {s}. match", .{ name, self.name });
            return entity;
        }
    }
    trace("searching for {s} in {s}. no match", .{ name, self.name });
    return null;
}

pub fn getChild(self: *Entity, no: usize) ?*Entity {
    if (self.type != .panel) {
        warn("getChild called on {t} name={s}", .{ self.type, self.name });
        return null;
    }
    trace("searching for child {d} in {s}", .{ no, self.name });
    if (no < self.type.panel.children.items.len)
        return self.type.panel.children.items[no];
    trace("searching for child {d} in {s}. no match", .{ no, self.name });
    return null;
}

/// Return true if this entity appears under this point on the screen.
pub fn atPoint(self: *Entity, cursor: Vector, parent_scroll_offset: Vector) bool {
    const point = Vector{ .x = self.rect.x, .y = self.rect.y };
    if (self.type == .panel and
        (self.type.panel.scrollable.scroll.x or self.type.panel.scrollable.scroll.y))
    {
        // Scrollable panels live at their pre-scroll-offset location.
        if (cursor.x < point.x) return false;
        if (cursor.y < point.y) return false;
        if (cursor.x > point.x + self.rect.width) return false;
        if (cursor.y > point.y + self.rect.height) return false;
    } else {
        const current = point.add(self.offset).add(parent_scroll_offset);
        if (cursor.x < current.x) return false;
        if (cursor.y < current.y) return false;
        if (cursor.x > current.x + self.rect.width) return false;
        if (cursor.y > current.y + self.rect.height) return false;
    }
    return true;
}

pub inline fn applyBackgroundTint(
    self: *Entity,
    display: *Display,
    texture: *sdl.SDL_Texture,
) void {
    if (self.type == .button) {
        switch (self.style) {
            .success => {
                tint_texture(texture, display.theme.success_button_colour);
                return;
            },
            .failed => {
                tint_texture(texture, display.theme.failed_button_colour);
                return;
            },
            .custom => {
                if (self.background.colour.a != Colour.TRANSPARENT.a)
                    tint_texture(texture, self.background.colour);
                return;
            },
            else => {
                // Otherwise apply toggle colurs if needed
            },
        }

        switch (self.type.button.toggle) {
            .off, .locked_off => tint_texture(texture, display.theme.toggle_button),
            .on => tint_texture(texture, display.theme.toggle_button_picked),
            .correct => tint_texture(texture, display.theme.toggle_button_correct),
            .incorrect => tint_texture(texture, display.theme.toggle_button_incorrect),
            .no_toggle, .disabled => tint_texture(texture, Colour.WHITE),
        }
        return;
    }

    if (self.type == .panel) {
        switch (self.style) {
            .emphasised => tint_texture(texture, display.theme.emphasised_panel_colour),
            .success => tint_texture(texture, display.theme.success_panel_colour),
            .failed => tint_texture(texture, display.theme.failed_panel_colour),
            .faded => tint_texture(texture, display.theme.faded_panel_colour),
            .background => tint_texture(texture, display.theme.background_colour),
            .normal => tint_texture(texture, display.theme.label_background_colour),
            .custom => tint_texture(texture, self.background.colour),
            else => {
                warn(
                    "unhandled panel tint option: {s}",
                    .{@tagName(self.style)},
                );
                tint_texture(texture, Colour.WHITE);
            },
        }
        return;
    }

    if (self.type == .sprite) {
        if (self.background.colour.a != 0) {
            tint_texture(texture, self.background.colour);
        } else {
            tint_texture(texture, Colour.WHITE);
        }
        return;
    }

    if (self.type == .label) {
        tint_texture(texture, display.theme.label_background_colour);
        return;
    }

    tint_texture(texture, Colour.WHITE);
}

/// The text_input entity may display placeholder text when there
/// is no text in the text_input. Placeholder text should be less
/// visibily prominent.
pub inline fn setPlaceholderText(
    self: *Entity,
    display: *Display,
    text: []const u8,
) !void {
    debug(
        "setPlaceholderText({s}.{s}) {s}",
        .{ @tagName(self.type), self.name, text },
    );
    switch (self.type) {
        .text_input => |*text_input| {
            if (text.len == 0) return;
            text_input.placeholder_text = text;
            _ = try text_input.font.measureText(
                display,
                text_input.text_size,
                text_input.placeholder_text.?,
            );
        },
        else => {
            info("setPlaceholderText({s}.{s}) invalid", .{ @tagName(self.type), text });
        },
    }
}

/// Find the avaialble inner width of this entity. This is the
/// width of the entity minus any padding.
pub inline fn inner_width(self: *const Entity) f32 {
    const padding = self.pad.left + self.pad.right;

    return engine.clamp(
        self.minimum.width - padding,
        self.rect.width - padding,
        self.maximum.width - padding,
    );
}

/// Find the avaialble inner height of this entity. This is the
/// height of the entity minus any padding.
pub inline fn inner_height(self: *const Entity) f32 {
    const padding = self.pad.top + self.pad.bottom;

    return engine.clamp(
        self.minimum.height - padding,
        self.rect.height - padding,
        self.maximum.height - padding,
    );
}

pub fn format(self: *const Entity, out: *std.Io.Writer) std.Io.Writer.Error!void {
    _ = try out.write(@tagName(self.type));
    if (self.name.len > 0) {
        _ = try out.write(" name=");
        _ = try out.write(self.name);
    }
    if (self.aria_label) |aria_label| {
        if (aria_label.len > 0) {
            _ = try out.write(" aria=");
            _ = try out.write(aria_label);
        }
    }
    if (self.texture_name) |name| {
        _ = try out.write(" texture=");
        _ = try out.write(name);
    }
    if (self.background.image_name) |name| {
        _ = try out.write(" background_image=");
        _ = try out.write(name);
    }
    _ = try out.print(" rect={d:1.0}x{d:1.0}/{d:1.0}x{d:1.0}", .{
        self.rect.x,
        self.rect.y,
        self.rect.width,
        self.rect.height,
    });
    if (self.minimum.height > 0 or self.minimum.width > 0) {
        _ = try out.print(" minimum={d:1.0}x{d:1.0}", .{
            self.minimum.width,
            self.minimum.height,
        });
    }
    if (self.maximum.height > 0 or self.maximum.width > 0) {
        _ = try out.print(" maximum={d:1.0}x{d:1.0}", .{
            self.maximum.width,
            self.maximum.height,
        });
    }
    if (self.pad.left > 0 or self.pad.right > 0 or self.pad.top > 0 or self.pad.bottom > 0) {
        _ = try out.write(" pad=");
        if (self.pad.left > 0)
            _ = try out.print("{d:1.0}l", .{self.pad.left});
        if (self.pad.right > 0)
            _ = try out.print("{d:1.0}r", .{self.pad.right});
        if (self.pad.top > 0)
            _ = try out.print("{d:1.0}t", .{self.pad.top});
        if (self.pad.bottom > 0)
            _ = try out.print("{d:1.0}b", .{self.pad.bottom});
    }
    if (self.style != .normal) {
        _ = try out.write(" style=");
        _ = try out.write(@tagName(self.style));
    }
    if (self.child_align.x != .start or self.child_align.y != .start) {
        _ = try out.write(" align=");
        _ = try out.write(@tagName(self.child_align.x));
        _ = try out.write("-");
        _ = try out.write(@tagName(self.child_align.y));
    }
    _ = try out.write(" layout=");
    _ = try out.write(@tagName(self.layout.x));
    _ = try out.write("/");
    _ = try out.write(@tagName(self.layout.y));
    if (self.type == .panel) {
        if (self.name.len > 0) {
            _ = try out.write(" direction=");
            _ = try out.write(@tagName(self.type.panel.direction));
        }
    }
    if (self.type == .sprite) {
        if (self.name.len > 0) {
            _ = try out.write(" stretch=");
            _ = try out.write(@tagName(self.type.sprite.scale));
        }
    }
    if (self.type == .label) {
        if (self.type.label.text.len > 0) {
            _ = try out.write(" text=");
            _ = try out.write(self.type.label.text);
        }
        if (!std.mem.eql(u8, self.type.label.text, self.type.label.translated) and self.type.label.translated.len > 0) {
            _ = try out.write(" translated=");
            _ = try out.write(self.type.label.text);
        }
        if (self.type.label.font_name) |font| {
            if (font.len > 0) {
                _ = try out.write(" font=");
                _ = try out.write(font);
            }
        }
        if (self.type.label.on_ui_event.func != null)
            _ = try out.write(" on_ui_event");
        if (self.type.label.on_pressed.func != null)
            _ = try out.write(" on_pressed");
    } else if (self.type == .button) {
        if (self.type.button.text.len > 0) {
            _ = try out.write(" text=");
            _ = try out.write(self.type.button.text);
        }
        if (!std.mem.eql(u8, self.type.button.text, self.type.button.translated) and self.type.button.translated.len > 0) {
            _ = try out.write(" translated=");
            _ = try out.write(self.type.button.translated);
        }
        if (self.type.button.icon.size.height > 0 or self.type.button.icon.size.width > 0) {
            _ = try out.print(" icon.size={d:1.0}x{d:1.0}", .{
                self.type.button.icon.size.width,
                self.type.button.icon.size.height,
            });
        }
        if (self.type.button.font_name) |font| {
            if (font.len > 0) {
                _ = try out.write(" font=");
                _ = try out.write(font);
            }
        }

        if (self.type.button.on_ui_event.func != null)
            _ = try out.write(" on_ui_event");
        if (self.type.button.on_pressed.func != null)
            _ = try out.write(" on_pressed");
    } else if (self.type == .checkbox) {
        if (self.type.checkbox.text.len > 0) {
            _ = try out.write(" text=");
            _ = try out.write(self.type.checkbox.text);
        }
        if (self.type.checkbox.checked) {
            _ = try out.write(" checked=");
            if (self.type.checkbox.checked) {
                _ = try out.write("true");
            } else {
                _ = try out.write("false");
            }
        }
        if (!std.mem.eql(u8, self.type.checkbox.text, self.type.checkbox.translated) and self.type.checkbox.translated.len > 0) {
            _ = try out.write(" translated=");
            _ = try out.write(self.type.checkbox.translated);
        }
        if (self.type.checkbox.checkbox_size.height > 0 or self.type.checkbox.checkbox_size.width > 0) {
            _ = try out.print(" checkbox_size={d:1.0}x{d:1.0}", .{
                self.type.checkbox.checkbox_size.width,
                self.type.checkbox.checkbox_size.height,
            });
        }
        if (self.type.checkbox.font_name) |font| {
            if (font.len > 0) {
                _ = try out.write(" font=");
                _ = try out.write(font);
            }
        }
        if (self.type.checkbox.on_change.func != null) {
            _ = try out.write(" on_change");
        }
    }
}

/// Changing the alignment requires reflowing the text in a label
pub inline fn setAlign(self: *Entity, x: LayoutAlign, y: LayoutAlign) void {
    self.child_align.x = x;
    self.child_align.y = y;
    switch (self.type) {
        .label, .checkbox => _ = Label.layout(self, self.rect.width),
        else => {},
    }
}

/// Show or hide this entity. If the visibliity is changed a relayout
/// will be triggerd, and the `on_visibility` callback will be triggered
/// if a callback is specified.
pub inline fn setVisibility(self: *Entity, display: *Display, visible: Visibility) Allocator.Error!void {
    if (self.visible == visible) return;
    self.visible = visible;
    display.need_relayout = true;

    if (visible != .visible) {
        if (display.selected) |s| {
            if (s == self)
                s.deselected(display, &.{})
            else if (Display.isVisibleInTree(&display.root, s)) |is_visible| {
                if (is_visible) {
                    // Is visible, so stay selected
                } else {
                    // Currently selected item was found, but
                    // it is not visible.
                    self.deselected(display, &.{});
                }
            } else {
                // Currently selected item was not found while
                // crawling visible tree.
                self.deselected(display, &.{});
            }
        }
    }
    try self.on_visibility.call(display, self);
}

/// Replace the foreground texture with an image resource found
/// in the default resource bundle.
///
/// `setTexture` is only valid on entities that permit a
/// foreground texture.
pub inline fn setTexture(
    self: *Entity,
    display: *Display,
    name: []const u8,
) error{OutOfMemory}!void {
    const texture = display.loadBundleTexture(&display.resources, name) catch |f| {
        err("setTexture({s}) error loading texture. {any}", .{ name, f });
        return;
    };
    if (texture != null) {
        if (self.texture != null) {
            display.releaseTextureResource(self.texture.?);
        }
        self.texture = texture.?;
    } else {
        err("setTexture({s}) resource not found", .{name});
    }
}

/// Replace the current background texture with an image resource
/// found in the default resource bundle.
///
/// `setBackgroundTexture` is only valid on entities that permit a
/// background texture.
pub inline fn setBackgroundTexture(
    self: *Entity,
    display: *Display,
    name: []const u8,
) error{OutOfMemory}!void {
    const texture = display.loadBundleTexture(&display.resources, name) catch |f| {
        err("setBackgroundTexture({s}) error loading texture. {any}", .{ name, f });
        return;
    };
    if (texture != null) {
        if (self.background.image != null)
            display.releaseTextureResource(self.background.image.?);
        self.background.image = texture.?;
    } else {
        err("setBackgroundTexture({s}) resource not found", .{name});
    }
}

/// Replace the current image texture with a a texture from a resource
/// bundle. Returns null if the resource name does not exist.
pub inline fn setImage(
    self: *Entity,
    display: *Display,
    repository: *Resources,
    name: []const u8,
) (Allocator.Error || Resources.Error || engine.Error)!?*Texture {
    const start = std.Io.Timestamp.now(display.io, .real).toMilliseconds();
    const texture = try display.loadBundleTexture(repository, name);
    if (texture == null) {
        info("setImage failed to find image resource named \"{s}\"", .{name});
        return null;
    }
    const end = std.Io.Timestamp.now(display.io, .real).toMilliseconds();
    debug("setImage loaded image named \"{s}\" in {d}ms", .{ name, end - start });
    self.texture_name = name;

    if (self.texture != null) {
        display.releaseTextureResource(self.texture.?);
        self.texture = null;
    }
    self.texture = texture.?;
    return texture;
}

/// Remove the foreground texture if a texture has been set.
pub inline fn clearImage(
    self: *Entity,
    display: *Display,
) void {
    if (self.texture != null) {
        display.releaseTextureResource(self.texture.?);
        self.texture = null;
    }
}

pub inline fn setBackgroundImage(
    self: *Entity,
    display: *Display,
    repository: *Resources,
    name: []const u8,
) (Allocator.Error || Resources.Error || engine.Error)!?*Texture {
    const texture = try display.loadBundleTexture(repository, name);
    if (texture == null) {
        warn("setBackgroundImage failed to find image resource named \"{s}\"", .{name});
        return null;
    }
    debug("setBackgroundImage loaded \"{s}\"", .{name});

    if (self.background.image != null) {
        display.releaseTextureResource(self.background.image.?);
        self.background.image = null;
    }
    self.background.image = texture.?;
    return texture;
}

/// Remove the background texture if a texture has been set.
pub inline fn clearBackgroundImage(
    self: *Entity,
    display: *Display,
) void {
    if (self.background.image != null) {
        display.releaseTextureResource(self.background.image.?);
        self.background.image = null;
    }
}

/// Change the default font belonging to this entity
pub inline fn setFont(
    self: *Entity,
    display: *Display,
    name: []const u8,
) Allocator.Error!void {
    const which: **Font = switch (self.type) {
        .button => &self.type.button.font,
        .label => &self.type.label.font,
        .checkbox => &self.type.checkbox.font,
        .text_input => &self.type.text_input.font,
        else => {
            warn("setFont invalid on entity {t} {s}", .{ self.type, self.name });
            return;
        },
    };
    const fname: *?[]const u8 = switch (self.type) {
        .button => &self.type.button.font_name,
        .label => &self.type.label.font_name,
        .checkbox => &self.type.checkbox.font_name,
        .text_input => &self.type.text_input.font_name,
        else => {
            warn("setFont invalid on entity {t} {s}", .{ self.type, self.name });
            return;
        },
    };

    for (display.fonts.items) |font| {
        if (std.mem.eql(u8, name, font.name)) {
            which.* = font;
            fname.* = name;
            return;
        }
    }
    warn("requested unknown font {s} on entity {t} {s}", .{ name, self.type, self.name });
}

pub inline fn getText(
    self: *Entity,
) ?[]const u8 {
    return switch (self.type) {
        .text_input => self.type.text_input.initial_text,
        .checkbox => self.type.checkbox.text,
        .label => self.type.label.text,
        .button => self.type.button.text,
        else => null,
    };
}

/// Update the `text` and corresponding`translation` field of a label,
/// checkbox, text input, or button. The backing image texture for
/// each word is regenerated if the text was changed. The memory
/// behind the `new_text` must remain valid while the entity exists
/// and is displaying this string.
pub inline fn setText(
    self: *Entity,
    display: *Display,
    new_text: []const u8,
) error{OutOfMemory}!void {
    const old_translated = switch (self.type) {
        .text_input => self.type.text_input.text.items,
        .checkbox => self.type.checkbox.translated,
        .label => self.type.label.translated,
        .button => self.type.button.translated,
        else => {
            err("setText({s}.{s}) invalid", .{ @tagName(self.type), new_text });
            return;
        },
    };
    if (engine.dev_build and engine.dev_mode) {
        const old_text = switch (self.type) {
            .text_input => self.type.text_input.text.items,
            .checkbox => self.type.checkbox.text,
            .label => self.type.label.text,
            .button => self.type.button.text,
            else => return,
        };
        debug("setText {s} {s} \"{s}\" => \"{s}\"", .{ self.name, @tagName(self.type), old_text, new_text });
    }
    const new_translated = display.translation.translate(new_text);
    trace("setText({s}.{s}) translated \"{s}\" => \"{s}\"", .{
        @tagName(self.type),
        self.name,
        old_translated,
        new_translated,
    });
    if (std.mem.eql(u8, new_translated, old_translated)) {
        // Do nothing if the text has not changed. This assumes that
        // the original text buffer was not modified.
        return;
    }

    switch (self.type) {
        .text_input => |*ti| {
            ti.text.clearRetainingCapacity();
            ti.runes.clearRetainingCapacity();
            if (new_text.len > 0) {
                ti.font = Chunker.guess_language(new_text, &display.font);
                try ti.text.appendSlice(display.allocator, new_text);
                ti.text_data_to_runes(display.allocator);
                ti.cursor_character = ti.runes.items.len;
                ti.cursor_pixels = try ti.font.measureText(
                    display,
                    ti.text_size,
                    ti.text.items,
                );
            } else {
                ti.cursor_pixels = 0.0;
                ti.cursor_character = 0;
            }
        },
        .label => |*label| {
            // Clear old text
            label.elements.clearRetainingCapacity();
            label.text = new_text;
            label.translated = new_translated;
            if (label.translated.len > 0) {
                var data = Chunker.init(label.translated);
                while (data.next(&display.font)) |word| {
                    // Store width as a placeholder until layout function is run.
                    const width = try word.font.measureText(
                        display,
                        label.text_size,
                        word.text,
                    );
                    try label.elements.append(display.allocator, .{
                        .text = word.text,
                        .width = width,
                        .font = word.font,
                    });
                }
            }
        },
        .checkbox => |*checkbox| {
            // Clear old text
            checkbox.elements.clearRetainingCapacity();
            checkbox.text = new_text;
            checkbox.translated = new_translated;
            if (checkbox.translated.len > 0) {
                self.type.checkbox.elements.clearRetainingCapacity();
                var data = Chunker.init(self.type.checkbox.translated);
                while (data.next(&display.font)) |text| {
                    // Store width as a placeholder until layout function is run.
                    const width = try text.font.measureText(
                        display,
                        checkbox.text_size,
                        text.text,
                    );
                    try self.type.checkbox.elements.append(display.allocator, .{
                        .text = text.text,
                        .width = width,
                        .font = text.font,
                    });
                }
            }
        },
        .button => |*button| {
            // Clear old text
            button.text = new_text;
            button.translated = new_translated;
            if (new_translated.len > 0) {
                button.font = if (button.font_name != null)
                    button.font
                else
                    Chunker.guess_language(self.type.button.translated, &display.font);

                button.translated_text_width = try button.font.measureText(
                    display,
                    button.text_size,
                    button.translated,
                );
            }
        },
        else => {
            warn("setText({s}) invalid for {s}", .{ @tagName(self.type), new_text });
        },
    }

    // Set an initial label width and height as placeholders until
    // the label is positioned in the entity tree.
    if (self.type == .label or self.type == .checkbox) {
        const width = if (self.layout.x == .fixed) self.rect.width else display.root.rect.width;
        const allowed_width = if (self.maximum.width == 0)
            width
        else
            @min(self.maximum.width, width);

        const size = Label.layout(self, allowed_width);
        if (self.layout.x != .fixed) self.rect.width = size.width;
        if (self.layout.y != .fixed) self.rect.height = size.height;
    }

    if (self.visible != .hidden) display.need_relayout = true;
}

/// `add` a child entity to this panel and return the entity. Only
/// permitted for the `panel` entity type. See also `insert`.
pub inline fn add(
    self: *Entity,
    conf: Entity,
    display: *Display,
) (Error || Allocator.Error || Resources.Error)!*Entity {
    std.debug.assert(self.type == .panel);
    const child = try display.allocator.create(Entity);
    child.* = conf;
    try child.setup(display);
    try self.type.panel.children.append(display.allocator, child);
    if (child.visible != .hidden and self.visible != .hidden)
        display.need_relayout = true;
    return child;
}

pub const EntityParser = @import("EntityParser.zig");

/// `append` a child entity to this panel and return the entity. Only
/// permitted for the `panel` entity type. See also `insert`.
pub inline fn append(
    self: *Entity,
    data: []const u8,
    HandlerType: type,
    handler: *HandlerType,
    display: *Display,
) (Error || Allocator.Error || Resources.Error)!*Entity {
    std.debug.assert(self.type == .panel);

    var token: Token = try .init(data);

    if (token.tag == .eof) return Error.UnexpectedToken;

    const child = try EntityParser.readEntityTokens(
        display.allocator,
        &token,
        HandlerType,
        handler,
        TextSize.pixels,
    ) orelse return Error.UnexpectedToken;

    try postAppend(display, child);
    try self.type.panel.children.append(display.allocator, child);

    return child;
}

/// `append` a child entity to this panel and return the entity. Only
/// permitted for the `panel` entity type. See also `insert`.
pub inline fn appendMultiple(
    self: *Entity,
    data: []const u8,
    HandlerType: type,
    handler: *HandlerType,
    display: *Display,
) (Error || Allocator.Error || Resources.Error)!void {
    std.debug.assert(self.type == .panel);

    var token: Token = try .init(data);

    if (token.tag == .eof) return Error.UnexpectedToken;

    while (token.tag != .eof) {
        const child = try EntityParser.readEntityTokens(
            display.allocator,
            &token,
            HandlerType,
            handler,
            TextSize.pixels,
        ) orelse return Error.UnexpectedToken;

        try postAppend(display, child);

        try self.type.panel.children.append(display.allocator, child);
        if (child.visible != .hidden and self.visible != .hidden)
            display.need_relayout = true;
    }
}

pub fn postAppend(display: *Display, entity: *Entity) (Error || Allocator.Error || Resources.Error)!void {
    if (entity.getText()) |text| {
        try entity.setText(display, text);
    }
    if (entity.type == .button) {
        if (entity.type.button.button.default_name) |value| {
            entity.background.image = try display.loadBundleTexture(&display.resources, value);
        }
        if (entity.type.button.button.hover_name) |value| {
            entity.type.button.button.hover = try display.loadBundleTexture(&display.resources, value);
        }
        if (entity.type.button.button.disabled_name) |value| {
            entity.type.button.button.disabled = try display.loadBundleTexture(&display.resources, value);
        }
        if (entity.type.button.button.pressed_name) |value| {
            entity.type.button.button.pressed = try display.loadBundleTexture(&display.resources, value);
        }
        if (entity.type.button.icon.default_name) |value| {
            entity.texture = try display.loadBundleTexture(&display.resources, value);
        }
        if (entity.type.button.icon.hover_name) |value| {
            entity.type.button.icon.hover = try display.loadBundleTexture(&display.resources, value);
        }
        if (entity.type.button.icon.disabled_name) |value| {
            entity.type.button.icon.disabled = try display.loadBundleTexture(&display.resources, value);
        }
        if (entity.type.button.icon.pressed_name) |value| {
            entity.type.button.icon.pressed = try display.loadBundleTexture(&display.resources, value);
        }
    } else {
        if (entity.background.image_name) |value| {
            entity.background.image = try display.loadBundleTexture(&display.resources, value);
        }
    }
    if (entity.type == .progress_bar) {
        if (entity.texture == null) {
            if (try display.requireImage("rounded progress bar")) |texture| {
                entity.texture = texture;
            } else {
                err("Failed to load progress_bar texture named \"rounded progress bar\"", .{});
            }
        }
    }
    if (entity.type == .panel) {
        for (entity.type.panel.children.items) |child| {
            try postAppend(display, child);
        }
    }
}

/// Use `insert` to insert a child entity in a specific location
/// in this panel. Only permitted for the `panel` entity type. See
/// also `add`.
pub inline fn insert(
    self: *Entity,
    location: usize,
    conf: Entity,
    display: *Display,
) (Error || Allocator.Error || Resources.Error)!*Entity {
    std.debug.assert(self.type == .panel);
    std.debug.assert(location <= self.type.panel.children.items.len);
    const child = try display.allocator.create(Entity);
    child.* = conf;
    try child.setup(display);
    try self.type.panel.children.insert(display.allocator, location, child);
    if (child.visible != .hidden and self.visible != .hidden)
        display.need_relayout = true;
    return child;
}

/// Swap the ordering of two child entities belonging to this panel.
pub inline fn swap(self: *Entity, from: usize, to: usize) void {
    std.debug.assert(self.type == .panel);
    std.debug.assert(from < self.type.panel.children.items.len);
    std.debug.assert(to < self.type.panel.children.items.len);
    const s = self.type.panel.children.items[from];
    self.type.panel.children.items[from] = self.type.panel.children.items[to];
    self.type.panel.children.items[to] = s;
}

/// Use `removeEntityAt` to attach a child entity in a specific location
/// in this panel. Only permitted for the `panel` entity type.
pub inline fn removeEntityAt(self: *Entity, display: *Display, location: usize) *Entity {
    std.debug.assert(self.type == .panel);
    std.debug.assert(location < self.type.panel.children.items.len);
    const item = self.type.panel.children.orderedRemove(location);
    if (item.visible != .hidden) display.need_relayout = true;
    return item;
}

/// Use `removeEntity` to remove a panel that is a
/// child of this entity.
pub inline fn removeEntity(
    self: *Entity,
    display: *Display,
    child: *Entity,
) ?*Entity {
    std.debug.assert(self.type == .panel);
    child.clearDisplayPointers(display);
    for (0..self.type.panel.children.items.len) |i| {
        if (self.type.panel.children.items[i] == child) {
            const item = self.type.panel.children.orderedRemove(i);
            debug("removed panel {s}", .{item.name});
            if (item.visible != .hidden) display.need_relayout = true;
            return item;
        }
    }
    debug("panel not found in children", .{});
    return null;
}

/// Use `removeEntities` to remove all childr entities in a panel.
/// TODO: rename to `clear` to match zig terminology
pub inline fn removeEntities(
    self: *Entity,
    display: *Display,
) void {
    std.debug.assert(self.type == .panel);
    for (0..self.type.panel.children.items.len) |i| {
        const item = self.type.panel.children.items[i];
        if (item.visible != .hidden) display.need_relayout = true;
        debug("removed child panel {s}", .{item.name});
        item.destroy(display);
    }
    self.type.panel.children.clearRetainingCapacity();
}

/// Make sure nothing is holding a reference to an entity that
/// is being removed from the display.
fn clearDisplayPointers(self: *Entity, display: *Display) void {
    if (display.selected == self) display.selected = null;
    if (display.hovered == self) display.hovered = null;
    if (self.type == .panel) {
        for (self.type.panel.children.items) |entity| {
            entity.clearDisplayPointers(display);
        }
    }
}

/// Animations, and used provided code may be updated inside the
/// update function. This is called prior to the `draw` function.
pub fn update(self: *Entity, display: *Display) void {
    if (self.type == .sprite) {
        self.type.sprite.on_update.call(display, self);

        if (self.velocity.x > 0)
            self.rect.x += self.velocity.x;

        if (self.velocity.y > 0)
            self.rect.y += self.velocity.y;
    }

    if (display.need_relayout)
        display.relayout();

    if (self.type == .panel) {
        self.type.panel.on_update.call(display, self);
        for (self.type.panel.children.items) |child|
            child.update(display);
    }
}

/// Shrink to the smallest height this object is allowed to
/// shrink to based on the children. If children wrap according
/// to the width of the parent, then the parent width is needed
/// to calculate the height
pub fn minimumNeededHeight(self: *Entity, parent_width: f32) f32 {
    if (self.visible == .hidden)
        return 0;
    if (self.layout.y == .fixed)
        return @max(self.minimum.height, self.rect.height);

    const height = switch (self.type) {
        .button => return self.type.button.minimumNeededHeight(self, parent_width),
        .checkbox => return self.type.checkbox.minimumNeededHeight(self, parent_width),
        .expander => return self.minimum.height,
        .label => return self.type.label.minimumNeededHeight(self, parent_width),
        .panel => return self.type.panel.minimumNeededHeight(self, parent_width),
        .text_input => return self.type.text_input.minimumNeededHeight(self, parent_width),
        else => self.rect.height,
    };
    return @max(self.minimum.height, height);
}

/// Return the smallest width this entity permits.
/// .
/// Some entities grow to the `parent_width`, which is usually the
/// `parent.rect.width` minus any internal padding.
pub fn minimumNeededWidth(self: *Entity, parent_inner_width: f32) f32 {
    if (self.visible == .hidden)
        return 0;

    if (self.layout.x == .fixed)
        return @max(self.minimum.width, self.rect.width);

    return switch (self.type) {
        .panel => self.type.panel.minimumNeededWidth(self, parent_inner_width),
        .button => self.type.button.minimumNeededWidth(self, parent_inner_width),
        .expander => self.type.expander.minimumNeededWidth(self, parent_inner_width),
        .label => self.type.label.minimumNeededWidth(self, parent_inner_width),
        .checkbox => self.type.checkbox.minimumNeededWidth(self, parent_inner_width),
        .text_input => self.type.text_input.minimumNeededWidth(self, parent_inner_width),
        else => @max(self.minimum.width, self.rect.width),
    };
}

/// Handle the langauge change event and propogate the event
/// downwards to each child entity, so that each child has
/// a chance to regenerate its translation and text texture.
pub fn language_changed(self: *Entity, display: *Display, lang: Lang) !void {
    switch (self.type) {
        .label => try self.setText(display, self.type.label.text),
        .checkbox => try self.setText(display, self.type.checkbox.text),
        .button => try self.setText(display, self.type.button.text),
        .panel => for (self.type.panel.children.items) |child| {
            try child.language_changed(display, lang);
        },
        else => {},
    }
}

/// Draw the current entity, along with any children entity.
pub fn draw(entity: *Entity, display: *Display, parent_scroll_offset: Vector, parent_clip: ?Clip) void {
    if (entity.visible == .hidden)
        return;

    const scroll_offset: Vector = entity.offset.add(parent_scroll_offset);

    // Mark visible entities as culled or not culled depending on
    // the parent_clip.
    if (parent_clip) |clip| {
        const pos = entity.rect.move(scroll_offset);
        if (clip.isClipped(pos)) {
            entity.visible = .culled;
            return;
        }
    }
    if (entity.visible == .culled)
        entity.visible = .visible;

    // An Entity may optionally have a background texture or a simple
    // filled background.
    if (entity.background.image) |texture| {
        // Buttons do not use the background.image or backgroud.image_name
        // field, so don't draw background image for buttons.
        if (entity.type != .button) {
            var dest = entity.rect.move(scroll_offset);
            if (parent_clip) |clip|
                clip.applyEdgeClipping(&dest);

            if (entity.flip.x) {
                dest.x += dest.width;
                dest.width = -dest.width;
            }
            if (entity.flip.y) {
                dest.y += dest.height;
                dest.height = -dest.height;
            }
            entity.applyBackgroundTint(display, texture.texture);
            if (entity.background.image_corner_radius == 0) {
                _ = sdl.SDL_RenderTexture(display.renderer, texture.texture, null, @ptrCast(&dest));
            } else {
                var corner: f32 = entity.background.corner_radius;
                if (corner * 2 > @abs(dest.height)) corner = @abs(dest.height) / 2;
                _ = sdl.SDL_RenderTexture9Grid(
                    display.renderer,
                    texture.texture,
                    null,
                    entity.background.image_corner_radius,
                    entity.background.image_corner_radius,
                    entity.background.image_corner_radius,
                    entity.background.image_corner_radius,
                    corner / entity.background.image_corner_radius,
                    @ptrCast(&dest),
                );
            }
        }
    } else if (entity.background.colour.a > 0 and entity.type != .rectangle and entity.type != .sprite and entity.type != .progress_bar) {
        // If there is no background image, but there is a background
        // colour, draw the background as a simple rectangle (except for
        // sprites and rectangles).
        _ = sdl.SDL_SetRenderDrawColor(
            display.renderer,
            entity.background.colour.r,
            entity.background.colour.g,
            entity.background.colour.b,
            entity.background.colour.a,
        );
        _ = sdl.SDL_RenderFillRect(display.renderer, @ptrCast(&entity.rect));
    }

    switch (entity.type) {
        inline else => |o| o.draw(
            entity,
            display,
            parent_scroll_offset,
            parent_clip,
            scroll_offset,
        ),
    }

    // Draw a border around an entity if a border is specified, or
    // if `dev_mode` has been enabled.
    if (engine.dev_mode) {
        var colour = display.theme.emphasised_text_colour;
        if (entity.type == .panel) {
            colour = display.theme.tinted_text_colour;
        }
        draw_rectangle(
            display.renderer,
            2,
            colour,
            entity.rect.move(scroll_offset),
            .{},
        );
        if (entity.type == .panel and (entity.type.panel.scrollable.scroll.x or entity.type.panel.scrollable.scroll.y)) {
            draw_rectangle(
                display.renderer,
                2,
                display.theme.success_panel_colour,
                entity.rect,
                .{},
            );
        } else if (entity.type == .label) {
            var pad_line = entity.rect.move(scroll_offset);
            pad_line.x += entity.pad.left;
            pad_line.y += entity.pad.top;
            pad_line.width -= (entity.pad.left + entity.pad.right);
            pad_line.height -= (entity.pad.top + entity.pad.bottom);
            entity.markCorners(display, scroll_offset);
        } else if (entity.type == .button) {
            // inner padding line
            colour = display.theme.tinted_text_colour;
            draw_rectangle(display.renderer, 2, colour, .{
                .x = entity.rect.x + scroll_offset.x + entity.pad.left,
                .y = entity.rect.y + scroll_offset.y + entity.pad.top,
                .width = entity.rect.width - (entity.pad.left + entity.pad.right),
                .height = entity.rect.height - (entity.pad.top + entity.pad.bottom),
            }, .{});
            entity.markCorners(display, scroll_offset);
        }
    } else if (entity.border_width > 0 and entity.border_colour.a > 0) {
        draw_rectangle(
            display.renderer,
            entity.border_width,
            entity.border_colour,
            entity.rect.move(scroll_offset),
            .{},
        );
    }

    // If an item has been selected by a keyboard or controller,
    // draw a cursor over the selected item.
    if (display.selected != null and display.selected == entity) {
        // Don't draw cursor line/mark if no keyboard activity
        // has been detected.
        if (!display.keyboard_activity) return;
        if (display.draw_cursor) |f|
            f(
                display.renderer,
                entity.type,
                entity.rect.move(scroll_offset),
                display.user_scale,
            )
        else
            drawCursor(
                display.renderer,
                entity.type,
                display.theme,
                entity.rect.move(scroll_offset),
                display.user_scale,
            );
    }
}

fn markCorners(entity: *Entity, display: *Display, scroll_offset: Vector) void {
    const length = 20;
    draw_line(
        display.renderer,
        3,
        Colour.RED,
        entity.rect.location().move(entity.pad.left, entity.pad.top),
        entity.rect.location().move(entity.pad.left + length, entity.pad.top),
        scroll_offset,
    );
    draw_line(
        display.renderer,
        3,
        Colour.RED,
        entity.rect.location().move(entity.pad.left, entity.pad.top),
        entity.rect.location().move(entity.pad.left, entity.pad.top + length),
        scroll_offset,
    );
    draw_line(
        display.renderer,
        3,
        Colour.RED,
        entity.rect.location().move(entity.rect.width - entity.pad.right - length, entity.rect.height - entity.pad.bottom),
        entity.rect.location().move(entity.rect.width - entity.pad.right, entity.rect.height - entity.pad.bottom),
        scroll_offset,
    );
    draw_line(
        display.renderer,
        3,
        Colour.RED,
        entity.rect.location().move(entity.rect.width - entity.pad.right, entity.rect.height - entity.pad.bottom),
        entity.rect.location().move(entity.rect.width - entity.pad.right, entity.rect.height - entity.pad.bottom - length),
        scroll_offset,
    );
}

/// Draw a visual indication that an entity is currently selected.
pub fn drawCursor(
    renderer: *sdl.SDL_Renderer,
    entity_type: Type,
    theme: *Theme,
    rect: Rect,
    user_scale: f32,
) void {
    if (entity_type == .text_input) return;
    const colour = theme.cursor_colour;
    const border_width = 4 * user_scale;
    if (border_width > 0 and colour.a > 0) {
        var dest: Rect = .{
            .x = rect.x,
            .y = rect.y + rect.height + border_width,
            .width = rect.width,
            .height = border_width,
        };
        dest = dest.move(.{ .x = border_width * 4, .y = 0 - border_width * 4 });
        dest.width = @max(border_width * 8, rect.width - border_width * 8);
        //if (rect.width > border_width * 16) {
        //    dest.width -= border_width * 8;
        //    dest.x += border_width * 4;
        //}
        _ = sdl.SDL_SetRenderDrawColor(
            renderer,
            colour.r,
            colour.g,
            colour.b,
            colour.a,
        );
        _ = sdl.SDL_RenderFillRect(renderer, @ptrCast(&dest));
    }
}

pub fn keypress(
    self: *Entity,
    display: *Display,
    key: u21,
    slice: []const u8,
    event: *const Event,
) Allocator.Error!void {
    switch (self.type) {
        .text_input => try self.type.text_input.keypress(self, display, key, slice, event),
        else => err("keypress ignored for {t}. {s} {t}", .{ self.type, slice, event.type }),
    }
}

/// Handle when a user chooses an entity like a button, using
/// the mouse or the keyboard.
pub fn chosen(
    self: *Entity,
    display: *Display,
    event: *const Event,
) Allocator.Error!void {
    debug("chosen entity {s}", .{self.name});
    switch (self.type) {
        .button => {
            switch (self.type.button.toggle) {
                .on => {
                    debug("toggle {s} off", .{self.name});
                    self.type.button.toggle = .off;
                },
                .off => {
                    debug("toggle {s} on", .{self.name});
                    self.type.button.toggle = .on;
                },
                .no_toggle, .correct, .incorrect, .locked_off, .disabled => {},
            }
            try self.type.button.on_pressed.call(display, self, event);
        },
        .panel => try self.type.panel.on_pressed.call(display, self, event),
        .label => try self.type.label.on_pressed.call(display, self, event),
        .sprite => try self.type.sprite.on_pressed.call(display, self, event),
        .checkbox => {
            self.type.checkbox.checked = !self.type.checkbox.checked;
            try self.type.checkbox.on_change.call(display, self, event);
        },
        .progress_bar, .text_input, .rectangle, .expander => {},
    }
}

/// Handle when a user clicks into or tabs into this entity.
pub fn selected(
    self: *Entity,
    display: *Display,
    event: *const Event,
) void {
    if (self.focus == .never_focus or self.focus == .unspecified) return;

    if (display.selected != null and self != display.selected)
        display.selected.?.deselected(display, event);

    display.selected = self;

    // If the item is off screen, perhaps it can scoll into visibility
    self.scrollSelectedEntity(display);

    debug("selected {s} {s}", .{ @tagName(self.type), self.name });
    // When an item is selected, refresh the kebyoard_activity to
    // indicate if the user is currently navigating with a keyboard
    // or button based controller. Stop drawing the cursor when the
    // use switches back to mouse.
    display.keyboard_activity = event.isKeyboardEvent();

    self.describeCurrentEntity(&display.translation);

    // Enter editing mode if we just selected a text entity
    if (self.type == .text_input)
        _ = sdl.SDL_StartTextInput(display.window);
}

/// Starting from the bottom of the entity tree, ensure the entity
/// is visible in its base panel, then walk back up and ensure each
/// parent scroller is scrolled to a point where the child is visible.
pub fn scrollSelectedEntity(
    self: *Entity,
    display: *Display,
) void {
    // This is a work in progress. It only functions for one
    // level of full screen scroller right now.
    var scrollers: [5]?*Entity = .{ null, null, null, null, null };
    const found = self.do_scrollSelectedEntity(&scrollers, 0, &display.root, .{});
    var len: usize = 0;
    for (scrollers) |panel| {
        if (panel != null) len += 1;
    }
    if (found) |location| {
        trace("selected entity at {d}x{d} (has {d} scrollers)", .{ location.x, location.y, len });
        if (location.x < 0) {
            // Entity is clipped on left.
            var move = 0 - location.x;
            for (scrollers) |scroller| {
                if (move <= 0) break;
                if (scroller) |s| {
                    const left_space = s.type.panel.leftScrollSpace();
                    if (left_space > 0) {
                        const offset = @min(move, left_space);
                        move -= offset;
                        s.offset.x += offset;
                    }
                }
            }
        } else if (location.x + self.rect.width > display.root.rect.width) {
            // Entity is clipped on right.
            var move = (location.x + self.rect.width) - display.root.rect.width;
            for (scrollers) |scroller| {
                if (move <= 0) break;
                if (scroller) |s| {
                    const right_space = s.type.panel.rightScrollSpace();
                    if (right_space > 0) {
                        const offset = @min(move, right_space);
                        move -= offset;
                        s.offset.x -= offset;
                    }
                }
            }
        }
        if (location.y < 0) {
            // Entity is clipped on top.
            var move = 0 - location.y;
            for (scrollers) |scroller| {
                if (move <= 0) break;
                if (scroller) |s| {
                    const top_space = s.type.panel.topScrollSpace();
                    if (top_space > 0) {
                        const offset = @min(move, top_space);
                        move -= offset;
                        s.offset.y += offset;
                    }
                }
            }
        } else if (location.y + self.rect.height > display.root.rect.height) {
            // Entity is clipped on bottom.
            var move = (location.y + self.rect.height) - display.root.rect.height;
            for (scrollers) |scroller| {
                if (move <= 0) break;
                if (scroller) |s| {
                    const bottom_space = s.type.panel.bottomScrollSpace();
                    if (bottom_space > 0) {
                        const offset = @min(move, bottom_space);
                        move -= offset;
                        s.offset.y -= offset;
                    }
                }
            }
        }
    } else err("selected entity not locatable", .{});
}

/// Recursively descend the entity tree to find the position and
/// scroll offset of the currently selected entity. Returns the
/// scrollers that might be used to adjust the scroll offset.
pub fn do_scrollSelectedEntity(
    self: *Entity,
    scrollers: *[5]?*Entity,
    len: usize,
    parent: *Entity,
    parent_offset: Vector,
) ?Vector {
    for (parent.type.panel.children.items) |child| {
        if (child == self) return child.rect.location().add(parent_offset);
        if (child.visible != .visible and child.visible != .culled) continue;
        if (child.type == .panel) {
            var nlen: usize = len;
            if (child.type.panel.scrollable.scroll.x or child.type.panel.scrollable.scroll.y) {
                scrollers.*[len] = child;
                nlen += 1;
            }
            if (self.do_scrollSelectedEntity(scrollers, nlen, child, parent_offset.add(parent.offset))) |v|
                return v;
        }
    }
    return null;
}

/// Returns true if this entity can be interacted with. If an
/// accessibilty mode has been enabled, text labels and other
/// accessiblity related elements become selectable.
pub fn isSelectable(self: *const Entity, display: *Display) bool {
    if (self.visible != .visible and self.visible != .culled) return false;
    if (self.focus == .never_focus or self.focus == .unspecified) return false;

    switch (self.type) {
        .panel => |p| if (p.clickable()) return true,
        .button => |b| {
            if (b.clickable()) return true;
            if (!display.blind_accessibility) return false;
            if (self.focus == .accessibility_focus)
                return true;
        },
        .sprite => |s| if (s.clickable()) return true,
        .label => |l| {
            if (l.clickable()) return true;
            if (!display.blind_accessibility) return false;
            if (self.focus == .accessibility_focus)
                if (l.translated.len > 0)
                    return true;
        },
        .text_input => return true,
        .checkbox => return true,
        .expander, .progress_bar, .rectangle => return false,
    }

    return false;
}

/// Describe content for a screen reader.
fn describeCurrentEntity(self: *Entity, translation: *Translation) void {
    const type_name = translation.translate(@tagName(self.type));
    switch (self.type) {
        .label => {
            if (self.aria_label) |aria| {
                std.log.info("aria: {s}", .{translation.translate(aria)});
            } else {
                std.log.info("aria: {s}", .{self.type.label.translated});
            }
        },
        .button => {
            if (self.aria_label) |aria|
                std.log.info("aria: {s} {s}", .{ type_name, translation.translate(aria) })
            else if (self.type.button.translated.len > 0)
                std.log.info("aria: {s} {s}", .{ type_name, self.type.button.translated })
            else
                std.log.info("aria: {s} {s}", .{ type_name, self.name });
        },
        .checkbox => {
            if (self.aria_label) |aria|
                std.log.info("aria: {s} {s}", .{ type_name, translation.translate(aria) })
            else if (self.type.checkbox.translated.len > 0)
                std.log.info("aria: {s} {s}", .{ type_name, self.type.checkbox.translated })
            else
                std.log.info("aria: {s} {s}", .{ type_name, self.name });
        },
        else => {
            if (self.aria_label) |aria|
                std.log.info("aria: {s} {s}", .{ type_name, translation.translate(aria) })
            else
                std.log.info("aria: {s} {s}", .{ type_name, self.name });
        },
    }
}

/// Handle when a user clicks or tabs out of this entity.
pub fn deselected(self: *Entity, display: *Display, event: *const Event) void {
    trace("deselected {s} {s}", .{ @tagName(self.type), self.name });

    if (self.type == .text_input) {
        _ = sdl.SDL_StopTextInput(display.window);
    }
    display.keyboard_activity = event.isKeyboardEvent();
    display.selected = null;
}

/// Calculate how many pixels of text we can draw until we must wrap to
/// the next line. By default the width is whatever the parent entity
/// has room for.
fn word_wrap_line(entity: *const Entity, max_parent_width: f32) f32 {
    var entity_padding: f32 = 0;
    if (entity.type == .checkbox) entity_padding += entity.type.checkbox.checkbox_size.width;

    // If a fixed width is specified, clamp to the fixed width
    const wrap = switch (entity.layout.x) {
        .grows, .fixed => @max(max_parent_width, entity.maximum.width) - entity_padding,
        .shrinks => @max(max_parent_width, entity.minimum.width) - entity_padding,
    };

    return wrap;
}

/// Internal function to initialise rect entity.
pub fn setup_rect(
    entity: *Entity,
    _: *Display,
) (Error || Allocator.Error || Resources.Error)!void {
    entity.texture = null;
    entity.background.image = null;
    if (entity.focus == .unspecified) {
        entity.focus = .never_focus;
    }
}

/// Internal function to initialise panel entity.
pub fn setup_panel(
    entity: *Entity,
    display: *Display,
) (Error || Allocator.Error || Resources.Error)!void {
    entity.texture = null;
    entity.background.image = null;

    if (entity.focus == .unspecified) {
        entity.focus = if (entity.type.panel.clickable())
            .can_focus
        else
            .never_focus;
    }

    if (entity.type.panel.safe_area == .unspecified)
        entity.type.panel.safe_area = .avoid_safe_area;

    if (entity.background.image_name) |name| {
        if (try display.requireImage(name)) |texture| {
            entity.background.image = texture;
        } else {
            err("Failed to load panel background image named \"{s}\"", .{name});
        }
    }

    entity.type.panel.children = .empty;
}

/// Internal function to initialise progress bar entity.
pub fn setup_progress_bar(
    entity: *Entity,
    display: *Display,
) (Error || Allocator.Error || Resources.Error)!void {
    entity.texture = null;
    entity.background.image = null;
    if (entity.focus == .unspecified)
        entity.focus = .never_focus;

    if (entity.type != .progress_bar) {
        err("create_progress_bar called without config.", .{});
        entity.type = .{ .progress_bar = .{} };
    }

    if (try display.requireImage("rounded progress bar")) |texture| {
        entity.texture = texture;
    } else {
        err("Failed to load progress_bar texture named \"rounded progress bar\"", .{});
    }
}

/// Internal function to initialise checkbox entity.
pub fn setup_checkbox(
    entity: *Entity,
    display: *Display,
) (Error || Allocator.Error || Resources.Error)!void {
    entity.texture = null;
    entity.background.image = null;
    entity.type.checkbox.translated = "";
    entity.type.checkbox.elements = .empty;
    entity.type.checkbox.font = try select_font(display.fonts.items, entity.type.checkbox.font_name);

    if (entity.focus == .unspecified)
        entity.focus = .can_focus;

    try entity.setText(display, entity.type.checkbox.text);

    if (try display.requireImage("ios-checkbox-on")) |texture| {
        entity.type.checkbox.on_texture = texture;
    }
    if (try display.requireImage("ios-checkbox-off")) |texture| {
        entity.type.checkbox.off_texture = texture;
    }

    // Is there a background for this checkbox
    if (entity.background.image_name) |name| {
        if (try display.requireImage(name)) |texture|
            entity.background.image = texture;
    }

    if (entity.type.checkbox.checkbox_size.width == 0 or entity.type.checkbox.checkbox_size.height == 0) {
        entity.type.checkbox.checkbox_size.width = entity.type.checkbox.text_size.size();
        entity.type.checkbox.checkbox_size.height = entity.type.checkbox.text_size.size();
    }

    const size = entity.type.checkbox.checkbox_size;
    if (entity.minimum.height < size.height)
        entity.minimum.height = size.height;

    if (entity.minimum.width < size.width)
        entity.minimum.width = size.width;
}

/// Internal function to initialise expander entity.
pub fn setup_expander(
    entity: *Entity,
    _: *Display,
) (Error || Allocator.Error || Resources.Error)!void {
    entity.texture = null;
    entity.background.image = null;
    entity.focus = .never_focus;
}

/// Internal function to initialise text input entity.
pub fn setup_text_input(
    entity: *Entity,
    display: *Display,
) (Error || Allocator.Error || Resources.Error)!void {
    entity.texture = null;
    entity.background.image = null;
    if (entity.focus == .unspecified)
        entity.focus = .can_focus;

    entity.type.text_input.font = try select_font(display.fonts.items, entity.type.text_input.font_name);

    if (entity.type.text_input.icon_texture_name) |icon| {
        if (try display.requireImage(icon)) |texture| {
            entity.texture = texture;
        } else {
            err("Failed to load text_input icon texture named \"{s}\"", .{icon});
        }
    }

    if (entity.background.image_name) |background| {
        if (try display.requireImage(background)) |texture| {
            entity.background.image = texture;
        } else {
            err("Failed to load text_input background image named \"{s}\"", .{background});
        }
    }

    entity.focus = .can_focus;
    entity.rect.height = (TextSize.normal.size()) + (entity.pad.top + entity.pad.bottom);

    entity.type.text_input.text = .empty;
    entity.type.text_input.runes = .empty;
    if (entity.type.text_input.initial_text) |text| {
        try entity.setText(display, text);
    } else {
        try entity.setText(display, "");
    }
    if (entity.type.text_input.placeholder_text) |text| {
        try entity.setPlaceholderText(display, text);
    } else {
        try entity.setPlaceholderText(display, "");
    }
}

/// Internal function to initialise sprite entity.
pub fn setup_sprite(
    entity: *Entity,
    display: *Display,
) (Error || Allocator.Error || Resources.Error)!void {
    entity.texture = null;
    entity.background.image = null;
    if (entity.focus == .unspecified)
        entity.focus = .accessibility_focus;

    if (entity.texture_name) |image| {
        if (try display.requireImage(image)) |texture| {
            entity.texture = texture;
            if (entity.rect.width == 0)
                entity.rect.width = @floatFromInt(texture.texture.w);
            if (entity.rect.height == 0)
                entity.rect.height = @floatFromInt(texture.texture.h);
        } else {
            err("Failed to load sprite texture named \"{s}\"", .{image});
        }
    }

    if (entity.background.image_name) |image| {
        if (try display.requireImage(image)) |texture| {
            entity.background.image = texture;
            if (entity.rect.width == 0)
                entity.rect.width = @floatFromInt(texture.texture.w);
            if (entity.rect.height == 0)
                entity.rect.height = @floatFromInt(texture.texture.h);
        } else {
            err("Failed to load sprite background image named \"{s}\" for button \"{s}\"", .{ image, entity.name });
        }
    }

    if (entity.texture_name != null)
        trace("sprite {s} fg {s}", .{ entity.name, entity.texture_name.? });
    if (entity.background.image_name != null)
        trace("sprite {s} bg {s}", .{ entity.name, entity.background.image_name.? });
}

/// Internal function to initialise button entity.
pub fn setup_button(
    entity: *Entity,
    display: *Display,
) (Error || Allocator.Error || Resources.Error)!void {
    entity.type.button.translated = "";
    entity.texture = null;
    entity.background.image = null;
    entity.type.button.icon.pressed = null;
    entity.type.button.icon.hover = null;
    entity.type.button.icon.disabled = null;
    entity.type.button.button.pressed = null;
    entity.type.button.button.hover = null;
    entity.type.button.button.disabled = null;
    //entity.type.button.text_size = .normal;
    entity.type.button.font = try select_font(display.fonts.items, entity.type.button.font_name);

    if (entity.focus == .unspecified)
        entity.focus = .can_focus;

    if (entity.texture_name != null)
        warn("button `{s}` has texture_name `{s}`. Buttons use `icon.default_name`", .{
            entity.name,
            entity.texture_name.?,
        });

    if (entity.background.image_name != null)
        warn("button `{s}` has background.image_name `{s}`. Buttons do not use `background.image_name`", .{
            entity.name,
            entity.background.image_name.?,
        });

    try entity.setText(display, entity.type.button.text);

    if (entity.type.button.icon.default_name) |value| {
        if (try display.requireImage(value)) |texture| {
            entity.texture = texture;
            if (entity.type.button.icon.size.width == 0 or entity.type.button.icon.size.height == 0)
                warn("button `{s}` has icon `{s}`, but no icon size.", .{
                    entity.name,
                    value,
                });
        }
    }

    if (entity.type.button.icon.pressed_name) |value| {
        if (try display.requireImage(value)) |ip|
            entity.type.button.icon.pressed = ip
        else
            err("setup_button failed to load icon_pressed resource {s}.", .{value});

        if (entity.type.button.icon.pressed == null and entity.texture != null)
            entity.type.button.icon.pressed = entity.texture.?.clone();
    }

    if (entity.type.button.icon.hover_name) |value| {
        if (try display.requireImage(value)) |ih|
            entity.type.button.icon.hover = ih
        else
            err("setup_button failed to load icon_hover resource {s}.", .{value});

        if (entity.type.button.icon.hover == null and entity.texture != null)
            entity.type.button.icon.hover = entity.texture.?.clone();
    }

    if (entity.type.button.icon.disabled_name) |value| {
        if (try display.requireImage(value)) |ih|
            entity.type.button.icon.disabled = ih
        else
            err("setup_button failed to load icon_disabled resource {s}.", .{value});

        if (entity.type.button.icon.disabled == null and entity.texture != null)
            entity.type.button.icon.disabled = entity.texture.?.clone();
    }

    if (entity.type.button.button.default_name) |value| {
        if (try display.requireImage(value)) |texture|
            entity.background.image = texture
        else
            err("setup_button failed to load button.default resource {s}.", .{value});
    }

    if (entity.type.button.button.pressed_name) |value| {
        if (try display.requireImage(value)) |bp|
            entity.type.button.button.pressed = bp
        else
            err("setup_button button.pressed resource resource `{s}` not loaded.", .{value});

        if (entity.type.button.button.pressed == null and entity.background.image != null)
            entity.type.button.button.pressed = entity.background.image.?.clone();
    }

    if (entity.type.button.button.hover_name) |value| {
        if (try display.requireImage(value)) |bh|
            entity.type.button.button.hover = bh
        else
            err("setup_button button.hover resource `{s}` not loaded.", .{value});

        if (entity.type.button.button.hover == null and entity.background.image != null)
            entity.type.button.button.hover = entity.background.image.?.clone();
    }

    if (entity.type.button.button.disabled_name) |value| {
        if (try display.requireImage(value)) |bh|
            entity.type.button.button.disabled = bh
        else
            err("setup_button background.disabled resource `{s}` not loaded.", .{value});

        if (entity.type.button.button.disabled == null and entity.background.image != null)
            entity.type.button.button.disabled = entity.background.image.?.clone();
    }
}

pub const Callback = struct {
    func: ?*const fn (
        ptr: *anyopaque,
        display: *Display,
        entity: *Entity,
        event: *const Event,
    ) Allocator.Error!void = null,
    ptr: *anyopaque = undefined,

    pub const empty: @This() = .{
        .func = null,
        .ptr = undefined,
    };

    /// Trigger the callback if the `func` is specified (not null)
    pub fn call(
        self: @This(),
        display: *Display,
        entity: *Entity,
        event: *const Event,
    ) Allocator.Error!void {
        if (self.func) |f| return f(self.ptr, display, entity, event);
    }
};

pub const StateCallback = struct {
    func: ?*const fn (
        ptr: *anyopaque,
        display: *Display,
        entity: *Entity,
    ) Allocator.Error!void = null,
    ptr: *anyopaque = undefined,

    pub const empty: @This() = .{
        .func = null,
        .ptr = undefined,
    };

    /// Trigger the callback if the `func` is specified (not null)
    pub fn call(
        self: @This(),
        display: *Display,
        entity: *Entity,
    ) Allocator.Error!void {
        if (self.func) |f| return f(self.ptr, display, entity);
    }
};

pub const UpdateCallback = struct {
    func: ?*const fn (
        ptr: *anyopaque,
        display: *Display,
        entity: *Entity,
    ) void = null,
    ptr: *anyopaque = undefined,

    pub const empty: @This() = .{
        .func = null,
        .ptr = undefined,
    };

    pub fn call(
        self: @This(),
        display: *Display,
        entity: *Entity,
    ) void {
        if (self.func) |f| f(self.ptr, display, entity);
    }
};

pub const PanelChangeCallback = struct {
    func: ?*const fn (
        ptr: *anyopaque,
        display: *Display,
        from: ?*Entity,
        to: *Entity,
    ) Allocator.Error!void = null,
    ptr: *anyopaque = undefined,

    pub const empty: @This() = .{
        .func = null,
        .ptr = undefined,
    };

    pub fn call(
        self: @This(),
        display: *Display,
        from: ?*Entity,
        to: *Entity,
    ) Allocator.Error!void {
        if (self.func) |f| return f(self.ptr, display, from, to);
    }
};

pub const BoolCallback = struct {
    func: ?*const fn (
        ptr: *anyopaque,
        display: *Display,
        entity: *Entity,
    ) bool = null,
    ptr: *anyopaque = undefined,

    pub const empty: @This() = .{
        .func = null,
        .ptr = undefined,
    };

    pub fn call(
        self: @This(),
        display: *Display,
        entity: *Entity,
    ) bool {
        if (self.func) |f| return f(self.ptr, display, entity);
        return false;
    }
};

/// Draw an outline of a rectangle. Used in debug mode to highlight where
/// items appear on the screen.
fn draw_rectangle(
    renderer: *sdl.SDL_Renderer,
    border_width: f32,
    colour: Colour,
    rect: Rect,
    scroll_offset: Vector,
) void {
    if (border_width > 0 and colour.a > 0) {
        _ = sdl.SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
        var dest: Rect = .{
            .x = rect.x,
            .y = rect.y,
            .width = rect.width,
            .height = border_width,
        };
        dest.x += scroll_offset.x;
        dest.y += scroll_offset.y;
        _ = sdl.SDL_SetRenderDrawColor(
            renderer,
            colour.r,
            colour.g,
            colour.b,
            colour.a,
        );
        _ = sdl.SDL_RenderFillRect(renderer, @ptrCast(&dest));
        dest.y = rect.y + rect.height - border_width;
        _ = sdl.SDL_RenderFillRect(renderer, @ptrCast(&dest));
        var dest2: Rect = .{
            .x = rect.x,
            .y = rect.y,
            .width = border_width,
            .height = rect.height,
        };
        _ = sdl.SDL_RenderFillRect(renderer, @ptrCast(&dest2));
        dest2.x = rect.x + rect.width - border_width;
        _ = sdl.SDL_RenderFillRect(renderer, @ptrCast(&dest2));
    }
}

/// Draw a simple line.
fn draw_line(
    renderer: *sdl.SDL_Renderer,
    border_width: f32,
    colour: Colour,
    start: Vector,
    end: Vector,
    scroll_offset: Vector,
) void {
    if (border_width > 0 and colour.a > 0) {
        _ = sdl.SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
        var dest: Rect = .{
            .x = if (start.x < end.x) start.x else end.x,
            .y = if (start.y < end.y) start.y else end.y,
            .width = @abs(end.x - start.x),
            .height = @abs(end.y - start.y),
        };
        if (dest.width == 0) dest.width = border_width;
        if (dest.height == 0) dest.height = border_width;
        // Try to centre the line
        dest.x -= border_width / 2;
        dest.y -= border_width / 2;
        dest.x += scroll_offset.x;
        dest.y += scroll_offset.y;
        _ = sdl.SDL_SetRenderDrawColor(
            renderer,
            colour.r,
            colour.g,
            colour.b,
            colour.a,
        );
        _ = sdl.SDL_RenderFillRect(renderer, @ptrCast(&dest));
    }
}

pub inline fn tint_texture(texture: *sdl.SDL_Texture, colour: Colour) void {
    _ = sdl.SDL_SetTextureAlphaMod(texture, colour.a);
    _ = sdl.SDL_SetTextureColorMod(texture, colour.r, colour.g, colour.b);
}

pub const Background = struct {
    colour: Colour = Colour.TRANSPARENT,

    /// Load an `image` resource by indicating the name of the image
    /// exactly as it appears in the resource bundle.
    image_name: ?[]const u8 = null,

    /// The `image` variable is filled on initialisation, by searching for
    /// the `image_name` inside the resource bundle, and loading the data into
    /// this `image`.
    image: ?*Texture = null,

    /// If the background texture has corners, the width of the corner in pixels.
    image_corner_radius: f32 = 0,

    /// If the background texture has corners, how many pixels wide should the corner be rendered on the display.
    corner_radius: f32 = 0,
};

pub fn select_font(fonts: []*Font, name: ?[]const u8) Error!*Font {
    if (name) |font_name| {
        for (fonts) |font| {
            if (std.mem.eql(u8, font.name, font_name)) {
                return font;
            }
        }
        err("select_font({s}) called, but no fonts have been loaded.", .{name.?});
    }
    if (fonts.len > 0) return fonts[0];
    return error.FontRequired;
}

pub const TextElement = struct {
    text: []const u8 = "",
    font: *Font,
    /// Width of this word/element not including display scaling
    /// or text size scaling.
    width: f32 = 0,
    location: Rect = .{ .x = 0, .y = 0, .width = 0, .height = 0 },
};

/// A vector may represent a position or distance in 2D space.
pub const Vector = struct {
    x: f32 = 0,
    y: f32 = 0,

    /// Add the x and y value from the `other` vector to this vector.
    pub fn add(self: Vector, other: Vector) Vector {
        return Vector{
            .x = self.x + other.x,
            .y = self.y + other.y,
        };
    }

    pub fn move(self: Vector, x: f32, y: f32) Vector {
        return Vector{
            .x = self.x + x,
            .y = self.y + y,
        };
    }

    /// Subtract the x and y value from the `other` vector to this vector.
    pub fn minus(self: Vector, other: Vector) Vector {
        return Vector{
            .x = self.x - other.x,
            .y = self.y - other.y,
        };
    }

    /// Multiply the x and y value from the `other` vector to this vector.
    pub fn multiply(self: Vector, value: f32) Vector {
        return Vector{
            .x = self.x * value,
            .y = self.y * value,
        };
    }

    pub fn distance(self: Vector, other: Vector) f32 {
        return sqrt(pow(f32, other.x - self.x, 2) + pow(f32, other.y - self.y, 2));
    }
};

/// A rectangle desribes a point and an area.
pub const Rect = extern struct {
    x: f32 = 0,
    y: f32 = 0,
    width: f32 = 0,
    height: f32 = 0,

    /// Add the x and y value from the `other` vector to this vector.
    pub fn move(self: *const Rect, offset: Vector) Rect {
        return .{
            .x = self.x + offset.x,
            .y = self.y + offset.y,
            .width = self.width,
            .height = self.height,
        };
    }

    /// The x and y position of the rectangle
    pub fn location(self: *Rect) Vector {
        return .{ .x = self.x, .y = self.y };
    }

    /// Return a new rectangle by shrinking this rectangle by the requested
    /// padding amount.
    pub fn removePadding(self: Rect, pad: Clip) Rect {
        return .{
            .x = self.x + pad.left,
            .y = self.y + pad.top,
            .width = self.width - pad.left - pad.right,
            .height = self.height - pad.top - pad.bottom,
        };
    }
};

/// Describe a bounding box or padding area.
pub const Clip = struct {
    top: f32 = 0,
    bottom: f32 = 0,
    left: f32 = 0,
    right: f32 = 0,

    pub fn isClipped(self: Clip, rect: Rect) bool {
        if (rect.x + rect.width < self.left) return true;
        if (rect.y + rect.height < self.top) return true;
        if (rect.x > self.right) return true;
        if (rect.y > self.bottom) return true;
        return false;
    }

    /// Shrink the bounding box if its crossing the clip boundary.
    pub fn applyEdgeClipping(clip: Clip, rect: *engine.Rect) void {
        // Is text crossing over scroll box boundary?
        if (rect.y + rect.height > clip.bottom) {
            rect.height = @max(0, clip.bottom - rect.y);
        } else if (rect.y < clip.top) {
            const cut_amount = clip.top - rect.y;
            rect.height = @max(0, rect.height - cut_amount);
            rect.y += cut_amount;
        }
    }
};

/// Describe the size of an entity.
pub const Size = struct {
    width: f32 = 0,
    height: f32 = 0,
};

/// The width and height an entity will used based on parent entity information.
pub const SizeInfo = struct {
    /// The width an entity has based on its parent entity width and shrink/grows setting.
    width: f32 = 0,
    /// The physical height needed for this entity. shrink/grows height ignored.
    /// TODO: Growing should be supported to allow horizontal centring.
    height: f32 = 0,
    /// The width an entity could be shrunk to
    minimum_width: f32 = 0,
};

/// Indicate if an entity should be flipped when it is drawn.
pub const Flip = struct {
    x: bool = false,
    y: bool = false,
};

/// Scroll information
pub const Scroller = struct {
    scroll: Flip,
    size: Size,
};

/// Describe how a child entity sits inside a parent entity.
pub const Layout = struct {
    position: LayoutMode = .@"inline",
    x: LayoutSize = .shrinks,
    y: LayoutSize = .shrinks,
};

/// Describe where to start drawing child entity inside the parent entity.
pub const ChildLayout = struct {
    x: LayoutAlign = .start,
    y: LayoutAlign = .start,
};

/// Specify if and entities `rect` width and height should grow or shrink to
/// fit the panel it belongs to.
pub const LayoutSize = enum {
    /// Default behavior is to neither grow or shirnk the `rect`
    fixed,
    /// Grow to the width of the parent panel.
    grows,
    /// Shrink the the minimum space that is needed.
    shrinks,
};

/// Specify how an image texture is applied to the entity `rect`.
pub const Fit = enum {
    /// Stretch the image texture to completely fill the `rect` width and height.
    stretch,

    /// Maintaining the image aspect ratio, increase the width and height of
    /// the image to completely fill the `rect`. If the image must overflow
    /// to fill the `rect`, any overflow is cropped.
    fill,

    /// Maintaining the image aspect ratio, enlarge the texture image to
    /// exactly fit the `entity.rect`, this may cause vertical or horizontal
    /// padding. Use `child_align` to place the texture at the `start`,
    /// `centre` or `end` of the entity rect.
    fit,
};

/// An entity is ignored when it is hidden. An entity is drawn when it is
/// visible. An entity is culled when it is visible, but not currently inside
/// thd drawable area on the screen.
pub const Visibility = enum {
    visible,
    culled,
    hidden,
};

/// The `x` and `y` position of an entity is either automatically
/// generated `inline` relative to its parent and sibiling entities;
/// or the `x` and `y` position is manually specified to `float` freely
/// outside of the entity tree.
pub const LayoutMode = enum {
    @"inline",
    float,
};

/// When an entity has spare space, its contents
/// will sit on the start of the box, end of the box,
/// or in the centre.
pub const LayoutAlign = enum {
    start,
    end,
    centre,
};

/// Entities inside entities may be drawn from left to right,
/// top to bottom, or every item is drawn in the centre.
pub const LayoutDirection = enum {
    /// Starting at the top, place each entity under the previous entity.
    top_to_bottom,

    /// Place all items along the top, from left to right.
    left_to_right,

    /// Place items along the top, but wrap if you reach
    /// the end of the line.
    left_to_right_wrap,

    //right_to_left,
    //bottom_to_top,

    /// Place _all_ items in the centre of this panel.
    centre,

    /// Place _all_ items in the top left of the panel.
    top_left,

    /// Place _all_ items in the top right of the panel.
    top_right,
};

/// The `normal` scale is designed for a regular person with regular
/// eyesight. The user may optionally decrease or increase the user
/// interface by slecting a smaller or larger scale.
pub const Scale = enum(u8) {
    unknown = 0,
    tiny = 1,
    small = 2,
    normal = 3,
    large = 4,
    extra_large = 5,

    /// Map a floating number representing the user interface scale
    /// back to the enum value. `.normal = 1`.
    pub fn from_float(value: f32) Scale {
        if (value == 0.5) return .tiny;
        if (value == 0.75) return .small;
        if (value == 1.25) return .large;
        if (value == 1.5) return .extra_large;
        return .normal;
    }

    /// Returns 1 for `normal` scale. Scale increments or decrements
    /// based on user preference.
    pub fn float(self: Scale) f32 {
        return switch (self) {
            .unknown, .normal => 1.0,
            .tiny => 0.5,
            .small => 0.75,
            .large => 1.25,
            .extra_large => 1.5,
        };
    }

    /// Map a text string to the enum value, `"normal" = .normal`.
    pub fn parse(value: []const u8) Scale {
        var buf: [40]u8 = undefined;
        const text = std.ascii.lowerString(&buf, value);
        if (std.mem.eql(u8, text, @tagName(.unknown))) return .unknown;
        if (std.mem.eql(u8, text, @tagName(.tiny))) return .tiny;
        if (std.mem.eql(u8, text, @tagName(.small))) return .small;
        if (std.mem.eql(u8, text, @tagName(.normal))) return .normal;
        if (std.mem.eql(u8, text, @tagName(.large))) return .large;
        if (std.mem.eql(u8, text, @tagName(.extra_large))) return .extra_large;
        return .unknown;
    }
};

/// Information about the location and visibility of an entity.
pub const Box = struct {};

pub const FocusOption = enum(u2) {
    unspecified,
    /// never_focus don't allow _tab into_ or _hover over_
    never_focus,
    /// can_focus allow _tab into_ or _hover over_ with a mouse.
    can_focus,
    /// accessibility_focus is used to indicate screen readers may tab
    /// into this entity to inspect it. Use to describe important
    /// on screen text and images
    accessibility_focus,
};

/// Describe the state of a toggle/checkbox button.
pub const ToggleState = enum {
    no_toggle,
    on,
    off,
    correct,
    incorrect,
    locked_off,
    disabled,
};

/// Describe the type of each entity in the elment tree.
pub const Type = enum {
    button,
    checkbox,
    expander,
    label,
    panel,
    progress_bar,
    rectangle,
    sprite,
    text_input,
};

const std = @import("std");
const ArrayListUnmanaged = std.ArrayListUnmanaged;
const Allocator = std.mem.Allocator;
const sqrt = std.math.sqrt;
const pow = std.math.pow;

const engine = @import("engine.zig");
const sdl = engine.sdl;
const err = engine.log.err;
const warn = engine.log.warn;
const info = engine.log.info;
const debug = engine.log.debug;
const trace = engine.log.trace;
const Display = engine.Display;
const Error = engine.Error;
const Font = engine.Font;
const Key = engine.Key;
const directional_clamp = engine.directional_clamp;

const resources = @import("resources");
const Resources = resources.Resources;
const Resource = resources.Resource;

const praxis = @import("praxis");
const Lang = @import("praxis").Lang;

const Translation = @import("translator").Translation;

const Chunker = @import("Chunker.zig");
const Texture = @import("Texture.zig");
const Colour = @import("Colour.zig");
const Theme = @import("Theme.zig");
const Event = @import("Event.zig");

pub const TextSize = engine.TextSize;

pub const Button = @import("Button.zig");
pub const Checkbox = @import("Checkbox.zig");
pub const Expander = @import("Expander.zig");
pub const Panel = @import("Panel.zig");
pub const ProgressBar = @import("ProgressBar.zig");
pub const Sprite = @import("Sprite.zig");
pub const Label = @import("Label.zig");
pub const Rectangle = @import("Rectangle.zig");
pub const TextInput = @import("TextInput.zig");
pub const Token = @import("Token.zig");
