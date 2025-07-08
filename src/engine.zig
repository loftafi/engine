pub const dev_build = (builtin.mode == .Debug);
pub var dev_mode = false;

pub const CORNER_RADIUS: f32 = 20.0;
pub const FONT_SIZE: f32 = 22.0;
pub const FONT_MUL: f32 = 2.0;
pub const RESOURCE_BUNDLE_FILENAME = "resources.bd";

// A vector may represent a position or distance in 2D space.
pub const Vector = struct {
    x: f32 = 0,
    y: f32 = 0,

    pub fn add(self: Vector, other: Vector) Vector {
        return Vector{
            .x = self.x + other.x,
            .y = self.y + other.y,
        };
    }

    pub fn minus(self: Vector, other: Vector) Vector {
        return Vector{
            .x = self.x - other.x,
            .y = self.y - other.y,
        };
    }

    pub fn multiply(self: Vector, value: f32) Vector {
        return Vector{
            .x = self.x * value,
            .y = self.y * value,
        };
    }
};

/// A rectangle desribes a point and an area.
pub const Rect = extern struct {
    x: f32 = 0,
    y: f32 = 0,
    width: f32 = 0,
    height: f32 = 0,

    pub fn move(self: *Rect, l: *const Vector) Rect {
        return .{
            .x = self.x + l.x,
            .y = self.y + l.y,
            .width = self.width,
            .height = self.height,
        };
    }
};

/// Describe a bounding box or padding area.
pub const Clip = struct {
    top: f32 = 0,
    bottom: f32 = 0,
    left: f32 = 0,
    right: f32 = 0,
};

/// Describe the size of an element.
pub const Size = struct {
    width: f32 = 0,
    height: f32 = 0,
};

/// Indicate if an element should be flipped when it is drawn.
pub const Flip = struct {
    x: bool,
    y: bool,
};

/// Scroll information
pub const Scroller = struct {
    scroll: Flip,
    size: Size,
};

/// Describe how a child element sits inside a parent element.
pub const Layout = struct {
    position: LayoutMode = .unspecified,
    x: LayoutSize = .shrinks,
    y: LayoutSize = .shrinks,
};

/// Describe where to start drawing child elements inside the parent element.
pub const ChildLayout = struct {
    x: LayoutAlign = .start,
    y: LayoutAlign = .start,
};

/// If an element is not a fixed size, it may choose
/// to grow as wide or tall as possible, or it may
/// choose to shrink to the minimum size it needs
/// for its contents.
pub const LayoutSize = enum {
    fixed,
    grows,
    shrinks,
};

/// An element is ignored when it is hidden. An element is drawn when it is
/// visible. An element is culled when it is visible, but not currently inside
/// thd drawable area on the screen.
pub const Visibility = enum {
    visible,
    culled,
    hidden,
};

/// An element lives inside its parent panel and takes
/// a position relative to its parefnt panel, unless
/// it has a floating position.
pub const LayoutMode = enum {
    unspecified,
    float,
};

/// When an element has spare space, its contents
/// will sit on the start of the box, end of the box,
/// or in the centre.
pub const LayoutAlign = enum {
    start,
    end,
    centre,
};

/// Elements inside elements may be drawn from left to right,
/// top to bottom, or every item is drawn in the centre.
pub const LayoutDirection = enum {
    top_to_bottom,
    left_to_right,
    //right_to_left,
    //bottom_to_top,
    centre,
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
        if (value == 0.5) {
            return .tiny;
        }
        if (value == 0.75) {
            return .small;
        }
        if (value == 1.25) {
            return .large;
        }
        if (value == 1.5) {
            return .extra_large;
        }
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
        if (std.mem.eql(u8, text, @tagName(.unknown))) {
            return .unknown;
        }
        if (std.mem.eql(u8, text, @tagName(.tiny))) {
            return .tiny;
        }
        if (std.mem.eql(u8, text, @tagName(.small))) {
            return .small;
        }
        if (std.mem.eql(u8, text, @tagName(.normal))) {
            return .normal;
        }
        if (std.mem.eql(u8, text, @tagName(.large))) {
            return .large;
        }
        if (std.mem.eql(u8, text, @tagName(.extra_large))) {
            return .extra_large;
        }
        return .unknown;
    }
};

/// Information about the location and visibility of an element.
pub const Box = struct {};

pub const FocusOption = enum(u2) {
    unspecified,
    /// never_focus allow tab into or activation with a mouse
    never_focus,
    /// can_focus
    can_focus,
    /// accessibility_focus is used to indicate screen readers may tab
    /// into this element to inspect it. Use to describe important
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
};

/// Describe the type of each element in the elment tree.
pub const ElementType = enum {
    panel,
    sprite,
    label,
    checkbox,
    text_input,
    rectangle,
    button,
    button_bar,
    progress_bar,
    expander,
};

pub const Colour = struct {
    r: u8 = 0,
    g: u8 = 0,
    b: u8 = 0,
    a: u8 = 0,
};

pub const TRANSPARENT: Colour = .{ .r = 0, .g = 0, .b = 0, .a = 0 };
pub const WHITE: Colour = .{ .r = 255, .g = 255, .b = 255, .a = 255 };
pub const BLACK: Colour = .{ .r = 0, .g = 0, .b = 0, .a = 255 };

/// Describe an element that will be rendered on the screen during a draw
/// loop. See `ElementType` for the types of elements that may be rendered.
pub const Element = struct {
    name: []const u8 = "",

    rect: Rect = .{ .x = 0, .y = 0, .width = 0, .height = 0 },

    /// If this element is a scroll panel, the offset tracks how far it has scrolled.
    offset: Vector = .{ .x = 0, .y = 0 },

    pad: Clip = .{ .top = 0, .left = 0, .right = 0, .bottom = 0 },
    velocity: Vector = .{ .x = 0, .y = 0 },
    flip: Flip = .{ .x = false, .y = false },
    visible: Visibility = .visible,
    layout: Layout = .{
        .x = .fixed,
        .y = .fixed,
    },
    child_align: ChildLayout = .{
        .x = .start,
        .y = .start,
    },
    minimum: Size = .{ .width = 0, .height = 0 },
    maximum: Size = .{ .width = 0, .height = 0 },

    pressed: bool = false,
    focussed: bool = false,
    hovered: bool = false,
    focus: FocusOption = .unspecified,

    texture: ?*TextureInfo = null,
    colour: Colour = WHITE,

    background_colour: Colour = TRANSPARENT,
    background_texture: ?*TextureInfo = null,

    border_colour: Colour = TRANSPARENT,
    border_width: f32 = 0,

    on_resized: ?*const fn (display: *Display, element: *Element) bool = null,

    type: union(ElementType) {
        panel: struct {
            children: ArrayList(*Element) = undefined,
            direction: LayoutDirection = .centre,
            spacing: f32 = 0,
            style: ThemeColour = .normal,
            on_click: ?*const fn (display: *Display, element: *Element) Allocator.Error!void = null,
            scrollable: Scroller = .{
                .scroll = .{ .x = false, .y = false },
                .size = .{ .width = 0, .height = 0 },
            },
            overflow: Vector = .{ .x = 0, .y = 0 },
        },
        sprite: struct {
            on_click: ?*const fn (display: *Display, element: *Element) Allocator.Error!void = null,
        },
        label: struct {
            text: []const u8 = "",
            translated: []const u8 = "",
            elements: ArrayList(TextElement) = undefined,
            line_height: f32 = 1,
            text_size: TextSize = .normal,
            text_colour: ThemeColour = .normal,
            on_click: ?*const fn (display: *Display, element: *Element) Allocator.Error!void = null,
        },
        checkbox: struct {
            checked: bool = false,
            translated: []const u8 = "",
            text: []const u8 = "",
            elements: ArrayList(TextElement) = undefined,
            line_height: f32 = 1,
            text_size: TextSize = .normal,
            text_colour: ThemeColour = .normal,
            on_texture: ?*TextureInfo = null,
            off_texture: ?*TextureInfo = null,
            on_change: ?*const fn (display: *Display, element: *Element) Allocator.Error!void = null,
        },
        text_input: struct {
            texture: ?*sdl.SDL_Texture = null,
            text: ArrayList(u8) = undefined,
            runes: ArrayList(u21) = undefined,
            max_runes: usize = 0,
            cursor_character: usize = 0,
            cursor_pixels: f32 = 0,
            on_change: ?*const fn (display: *Display, element: *Element) Allocator.Error!void = null,
            on_submit: ?*const fn (display: *Display, element: *Element) Allocator.Error!void = null,
            placeholder_texture: ?*sdl.SDL_Texture = null,
            placeholder_text: ArrayList(u8) = undefined,
            placeholder_translate: []const u8 = "",
        },
        rectangle: struct {
            style: ThemeColour = .normal,
        },
        button: struct {
            text: []const u8 = "",
            translated: []const u8 = "",
            text_texture: ?*sdl.SDL_Texture = null,
            icon_size: Vector = .{ .x = 0, .y = 0 },
            spacing: f32 = 0,
            icon_hover: ?*TextureInfo = null,
            icon_pressed: ?*TextureInfo = null,
            background_hover: ?*TextureInfo = null,
            background_pressed: ?*TextureInfo = null,
            on_click: ?*const fn (display: *Display, element: *Element) Allocator.Error!void = null,
            toggle: ToggleState = .no_toggle,
            style: ThemeColour = .normal,
        },
        button_bar: struct {},
        progress_bar: struct {
            progress: f32 = 0,
        },
        expander: struct {
            weight: f32 = 0,
        },
    },

    /// Cleanup memory associated with this element. This is automatically
    /// called on all elements inside the display when the display is destroyed.
    ///
    /// Never call `destroy()` unless you know the element is not inside the
    /// display tree.
    pub fn destroy(self: *Element, display: *Display, allocator: Allocator) void {
        self.deinit(display, allocator);
        allocator.destroy(self);
    }

    /// Cleanup memory associated with this element. This is automatically
    /// called on all elements inside the display when the display is destroyed.
    ///
    /// Never call `deinit()` unless you know the element is not inside the
    /// display tree.
    pub fn deinit(self: *Element, display: *Display, allocator: Allocator) void {
        // Cleanup shared attributes

        if (self.texture) |texture| {
            display.release_texture_resource(texture);
            self.texture = null;
        }

        if (self.background_texture) |texture| {
            display.release_texture_resource(texture);
            self.background_texture = null;
        }

        // Cleanup element type specific attributes
        switch (self.type) {
            .panel => |*i| {
                for (i.*.children.items) |child| {
                    child.destroy(display, allocator);
                }
                i.*.children.deinit();
            },
            .progress_bar => |_| {
                //
            },
            .expander => |_| {
                //
            },
            .text_input => |*i| {
                if (i.*.texture) |texture| {
                    sdl.SDL_DestroyTexture(texture);
                }
                i.*.placeholder_text.deinit();
                i.*.runes.deinit();
                i.*.text.deinit();
            },
            .label => |*i| {
                for (i.*.elements.items) |item| {
                    sdl.SDL_DestroyTexture(item.texture);
                }
                i.*.elements.deinit();
            },
            .checkbox => |*i| {
                for (i.*.elements.items) |item| {
                    sdl.SDL_DestroyTexture(item.texture);
                }
                if (i.*.on_texture) |texture| {
                    display.release_texture_resource(texture);
                    i.*.on_texture = null;
                }
                if (i.*.off_texture) |texture| {
                    display.release_texture_resource(texture);
                    i.*.off_texture = null;
                }
                i.*.elements.deinit();
            },
            .rectangle => {},
            .sprite => {},
            .button => |*i| {
                if (i.*.text_texture) |texture| {
                    sdl.SDL_DestroyTexture(texture);
                }
                if (i.*.icon_hover) |texture| {
                    display.release_texture_resource(texture);
                }
                if (i.*.icon_pressed) |texture| {
                    display.release_texture_resource(texture);
                }
                if (i.*.background_hover) |texture| {
                    display.release_texture_resource(texture);
                }
                if (i.*.background_pressed) |texture| {
                    display.release_texture_resource(texture);
                }
            },
            .button_bar => {
                //
            },
        }
    }

    /// Find a direct child of this element by the name attached to
    /// the element.
    pub fn get_child_by_name(self: *Element, name: []const u8) ?*Element {
        trace("searching for {s} in {s}", .{ name, self.name });
        for (self.type.panel.children.items) |element| {
            if (std.mem.eql(u8, name, element.name)) {
                trace("searching for {s} in {s}. match", .{ name, self.name });
                return element;
            }
        }
        trace("searching for {s} in {s}. no match", .{ name, self.name });
        return null;
    }

    /// Return true if this element appears under this point on the screen.
    pub fn at_point(self: *Element, cursor: Vector, parent_scroll_offset: Vector) bool {
        const point = Vector{ .x = self.rect.x, .y = self.rect.y };
        if (self.type == .panel and (self.type.panel.scrollable.scroll.x or self.type.panel.scrollable.scroll.y)) {
            // Scrollable panels live at their pre-scroll-offset location.
            if (cursor.x < point.x) {
                return false;
            }
            if (cursor.y < point.y) {
                return false;
            }
            if (cursor.x > point.x + self.rect.width) {
                return false;
            }
            if (cursor.y > point.y + self.rect.height) {
                return false;
            }
        } else {
            const current = point.add(self.offset).add(parent_scroll_offset);
            if (cursor.x < current.x) {
                return false;
            }
            if (cursor.y < current.y) {
                return false;
            }
            if (cursor.x > current.x + self.rect.width) {
                return false;
            }
            if (cursor.y > current.y + self.rect.height) {
                return false;
            }
        }
        return true;
    }

    inline fn button_tint(self: *Element, theme: *Theme) Colour {
        if (self.type.button.style == .success) {
            return theme.success_text_colour;
        }
        if (self.type.button.style == .failed) {
            return theme.failed_text_colour;
        }
        if (self.pressed) {
            return theme.tinted_text_colour;
        }
        if (self.hovered) {
            return theme.tinted_text_colour;
        }
        return theme.text_colour;
    }

    inline fn apply_background_tint(
        self: *Element,
        display: *Display,
        texture: *sdl.SDL_Texture,
    ) void {
        if (self.type == .button) {
            switch (self.type.button.style) {
                .success => {
                    _ = sdl.SDL_SetTextureColorMod(
                        texture,
                        display.theme.success_button_colour.r,
                        display.theme.success_button_colour.g,
                        display.theme.success_button_colour.b,
                    );
                    return;
                },
                .failed => {
                    _ = sdl.SDL_SetTextureColorMod(
                        texture,
                        display.theme.failed_button_colour.r,
                        display.theme.failed_button_colour.g,
                        display.theme.failed_button_colour.b,
                    );
                    return;
                },
                else => {
                    // Otherwise apply toggle colurs if needed
                },
            }
            switch (self.type.button.toggle) {
                .off, .locked_off => {
                    _ = sdl.SDL_SetTextureColorMod(
                        texture,
                        display.theme.toggle_button.r,
                        display.theme.toggle_button.g,
                        display.theme.toggle_button.b,
                    );
                    return;
                },
                .on => {
                    _ = sdl.SDL_SetTextureColorMod(
                        texture,
                        display.theme.toggle_button_picked.r,
                        display.theme.toggle_button_picked.g,
                        display.theme.toggle_button_picked.b,
                    );
                    return;
                },
                .correct => {
                    _ = sdl.SDL_SetTextureColorMod(
                        texture,
                        display.theme.toggle_button_correct.r,
                        display.theme.toggle_button_correct.g,
                        display.theme.toggle_button_correct.b,
                    );
                    return;
                },
                .incorrect => {
                    _ = sdl.SDL_SetTextureColorMod(
                        texture,
                        display.theme.toggle_button_incorrect.r,
                        display.theme.toggle_button_incorrect.g,
                        display.theme.toggle_button_incorrect.b,
                    );
                    return;
                },
                .no_toggle => {},
            }
        }
        if (self.type == .panel) {
            switch (self.type.panel.style) {
                .emphasised => {
                    _ = sdl.SDL_SetTextureColorMod(
                        texture,
                        display.theme.emphasised_panel_colour.r,
                        display.theme.emphasised_panel_colour.g,
                        display.theme.emphasised_panel_colour.b,
                    );
                    return;
                },
                .success => {
                    _ = sdl.SDL_SetTextureColorMod(
                        texture,
                        display.theme.success_panel_colour.r,
                        display.theme.success_panel_colour.g,
                        display.theme.success_panel_colour.b,
                    );
                    return;
                },
                .failed => {
                    _ = sdl.SDL_SetTextureColorMod(
                        texture,
                        display.theme.failed_panel_colour.r,
                        display.theme.failed_panel_colour.g,
                        display.theme.failed_panel_colour.b,
                    );
                    return;
                },
                .faded => {
                    _ = sdl.SDL_SetTextureColorMod(
                        texture,
                        display.theme.faded_panel_colour.r,
                        display.theme.faded_panel_colour.g,
                        display.theme.faded_panel_colour.b,
                    );
                    return;
                },
                .background => {
                    _ = sdl.SDL_SetTextureColorMod(
                        texture,
                        display.theme.background_colour.r,
                        display.theme.background_colour.g,
                        display.theme.background_colour.b,
                    );
                    return;
                },
                .normal => {
                    _ = sdl.SDL_SetTextureColorMod(
                        texture,
                        display.theme.label_background_colour.r,
                        display.theme.label_background_colour.g,
                        display.theme.label_background_colour.b,
                    );
                    return;
                },
                else => {
                    warn("unhandled panel tint option: {s}", .{@tagName(self.type.panel.style)});
                },
            }
        }
        _ = sdl.SDL_SetTextureColorMod(
            texture,
            display.theme.label_background_colour.r,
            display.theme.label_background_colour.g,
            display.theme.label_background_colour.b,
        );
    }

    /// An icon may have different background textures for hovered,
    /// pressed and normal state. Return the background that is valid
    /// for the current state.
    inline fn current_background(self: *Element) ?*sdl.SDL_Texture {
        if (self.type == .button) {
            if (self.pressed and self.type.button.background_pressed != null) {
                return self.type.button.background_pressed.?.texture;
            }
            if (self.hovered and self.type.button.background_hover != null) {
                return self.type.button.background_hover.?.texture;
            }
        }
        if (self.background_texture != null) {
            return self.background_texture.?.texture;
        }
        return null;
    }

    /// An icon may have different image textures for hovered, pressed
    /// and normal state. Return the image that is valid for the current state.
    inline fn current_icon(self: *Element) ?*sdl.SDL_Texture {
        if (self.type == .button) {
            if (self.pressed and self.type.button.icon_pressed != null) {
                return self.type.button.icon_pressed.?.texture;
            }
            if (self.hovered and self.type.button.icon_hover != null) {
                return self.type.button.icon_hover.?.texture;
            }
        }
        if (self.texture != null) {
            return self.texture.?.texture;
        }
        return null;
    }

    /// The text_input element may display placeholder text when there
    /// is no text in the text_input. Placeholder text should be less
    /// visibily prominent.
    pub inline fn set_placeholder_text(
        self: *Element,
        display: *Display,
        text: []const u8,
    ) !void {
        debug("set_placeholder_text({s}.{s}) {s}", .{ @tagName(self.type), self.name, text });
        switch (self.type) {
            .text_input => {
                if (self.type.text_input.placeholder_texture) |texture| {
                    sdl.SDL_DestroyTexture(texture);
                    self.texture = null;
                }
                self.type.text_input.placeholder_text.clearRetainingCapacity();
                if (text.len > 0) {
                    try self.type.text_input.placeholder_text.appendSlice(text);
                    if (display.generate_text_texture(self.type.text_input.placeholder_text.items)) |texture| {
                        self.type.text_input.placeholder_texture = texture;
                    }
                }
            },
            else => {
                log.info("set_placeholder_text({s}.{s}) invalid", .{ @tagName(self.type), text });
            },
        }
    }

    /// set_text updates the `text` and `translation` fields of labels,
    /// checkboxes and buttons, and regenerates the grahpics/image
    /// textures for each word if the text was changed or `forced`
    /// is requested.
    pub inline fn set_text(self: *Element, display: *Display, new_text: []const u8, forced: bool) error{OutOfMemory}!void {
        const old_translated = switch (self.type) {
            .text_input => self.type.text_input.text.items,
            .checkbox => self.type.checkbox.translated,
            .label => self.type.label.translated,
            .button => self.type.button.translated,
            else => {
                err("set_text({s}.{s}) invalid", .{ @tagName(self.type), new_text });
                return;
            },
        };
        if (dev_build and dev_mode) {
            const old_text = switch (self.type) {
                .text_input => self.type.text_input.text.items,
                .checkbox => self.type.checkbox.text,
                .label => self.type.label.text,
                .button => self.type.button.text,
                else => {
                    return;
                },
            };
            debug("set_text {s} {s} \"{s}\" => \"{s}\"", .{ self.name, @tagName(self.type), old_text, new_text });
        }
        const new_translated = display.translation.translate(new_text);
        trace("set_text({s}.{s}) translated \"{s}\" => \"{s}\"", .{
            @tagName(self.type),
            self.name,
            old_translated,
            new_translated,
        });
        if (std.mem.eql(u8, new_translated, old_translated) and !forced) {
            // Don't update if nothing changed
            return;
        }

        switch (self.type) {
            .text_input => {
                if (self.type.text_input.texture) |texture| {
                    sdl.SDL_DestroyTexture(texture);
                    self.texture = null;
                }
                self.type.text_input.text.clearRetainingCapacity();
                self.type.text_input.runes.clearRetainingCapacity();
                if (new_text.len > 0) {
                    try self.type.text_input.text.appendSlice(new_text);
                    self.text_data_to_runes();
                    if (display.generate_text_texture(self.type.text_input.text.items)) |texture| {
                        self.type.text_input.cursor_pixels = text_size(display, texture, .normal).width;
                        self.type.text_input.texture = texture;
                        self.type.text_input.cursor_character = self.type.text_input.runes.items.len;
                    } else {
                        self.type.text_input.cursor_pixels = 0.0;
                        self.type.text_input.cursor_character = 0;
                    }
                } else {
                    self.type.text_input.cursor_pixels = 0.0;
                    self.type.text_input.cursor_character = 0;
                }
            },
            .label => {
                // Clear old text
                for (self.type.label.elements.items) |item| {
                    sdl.SDL_DestroyTexture(item.texture);
                }
                self.type.label.elements.clearRetainingCapacity();
                self.type.label.text = new_text;
                self.type.label.translated = new_translated;
                if (self.type.label.translated.len > 0) {
                    var data = Chunker.init(self.type.label.translated);
                    while (data.next()) |text| {
                        if (display.generate_text_texture(text)) |texture| {
                            try self.type.label.elements.append(.{
                                .text = text,
                                .width = @floatFromInt(texture.*.w),
                                .texture = texture,
                                .location = .{}, // Location of each element is unknown at this point
                            });
                        }
                    }
                    if (self.layout.y == .shrinks or self.layout.y == .grows) {
                        // Generate the image textures for each word and the locations they
                        // should be rendered.
                        draw_text_elements(self, display, .{ .x = 0, .y = 0 }, null, false);
                    }
                }
            },
            .checkbox => {
                // Clear old text
                for (self.type.checkbox.elements.items) |item| {
                    sdl.SDL_DestroyTexture(item.texture);
                }
                self.type.checkbox.elements.clearRetainingCapacity();
                self.type.checkbox.text = new_text;
                self.type.checkbox.translated = new_translated;
                if (self.type.checkbox.translated.len > 0) {
                    self.type.checkbox.elements.clearRetainingCapacity();
                    var data = Chunker.init(self.type.checkbox.translated);
                    while (data.next()) |text| {
                        if (display.generate_text_texture(text)) |texture| {
                            try self.type.checkbox.elements.append(.{
                                .text = text,
                                .width = @floatFromInt(texture.*.w),
                                .texture = texture,
                                .location = .{}, // Location of each element is unknown at this point
                            });
                        }
                    }
                    if (self.layout.y == .shrinks or self.layout.y == .grows) {
                        // Simulate a draw of this element to see how many
                        // lines it would take.
                        // TODO: dont need draw_text_elements?
                        draw_text_elements(self, display, .{ .x = 0, .y = 0 }, null, false);
                    }
                }
            },
            .button => {
                // Clear old text
                if (self.type.button.text_texture) |texture| {
                    sdl.SDL_DestroyTexture(texture);
                    self.type.button.text_texture = null;
                }
                self.type.button.text = new_text;
                self.type.button.translated = new_translated;
                if (new_translated.len > 0) {
                    if (display.generate_text_texture(self.type.button.translated)) |texture| {
                        self.type.button.text_texture = texture;
                    }
                }
            },
            else => {
                warn("set_text({s}) invalid for {s}", .{ @tagName(self.type), new_text });
            },
        }
    }

    /// `add` a child element to this panel and return the element. Only
    /// permitted for the `panel` element type. See also `add_element`
    pub inline fn add(self: *Element, child: *Element) error{OutOfMemory}!*Element {
        std.debug.assert(self.type == .panel);
        try self.type.panel.children.append(child);
        return child;
    }

    /// `add_element` adds a child element to this panel and does
    /// not return the child pointer. Only permitted for the `panel`
    /// element type.
    pub inline fn add_element(self: *Element, child: *Element) error{OutOfMemory}!void {
        std.debug.assert(self.type == .panel);
        try self.type.panel.children.append(child);
    }

    /// Use `insert_element` to insert a child element in a specific location
    /// in this panel. Only permitted for the `panel` element type.
    pub inline fn insert_element(self: *Element, location: usize, child: *Element) error{OutOfMemory}!void {
        std.debug.assert(self.type == .panel);
        std.debug.assert(location <= self.type.panel.children.items.len);
        try self.type.panel.children.insert(location, child);
    }

    /// Use `remove_element_at` to attach a child element in a specific location
    /// in this panel. Only permitted for the `panel` element type.
    pub inline fn remove_element_at(self: *Element, location: usize) *Element {
        std.debug.assert(self.type == .panel);
        std.debug.assert(location < self.type.panel.children.items.len);
        const item = self.type.panel.children.orderedRemove(location);
        return item;
    }

    /// Use `remove_element` to remove a panel that is a
    /// child of this element.
    pub inline fn remove_element(self: *Element, display: *Display, child: *Element) ?*Element {
        std.debug.assert(self.type == .panel);
        child.clear_display_pointers(display);
        for (0..self.type.panel.children.items.len) |i| {
            if (self.type.panel.children.items[i] == child) {
                const item = self.type.panel.children.orderedRemove(i);
                debug("removed panel {s}", .{item.name});
                return item;
            }
        }
        debug("panel not found in children", .{});
        return null;
    }

    /// Make sure nothing is holding a reference to an element that
    /// is being removed from the display.
    fn clear_display_pointers(self: *Element, display: *Display) void {
        if (display.selected == self) {
            display.selected = null;
        }
        if (display.hovered == self) {
            display.hovered = null;
        }
        if (self.type == .panel) {
            for (self.type.panel.children.items) |element| {
                element.clear_display_pointers(display);
            }
        }
    }

    /// Animations, and used provided code may be updated inside the
    /// update function. This is called prior to the `draw` function.
    pub fn update(self: *Element, display: *Display) void {
        if (display.need_relayout) {
            display.relayout();
        }
        if (self.velocity.x > 0) {
            self.rect.x += self.velocity.x;
        }
        if (self.velocity.y > 0) {
            self.rect.y += self.velocity.y;
        }

        if (self.type == .panel) {
            for (self.type.panel.children.items) |child| {
                child.update(display);
            }
        }
    }

    /// Shrink to the smallest height this object is allowed to
    /// shrink to based on the children. If children wrap according
    /// to the width of the parent, then the parent width is needed
    /// to calculate the height
    fn shrink_height(self: *Element, display: *Display, parent_width: f32) f32 {
        if (self.visible == .hidden) {
            return 0;
        }
        if (self.layout.y == .fixed) {
            return @max(self.minimum.height, self.rect.height);
        }
        const height = switch (self.type) {
            .label, .checkbox => {
                // Simulate a draw of this element to see how many lines it
                // would take. This is done when the label is created but also
                // needs to be done here as the width of the label may have changed.
                switch (self.layout.y) {
                    .shrinks => {
                        const mm = text_elements_size(self, display, parent_width);
                        //err("{s} {s} use shrink height {d} (parent_width={d})", .{ self.name, @tagName(self.type), mm.max_height, parent_width });
                        return mm.max_height;
                    },
                    .grows => {
                        const mm = text_elements_size(self, display, parent_width);
                        //err("{s} {s} use grows height {d} (parent_width={d})", .{ self.name, @tagName(self.type), mm.max_height, parent_width });
                        return mm.max_height;
                    },
                    .fixed => {
                        //err("{s} {s} use fixed height {d} (parent_width={d})", .{ self.name, @tagName(self.type), self.height, parent_width });
                        return self.rect.height;
                    },
                }
            },
            .expander => {
                return self.minimum.height;
            },
            .button => {
                var height: f32 = 0;
                if (self.type.button.text_texture) |_| {
                    height = display.text_height * display.scale; // * text_height;
                }
                height = @max(self.type.button.icon_size.y, height);
                height += (self.pad.top + self.pad.bottom);
                return @max(self.minimum.height, height);
            },
            .text_input => {
                const height = (display.text_height * display.scale) + (self.pad.top + self.pad.bottom);
                return height;
            },
            .panel => find_minimum_panel_height(self, display),
            else => self.rect.height,
        };
        return @max(self.minimum.height, height);
    }

    /// Shrink to the smallest width this object is desires to
    /// shrink to. That could mean shrinking to the size needed by
    /// children elements, or growing to the full width of the parent.
    ///
    /// If text is longer than the parent width, then wrapping is forced.
    fn shrink_width(self: *Element, display: *Display, parent_width: f32) f32 {
        if (self.visible == .hidden) {
            return 0;
        }
        if (self.layout.x == .fixed) {
            return @max(self.minimum.width, self.rect.width);
        }
        switch (self.type) {
            .panel => {
                return @max(self.minimum.width, find_minimum_panel_width(self, display));
            },
            .button => {
                var width: f32 = self.pad.left + self.pad.right;

                width += self.type.button.icon_size.x;

                // Do we need to pad between icon and text?
                if (self.type.button.icon_size.x > 0 and self.type.button.text.len > 0) {
                    width += self.type.button.spacing;
                }

                if (self.type.button.text_texture) |t| {
                    const size = text_size(display, t, .normal);
                    width += size.width;
                }
                return @max(self.minimum.width, width);
            },
            .expander => {
                return self.minimum.width;
            },
            .label => {
                switch (self.layout.x) {
                    .shrinks, .grows => {
                        // Growing or shrinking, our task here is to find
                        // the minimum that would be needed.
                        const mm = text_elements_size(self, display, parent_width);
                        const choose = @max(mm.min_width, self.minimum.width);
                        //err("{s} {s} use width {d}", .{ self.name, @tagName(self.type), choose });
                        return choose;
                    },
                    .fixed => {
                        const choose = @min(@max(self.rect.width, self.minimum.width), self.maximum.width);
                        //err("{s} {s} use width {d}", .{ self.name, @tagName(self.type), choose });
                        return choose;
                    },
                }
            },
            .checkbox => {
                switch (self.layout.x) {
                    .shrinks, .grows => {
                        // Growing or shrinking, our task here is to find
                        // the minimum that would be needed.
                        const mm = text_elements_size(self, display, parent_width);
                        const choose = @max(mm.min_width, self.minimum.width);
                        //err("{s} {s} use width {d}", .{ self.name, @tagName(self.type), choose });
                        return choose + self.pad.left + display.checkbox().width;
                    },
                    .fixed => {
                        const choose = @min(@max(self.rect.width, self.minimum.width), self.maximum.width);
                        //err("{s} {s} use width {d}", .{ self.name, @tagName(self.type), choose });
                        return choose;
                    },
                }
            },

            else => {
                return @max(self.minimum.width, self.rect.width);
            },
        }
    }

    /// Handle the langauge change event and propogate the event
    /// downwards to each child element, so that each child has
    /// a chance to regenerate its translation and text texture.
    fn language_changed(self: *Element, display: *Display, lang: Lang) !void {
        switch (self.type) {
            .label => try self.set_text(display, self.type.label.text, false),
            .checkbox => try self.set_text(display, self.type.checkbox.text, false),
            .button => try self.set_text(display, self.type.button.text, false),
            .panel => for (self.type.panel.children.items) |child| {
                try child.language_changed(display, lang);
            },
            else => {},
        }
    }

    /// Draw the current element, along with any children elements.
    pub fn draw(element: *Element, display: *Display, parent_scroll_offset: Vector, parent_clip: ?Clip) void {
        if (element.visible == .hidden) {
            return;
        }

        const scroll_offset: Vector = element.offset.add(parent_scroll_offset);

        // Mark visible elements as culled or not culled depending on
        // the parent_clip.
        if (parent_clip) |clip| {
            if (element.rect.x + scroll_offset.x + element.rect.width < clip.left) {
                element.visible = .culled;
                return;
            }
            if (element.rect.y + scroll_offset.y + (element.rect.height / 2) + 1 < clip.top) {
                element.visible = .culled;
                return;
            }
            if (element.rect.x + scroll_offset.x > clip.right) {
                element.visible = .culled;
                return;
            }
            if (element.rect.y + scroll_offset.y > clip.bottom) {
                element.visible = .culled;
                return;
            }
        }
        if (element.visible == .culled) {
            element.visible = .visible;
        }

        // Any element can have a background texture
        if (element.type != .button) {
            if (element.background_texture) |texture| {
                if (element.type != .text_input and element.type != .panel and element.type != .button) {
                    log.info("drawing background for {s}", .{@tagName(element.type)});
                }
                // Elements may optionally have a background texture
                var dest = element.rect.move(&scroll_offset);
                if (element.flip.x) {
                    dest.x += dest.width;
                    dest.width = 0 - dest.width;
                }
                if (element.flip.y) {
                    dest.y += dest.height;
                    dest.height = 0 - dest.height;
                }
                element.apply_background_tint(display, texture.texture);
                _ = sdl.SDL_RenderTexture9Grid(
                    display.renderer,
                    texture.texture,
                    null,
                    CORNER_RADIUS,
                    CORNER_RADIUS,
                    CORNER_RADIUS,
                    CORNER_RADIUS,
                    1.5,
                    @ptrCast(&dest),
                );
            }
        }

        // Any element can contain a basic background fill colour
        if (element.type != .rectangle and element.background_colour.a > 0) {
            _ = sdl.SDL_SetRenderDrawColor(
                display.renderer,
                element.background_colour.r,
                element.background_colour.g,
                element.background_colour.b,
                element.background_colour.a,
            );
            _ = sdl.SDL_RenderFillRect(display.renderer, @ptrCast(&element.rect));
        }

        switch (element.type) {
            .panel => draw_panel(element, display, parent_scroll_offset, parent_clip, scroll_offset),
            .button => draw_button(element, display, parent_scroll_offset, parent_clip, scroll_offset),
            .checkbox => draw_checkbox(element, display, parent_scroll_offset, parent_clip, scroll_offset),
            .text_input => draw_text_input(element, display, parent_scroll_offset, parent_clip),
            .sprite => draw_sprite(element, display, parent_scroll_offset, parent_clip),
            .rectangle => draw_rectangle_element(element, display, parent_scroll_offset, parent_clip),
            .label => if (element.type.label.text.len > 0) {
                draw_text_elements(element, display, scroll_offset, parent_clip, true);
            },
            .progress_bar => draw_progress_bar(element, display, parent_scroll_offset, parent_clip),
            .expander => {},
            else => {},
        }

        // Draw a border around an element if a border is specified, or
        // if `dev_mode` has been enabled.
        if (dev_mode) {
            var colour = display.theme.emphasised_text_colour;
            if (element.type == .panel) {
                colour = display.theme.tinted_text_colour;
            }
            draw_rectangle(
                display.renderer,
                2,
                colour,
                element.rect.move(&scroll_offset),
            );
            if (element.type == .panel and (element.type.panel.scrollable.scroll.x or element.type.panel.scrollable.scroll.y)) {
                draw_rectangle(
                    display.renderer,
                    2,
                    display.theme.success_panel_colour,
                    element.rect,
                );
            }
            if (element.type == .button) {
                // inner padding line
                colour = display.theme.tinted_text_colour;
                draw_rectangle(display.renderer, 2, colour, .{
                    .x = element.rect.x + scroll_offset.x + element.pad.left,
                    .y = element.rect.y + scroll_offset.y + element.pad.top,
                    .width = element.rect.width - (element.pad.left + element.pad.right),
                    .height = element.rect.height - (element.pad.top + element.pad.bottom),
                });
            }
        } else if (element.border_width > 0 and element.border_colour.a > 0) {
            draw_rectangle(
                display.renderer,
                element.border_width,
                element.border_colour,
                element.rect.move(&scroll_offset),
            );
        }

        // Any element can have a selection underline
        if (display.selected != null and display.selected == element) {
            if (element.type != .text_input) {
                if (display.keyboard_selected) {
                    draw_selection_marker(display, display.renderer, display.theme.cursor_colour, element.rect.move(&scroll_offset));
                }
            }
        }
    }

    inline fn draw_panel(element: *Element, display: *Display, _: Vector, parent_clip: ?Clip, scroll_offset: Vector) void {
        if (parent_clip) |clip| {
            for (element.type.panel.children.items) |child| {
                child.draw(display, scroll_offset, clip);
            }
        } else if (element.type.panel.scrollable.scroll.x or element.type.panel.scrollable.scroll.y) {
            for (element.type.panel.children.items) |child| {
                child.draw(display, scroll_offset, Clip{
                    .top = element.rect.y,
                    .left = element.rect.x,
                    .bottom = element.rect.y + element.rect.height,
                    .right = element.rect.x + element.rect.width,
                });
            }
        } else {
            for (element.type.panel.children.items) |child| {
                child.draw(display, scroll_offset, null);
            }
        }
    }

    inline fn draw_rectangle_element(element: *Element, display: *Display, _: Vector, _: ?Clip) void {
        const colour = element.type.rectangle.style.from(display.theme, element.background_colour);
        _ = sdl.SDL_SetRenderDrawColor(
            display.renderer,
            colour.r,
            colour.g,
            colour.b,
            colour.a,
        );
        _ = sdl.SDL_RenderFillRect(display.renderer, @ptrCast(&element.rect));
    }

    inline fn draw_text_input(element: *Element, display: *Display, _: Vector, _: ?Clip) void {
        var x = element.rect.x + element.pad.left;
        const y = element.rect.y + element.pad.top;
        const word_spacing = display.text_height / 3.0 * display.scale;

        if (display.selected != null and element == display.selected.?) {
            // Draw cursor
            var cursor_box: Rect = .{
                .x = @round(x + element.type.text_input.cursor_pixels),
                .y = @round(y),
                .width = display.text_height * display.scale / 8.0,
                .height = display.text_height * display.scale,
            };
            if (element.texture) |_| {
                // Add the icon width
                cursor_box.x += (element.rect.height - element.pad.top - element.pad.bottom);
                cursor_box.x += word_spacing;
            }
            _ = sdl.SDL_SetRenderDrawColor(
                display.renderer,
                display.theme.cursor_colour.r,
                display.theme.cursor_colour.g,
                display.theme.cursor_colour.b,
                display.theme.cursor_colour.a,
            );
            _ = sdl.SDL_RenderFillRect(display.renderer, @ptrCast(&cursor_box));
        }

        if (element.texture) |texture| {
            //const size = text_size(display, texture.texture, .normal);
            const icon_size = element.rect.height - element.pad.top - element.pad.bottom;
            // Draw the text
            var dest: Rect = .{
                .x = @round(x),
                .y = @round(y),
                .width = icon_size,
                .height = icon_size,
            };
            x += icon_size + word_spacing;
            _ = sdl.SDL_SetTextureColorMod(
                texture.texture,
                display.theme.placeholder_text_colour.r,
                display.theme.placeholder_text_colour.g,
                display.theme.placeholder_text_colour.b,
            );
            _ = sdl.SDL_RenderTexture(
                display.renderer,
                texture.texture,
                null,
                @ptrCast(&dest),
            );
        }

        // Font baseline offset
        //y -= display.text_height * display.scale / 3.5;

        if (element.type.text_input.text.items.len > 0) {
            if (element.type.text_input.texture) |texture| {
                const size = text_size(display, texture, .normal);
                // Draw the text
                var dest: Rect = .{
                    .x = @round(x),
                    .y = @round(y),
                    .width = size.width,
                    .height = size.height,
                };
                x += size.height + word_spacing;
                _ = sdl.SDL_SetTextureColorMod(
                    texture,
                    display.theme.text_colour.r,
                    display.theme.text_colour.g,
                    display.theme.text_colour.b,
                );
                _ = sdl.SDL_RenderTexture(
                    display.renderer,
                    texture,
                    null,
                    @ptrCast(&dest),
                );
            }
        } else {
            if (element.type.text_input.placeholder_texture) |texture| {
                const size = text_size(display, texture, .normal);
                // Draw the placeholder text
                var dest: Rect = .{
                    .x = @round(x),
                    .y = @round(y),
                    .width = size.width,
                    .height = size.height,
                };
                x += size.width + word_spacing;
                _ = sdl.SDL_SetTextureColorMod(
                    texture,
                    display.theme.placeholder_text_colour.r,
                    display.theme.placeholder_text_colour.g,
                    display.theme.placeholder_text_colour.b,
                );
                _ = sdl.SDL_RenderTexture(
                    display.renderer,
                    texture,
                    null,
                    @ptrCast(&dest),
                );
            }
        }
    }

    inline fn draw_sprite(element: *Element, display: *Display, _: Vector, _: ?Clip) void {
        if (element.texture) |texture| {
            var dest: Rect = .{
                .x = element.rect.x + element.pad.left,
                .y = element.rect.y + element.pad.top,
                .width = element.rect.width - element.pad.left - element.pad.right,
                .height = element.rect.height - element.pad.top - element.pad.bottom,
            };

            // TODO: Sprites might have frames
            //const source: Rect = .{
            //    .x = 0,
            //    .y = 0,
            //    .w = @as(f32, @floatFromInt(texture.texture.w)),
            //    .h = @as(f32, @floatFromInt(texture.texture.h)),
            //};
            //_ = sdl.SDL_RenderTexture(display.renderer, texture.texture, &source, @ptrCast(&dest));

            _ = sdl.SDL_RenderTexture(display.renderer, texture.texture, null, @ptrCast(&dest));
        }
    }

    inline fn draw_checkbox(element: *Element, display: *Display, _: Vector, _: ?Clip, scroll_offset: Vector) void {
        const checkbox = display.checkbox();
        // Output checkbox text.
        draw_text_elements(element, display, scroll_offset, null, true);
        var dest: Rect = .{
            .x = element.rect.x + element.rect.width - checkbox.width - element.pad.left,
            .y = element.rect.y + (element.rect.height / 2) - (checkbox.height / 2),
            .width = checkbox.width,
            .height = checkbox.height,
        };
        dest.x += scroll_offset.x;
        dest.y += scroll_offset.y;
        if (element.type.checkbox.checked) {
            if (element.type.checkbox.on_texture) |texture| {
                _ = sdl.SDL_RenderTexture(display.renderer, texture.texture, null, @ptrCast(&dest));
            }
        } else {
            if (element.type.checkbox.off_texture) |texture| {
                _ = sdl.SDL_RenderTexture(display.renderer, texture.texture, null, @ptrCast(&dest));
            }
        }
    }

    inline fn draw_progress_bar(element: *Element, display: *Display, _: Vector, _: ?Clip) void {
        // Draw the background matching the  current button state
        if (element.texture) |texture| {
            //const radius = @as(f32, @floatFromInt(texture.texture.h >> 1));
            const radius = 6;
            // Progress bar background
            var dest: Rect = .{
                .x = element.rect.x + element.pad.left,
                .y = element.rect.y + element.pad.top,
                .width = element.rect.width - element.pad.left - element.pad.right,
                .height = element.rect.height - element.pad.top - element.pad.bottom,
            };
            var tint = display.theme.label_background_colour;
            _ = sdl.SDL_SetTextureColorMod(texture.texture, tint.r, tint.g, tint.b);
            _ = sdl.SDL_RenderTexture9Grid(
                display.renderer,
                texture.texture,
                null,
                radius,
                radius,
                radius,
                radius,
                0,
                @ptrCast(&dest),
            );

            if (element.type.progress_bar.progress > 0.01) {
                // Progress bar foreground
                dest.width *= element.type.progress_bar.progress;
                tint = display.theme.placeholder_text_colour;
                //tint = display.theme.placeholder_text_colour;
                _ = sdl.SDL_SetTextureColorMod(texture.texture, tint.r, tint.g, tint.b);
                _ = sdl.SDL_RenderTexture9Grid(
                    display.renderer,
                    texture.texture,
                    null,
                    radius,
                    radius,
                    radius,
                    radius,
                    0,
                    @ptrCast(&dest),
                );
            }
        } else {
            err("progress bar image missing.", .{});
        }
    }

    inline fn draw_button(element: *Element, display: *Display, _: Vector, _: ?Clip, scroll_offset: Vector) void {
        // Draw the background matching the  current button state
        if (element.current_background()) |background_image| {
            var dest: Rect = .{
                .x = element.rect.x + scroll_offset.x,
                .y = element.rect.y + scroll_offset.y,
                .width = element.rect.width,
                .height = element.rect.height,
            };
            if (element.flip.x) {
                dest.x += dest.width;
                dest.width = 0 - dest.width;
            }
            if (element.flip.y) {
                dest.y += dest.height;
                dest.height = 0 - dest.height;
            }
            element.apply_background_tint(display, background_image);
            _ = sdl.SDL_RenderTexture9Grid(
                display.renderer,
                background_image,
                null,
                CORNER_RADIUS,
                CORNER_RADIUS,
                CORNER_RADIUS,
                CORNER_RADIUS,
                1.5,
                @ptrCast(&dest),
            );
            _ = sdl.SDL_RenderTexture(display.renderer, background_image, null, @ptrCast(&dest));
        }

        // The inner content can contain a button and/or text texture.
        var content_width = element.type.button.icon_size.x;
        if (element.type.button.text_texture) |texture| {
            const size = text_size(display, texture, .normal);

            // Do we need space between text and icon?
            if (content_width > 0) {
                content_width += element.type.button.spacing;
            }

            content_width += size.width;
        }
        content_width += element.pad.left + element.pad.right;

        const content_offset = switch (element.child_align.x) {
            .start => 0,
            .centre => (element.rect.width - content_width) / 2.0,
            .end => element.rect.width - content_width,
        };

        const tint = element.button_tint(display.theme);
        var has_icon = false;
        if (element.current_icon()) |icon_image| {
            has_icon = true;
            {
                var dest: Rect = .{
                    .x = element.rect.x + element.pad.left + content_offset,
                    .y = element.rect.y + element.pad.top,
                    .width = element.type.button.icon_size.x,
                    .height = element.type.button.icon_size.y,
                };
                dest.x += scroll_offset.x;
                dest.y += scroll_offset.y;
                if (element.flip.x) {
                    dest.x += dest.width;
                    dest.width = 0 - dest.width;
                }
                if (element.flip.y) {
                    dest.y += dest.height;
                    dest.height = 0 - dest.height;
                }
                if (element.type.button.style != .custom) {
                    _ = sdl.SDL_SetTextureColorMod(icon_image, tint.r, tint.g, tint.b);
                }
                _ = sdl.SDL_RenderTexture(display.renderer, icon_image, null, @ptrCast(&dest));
            }
        }
        if (element.type.button.text_texture) |texture| {
            const size = text_size(display, texture, .normal);
            var dest: Rect = .{
                .x = element.rect.x + element.type.button.icon_size.x + element.pad.left + content_offset,
                .y = element.rect.y + (element.rect.height / 2.0) - (size.height / 2),
                .width = size.width,
                .height = size.height,
            };
            dest = dest.move(&scroll_offset);
            if (has_icon or element.type.button.icon_size.x > 0) {
                dest.x += element.type.button.spacing;
            }
            _ = sdl.SDL_SetTextureColorMod(texture, tint.r, tint.g, tint.b);
            _ = sdl.SDL_RenderTexture(display.renderer, texture, null, @ptrCast(&dest));
        }
    }

    pub fn keypress(
        self: *Element,
        display: *Display,
        key: u21,
        slice: []const u8,
    ) Allocator.Error!void {
        if (self.type == .text_input) {
            // Update the text line
            trace("pressed {d} {s}", .{ key, slice });
            switch (key) {
                13, 10 => {
                    _ = sdl.SDL_StopTextInput(display.window);
                    if (self.type.text_input.on_submit != null) {
                        try self.type.text_input.on_submit.?(display, self);
                    }
                    return;
                },
                sdl.SDLK_BACKSPACE => {
                    if (self.type.text_input.runes.items.len == 0) {
                        return;
                    }
                    _ = self.type.text_input.runes.pop();
                    self.text_runes_to_data();
                    self.type.text_input.cursor_character -= 1;
                },
                else => {
                    if (self.type.text_input.runes.items.len >= self.type.text_input.max_runes) {
                        trace("Ignoring {u}. Input limited to {d} characters", .{ key, self.type.text_input.max_runes });
                        return;
                    }
                    self.type.text_input.text.appendSlice(slice) catch {};
                    self.type.text_input.runes.append(key) catch {};
                    self.type.text_input.cursor_character += 1;
                },
            }
            self.text_data_to_runes();

            // Update the text texture image.
            if (self.type.text_input.texture) |texture| {
                sdl.SDL_DestroyTexture(texture);
                self.type.text_input.texture = null;
            }
            if (self.type.text_input.text.items.len > 0) {
                if (display.generate_text_texture(self.type.text_input.text.items)) |texture| {
                    self.type.text_input.texture = texture;
                    // For now, the cursor position is simply the end of the text.
                    self.type.text_input.cursor_pixels = text_size(display, texture, .normal).width;
                }
            } else {
                self.type.text_input.cursor_pixels = 0;
            }

            // Optionally, a text_input may have an `on_change` callback function.
            if (self.type.text_input.on_change) |f| {
                trace("text_input calling on_change", .{});
                try f(display, self);
                trace("text_input called on_change", .{});
            } else {
                debug("text_input no on_change", .{});
            }
        }
    }

    /// Handle when a user chooses an element like a button, using
    /// the mouse or the keyboard.
    pub fn chosen(self: *Element, display: *Display) error{OutOfMemory}!void {
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
                    .no_toggle, .correct, .incorrect, .locked_off => {},
                }
                if (self.type.button.on_click) |f| {
                    try f(display, self);
                    return;
                }
            },
            .panel => {
                if (self.type.panel.on_click) |f| {
                    try f(display, self);
                    return;
                }
            },
            .label => {
                if (self.type.label.on_click) |f| {
                    try f(display, self);
                    return;
                }
            },
            .sprite => {
                if (self.type.sprite.on_click) |f| {
                    try f(display, self);
                    return;
                }
            },
            .checkbox => {
                self.type.checkbox.checked = !self.type.checkbox.checked;
                if (self.type.checkbox.on_change) |f| {
                    try f(display, self);
                    return;
                }
            },
            .button_bar, .progress_bar, .text_input, .rectangle, .expander => {},
        }
    }

    /// Handle when a user clicks into or tabs into this element.
    pub fn selected(self: *Element, display: *Display) void {
        if (self.focus == .never_focus or self.focus == .unspecified) {
            return;
        }
        if (display.selected != null and self != display.selected) {
            display.selected.?.deselected(display);
        }
        display.selected = self;

        const content = self.describe_content();
        debug("selected {s} {s} = {s}", .{ @tagName(self.type), self.name, content });

        // Enter editing mode if we just selected a text element
        if (self.type == .text_input) {
            _ = sdl.SDL_StartTextInput(display.window);
        }
    }

    /// Describe content for a screen reader
    fn describe_content(self: *Element) []const u8 {
        return switch (self.type) {
            .label => self.type.label.translated,
            .button => if (self.type.button.translated.len > 0)
                self.type.button.translated
            else
                self.name,
            //self.type.button.icon;
            .checkbox => if (self.type.checkbox.translated.len > 0)
                self.type.checkbox.translated
            else
                self.name,
            //self.type.checkbox.icon,
            else => self.name,
        };
    }

    /// Handle when a user clicks or tabs out of this element.
    pub fn deselected(self: *Element, display: *Display) void {
        const content = self.describe_content();
        debug("deselected {s} {s} = {s}", .{ @tagName(self.type), self.name, content });

        if (self.type == .text_input) {
            _ = sdl.SDL_StopTextInput(display.window);
        }
        display.keyboard_selected = false;
        display.selected = null;
    }

    pub fn text_runes_to_data(self: *Element) void {
        std.debug.assert(self.type == .text_input);
        self.type.text_input.text.clearRetainingCapacity();
        for (self.type.text_input.runes.items) |rune| {
            var buff: [4]u8 = undefined;
            const len = std.unicode.utf8Encode(rune, &buff) catch {
                return;
            };
            self.type.text_input.text.appendSlice(buff[0..len]) catch {
                return;
            };
        }
    }

    pub fn text_data_to_runes(self: *Element) void {
        std.debug.assert(self.type == .text_input);
        self.type.text_input.runes.clearRetainingCapacity();
        var v = std.unicode.Utf8View.init(self.type.text_input.text.items) catch {
            return;
        };
        var i = v.iterator();
        var cursor_slice: usize = 0; // utf8 index of cursor position
        var count: usize = 0;
        while (i.nextCodepoint()) |rune| {
            if (count == self.type.text_input.cursor_character) {
                cursor_slice = i.i;
            }
            self.type.text_input.runes.append(rune) catch {
                return;
            };
            count += 1;
        }
        if (count == self.type.text_input.cursor_character) {
            cursor_slice = i.i;
        }
        if (self.type.text_input.cursor_character > self.type.text_input.runes.items.len) {
            self.type.text_input.cursor_character = self.type.text_input.runes.items.len;
            cursor_slice = self.type.text_input.text.items.len;
        }

        if (dev_build) {
            //debug(
            //    "text to runes cursor {d} {d}",
            //    .{ self.type.text_input.cursor_character, cursor_slice },
            //);
        }
    }

    inline fn do_word_alignment(element: *Element, _: f32, x: f32, x_ending: f32, children: []TextElement, _: ?*Display) void {
        // At end of line, do we need to centre or right align?
        const trailing_pixel_space = x_ending - x;

        if (dev_build and dev_mode) {
            //debug("align line: {s} {s} {d}-{d} {d} (parent width {d})", .{
            //    element.name,
            //    @tagName(element.child_align.x),
            //    x_start,
            //    x_ending,
            //    trailing_pixel_space,
            //    element.width,
            //});
        }

        if (trailing_pixel_space > 0) {
            switch (element.child_align.x) {
                .start => {
                    // No adjustment needed
                },
                .centre => {
                    const adjust_by = trailing_pixel_space / 2;
                    for (children) |*child| {
                        child.location.x += adjust_by;
                    }
                },
                .end => {
                    const adjust_by = trailing_pixel_space;
                    for (children) |*child| {
                        child.location.x += adjust_by;
                    }
                },
            }
        }
    }
};

/// Draw a visual indication that an element is currently selected.
inline fn draw_selection_marker(
    display: *Display,
    renderer: *sdl.SDL_Renderer,
    colour: Colour,
    rect: Rect,
) void {
    const border_width = 2 * display.user_scale;
    if (border_width > 0 and colour.a > 0) {
        _ = sdl.SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
        var dest: Rect = .{
            .x = rect.x,
            .y = rect.y + rect.height + border_width,
            .width = rect.width,
            .height = border_width,
        };
        if (rect.width > border_width * 16) {
            dest.width -= border_width * 8;
            dest.x += border_width * 4;
        }
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

/// Draw an outline of a rectangle. Used in debug mode to highlight where
/// items appear on the screen.
inline fn draw_rectangle(
    renderer: *sdl.SDL_Renderer,
    border_width: f32,
    colour: Colour,
    rect: Rect,
) void {
    if (border_width > 0 and colour.a > 0) {
        _ = sdl.SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
        var dest: Rect = .{
            .x = rect.x,
            .y = rect.y,
            .width = rect.width,
            .height = border_width,
        };
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

inline fn text_size(display: *Display, texture: *sdl.SDL_Texture, size: TextSize) Size {
    const height = display.text_height * display.scale * size.height();
    return .{
        .height = height,
        .width = height * @as(f32, @floatFromInt(texture.*.w)) / @as(f32, @floatFromInt(texture.*.h)),
    };
}

/// Calculate the layout of all elements, and optionally render every element.
///
/// Normally text is converted to an image and rendered left to right, starting
/// at the top left corner of the element (including padding).
///
/// If the text is centred or right aligned, then each line must be pushed along
/// by a certain offset amount.
inline fn draw_text_elements(
    element: *Element,
    display: *Display,
    scroll_offset: Vector,
    parent_clip: ?Clip,
    comptime render: bool,
) void {
    std.debug.assert(element.type == .label or element.type == .checkbox);

    var x: f32 = element.rect.x + element.pad.left;
    var y: f32 = element.rect.y + element.pad.top;
    const word_spacing = display.text_height / 3.0 * display.scale;
    const x_start: f32 = @floor(x);

    const x_ending = switch (element.type) {
        .checkbox => @ceil(element.rect.x + element.rect.width - element.pad.right - display.checkbox().width),
        .label => @ceil(element.rect.x + element.rect.width - element.pad.right),
        else => unreachable,
    } + 1; // +1 to allow tiny overflow into border to avoid wrapping.
    const text_height = switch (element.type) {
        .label => element.type.label.text_size,
        .checkbox => element.type.checkbox.text_size,
        else => unreachable,
    };
    const children = switch (element.type) {
        .label => element.type.label.elements.items,
        .checkbox => element.type.checkbox.elements.items,
        else => unreachable,
    };
    const text_colour = switch (element.type) {
        .label => element.type.label.text_colour,
        .checkbox => element.type.checkbox.text_colour,
        else => unreachable,
    };

    var lines: usize = 0;
    // A line must have at least one word before a line break is inserted
    // otherwise we are just drawing pointless broken blank lines.
    var line_word_count: usize = 0;
    var current_line_start: usize = 0;

    for (children, 0..) |*item, i| {
        const size = text_size(display, item.texture, text_height);
        // Would drawing this word overflow?
        if (x + size.width > x_ending and line_word_count > 0) {
            element.do_word_alignment(x_start, x, x_ending, children[current_line_start..i], display);
            // Wrap to next line
            x = element.rect.x + element.pad.left;
            y += size.height;
            lines += 1;
            line_word_count = 0;
            current_line_start = i;
        }
        if (line_word_count > 0) {
            x += word_spacing;
        }
        item.location = .{
            .x = @round(x + scroll_offset.x),
            .y = @round(y + scroll_offset.y),
            .width = size.width,
            .height = size.height,
        };
        line_word_count += 1;
        x += size.width;
    }

    if (children.len > 0) {
        if (current_line_start != children.len) {
            element.do_word_alignment(x_start, x, x_ending, children[current_line_start..children.len], display);
        }
        // Wrap the currently drawn line by its height.
        const height = display.text_height * display.scale * text_height.height();
        y += height;
    }

    if (render) {
        for (children) |*item| {
            if (parent_clip) |clip| {
                if (item.location.x + item.location.width < clip.left) {
                    continue;
                }
                if (item.location.y + item.location.height + 1 < clip.top) {
                    continue;
                }
                if (item.location.x > clip.right) {
                    continue;
                }
                if (item.location.y > clip.bottom) {
                    continue;
                }
            }

            // Only do rendering if display parameter is provided
            const current_colour = text_colour.from(display.theme, element.colour);
            _ = sdl.SDL_SetTextureColorMod(
                item.texture,
                current_colour.r,
                current_colour.g,
                current_colour.b,
            );
            _ = sdl.SDL_RenderTexture(
                display.renderer,
                item.texture,
                null,
                @ptrCast(&item.location),
            );
        }
    }

    // Add y padding at the bottom so that we can calculate the final height.
    y += element.pad.bottom;

    const final_height: f32 = y - element.rect.y;
    switch (element.layout.y) {
        .shrinks => {
            // Shrinkable means take the smallest size it needs
            element.rect.height = final_height;
        },
        .grows => {
            // Growable must use at least the size it needs
            element.rect.height = @max(final_height, element.rect.height);
        },
        .fixed => {
            // Fixed sized objects are ignored by the layout
            // algorithm
        },
    }
}

pub const MinMax = struct {
    min_width: f32 = 0.0,
    min_height: f32 = 0.0,
    max_width: f32 = 0.0,
    max_height: f32 = 0.0,
};

/// Calculate the width of this element by examining each of the child
/// elements. This is a cut down version of draw_text_elements but
/// without the overhead of things like text justifications.
inline fn text_elements_size(
    element: *Element,
    display: *Display,
    max_parent_width: f32,
) MinMax {
    var mm: MinMax = .{};
    var x: f32 = 0;
    var y: f32 = 0;

    var max_width = max_parent_width - (element.pad.left + element.pad.right);
    if (element.type == .checkbox) {
        max_width -= display.checkbox().width;
    }

    const word_spacing = display.text_height / 3.0 * display.scale;

    const text_height: TextSize = if (element.type == .label)
        element.type.label.text_size
    else
        element.type.checkbox.text_size;

    const children = if (element.type == .label)
        element.type.label.elements.items
    else
        element.type.checkbox.elements.items;

    var lines: usize = 0;
    // A line must have at least one word before a line break is inserted
    // otherwise we are just drawing pointless broken blank lines.
    var line_word_count: usize = 0;

    for (children, 0..) |item, i| {
        const size = text_size(display, item.texture, text_height);

        mm.min_width = @max(size.width, mm.min_width);
        mm.min_height = @max(size.height, mm.min_height);
        if (i > 0) {
            mm.max_width += word_spacing;
        }
        mm.max_width += size.width;

        // Would drawing this word overflow?
        if (x + size.width > max_width and line_word_count > 0) {
            // Wrap to next line
            x = 0;
            y += size.height;
            lines += 1;
            line_word_count = 0;
        }
        line_word_count += 1;
        x += size.width + word_spacing;
    }

    // Add the height of the line currently being drawn.
    const height = display.text_height * display.scale * text_height.height();
    y += height;

    mm.min_width += element.pad.left + element.pad.right;
    mm.max_width += element.pad.left + element.pad.right;
    mm.min_height += element.pad.top + element.pad.bottom;
    mm.max_height = y + element.pad.top + element.pad.bottom;
    return mm;
}

const TextElement = struct {
    text: []const u8,
    width: f32, // compared to default height
    texture: *sdl.SDL_Texture,
    location: Rect,
};

/// A texture is held in memory for the entire duration it might be needed.
/// If a texture is in use by more than one element, then the `references`
/// counter keeps track of how many elements are currently depending on
/// this texture.
const TextureInfo = struct {
    name: []const u8,
    texture: *sdl.SDL_Texture,
    references: i32,

    pub fn create(allocator: Allocator, name: []const u8, texture: *sdl.SDL_Texture) !*TextureInfo {
        var texture_info = try allocator.create(TextureInfo);
        if (name.len == 0) {
            texture_info.name = "";
        } else {
            texture_info.name = try allocator.dupe(u8, name);
        }
        texture_info.texture = texture;
        texture_info.references = 0;
        debug("loaded texture: {s}", .{name});
        return texture_info;
    }

    pub fn destroy(self: *TextureInfo, allocator: Allocator) void {
        //debug("TextureInfo.destroy: {s}", .{self.name});
        sdl.SDL_DestroyTexture(self.texture);
        if (self.name.len > 0) {
            allocator.free(self.name);
            self.name = "";
        }
        allocator.destroy(self);
    }

    pub fn clone(self: *TextureInfo) *TextureInfo {
        self.references += 1;
        return self;
    }
};

/// A font is held in memory for the entire duration it might be needed.
/// Typically this is the lifetime of the app.
const FontInfo = struct {
    name: []const u8,
    font: *sdl.TTF_Font,
    font_buffer: []const u8,

    pub fn create(allocator: Allocator, name: []const u8, font: *sdl.TTF_Font) !*FontInfo {
        var font_info = try allocator.create(FontInfo);
        font_info.name = try allocator.dupe(u8, name);
        font_info.font = font;
        const fontname = sdl.TTF_GetFontFamilyName(font_info.font);
        debug("loaded font: {s}", .{fontname});
        return font_info;
    }

    pub fn destroy(self: *FontInfo, allocator: Allocator) void {
        sdl.TTF_CloseFont(self.font);
        debug("unloaded font: {s}", .{self.name});
        allocator.free(self.font_buffer);
        allocator.free(self.name);
        allocator.destroy(self);
    }
};

/// Describe the colour and theme of every visual element. Attributes
/// of all visual elements must never be hardcoded.
const Theme = struct {
    background_colour: Colour,

    label_background_colour: Colour,
    tinted_text_colour: Colour,
    emphasised_text_colour: Colour,
    emphasised_panel_colour: Colour,
    success_text_colour: Colour,
    success_button_colour: Colour,
    success_panel_colour: Colour,
    failed_text_colour: Colour,
    failed_button_colour: Colour,
    failed_panel_colour: Colour,
    faded_panel_colour: Colour,

    text_colour: Colour,
    placeholder_text_colour: Colour,
    cursor_colour: Colour,

    toggle_button: Colour,
    toggle_button_picked: Colour,
    toggle_button_correct: Colour,
    toggle_button_incorrect: Colour,
};

pub const ThemeColour = enum {
    normal,
    faded,
    tinted,
    emphasised,
    success,
    failed,
    background,
    custom,

    pub fn from(self: ThemeColour, theme: *Theme, custom: Colour) Colour {
        return switch (self) {
            .normal => theme.text_colour,
            .faded => theme.faded_panel_colour,
            .tinted => theme.tinted_text_colour,
            .emphasised => theme.emphasised_text_colour,
            .success => theme.success_text_colour,
            .failed => theme.failed_text_colour,
            .background => theme.background_colour,
            .custom => custom,
        };
    }
};

pub const TextSize = enum {
    small,
    normal,
    subheading,
    heading,
    footnote,

    pub fn height(self: TextSize) f32 {
        return switch (self) {
            .small => 0.75,
            .normal => 1.0,
            .heading => 1.5,
            .subheading => 1.25,
            .footnote => 0.75,
        };
    }
};

/// Display describes how to draw all visual elements onto the main
/// application window. Typically one app has one display window.
/// Typically a display consists of one or more panels. A background
/// panel, a main panel, and sometimes a user interface overlay.
pub const Display = struct {
    window: *sdl.SDL_Window,
    renderer: *sdl.SDL_Renderer,
    allocator: Allocator,
    quit: bool = false,
    need_relayout: bool = true,
    accessibility: bool = false,
    last_draw: i64 = 0,

    // Text height in pixels _before_ display scaling. i.e.
    // 16 on normal screens,
    // 32 on retina screens (16 * 2)
    text_height: f32 = FONT_SIZE,

    /// A list of read only resources is loaded from a resource
    /// bundle, or an on disk development directory. This may
    /// include images, fonts, audio, or text data files.
    resources: *Resources,

    /// A list of all active fonts loaded from the resources bundle.
    fonts: ArrayList(*FontInfo),

    /// Translates the default provided text into a specific language
    /// using a csv translation file
    translation: Translation,
    current_language: Lang = .unknown,

    /// Cache of currently loaded textures.
    textures: std.StringHashMap(*TextureInfo),

    /// Four possible theme options are available.
    themes: [4]Theme,

    /// Current theme choice.
    theme: *Theme,

    /// The tab key, arrow keys, or game controler may be used
    /// to switch between focussable user interface elements.
    focussed: ?*Element = null,

    /// When the mouse is clicked dcown on a scrollable/movable
    /// element, this is the current element that is being
    /// scrolled/moved.
    scrolling: ?*Element = null,

    /// When a user clicks to begin a scroll action, the scroll
    /// movement begins from a specific point on the screen.
    /// This is used to calculate how far an item has been
    /// pushed/dragged
    scroll_start: Vector = .{ .x = 0, .y = 0 },
    scroll_initial_offset: Vector = .{ .x = 0, .y = 0 },

    /// Some devices have screen notches and cutouts.
    safe_area: Clip = .{ .left = 0, .right = 0, .top = 0, .bottom = 0 },

    /// One user interface element may be marked as selected to recieve
    /// keyboard input
    selected: ?*Element = null,
    keyboard_selected: bool = false,

    /// One user interface element may be rendered differently
    /// when the mouse/pointer is floating over that element.
    /// i.e. A button might light up when the mouse hovers above it.
    hovered: ?*Element = null,

    /// iOS and retina mac displays report the mouse position according
    /// to traditional dimensions (i.e. 1920x1080) rather than actual
    /// pixels (i.e. 3840x2160). A mouse/tap at 100x100, must be
    /// translated to the physical pixel/element position of 200x200.
    pixel_density: f32 = 1,

    /// On some devices, the reported screen size and physical pixel size
    /// may be different. The scale variable is used to convert between
    /// OS reported size, and physical pixel size. i.e.
    ///
    /// 1.0 = Non retina display, width = 1920, pixel width = 1920.
    /// 2.0 = Retina display,     width = 1920, pixel width = 3840.
    /// 3.0 = iPhone 16 display,  width =  393, pixel width = 1179.
    ///
    pixel_scale: f32 = 0,

    /// Used when user adjusts the global size of the interface
    user_scale: f32 = 1,

    /// The actual scale is the pixel_scale * user_scale
    scale: f32 = 0,

    root: Element = .{
        .name = "root",
        .rect = .{ .x = 0, .y = 0, .width = 100, .height = 100 },
        .maximum = .{ .width = 100, .height = 100 },
        .layout = .{ .x = .grows, .y = .grows },
        .child_align = .{ .x = .centre, .y = .start },
        .colour = .{},
        .background_colour = .{},
        .border_colour = .{},
        .border_width = 0,
        .type = .{ .panel = .{ .direction = .centre, .spacing = 0 } },
        .on_resized = null,
    },
    animators: ArrayList(*Animator),

    keybindings: std.AutoHashMap(c_uint, *const fn (display: *Display) Allocator.Error!void),
    on_resized: ?*const fn (display: *Display, element: *Element) bool = null,
    event_hook: ?*const fn (display: *Display, e: u32) error{OutOfMemory}!void = null,

    pub fn create(allocator: Allocator, app_name: [:0]const u8, app_version: [:0]const u8, app_id: [:0]const u8, dev_resource_folder: []const u8, translation_filename: []const u8, gui_flags: usize) !*Display {
        var display = try allocator.create(Display);
        errdefer allocator.destroy(display);
        display.allocator = allocator;
        display.hovered = null;
        display.selected = null;
        display.keyboard_selected = false;
        display.focussed = null;
        display.scrolling = null;
        display.text_height = FONT_SIZE;
        display.on_resized = null;
        display.current_language = .unknown;
        display.need_relayout = true;
        display.quit = false;
        display.translation.init(allocator);
        display.accessibility = false;
        errdefer display.translation.deinit();
        display.animators = ArrayList(*Animator).init(allocator);
        display.keybindings = std.AutoHashMap(c_uint, *const fn (display: *Display) Allocator.Error!void).init(display.allocator);
        errdefer display.keybindings.deinit();
        display.event_hook = null;

        _ = sdl.SDL_SetAppMetadata(app_name, app_version, app_id);

        if (dev_build) {
            _ = sdl.SDL_SetLogPriority(sdl.SDL_LOG_CATEGORY_GPU, sdl.SDL_LOG_PRIORITY_DEBUG);
            _ = sdl.SDL_SetLogPriority(sdl.SDL_LOG_CATEGORY_VIDEO, sdl.SDL_LOG_PRIORITY_DEBUG);
            _ = sdl.SDL_SetLogPriority(sdl.SDL_LOG_CATEGORY_ERROR, sdl.SDL_LOG_PRIORITY_DEBUG);
            _ = sdl.SDL_SetLogPriority(sdl.SDL_LOG_CATEGORY_RENDER, sdl.SDL_LOG_PRIORITY_DEBUG);
            _ = sdl.SDL_SetLogPriority(sdl.SDL_LOG_CATEGORY_SYSTEM, sdl.SDL_LOG_PRIORITY_DEBUG);
        } else {
            _ = sdl.SDL_SetLogPriority(sdl.SDL_LOG_CATEGORY_GPU, sdl.SDL_LOG_PRIORITY_INFO);
            _ = sdl.SDL_SetLogPriority(sdl.SDL_LOG_CATEGORY_VIDEO, sdl.SDL_LOG_PRIORITY_INFO);
            _ = sdl.SDL_SetLogPriority(sdl.SDL_LOG_CATEGORY_ERROR, sdl.SDL_LOG_PRIORITY_INFO);
            _ = sdl.SDL_SetLogPriority(sdl.SDL_LOG_CATEGORY_RENDER, sdl.SDL_LOG_PRIORITY_INFO);
            _ = sdl.SDL_SetLogPriority(sdl.SDL_LOG_CATEGORY_SYSTEM, sdl.SDL_LOG_PRIORITY_INFO);
        }

        if (!builtin.abi.isAndroid()) {
            // On android, the builtin SDL log function is used
            // to output log info to logcat.
            sdl.SDL_SetLogOutputFunction(sdl_log_callback, null);
        }

        // LandscapeLeft LandscapeRight Portrait PortraitUpsideDown
        _ = sdl.SDL_SetHint(sdl.SDL_HINT_ORIENTATIONS, "Portrait PortraitUpsideDown");

        //if (!sdl.SDL_Init(sdl.SDL_INIT_VIDEO | sdl.SDL_INIT_EVENTS | sdl.SDL_INIT_AUDIO | sdl.SDL_INIT_GAMEPAD | sdl.SDL_INIT_JOYSTICK)) {
        if (!sdl.SDL_Init(sdl.SDL_INIT_VIDEO | sdl.SDL_INIT_EVENTS | sdl.SDL_INIT_AUDIO)) {
            err("sdl setup failed. {s}", .{sdl.SDL_GetError()});
            return error.graphics_init_failed;
        }

        if (!sdl.TTF_Init()) {
            err("ttf setup font failed. {s}", .{sdl.SDL_GetError()});
            return error.font_init_failed;
        }

        debug("Initialising resource loader", .{});
        display.resources = try init_resource_loader(allocator, engine.RESOURCE_BUNDLE_FILENAME, dev_resource_folder);
        if (display.resources.lookupOne(translation_filename, .csv)) |resource| {
            const data = try sdl_load_resource(display.resources, resource, allocator);
            defer allocator.free(data);
            try display.translation.load_translation_data(data);
            debug("Translation file loaded", .{});
        } else {
            err("No translation file found.", .{});
        }

        const window = sdl.SDL_CreateWindow(
            app_name,
            600,
            800,
            sdl.SDL_WINDOW_RESIZABLE | sdl.SDL_WINDOW_HIGH_PIXEL_DENSITY | sdl.SDL_WINDOW_RESIZABLE | gui_flags,
        ) orelse {
            err("No Window created. {s}", .{sdl.SDL_GetError()});
            return error.window_creation_failed;
        };

        const renderer = sdl.SDL_CreateRenderer(window, null) orelse {
            err("No Renderer created. {s}", .{sdl.SDL_GetError()});
            return error.graphics_renderer_failed;
        };

        debug("Renderers: {}", .{driver_formatter(renderer)});

        const pixel_scale = sdl.SDL_GetWindowDisplayScale(window);
        log.info("WindowDisplayScale: {d}", .{pixel_scale});

        var pixel_width: c_int = 0;
        var pixel_height: c_int = 0;
        _ = sdl.SDL_GetWindowSizeInPixels(window, &pixel_width, &pixel_height);
        log.info("WindowSizeInPixels: {d}x{d}", .{ pixel_width, pixel_height });

        var window_width: c_int = 0;
        var window_height: c_int = 0;
        _ = sdl.SDL_GetWindowSize(window, &window_width, &window_height);
        log.info("GetWindowSize: {d}x{d}", .{ window_width, window_height });

        const density = sdl.SDL_GetWindowPixelDensity(window);
        log.info("WindowPixelDensity: {d}", .{density});

        _ = sdl.SDL_SetRenderVSync(renderer, 1);

        display.renderer = renderer;
        display.window = window;
        display.pixel_density = density;
        display.pixel_scale = pixel_scale;
        display.user_scale = 1;
        display.scale = display.pixel_scale / display.user_scale;

        // App can accept these keybindings or replace them
        try display.keybindings.put(sdl.SDLK_D, toggle_dev_mode);
        try display.keybindings.put(sdl.SDLK_K, use_next_theme);
        try display.keybindings.put(sdl.SDLK_X, increase_content_size);
        try display.keybindings.put(sdl.SDLK_PLUS, increase_content_size);
        try display.keybindings.put(sdl.SDLK_EQUALS, increase_content_size);
        try display.keybindings.put(sdl.SDLK_MINUS, decrease_content_size);
        try display.keybindings.put(sdl.SDLK_KP_PLUS, increase_content_size);
        try display.keybindings.put(sdl.SDLK_KP_MINUS, decrease_content_size);
        if (engine.dev_build) {
            try display.keybindings.put(sdl.SDLK_B, make_bundle);
        }

        // Black
        display.themes[0].background_colour = .{ .r = 0, .g = 0, .b = 0, .a = 255 };
        display.themes[0].label_background_colour = .{ .r = 31, .g = 34, .b = 48, .a = 255 };
        display.themes[0].tinted_text_colour = .{ .r = 185, .g = 185, .b = 245, .a = 255 };
        display.themes[0].emphasised_text_colour = .{ .r = 255, .g = 205, .b = 205, .a = 128 };
        display.themes[0].emphasised_panel_colour = .{ .r = 255, .g = 205, .b = 205, .a = 128 };
        display.themes[0].success_text_colour = .{ .r = 255, .g = 255, .b = 255, .a = 255 };
        display.themes[0].success_button_colour = .{ .r = 35, .g = 129, .b = 43, .a = 255 };
        display.themes[0].success_panel_colour = .{ .r = 83, .g = 172, .b = 75, .a = 128 };
        display.themes[0].failed_text_colour = .{ .r = 255, .g = 255, .b = 255, .a = 255 };
        display.themes[0].failed_button_colour = .{ .r = 145, .g = 59, .b = 59, .a = 255 };
        display.themes[0].failed_panel_colour = .{ .r = 150, .g = 80, .b = 65, .a = 255 };
        display.themes[0].faded_panel_colour = .{ .r = 15, .g = 17, .b = 25, .a = 255 };
        display.themes[0].cursor_colour = .{ .r = 255, .g = 255, .b = 255, .a = 128 };
        display.themes[0].text_colour = .{ .r = 255, .g = 255, .b = 255, .a = 255 };
        display.themes[0].placeholder_text_colour = .{ .r = 132, .g = 142, .b = 172, .a = 255 };
        display.themes[0].toggle_button = .{ .r = 42, .g = 52, .b = 62, .a = 255 };
        display.themes[0].toggle_button_picked = .{ .r = 80, .g = 99, .b = 119, .a = 255 };
        display.themes[0].toggle_button_correct = .{ .r = 80, .g = 119, .b = 81, .a = 255 };
        display.themes[0].toggle_button_incorrect = .{ .r = 119, .g = 80, .b = 80, .a = 255 };

        // Midnight
        display.themes[1].background_colour = .{ .r = 31, .g = 41, .b = 51, .a = 255 };
        display.themes[1].label_background_colour = .{ .r = 47, .g = 58, .b = 69, .a = 255 };
        display.themes[1].tinted_text_colour = .{ .r = 150, .g = 150, .b = 142, .a = 128 };
        display.themes[1].emphasised_text_colour = .{ .r = 185, .g = 166, .b = 194, .a = 255 };
        display.themes[1].emphasised_panel_colour = .{ .r = 185, .g = 166, .b = 194, .a = 255 };
        display.themes[1].success_text_colour = .{ .r = 255, .g = 255, .b = 255, .a = 255 };
        display.themes[1].success_button_colour = .{ .r = 35, .g = 129, .b = 43, .a = 255 };
        display.themes[1].success_panel_colour = .{ .r = 83, .g = 172, .b = 75, .a = 128 };
        display.themes[1].failed_text_colour = .{ .r = 255, .g = 255, .b = 255, .a = 255 };
        display.themes[1].failed_button_colour = .{ .r = 145, .g = 59, .b = 59, .a = 255 };
        display.themes[1].failed_panel_colour = .{ .r = 150, .g = 80, .b = 65, .a = 255 };
        display.themes[1].faded_panel_colour = .{ .r = 36, .g = 46, .b = 56, .a = 255 };
        display.themes[1].cursor_colour = .{ .r = 195, .g = 195, .b = 220, .a = 128 };
        display.themes[1].text_colour = .{ .r = 195, .g = 195, .b = 220, .a = 255 };
        display.themes[1].placeholder_text_colour = .{ .r = 146, .g = 146, .b = 175, .a = 255 };
        display.themes[1].toggle_button = .{ .r = 58, .g = 72, .b = 86, .a = 255 };
        display.themes[1].toggle_button_picked = .{ .r = 80, .g = 99, .b = 119, .a = 255 };
        display.themes[1].toggle_button_correct = .{ .r = 80, .g = 119, .b = 81, .a = 255 };
        display.themes[1].toggle_button_incorrect = .{ .r = 119, .g = 80, .b = 80, .a = 255 };

        // Sand
        display.themes[2].background_colour = .{ .r = 224, .g = 214, .b = 204, .a = 255 };
        display.themes[2].label_background_colour = .{ .r = 210, .g = 200, .b = 190, .a = 255 };
        display.themes[2].tinted_text_colour = .{ .r = 90, .g = 90, .b = 65, .a = 255 };
        display.themes[2].emphasised_text_colour = .{ .r = 100, .g = 60, .b = 35, .a = 128 };
        display.themes[2].emphasised_panel_colour = .{ .r = 100, .g = 60, .b = 35, .a = 128 };
        display.themes[2].success_text_colour = .{ .r = 255, .g = 255, .b = 255, .a = 255 };
        display.themes[2].success_button_colour = .{ .r = 35, .g = 129, .b = 43, .a = 255 };
        display.themes[2].success_panel_colour = .{ .r = 83, .g = 172, .b = 75, .a = 128 };
        display.themes[2].failed_text_colour = .{ .r = 255, .g = 255, .b = 255, .a = 255 };
        display.themes[2].failed_button_colour = .{ .r = 145, .g = 59, .b = 59, .a = 255 };
        display.themes[2].failed_panel_colour = .{ .r = 150, .g = 80, .b = 65, .a = 255 };
        display.themes[2].faded_panel_colour = .{ .r = 217, .g = 207, .b = 197, .a = 255 };
        display.themes[2].cursor_colour = .{ .r = 60, .g = 60, .b = 35, .a = 128 };
        display.themes[2].text_colour = .{ .r = 60, .g = 60, .b = 35, .a = 255 };
        display.themes[2].placeholder_text_colour = .{ .r = 128, .g = 128, .b = 85, .a = 255 };
        display.themes[2].toggle_button = .{ .r = 196, .g = 184, .b = 170, .a = 255 };
        display.themes[2].toggle_button_picked = .{ .r = 157, .g = 138, .b = 118, .a = 255 };
        display.themes[2].toggle_button_correct = .{ .r = 132, .g = 160, .b = 100, .a = 255 };
        display.themes[2].toggle_button_incorrect = .{ .r = 159, .g = 111, .b = 98, .a = 255 };

        // White
        display.themes[3].background_colour = .{ .r = 255, .g = 255, .b = 255, .a = 255 };
        display.themes[3].label_background_colour = .{ .r = 217, .g = 230, .b = 242, .a = 255 };
        display.themes[3].tinted_text_colour = .{ .r = 99, .g = 138, .b = 171, .a = 128 };
        display.themes[3].emphasised_text_colour = .{ .r = 40, .g = 0, .b = 0, .a = 128 };
        display.themes[3].emphasised_panel_colour = .{ .r = 40, .g = 0, .b = 0, .a = 128 };
        display.themes[3].success_text_colour = .{ .r = 255, .g = 255, .b = 255, .a = 255 };
        display.themes[3].success_button_colour = .{ .r = 35, .g = 129, .b = 43, .a = 255 };
        display.themes[3].success_panel_colour = .{ .r = 83, .g = 172, .b = 75, .a = 128 };
        display.themes[3].failed_text_colour = .{ .r = 255, .g = 255, .b = 255, .a = 255 };
        display.themes[3].failed_button_colour = .{ .r = 145, .g = 59, .b = 59, .a = 255 };
        display.themes[3].failed_panel_colour = .{ .r = 150, .g = 80, .b = 65, .a = 255 };
        display.themes[3].faded_panel_colour = .{ .r = 240, .g = 247, .b = 255, .a = 255 };
        display.themes[3].cursor_colour = .{ .r = 0, .g = 0, .b = 0, .a = 128 };
        display.themes[3].text_colour = .{ .r = 0, .g = 0, .b = 0, .a = 255 };
        display.themes[3].placeholder_text_colour = .{ .r = 104, .g = 104, .b = 114, .a = 255 };
        display.themes[3].toggle_button = .{ .r = 193, .g = 203, .b = 213, .a = 255 };
        display.themes[3].toggle_button_picked = .{ .r = 131, .g = 142, .b = 149, .a = 255 };
        display.themes[3].toggle_button_correct = .{ .r = 132, .g = 160, .b = 100, .a = 255 };
        display.themes[3].toggle_button_incorrect = .{ .r = 159, .g = 111, .b = 98, .a = 255 };

        display.update_system_theme();

        display.fonts = ArrayList(*FontInfo).init(allocator);
        display.textures = std.StringHashMap(*TextureInfo).init(allocator);

        display.last_draw = std.time.microTimestamp();

        display.root = .{
            .name = "root",
            .rect = .{ .x = 0, .y = 0, .width = 100, .height = 100 },
            .pad = .{ .left = 0, .right = 0, .top = 0, .bottom = 0 },
            .maximum = .{ .width = 100, .height = 100 },
            .layout = .{ .x = .grows, .y = .grows },
            .child_align = .{ .x = .centre, .y = .start },
            .colour = .{},
            .background_colour = .{},
            .border_colour = .{},
            .border_width = 0,
            .type = .{ .panel = .{ .direction = .centre, .spacing = 0 } },
            .on_resized = null,
        };
        display.root.rect.width = @as(f32, @floatFromInt(window_width)) * display.pixel_density;
        display.root.rect.height = @as(f32, @floatFromInt(window_height)) * display.pixel_density;
        display.root.texture = null;
        display.root.type.panel.children = ArrayList(*Element).init(allocator);

        try display.update_screen_metrics(true);

        return display;
    }

    /// Cleanup memory assocaited with this display.
    pub fn destroy(self: *Display) void {
        trace("Engine cleanup", .{});

        self.root.deinit(self, self.allocator);

        for (self.fonts.items) |item| {
            item.destroy(self.allocator);
        }
        self.fonts.deinit();

        var i = self.textures.iterator();
        while (i.next()) |x| {
            if (x.value_ptr.*.references > 0) {
                warn("texture was not deallocated. {s} has {d} references", .{
                    x.key_ptr.*,
                    x.value_ptr.*.references,
                });
            }
            x.value_ptr.*.destroy(self.allocator);
        }
        self.textures.deinit();
        self.resources.destroy();
        for (self.animators.items) |animator| {
            self.allocator.destroy(animator);
        }
        self.animators.deinit();

        sdl.SDL_DestroyRenderer(self.renderer);
        sdl.SDL_DestroyWindow(self.window);
        sdl.TTF_Quit();
        sdl.SDL_Quit();

        self.keybindings.deinit();
        self.translation.deinit();
        self.allocator.destroy(self);
    }

    pub fn update_system_theme(self: *Display) void {
        switch (sdl.SDL_GetSystemTheme()) {
            sdl.SDL_SYSTEM_THEME_DARK => {
                self.theme = &self.themes[0];
            },
            sdl.SDL_SYSTEM_THEME_LIGHT => {
                self.theme = &self.themes[3];
            },
            sdl.SDL_SYSTEM_THEME_UNKNOWN => {
                self.theme = &self.themes[3];
            },
            else => {
                self.theme = &self.themes[3];
            },
        }
    }

    /// Return pointer to a top level panel if it exists. Can be used
    /// to update the contents of a top level panel.
    pub fn get_panel(self: *Display, name: []const u8) ?*Element {
        for (self.root.type.panel.children.items) |element| {
            if (element.type != .panel) {
                continue;
            }
            if (std.mem.eql(u8, name, element.name)) {
                return element;
            }
        }
        return null;
    }

    /// Mark a top level panel as visible, and all other
    /// top level panels as not visible. The visibility of the
    /// _background_ and _menu_ panel is not altered.
    pub fn choose_panel(self: *Display, name: []const u8) void {
        var found = false;
        try self.update_screen_metrics(false);
        for (self.root.type.panel.children.items) |element| {
            if (element.type != .panel) {
                continue;
            }
            if (std.mem.eql(u8, "background", element.name)) {
                continue;
            }
            if (std.mem.eql(u8, "menu", element.name)) {
                continue;
            }
            if (std.mem.eql(u8, name, element.name)) {
                if (element.visible != .visible) {
                    debug("choose_panel({s}) showing panel.", .{name});
                    element.visible = .visible;
                    if (element.on_resized != null) {
                        self.need_relayout = true;
                        _ = element.on_resized.?(self, element);
                    }
                }
            } else {
                if (element.visible != .hidden) {
                    debug("choose_panel({s}) hiding panel {s}.", .{ name, element.name });
                    element.visible = .hidden;
                }
            }
            found = true;
        }
        if (self.selected) |selected| {
            selected.deselected(self);
        }
        try self.update_screen_metrics(true);
        if (!found) {
            warn("choose_panel({s}) did not find panel.", .{name});
        }
    }

    /// Get the name of the currently visible top panel that isn't
    /// the background or menu panel.
    pub fn current_panel(self: *Display) ?*Element {
        for (self.root.type.panel.children.items) |element| {
            if (element.type != .panel) {
                continue;
            }
            if (std.mem.eql(u8, "background", element.name)) {
                continue;
            }
            if (std.mem.eql(u8, "menu", element.name)) {
                continue;
            }
            if (element.visible == .visible) {
                debug("current_panel() found panel {s}.", .{element.name});
                return element;
            }
        }
        warn("current_panel() did not find panel.", .{});
        return null;
    }

    /// Do a draw, but dont block to wait for events. Use to ensure the
    /// window starts being drawn wile starting the app.
    pub fn initial_draw(display: *Display) !void {
        _ = sdl.SDL_SetRenderDrawColor(
            display.renderer,
            display.theme.background_colour.r,
            display.theme.background_colour.g,
            display.theme.background_colour.b,
            255,
        );
        _ = sdl.SDL_RenderClear(display.renderer);
        // Commit everything to the display
        _ = sdl.SDL_RenderPresent(display.renderer);

        display.need_relayout = true;

        // Update and draw all elements
        try display.draw();
    }

    /// Relayout the size and position of all elements on
    /// the display.
    pub fn relayout(display: *Display) void {
        display.need_relayout = false;

        for (display.root.type.panel.children.items) |*scene| {
            if (scene.*.visible != .visible) continue;

            const user_pad: Clip = scene.*.pad;

            if (!std.mem.eql(u8, "background", scene.*.name)) {
                scene.*.pad.top += display.safe_area.top;
                scene.*.pad.bottom += display.safe_area.bottom;
                scene.*.pad.left += display.safe_area.left;
                scene.*.pad.right += display.safe_area.right;
            }

            // Root scene/panels get placement before relayout begins.
            if (scene.*.layout.x == .grows) {
                if (scene.*.maximum.width > 0) {
                    scene.*.rect.width = @min(display.root.rect.width, scene.*.maximum.width);
                } else {
                    scene.*.rect.width = display.root.rect.width;
                }
            }
            if (scene.*.layout.y == .grows) {
                if (scene.*.maximum.height > 0) {
                    scene.*.rect.height = @min(scene.*.rect.height, scene.*.maximum.height);
                } else {
                    scene.*.rect.height = display.root.rect.height;
                }
            }
            if (scene.*.layout.x == .shrinks and scene.*.minimum.width > 0) {
                // Root panels don't shrink past the width requested.
                scene.*.rect.width = @max(scene.*.rect.width, scene.*.minimum.width);
            }
            if (scene.*.layout.y == .shrinks and scene.*.maximum.height > 0) {
                // Root panels don't shrink past the width requested.
                scene.*.rect.height = @max(scene.*.rect.height, scene.*.minimum.height);
            }
            switch (scene.*.child_align.x) {
                .start => scene.*.rect.x = 0,
                .end => scene.*.rect.x = display.root.rect.width - scene.*.rect.width,
                else => scene.*.rect.x = display.root.rect.width / 2 - scene.*.rect.width / 2,
            }
            switch (scene.*.child_align.y) {
                .start => scene.*.rect.y = 0,
                .end => scene.*.rect.y = display.root.rect.height - scene.*.rect.height,
                else => scene.*.rect.y = display.root.rect.height / 2 - scene.*.rect.height / 2,
            }

            do_relayout(display, scene.*);
            display.propogate_resize_event(scene.*);
            do_relayout(display, scene.*); //TODO: fix
            var did_resize = false;
            if (display.on_resized) |on_resized| {
                if (on_resized(display, scene.*)) {
                    did_resize = true;
                }
            }

            if (did_resize) {
                do_relayout(display, scene.*);
            }

            scene.*.pad = user_pad;
        }
    }

    /// Starting with the root parent panel, recursively layout each element
    /// and child panel.
    fn do_relayout(self: *Display, parent: *Element) void {
        std.debug.assert(parent.type == .panel);
        //debug("relayout: {d}x{d}", .{ parent.width, parent.rect.height });

        var expanders = std.BoundedArray(*Element, 10){};
        var expander_weights: f32 = 0;

        // Make sure this element never exceeds its maximum.
        if (parent.layout.x == .grows and parent.maximum.width > 0) {
            parent.rect.width = @min(parent.rect.width, parent.maximum.width);
        }
        if (parent.layout.y == .grows and parent.maximum.height > 0) {
            parent.rect.height = @min(parent.rect.height, parent.maximum.height);
        }

        // # Step 1
        //
        // Children of this panel are either fixed positioned, growing, or shrinking.
        //
        // Fixed elements are not touched, they retain their requested size.
        // Shrinking elements shrink to the space they need.
        // Growing elements grow to the width or height of the parent.
        //
        for (parent.type.panel.children.items) |element| {
            if (element.visible == .hidden) {
                continue;
            }
            if ((dev_build or dev_mode) and element.layout.position == .float) {
                if (element.layout.x == .grows) {
                    err("floating items cant grow. {s} {s}", .{ element.name, @tagName(element.type) });
                    element.layout.x = .fixed;
                }
                if (element.layout.x == .shrinks) {
                    err("floating items cant shrink. {s} {s}", .{ element.name, @tagName(element.type) });
                    element.layout.x = .fixed;
                }
            }
            switch (element.layout.x) {
                .grows => {
                    // Grow to the maximum the parent will allow
                    element.rect.x = 0;
                    element.rect.width = parent.rect.width - (parent.pad.left + parent.pad.right);
                    if (element.maximum.width > 0 and element.rect.width > element.maximum.width) {
                        element.rect.width = element.maximum.width;
                    }
                },
                .shrinks => {
                    // Shrink to the smallest the children will allow
                    // Shrink to the left, centre, or right.
                    element.rect.width = element.shrink_width(self, parent.rect.width);
                    switch (element.child_align.x) {
                        .start => element.rect.x = 0,
                        .end => element.rect.x = parent.rect.width - element.rect.width,
                        .centre => element.rect.x = (parent.rect.width / 2.0) - (element.rect.width / 2.0),
                    }
                },
                .fixed => {
                    // No shrinking or growing applies.
                },
            }
            switch (element.layout.y) {
                .grows => {
                    // Grow to the maximum the parent will allow
                    element.rect.y = 0;
                    element.rect.height = parent.rect.height - (parent.pad.top + parent.pad.bottom);
                    if (element.maximum.height > 0 and element.rect.height > element.maximum.height) {
                        element.rect.height = element.maximum.height;
                    }
                },
                .shrinks => {
                    // Shrink to the smallest the children will allow
                    element.rect.height = element.shrink_height(self, parent.rect.width);
                    switch (element.child_align.y) {
                        .start => element.rect.y = 0,
                        .end => element.rect.y = parent.rect.height - element.rect.height,
                        .centre => element.rect.y = (parent.rect.height / 2.0) - (element.rect.height / 2.0),
                    }
                },
                .fixed => {
                    // No shrinking or growing applies.
                },
            }
            if (element.type == .expander) {
                expanders.appendAssumeCapacity(element);
                expander_weights += element.type.expander.weight;
            }
        }

        // Step 2
        //
        // The parent panel dictates if the children align to start, centre, or end.
        // Growing/Shrinking children must be aligned to the start, centre, or end.
        // The parent panel decides if the elements are left-to-right or top-to-bottom.

        //debug("layout elements {s} {s}", .{
        //    parent.name,
        //    @tagName(parent.child_direction),
        //});
        parent.type.panel.scrollable.size.width = parent.minimum.width;
        parent.type.panel.scrollable.size.height = parent.minimum.height;
        switch (parent.type.panel.direction) {
            .left_to_right => relayout_left_to_right(self, parent, &expanders, expander_weights),
            .top_to_bottom => relayout_top_to_bottom(self, parent, &expanders, expander_weights),
            .centre => relayout_centre(self, parent),
        }

        for (parent.type.panel.children.items) |child| {
            if (child.type == .panel) {
                self.do_relayout(child);
            }
        }
    }

    inline fn relayout_centre(_: *Display, parent: *Element) void {
        // First pass just does a layout assuming top/left positioning.
        for (parent.type.panel.children.items) |child| {
            if (child.visible == .hidden) {
                // Layout the clipped and visible items,
                // but not the hidden items.
                continue;
            }
            if (child.layout.position == .float) {
                continue;
            }
            child.rect.x = parent.rect.width / 2 - child.rect.width / 2;
            child.rect.y = parent.rect.height / 2 - child.rect.height / 2;
            if (dev_build or dev_mode) {
                err("relayout centre {s} puts child {s} size={d}x{d} at={d}x{d}", .{
                    parent.name,
                    child.name,
                    child.rect.width,
                    child.rect.height,
                    child.rect.x,
                    child.rect.y,
                });
            }
        }
        //TODO: Im not sure scroller detection is needed here or not

        //const needed_height = current.y - parent.y;
        //const overflow_height = (parent.y + parent.height) - current.y;
        //parent.type.panel.scrollable.size.height = @max(needed_height, parent.height);
    }

    inline fn relayout_top_to_bottom(_: *Display, parent: *Element, expanders: *std.BoundedArray(*Element, 10), expander_weights: f32) void {
        // Layout each item from top to bottom, initially ignoring
        // the need to centre the items or expand any expanders.
        var current: Vector = .{
            .x = parent.rect.x + parent.pad.left,
            .y = parent.rect.y + parent.pad.top,
        };
        var i: usize = 0;
        for (parent.type.panel.children.items) |child| {
            if (child.visible == .hidden) {
                // Layout the clipped and visible items,
                // but not the hidden items.
                continue;
            }
            if (child.layout.position == .float) {
                continue;
            }
            if (i > 0) {
                current.y += parent.type.panel.spacing;
            }
            child.rect.x = current.x;
            child.rect.y = current.y;
            current.y += child.rect.height;
            i += 1;
            if (child.layout.x == .grows) {
                child.rect.width = parent.rect.width - parent.pad.left - parent.pad.right;
                if (child.maximum.width > 0 and child.rect.width > child.maximum.width) {
                    child.rect.width = child.maximum.width;
                }
            }
        }
        const needed_height = current.y - parent.rect.y - parent.pad.top;
        const overflow_height = (parent.rect.y + parent.rect.height - parent.pad.bottom) - current.y;
        parent.type.panel.scrollable.size.height = @max(needed_height, parent.rect.height);

        //log.info(" top to bottom layout {s} {s} - need {d} overflow {d}", .{ parent.name, @tagName(parent.type), needed_height, overflow_height });

        // If there are expanders, expand them, otherwise,
        // do start/centre/end alignment.
        if (expanders.len > 0) {
            // Relayout the children with expanders
            debug("expanders: {s} has {any}.  needed_height: {d} available_height: {d}", .{
                parent.name,
                expanders.len,
                needed_height,
                parent.rect.height,
            });

            if (parent.rect.height > needed_height) {
                const spare_height = parent.rect.height - needed_height;
                for (expanders.slice()) |expander| {
                    if (expander.type.expander.weight <= 0) {
                        continue;
                    }
                    const percent = expander.type.expander.weight / expander_weights;
                    expander.rect.height = @trunc(spare_height * percent);
                    trace("   expander: weight {d} given: {d}", .{
                        percent,
                        expander.rect.height,
                    });
                }
                var new_y: f32 = parent.rect.y + parent.pad.top;
                for (parent.type.panel.children.items) |child| {
                    // Relayout top to bottom using expander sizes
                    if (child.visible == .hidden) {
                        // Layout the clipped and visible items,
                        // but not the hidden items.
                        continue;
                    }
                    if (child.layout.position != .float) {
                        child.rect.y = new_y;
                        new_y += child.rect.height + parent.type.panel.spacing;
                    }
                }
            }
        } else {
            // If there is remaining space at end of children, maybe we
            // need to centre or right align.
            switch (parent.child_align.y) {
                .start => {},
                .centre => {
                    // Align from top to work out how much space is left
                    var new_y: f32 = parent.rect.y + parent.pad.top + (overflow_height / 2.0);
                    for (parent.type.panel.children.items) |child| {
                        if (child.visible == .hidden) {
                            // Layout the clipped and visible items,
                            // but not the hidden items.
                            continue;
                        }
                        if (child.layout.position == .float) {
                            continue;
                        }
                        child.rect.y = new_y;
                        new_y += child.rect.height + parent.type.panel.spacing;
                    }
                },
                .end => {
                    // Workout the offset between the initial draw position
                    // and the overflow (underflow) to adjust for.
                    var new_y: f32 = parent.rect.y + parent.pad.top + overflow_height;
                    for (parent.type.panel.children.items) |child| {
                        if (child.visible == .hidden) {
                            // Layout the clipped and visible items,
                            // but not the hidden items.
                            continue;
                        }
                        if (child.layout.position == .float) {
                            continue;
                        }
                        child.rect.y = new_y;
                        new_y += child.rect.height + parent.type.panel.spacing;
                    }
                    parent.type.panel.scrollable.size.width = @max(needed_height, parent.rect.height);
                },
            }
        }
    }

    inline fn relayout_left_to_right(_: *Display, parent: *Element, _: *std.BoundedArray(*Element, 10), _: f32) void {
        // Draw panel children from top left corner of the panel
        // assuming no scrolling of the child elements. Offsets
        // applied at runtime.
        var current: Vector = .{
            .x = parent.rect.x + parent.pad.left,
            .y = parent.rect.y + parent.pad.top,
        };
        var i: usize = 0;
        for (parent.type.panel.children.items) |child| {
            if (child.visible == .hidden) {
                // Layout the clipped and visible items,
                // but not the hidden items.
                continue;
            }
            if (child.layout.position == .float) {
                continue;
            }
            if (i > 0) {
                // Spacing before all items except the first
                current.x += parent.type.panel.spacing;
            }
            child.rect.x = current.x;
            child.rect.y = current.y;
            current.x += child.rect.width;
            i += 1;
            if (child.layout.y == .grows) {
                child.rect.height = parent.rect.height - parent.pad.top - parent.pad.bottom;
                if (child.maximum.height > 0 and child.rect.height > child.maximum.height) {
                    child.rect.height = child.maximum.height;
                }
            }
        }
        const needed_width = current.x - parent.rect.x - parent.pad.left;
        const overflow_width = (parent.rect.x + parent.rect.width - parent.pad.right) - current.x;
        parent.type.panel.scrollable.size.width = @max(needed_width, parent.rect.width);

        //log.info(" left to right layout {s} {s} - need {d} overflow {d}", .{ parent.name, @tagName(parent.type), needed_width, overflow_width });

        // If there is remaining space at end of children, maybe we
        // need to centre or right align.
        switch (parent.child_align.x) {
            .start => {},
            .centre => {
                // Align from left to work out how much space is left
                var new_x: f32 = parent.rect.x + parent.pad.left + (overflow_width / 2.0);
                for (parent.type.panel.children.items) |child| {
                    if (child.visible == .hidden) {
                        // Layout the clipped and visible items,
                        // but not the hidden items.
                        continue;
                    }
                    if (child.layout.position == .float) {
                        continue;
                    }
                    child.rect.x = new_x;
                    new_x += child.rect.width + parent.type.panel.spacing;
                }
            },
            .end => {
                // Workout the offset between the initial draw position
                // and the overflow (underflow) to adjust for.
                var new_x: f32 = parent.rect.x + parent.pad.left + overflow_width;
                for (parent.type.panel.children.items) |child| {
                    if (child.visible == .hidden) {
                        // Layout the clipped and visible items,
                        // but not the hidden items.
                        continue;
                    }
                    if (child.layout.position == .float) {
                        continue;
                    }
                    child.rect.x = new_x;
                    new_x += child.rect.width + parent.type.panel.spacing;
                }
                parent.type.panel.scrollable.size.width = @max(needed_width, parent.rect.width);
            },
        }
    }

    pub fn set_language(display: *Display, language: Lang) !void {
        if (language == display.current_language) {
            debug("set_language({s}) unchanged.", .{@tagName(display.current_language)});
            return;
        }
        debug("set_language() {s} => {s}.", .{
            @tagName(display.current_language),
            @tagName(language),
        });
        display.current_language = language;
        display.translation.set_language(language);
        for (display.root.type.panel.children.items) |element| {
            switch (element.type) {
                .label => try element.language_changed(display, language),
                .checkbox => try element.language_changed(display, language),
                .button => try element.language_changed(display, language),
                .panel => try element.language_changed(display, language),
                else => {},
            }
        }
        display.need_relayout = true;
    }

    /// Update and draw all elements on the display.
    pub fn draw(display: *Display) !void {
        const now = std.time.microTimestamp();
        //const delta = now - display.last_draw;
        //display.last_draw = now;
        //log.info("animate delta={d}", .{delta});
        var i: usize = 0;
        while (i < display.animators.items.len) {
            const done = display.animators.items[i].animate(display, now);
            if (done) {
                const old = display.animators.swapRemove(i);
                trace("animate complete for {s} start={d} end={d}", .{ old.target.name, old.start_time, old.end_time });
                display.allocator.destroy(old);
            } else {
                i += 1;
            }
        }

        // Step 1: Clear the background
        _ = sdl.SDL_SetRenderDrawColor(
            display.renderer,
            display.theme.background_colour.r,
            display.theme.background_colour.g,
            display.theme.background_colour.b,
            255,
        );
        _ = sdl.SDL_RenderClear(display.renderer);

        // Step 2: Update and draw all elements to the screen
        display.root.update(display);
        display.root.draw(display, .{ .x = 0, .y = 0 }, null);

        // Step 3: Send everything to the display.
        _ = sdl.SDL_RenderPresent(display.renderer);
    }

    /// Reteurn the size of a checkbox button based on the user
    /// selected screen size/scale.
    pub fn checkbox(self: *Display) Size {
        const CHECKBOX_WIDTH: f32 = 72;
        const CHECKBOX_HEIGHT: f32 = 44;
        const screen_height = self.text_height * self.pixel_scale * self.user_scale;
        const screen_width = screen_height * (CHECKBOX_WIDTH / CHECKBOX_HEIGHT);
        return .{ .width = screen_width, .height = screen_height };
    }

    /// Load and associate a font file with a font name.
    pub fn load_font(self: *Display, name: []const u8) error{ OutOfMemory, ResourceNotFound, ResourceReadError }!*FontInfo {
        const resource = self.resources.lookupOne(name, .font);
        if (resource == null) {
            return error.ResourceNotFound;
        }
        const font_buffer = try sdl_load_resource(self.resources, resource.?, self.allocator);

        const fio = sdl.SDL_IOFromConstMem(font_buffer.ptr, font_buffer.len) orelse {
            err("SDL_IOFromConstMem: {s}", .{sdl.SDL_GetError()});
            return error.ResourceReadError;
        };
        var font_pixel_height = self.text_height * self.pixel_scale * FONT_MUL;
        if (self.scale == 0) {
            err("load_font called before screen scale detected. Font texture not optimized.", .{});
            font_pixel_height = self.text_height * FONT_MUL;
        }
        const myfont = sdl.TTF_OpenFontIO(fio, true, font_pixel_height) orelse {
            err("open font failed. size = {d}*{d}*2={d} error = {s}", .{
                self.text_height,
                self.scale,
                font_pixel_height,
                sdl.SDL_GetError(),
            });
            return error.ResourceReadError;
        };
        //sdl.TTF_SetFontHinting(myfont, 0);

        const font_info = try FontInfo.create(self.allocator, name, myfont);
        font_info.font_buffer = font_buffer;
        errdefer font_info.destroy(self.allocator);
        try self.fonts.append(font_info);

        if (self.fonts.items.len > 1) {
            const i = self.fonts.items.len - 2;
            _ = sdl.TTF_AddFallbackFont(self.fonts.items[i].font, self.fonts.items[i + 1].font);
        }

        return font_info;
    }

    /// Add an animator that points to a currently active/valid element.
    /// The element must not be destroyed for the lifetime of the animation.
    pub inline fn add_animator(self: *Display, animator: Animator) error{OutOfMemory}!void {
        var new_animator = try self.allocator.create(Animator);
        new_animator.* = animator;
        new_animator.setup = false;
        try self.animators.append(new_animator);
    }

    /// Attach a child element to the main display panel (root) element. The
    /// main display panel should only contain panels as children
    pub inline fn add_element(self: *Display, element: *Element) error{OutOfMemory}!void {
        //std.debug.assert(element.type == .panel);
        if (element.type != .panel) {
            warn("parent display should contan panels. Not {s} {s}", .{
                @tagName(element.type),
                element.name,
            });
            return;
        }
        try self.root.type.panel.children.append(element);
    }

    /// Convert a text string into an image that is sent as a texture to
    /// the graphics card.
    fn generate_text_texture(self: *Display, text: []const u8) ?*sdl.SDL_Texture {
        const myfont = self.fonts.items[0].font;

        // Step 1: Create a surface (a bitmap) that holds the text.
        //
        // The text colour is set to white, so that it can be tinted to
        // match the current theme.
        const surface = sdl.TTF_RenderText_Blended(
            myfont,
            text.ptr,
            text.len,
            .{ .r = 255, .g = 255, .b = 255, .a = 255 },
        ) orelse {
            err("generate_text_texture failed. {any} Error: {s}", .{
                text,
                sdl.SDL_GetError(),
            });
            return null;
        };
        errdefer sdl.SDL_DestroySurface(surface);

        // Step 2: Send the surface (a bitmap) to the grahpics card.
        const texture = sdl.SDL_CreateTextureFromSurface(self.renderer, surface) orelse {
            err("text input texture failed. {s}", .{sdl.SDL_GetError()});
            return null;
        };
        errdefer sdl.SDL_DestroyTexture(texture);

        // Step 3: The surface bitmap is no longer needed.
        sdl.SDL_DestroySurface(surface);
        return texture;
    }

    /// A texture resource may be referenced by multiple on screen
    /// elements. This releases a texture, only when all references to
    /// a texture no longer exist.
    pub fn release_texture_resource(self: *Display, ti: *TextureInfo) void {
        ti.references -= 1;
        if (ti.references != 0) {
            if (ti.references < 0) {
                err("free texture \"{s}\" (duplicate free)", .{ti.name});
            } else {
                trace("free texture \"{s}\" (not yet {d})", .{ ti.name, ti.references });
            }
            return;
        }
        trace("free texture \"{s}\" (now)", .{ti.name});
        _ = self.textures.remove(ti.name);
        ti.destroy(self.allocator);
    }

    /// Load an image from the resource bundle or resource directory.
    pub fn load_texture_resource(self: *Display, name: []const u8) error{ UnknownImageFormat, OutOfMemory, ResourceNotFound, ResourceReadError }!?*TextureInfo {
        if (name.len == 0) {
            return null;
        }

        if (self.textures.get(name)) |texture| {
            texture.references += 1;
            return texture;
        }

        const resource = self.resources.lookupOne(name, .image);
        if (resource == null) {
            return null;
        }
        const buf: []const u8 = try sdl_load_resource(self.resources, resource.?, self.allocator);
        defer self.allocator.free(buf);

        var img = zigimg.Image.fromMemory(self.allocator, buf[0..]) catch |e| {
            if (e == error.OutOfMemory) return error.OutOfMemory;
            return error.UnknownImageFormat;
        };
        defer img.deinit();

        var row_size: c_int = 0;
        var sdl_format: sdl.SDL_PixelFormat = sdl.SDL_PIXELFORMAT_UNKNOWN;
        switch (img.pixels) {
            //1 => //PIXELFORMAT_UNCOMPRESSED_GRAYSCALE,
            //2 => //PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA,
            .rgb24 => {
                //PIXELFORMAT_UNCOMPRESSED_R8G8B8
                sdl_format = sdl.SDL_PIXELFORMAT_RGB24;
                row_size = @intCast(img.width * 3);
            },
            .rgba32 => {
                //PIXELFORMAT_UNCOMPRESSED_R8G8B8A8
                sdl_format = sdl.SDL_PIXELFORMAT_ABGR8888;
                row_size = @intCast(img.width * 4);
            },
            else => {
                warn("unknown file format. Loading {s} format {s}", .{ name, @tagName(img.pixels) });
                return error.UnknownImageFormat;
            },
        }

        const img_width: c_int = @intCast(img.width);
        const img_height: c_int = @intCast(img.height);
        const surface = sdl.SDL_CreateSurfaceFrom(img_width, img_height, sdl_format, img.pixels.asBytes().ptr, row_size);
        const texture = sdl.SDL_CreateTextureFromSurface(self.renderer, surface);
        const ti = try TextureInfo.create(self.allocator, name, texture);
        ti.references += 1;
        try self.textures.put(ti.name, ti);
        return ti;
    }

    pub fn select_first_element(self: *Display, elements: []*Element) bool {
        for (elements) |element| {
            if (element.visible != .visible) {
                continue;
            }
            if (element.type == .panel) {
                if (self.select_first_element(element.type.panel.children.items)) {
                    return true;
                }
                if (element.type.panel.on_click == null) {
                    continue;
                }
            }
            if (element.focus == .never_focus or element.focus == .unspecified) {
                continue;
            }
            if (element.focus == .accessibility_focus and self.accessibility == false) {
                continue;
            }
            element.selected(self);
            return true;
        }
        return false;
    }

    const SelectState = enum(u2) {
        no_selectable_items,
        has_selectable_item,
        found_currently_selected_item,
        selected_item,
    };

    pub fn select_next_element(self: *Display) void {
        trace("select_next_element() find next element", .{});
        var state = SelectState.no_selectable_items;
        var previous: ?*Element = null;
        const element = self.do_select_next_element(self.root.type.panel.children.items, &state, &previous);
        if (element) |found| {
            found.selected(self);
            return;
        }
        if (state == .has_selectable_item or state == .found_currently_selected_item) {
            _ = self.select_first_element(self.root.type.panel.children.items);
        } else {
            debug("select_next_element() no element found. {s}", .{@tagName(state)});
        }
    }

    pub fn select_previous_element(self: *Display) void {
        trace("select_previous_element() find previous element", .{});
        var state = SelectState.no_selectable_items;
        var previous: ?*Element = null;
        _ = self.do_select_next_element(self.root.type.panel.children.items, &state, &previous);
        if (previous) |found| {
            found.selected(self);
            return;
        }
        if (state == .has_selectable_item or state == .found_currently_selected_item) {
            _ = self.select_first_element(self.root.type.panel.children.items);
        } else {
            debug("select_next_element() no element found. {s}", .{@tagName(state)});
        }
    }

    fn do_select_next_element(self: *Display, elements: []*Element, state: *SelectState, previous: *?*Element) ?*Element {
        for (elements) |element| {
            trace("search: {s} inspect {s}/{s}/{s}", .{
                @tagName(state.*),
                @tagName(element.type),
                @tagName(element.focus),
                element.name,
            });
            if (element.visible != .visible) {
                trace("     skip not visible {s}/{s}", .{ @tagName(element.type), element.name });
                continue;
            }
            if (element.type == .panel) {
                if (self.do_select_next_element(element.type.panel.children.items, state, previous)) |found| {
                    return found;
                }
                if (element.type.panel.on_click == null) {
                    continue;
                }
            }
            if (element.focus == .never_focus or element.focus == .unspecified) {
                continue;
            }
            if (element.focus == .accessibility_focus) {
                if (self.accessibility == false) {
                    trace("     skip no accessibility {s}/{s}", .{ @tagName(element.type), element.name });
                    continue;
                }
                if (element.type == .label and element.type.label.translated.len == 0) {
                    continue;
                }
            }
            // We found a selectable element
            if (state.* == .no_selectable_items) {
                state.* = .has_selectable_item;
                //debug("    --> {any}\n", .{state.*});
            }
            if (state.* == .has_selectable_item) {
                if (element == self.selected) {
                    state.* = .found_currently_selected_item;
                    //debug("    --> {any}\n", .{state.*});
                    continue;
                }
                previous.* = element;
                continue;
            }
            state.* = .selected_item;
            //debug("    --> {any}\n", .{state.*});
            return element;
        }
        return null;
    }

    pub const FindQuery = enum { any, clickable, scrollable };

    // Find what element appears directly under the cursor.
    //
    // Because the first elements in the element list are drawn first,
    // the first elements appear below elements later on in the list.
    //
    // When searching for buttons to click on, we are seeking the top
    // most (last drawn) items.
    //
    // When searching for panels to grab and scroll with, we are seeking
    // the panel surface under the button. We are seeking the bottom most
    // (first drawn) items. (Because on mouse down is not a button click
    // we dont need to handle this special case.)
    pub fn find_under_cursor(
        display: *Display,
        elements: []*Element,
        cursor: Vector,
        scroll_offset: Vector,
        comptime query: FindQuery,
    ) ?*Element {
        var i = elements.len;
        while (i > 0) : (i -= 1) {
            const element: *Element = elements[i - 1];
            //debug("seek={s} visible={any} {s} {s}", .{ @tagName(query), element.visible, @tagName(element.type), element.name });
            if (element.visible != .visible) {
                continue;
            }
            const is_under_cursor = element.at_point(cursor, scroll_offset);
            if (!is_under_cursor and element.type != .panel) {
                continue;
            }
            //debug("under cursor {s}.{s}", .{ @tagName(element.type), element.name });
            if (element.type == .panel) {
                const so = scroll_offset.add(element.offset);
                if (display.find_under_cursor(element.type.panel.children.items, cursor, so, query)) |found| {
                    return found;
                }
            }
            // This item is under the cursor
            if (query == .any) {
                if (element.type != .panel) {
                    return element;
                }
                if (is_under_cursor) {
                    if (element.type.panel.on_click != null) {
                        return element;
                    }
                    if (element.type.panel.scrollable.scroll.x == true or element.type.panel.scrollable.scroll.y == true) {
                        return element;
                    }
                }
            }
            if (query == .clickable) {
                // Only clickable things
                //debug("under cursor clickable {s} {s}", .{ @tagName(element.type), element.name });
                switch (element.type) {
                    .text_input, .checkbox => return element,
                    .button => {
                        if (element.type.button.toggle == .no_toggle or element.type.button.toggle == .on or element.type.button.toggle == .off) {
                            return element;
                        }
                    },
                    .label => if (element.type.label.on_click != null) {
                        return element;
                    },
                    .sprite => if (element.type.sprite.on_click != null) {
                        return element;
                    },
                    .panel => if (is_under_cursor and element.type.panel.on_click != null) {
                        return element;
                    },
                    .button_bar, .rectangle, .progress_bar, .expander => {},
                }
            } else if (query == .scrollable) {
                //debug("check cursor scrollable {s} {s}", .{ @tagName(element.type), element.name });
                if (element.type == .panel and is_under_cursor) {
                    if (element.type.panel.scrollable.scroll.x or element.type.panel.scrollable.scroll.y) {
                        return element;
                    }
                }
            }
        }
        return null;
    }

    /// Switch from the current theme to the next theme.
    pub fn rotate_theme(self: *Display) void {
        var index: usize = 0;

        // Find the current theme
        for (&self.themes) |*theme| {
            if (theme == self.theme) {
                break;
            }
            index += 1;
        }
        index += 1;
        if (index >= self.themes.len) {
            index = 0;
        }
        self.theme = &self.themes[index];
    }

    /// Update the quit flag to indicate to the main loop that
    /// it should exit after processing the current event.
    pub fn end_main_loop(display: *Display) void {
        log.info("Ending main loop.", .{});
        display.quit = true;
    }

    /// Draw all entities. Used in conjunction with SDL_AppIterate
    pub fn iterate(display: *Display) !void {
        try display.draw();
    }

    /// Enters the main run loop and only returns when quit has been
    /// requested. Use in conjunction with SDL_Main
    pub fn main(display: *Display) !void {
        log.info("Main loop starting", .{});
        display.quit = false;

        while (!display.quit) {
            // Update and draw all elements
            try display.draw();

            // Handle any outstanding events on the event queue
            var e: sdl.SDL_Event = undefined;
            while (sdl.SDL_PollEvent(&e)) {
                try display.handle_event(&e);
                if (display.quit) break;
            }
        }

        debug("Main loop ended", .{});
    }

    inline fn handle_key_up_event(display: *Display, e: *sdl.SDL_Event) !void {
        trace("handle_key_up_event({any})", .{e.key.key});
        if (e.key.key == sdl.SDLK_TAB) {
            if (e.key.mod == sdl.SDL_KMOD_SHIFT or e.key.mod == sdl.SDL_KMOD_LSHIFT or e.key.mod == sdl.SDL_KMOD_RSHIFT) {
                display.select_previous_element();
            } else {
                display.select_next_element();
            }
            if (display.selected != null) {
                display.keyboard_selected = true;
            }
            return;
        }
        if (display.selected) |selected| {
            trace("handle_key_up_event({any}) for selected {s} {s}", .{ e.key.key, @tagName(selected.type), selected.name });
            switch (selected.type) {
                .button => {
                    if (e.key.key == sdl.SDLK_RETURN or
                        e.key.key == sdl.SDLK_KP_ENTER or
                        e.key.key == sdl.SDLK_RETURN2 or
                        e.key.key == sdl.SDLK_KP_SPACE or
                        e.key.key == sdl.SDLK_SPACE)
                    {
                        try selected.chosen(display);
                        return; // keypress handled
                    }
                },
                .sprite => {
                    if (e.key.key == sdl.SDLK_RETURN or
                        e.key.key == sdl.SDLK_KP_ENTER or
                        e.key.key == sdl.SDLK_RETURN2 or
                        e.key.key == sdl.SDLK_KP_SPACE or
                        e.key.key == sdl.SDLK_SPACE)
                    {
                        try selected.chosen(display);
                        return; // keypress handled
                    }
                },
                .panel => {
                    if (e.key.key == sdl.SDLK_RETURN or
                        e.key.key == sdl.SDLK_KP_ENTER or
                        e.key.key == sdl.SDLK_RETURN2 or
                        e.key.key == sdl.SDLK_KP_SPACE or
                        e.key.key == sdl.SDLK_SPACE)
                    {
                        try selected.chosen(display);
                        return; // keypress handled
                    }
                },
                .checkbox => {
                    if (e.key.key == sdl.SDLK_RETURN or
                        e.key.key == sdl.SDLK_KP_ENTER or
                        e.key.key == sdl.SDLK_RETURN2 or
                        e.key.key == sdl.SDLK_KP_SPACE or
                        e.key.key == sdl.SDLK_SPACE)
                    {
                        try selected.chosen(display);
                        return; // keypress handled
                    }
                },
                .label => {
                    if (e.key.key == sdl.SDLK_RETURN or
                        e.key.key == sdl.SDLK_KP_ENTER or
                        e.key.key == sdl.SDLK_RETURN2 or
                        e.key.key == sdl.SDLK_KP_SPACE or
                        e.key.key == sdl.SDLK_SPACE)
                    {
                        try selected.chosen(display);
                        return; // keypress handled
                    }
                },
                .text_input => {
                    switch (e.key.key) {
                        sdl.SDLK_BACKSPACE,
                        sdl.SDLK_DELETE,
                        sdl.SDLK_KP_BACKSPACE,
                        => try selected.keypress(display, sdl.SDLK_BACKSPACE, ""),
                        sdl.SDLK_RETURN,
                        sdl.SDLK_KP_ENTER,
                        sdl.SDLK_RETURN2,
                        => {
                            switch (selected.type) {
                                .text_input => {
                                    try selected.keypress(display, 10, "");
                                },
                                .button => {
                                    if (selected.type.button.on_click != null) {
                                        try selected.type.button.on_click.?(display, selected);
                                    }
                                },
                                else => {},
                            }
                        },
                        sdl.SDLK_ESCAPE => if (display.keybindings.get(sdl.SDLK_ESCAPE)) |f| {
                            try f(display);
                            // s.deselected(display);
                        },
                        else => {},
                    }
                    return; // keypress consumed by text edit box
                },
                else => {
                    // Only button, label, and text_input have
                    // special key handling.
                },
            }
        }

        // Unhandled keypresses fall through to user defined keybindings.
        var i = display.keybindings.iterator();
        while (i.next()) |k| {
            if (k.key_ptr.* == e.key.key) {
                try k.value_ptr.*(display);
            }
        }
    }

    /// Handle key down events. Usually no action is triggered until the
    /// key is released.
    inline fn handle_key_down_event(_: *Display, _: *sdl.SDL_Event) !void {
        //
    }

    /// Refresh the window size information, then refresh the
    /// safe area information.
    pub inline fn update_screen_metrics(display: *Display, forced: bool) !void {
        var updated = false;

        var rwidth: c_int = 0;
        var rheight: c_int = 0;
        _ = sdl.SDL_GetRenderOutputSize(display.renderer, &rwidth, &rheight);
        if (display.root.rect.width != @as(f32, @floatFromInt(rwidth)))
            updated = true;
        if (display.root.rect.height != @as(f32, @floatFromInt(rheight)))
            updated = true;
        if (updated or dev_build or dev_mode) {
            debug("current display size {d}x{d} -=> new display size {d}x{d}", .{
                display.root.rect.width,
                display.root.rect.height,
                @as(f32, @floatFromInt(rwidth)),
                @as(f32, @floatFromInt(rheight)),
            });
        }
        display.root.rect.width = @as(f32, @floatFromInt(rwidth));
        display.root.rect.height = @as(f32, @floatFromInt(rheight));
        display.root.minimum.width = display.root.rect.x;
        display.root.maximum.width = display.root.rect.x;
        display.root.minimum.height = display.root.rect.y;
        display.root.maximum.height = display.root.rect.y;

        if (display.recalculate_safe_area()) {
            updated = true;
        }

        if (updated or forced) {
            display.need_relayout = true;
        }
    }

    /// Trigger `on_resized` events on each node in the tree.
    fn propogate_resize_event(self: *Display, parent: *Element) void {
        if (parent.on_resized != null) {
            if (parent.visible == .visible) {
                _ = parent.on_resized.?(self, parent);
            }
        }
        if (parent.type == .panel) {
            for (parent.type.panel.children.items) |element| {
                self.propogate_resize_event(element);
            }
        }
    }

    /// Handle events that impact the usable area of the screen.
    fn recalculate_safe_area(self: *Display) bool {
        var area: sdl.SDL_Rect = undefined;
        var updated = false;
        if (sdl.SDL_GetRenderSafeArea(self.renderer, &area)) {
            log.info("System reported safe area: {d}x{d} {d}x{d}", .{
                area.x,
                area.y,
                area.w,
                area.h,
            });

            // SDL_GetRenderSafeArea returns physical display pixels, not
            // window pretend pixels.
            const left_pad = @as(f32, @floatFromInt(area.x));
            const right_pad = self.root.rect.width - left_pad - @as(f32, @floatFromInt(area.w));
            var top_pad = @as(f32, @floatFromInt(area.y));
            var bottom_pad = self.root.rect.height - top_pad - @as(f32, @floatFromInt(area.h));

            if (builtin.abi.isAndroid()) {
                if (top_pad > 0 and bottom_pad > 0) {
                    if (top_pad > bottom_pad) {
                        log.info("Android safe area hack {d},{d} -=> {d},{d}", .{
                            top_pad, bottom_pad,
                            0,       bottom_pad,
                        });
                        top_pad = 0;
                    } else {
                        log.info("Android safe area hack {d},{d} -=> {d},{d}", .{
                            top_pad, bottom_pad,
                            top_pad, 0,
                        });
                        bottom_pad = 0;
                    }
                }
            }

            if (self.safe_area.left != left_pad) updated = true;
            if (self.safe_area.top != top_pad) updated = true;
            if (self.safe_area.right != right_pad) updated = true;
            if (self.safe_area.bottom != bottom_pad) updated = true;

            if (updated or (dev_build and dev_mode)) {
                // Log the padding numbers in css/border ordering
                log.info("safe area changed: {d} {d} {d} {d} -=> {d} {d} {d} {d}", .{
                    self.safe_area.left,  self.safe_area.top,
                    self.safe_area.right, self.safe_area.bottom,
                    left_pad,             top_pad,
                    right_pad,            bottom_pad,
                });
                self.safe_area.left = left_pad;
                self.safe_area.right = right_pad;
                self.safe_area.top = top_pad;
                self.safe_area.bottom = bottom_pad;
            }
        } else {
            err("SDL_GetRenderSafeArea() failed", .{});
        }
        return updated;
    }

    /// The mouse up event idicates a mouse click, or the end of a mouse
    /// scroll/drag action.
    inline fn handle_mouse_up_event(display: *Display, _: *sdl.SDL_Event) !void {
        var cursor: Vector = undefined;
        _ = sdl.SDL_GetMouseState(&cursor.x, &cursor.y);
        cursor = cursor.multiply(display.pixel_density);

        if (display.scrolling != null) {
            trace("end scrolling {s} at {any}", .{
                display.scrolling.?.name,
                cursor,
            });
            const moved = display.scroll_start.minus(cursor);
            const ignore_distance = 6;
            if (@abs(moved.x) > ignore_distance or @abs(moved.y) > ignore_distance) {
                // If scrolling occurred, this cant be a click
                debug("tap became scroll. proper movement on {s} at {any}", .{
                    display.scrolling.?.name,
                    cursor,
                });
                display.scrolling = null;
                return;
            }
            debug("tap is not scroll. minimal movement on {s} at {any}", .{
                display.scrolling.?.name,
                moved,
            });
            display.scrolling = null;
        }

        if (display.find_under_cursor(
            display.root.type.panel.children.items,
            cursor,
            .{},
            .clickable,
        )) |found| {
            found.selected(display);
            display.hovered = found;
            switch (found.type) {
                .panel => {
                    if (found.type.panel.on_click != null) {
                        try found.type.panel.on_click.?(display, found);
                    } else if (found.type.panel.scrollable.scroll.x or found.type.panel.scrollable.scroll.y) {
                        display.scrolling = found;
                        display.scroll_start = cursor;
                        trace("begin scrolling {s} at {any}", .{ found.name, cursor });
                    }
                },
                .button => try found.chosen(display),
                .label => try found.chosen(display),
                .sprite => try found.chosen(display),
                .checkbox => try found.chosen(display),
                .text_input => found.selected(display),
                .rectangle, .button_bar, .progress_bar, .expander => {
                    // Not clickable
                },
            }
        } else {
            trace("nothing clickable under mouse at {d:.1}x{d:.1}", .{
                cursor.x,
                cursor.y,
            });
        }
    }

    /// Event handler for mouse down events. This begins a scroll event, or converts
    /// to a click on mouse up event later.
    inline fn handle_mouse_down_event(display: *Display, _: *sdl.SDL_Event) !void {
        var cursor: Vector = undefined;
        _ = sdl.SDL_GetMouseState(&cursor.x, &cursor.y);
        cursor = cursor.multiply(display.pixel_density);

        if (display.find_under_cursor(
            display.root.type.panel.children.items,
            cursor,
            .{},
            .scrollable,
        )) |found| {
            if (found.type == .panel) {
                if (found.type.panel.scrollable.scroll.x or found.type.panel.scrollable.scroll.y) {
                    display.scrolling = found;
                    // scroll_start is the cursor position when drag
                    // started, used to calculate drag distance.
                    display.scroll_start = cursor;
                    // If a previos drag occured then this new drag
                    // adds to the previous drag.
                    display.scroll_initial_offset = found.offset;
                    trace("begin scrolling {s} at {any}", .{ found.name, cursor });
                }
            }
        }
    }

    /// Event handler for mouse motion
    inline fn handle_mouse_motion_event(display: *Display, _: *sdl.SDL_Event) !void {
        var cursor: Vector = undefined;
        _ = sdl.SDL_GetMouseState(&cursor.x, &cursor.y);
        // Translate cursor position to pixel position
        cursor = cursor.multiply(display.pixel_density);

        if (display.scrolling) |element| {
            // If mouse is down while movement is detected, and mouse was
            // down on a movable item, we are in scrolling/moving mode.
            switch (element.type) {
                .panel => |*panel| {

                    // How far has the mouse/finger moved the item
                    element.offset = cursor.minus(display.scroll_start).add(display.scroll_initial_offset);

                    // Clamp offset so we cant scroll past start at all
                    element.offset.x = @min(element.offset.x, 0);
                    element.offset.y = @min(element.offset.y, 0);

                    // Clamp offset so we cant scroll past end at all
                    const allowable_x_scroll = @min(0, element.rect.width - panel.scrollable.size.width);
                    const allowable_y_scroll = @min(0, element.rect.height - panel.scrollable.size.height);

                    element.offset.x = @max(element.offset.x, allowable_x_scroll);
                    element.offset.y = @max(element.offset.y, allowable_y_scroll);

                    if (!panel.scrollable.scroll.y) {
                        element.offset.y = 0;
                    }
                    if (!panel.scrollable.scroll.x) {
                        element.offset.x = 0;
                    }
                    trace("scrolling panel {s}. scrollable.size={d}x{d} panel.size={d}x{d}. draw.offset={d}x{d}", .{
                        element.name,
                        panel.scrollable.size.width,
                        panel.scrollable.size.height,
                        element.rect.width,
                        element.rect.height,
                        element.offset.x,
                        element.offset.y,
                    });
                },
                else => {
                    err("Cant scroll {s}. Not a panel.", .{element.name});
                },
            }
            return;
        }

        const found = display.find_under_cursor(
            display.root.type.panel.children.items,
            cursor,
            .{},
            .any,
        );
        if (display.hovered) |old_item| {
            // Deactivate previously hovered item if it is
            // not still being hovered over.
            if (found != display.hovered) {
                trace("end hover: {s} {s}", .{ @tagName(old_item.type), old_item.name });
                old_item.hovered = false;
                display.hovered = null;
            }
        }
        if (found != null) {
            // Mark the newly hovered item as hovered
            // if there is one that is hovered.
            if (found != display.hovered) {
                trace("entered hover({s} {s}) pos: {d}x{d} size: {d}x{d}  min: {d}x{d}   max: {d}x{d}", .{
                    @tagName(found.?.type),
                    found.?.name,
                    found.?.rect.x,
                    found.?.rect.y,
                    found.?.rect.width,
                    found.?.rect.height,
                    found.?.minimum.width,
                    found.?.minimum.height,
                    found.?.maximum.width,
                    found.?.maximum.height,
                });
                if (dev_build and dev_mode and found.?.type == .panel) {
                    trace("entered hover({s} {s}) panel content {d}x{d}.  usable area: {d}x{d}", .{
                        @tagName(found.?.type),
                        found.?.name,
                        found.?.type.panel.scrollable.size.width,
                        found.?.type.panel.scrollable.size.height,
                        found.?.rect.width,
                        found.?.rect.height,
                    });
                }
                display.hovered = found.?;
                display.hovered.?.hovered = true;
            } else {
                if (dev_build and dev_mode) {
                    //debug("mouse over: {s} {s}", .{ @tagName(found.?.type), found.?.name });
                }
            }
        }
    }

    /// Handle an event on the event queue.
    pub fn handle_event(display: *Display, e: *sdl.SDL_Event) !void {
        switch (e.type) {
            sdl.SDL_EVENT_TEXT_INPUT => {
                if (display.selected) |selected| {
                    if (selected.type == .text_input) {
                        try selected.keypress(
                            display,
                            c_unicode_to_u21(e.text.text),
                            c_unicode_to_slice(e.text.text),
                        );
                    } else {
                        err("sdl text input event on non text_input element.", .{});
                    }
                } else {
                    err("sdl text input event when nothing selected.", .{});
                }
            },
            sdl.SDL_EVENT_KEY_UP => try display.handle_key_up_event(e),
            sdl.SDL_EVENT_KEY_DOWN => try display.handle_key_down_event(e),
            sdl.SDL_EVENT_MOUSE_BUTTON_DOWN => try display.handle_mouse_down_event(e),
            sdl.SDL_EVENT_MOUSE_BUTTON_UP => try display.handle_mouse_up_event(e),
            sdl.SDL_EVENT_MOUSE_MOTION => try display.handle_mouse_motion_event(e),

            sdl.SDL_EVENT_SYSTEM_THEME_CHANGED => display.update_system_theme(),
            sdl.SDL_EVENT_WINDOW_RESIZED,
            sdl.SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED,
            sdl.SDL_EVENT_DISPLAY_ORIENTATION,
            sdl.SDL_EVENT_WINDOW_SAFE_AREA_CHANGED,
            => try display.update_screen_metrics(false),

            sdl.SDL_EVENT_QUIT => display.end_main_loop(),

            sdl.SDL_EVENT_TERMINATING => {},
            sdl.SDL_EVENT_LOW_MEMORY => {},
            sdl.SDL_EVENT_WILL_ENTER_BACKGROUND => {},
            sdl.SDL_EVENT_DID_ENTER_BACKGROUND => {},
            sdl.SDL_EVENT_WILL_ENTER_FOREGROUND => {},
            sdl.SDL_EVENT_DID_ENTER_FOREGROUND => {},

            else => {
                if (display.event_hook) |eh| {
                    try eh(display, e.type);
                }
                // Other SDL events are not handled
            },
        }
    }

    /// Set the user preferred screen scale.
    pub fn set_scale(display: *Display, scale: Scale) void {
        display.user_scale = scale.float();
        display.scale = display.pixel_scale * display.user_scale;
    }

    /// Lookoup the user preferred screen scale.
    pub fn user_scale_setting(display: *Display) Scale {
        return Scale.from_float(display.user_scale);
    }

    pub fn increase_size(display: *Display) void {
        display.user_scale = if (display.user_scale == 0.5)
            0.75
        else if (display.user_scale == 0.75)
            1
        else if (display.user_scale == 1.0)
            1.25
        else if (display.user_scale == 1.25)
            if (dev_build or dev_mode) 1.5 else 1.25
        else if (dev_build or dev_mode) 1.5 else 1.25;
        display.scale = display.pixel_scale * display.user_scale;
        display.need_relayout = true;
        debug("Increase size. {d}*{d} = {d}", .{
            display.pixel_scale,
            display.user_scale,
            display.scale,
        });
    }

    pub fn decrease_size(display: *Display) void {
        debug("size = {d}", .{display.user_scale});
        display.user_scale = if (display.user_scale == 0.75)
            if (dev_build or dev_mode) 0.5 else 0.75
        else if (display.user_scale == 1.0)
            0.75
        else if (display.user_scale == 1.25)
            1.0
        else if (display.user_scale == 1.5)
            1.25
        else if (dev_build or dev_mode) 0.5 else 0.75;
        display.scale = display.pixel_scale * display.user_scale;
        display.need_relayout = true;
        debug("Decrease size. {d}*{d} = {d}", .{
            display.pixel_scale,
            display.user_scale,
            display.scale,
        });
    }

    fn make_bundle(display: *Display) error{OutOfMemory}!void {
        if (!dev_build) {
            return;
        }
        //const allocator = app_context.?.allocator;
        if (display.resources.used_resource_list) |manifest| {
            if (manifest.items.len == 0) {
                log.info("no resources in manifest, nothing to bundle.", .{});
                return;
            }
            //const base_folder = find_base_folder(allocator, RESOURCE_BUNDLE_FILENAME) catch |e| {
            //    err("make_bundle failed to find app folder. {any}", .{e});
            //    return;
            //};
            //defer if (base_folder.len > 0) {
            //    allocator.free(base_folder);
            //};

            const base_folder = "/tmp/";
            var buffer = std.BoundedArray(u8, 1000){};
            buffer.appendSlice(base_folder) catch {
                return std.mem.Allocator.Error.OutOfMemory;
            };
            buffer.appendSlice(RESOURCE_BUNDLE_FILENAME) catch {
                return std.mem.Allocator.Error.OutOfMemory;
            };
            log.info("making resource bundle: {s}", .{buffer.slice()});

            display.resources.save_bundle(buffer.slice(), manifest.items) catch |e| {
                log.info("save resource bundle failed. {s} {any}", .{ buffer.slice(), e });
            };
        } else {
            log.info("no resource bundle manifest", .{});
        }
    }

    /// Provides a standardised way to place a back button in the top left
    /// corner of the screen.
    pub fn add_back_button(display: *Display, parent: *Element, close_fn: fn (
        display: *Display,
        _: *Element,
    ) Allocator.Error!void) error{
        OutOfMemory,
        ResourceNotFound,
        ResourceReadError,
        UnknownImageFormat,
    }!*Element {
        const button = try engine.create_button(
            display,
            "icon-back",
            "icon-back",
            "icon-back",
            .{
                .name = "back",
                .focus = .can_focus,
                .rect = .{ .x = 20, .y = 20, .width = 120, .height = 120 },
                .pad = .{ .left = 20, .right = 20, .top = 20, .bottom = 20 },
                .layout = .{ .x = .fixed, .y = .fixed, .position = .float },
                .type = .{ .button = .{
                    .text = "",
                    .translated = "",
                    .on_click = close_fn,
                    .icon_size = .{ .x = 70, .y = 70 },
                } },
                .on_resized = back_button_resize,
            },
            "",
            "",
            "",
        );
        try parent.add_element(button);
        return button;
    }

    /// Add an empty panel that keeps a space open in a list of elements.
    pub fn add_spacer(
        display: *Display,
        parent: *Element,
        size: f32,
    ) error{
        OutOfMemory,
        ResourceNotFound,
        ResourceReadError,
        UnknownImageFormat,
    }!*Element {
        return try parent.add(try engine.create_panel(
            display,
            "",
            .{
                .name = "spacer",
                .rect = .{ .width = size, .height = size },
                .layout = .{ .x = .shrinks, .y = .shrinks },
                .minimum = .{ .width = size, .height = size },
                .type = .{ .panel = .{} },
            },
        ));
    }

    /// Add a label with generic settings needed for a paragraph.
    pub fn add_paragraph(
        display: *Display,
        parent: *Element,
        size: TextSize,
        name: []const u8,
        text: []const u8,
    ) error{
        OutOfMemory,
        ResourceNotFound,
        ResourceReadError,
        UnknownImageFormat,
    }!void {
        try parent.add_element(try engine.create_label(
            display,
            "",
            .{
                .name = name,
                .focus = .accessibility_focus,
                .rect = .{ .x = 250, .y = 50, .width = 500, .height = 80 },
                .layout = .{ .y = .shrinks, .x = .grows },
                .child_align = .{ .x = .start, .y = .start },
                .type = .{ .label = .{
                    .text = text,
                    .translated = "",
                    .text_size = size,
                    .text_colour = .normal,
                } },
            },
        ));
    }
};

fn toggle_dev_mode(_: *Display) error{OutOfMemory}!void {
    engine.dev_mode = !engine.dev_mode;
    log.info("Dev mode: {any}", .{engine.dev_mode});
}

fn increase_content_size(display: *Display) error{OutOfMemory}!void {
    display.increase_size();
}

fn decrease_content_size(display: *Display) error{OutOfMemory}!void {
    display.decrease_size();
}

fn use_next_theme(display: *Display) std.mem.Allocator.Error!void {
    display.rotate_theme();
}

/// Discover the minimum needed for a particular object.
///
/// If the object has children, a `parent` object must check
/// the heights of its children.
///
/// If parent stacks children top-to-bottom, we must add the heights.
/// If parent stacks children left-to-right simply find the tallest item.
fn find_minimum_panel_height(parent: *const Element, display: *Display) f32 {
    std.debug.assert(parent.type == .panel);
    if (parent.visible == .hidden) {
        return 0;
    }
    if (parent.layout.position == .float) {
        return 0;
    }
    switch (parent.type.panel.direction) {
        .top_to_bottom => {
            // a, above b, above c. (top to bottom)
            var minimum_needed: f32 = parent.pad.top + parent.pad.bottom;
            // Add the size needed for each inline child.
            var first = true;
            for (parent.type.panel.children.items) |element| {
                if (element.layout.position == .float) {
                    continue;
                }
                if (element.visible == .hidden) {
                    continue;
                }
                if (first) {
                    first = false;
                } else {
                    // Add spacing before next element, if needed
                    minimum_needed += parent.type.panel.spacing;
                }
                const height = element.shrink_height(display, parent.rect.width);
                minimum_needed += height;
            }
            // Bound to the minimum/maximum height
            var result = minimum_needed;
            if (parent.maximum.height > 0 and parent.maximum.height < minimum_needed) {
                result = parent.maximum.height;
            }
            result = @max(result, parent.minimum.height);
            return result;
        },

        .centre, .left_to_right => {
            // centred all together
            // a, next to b, next c.
            //
            // Just need to know the highest/tallest child.
            var minimum_needed: f32 = 0;
            for (parent.type.panel.children.items) |element| {
                if (element.layout.position == .float) {
                    continue;
                }
                const height = element.shrink_height(display, parent.rect.width);
                if (height > minimum_needed) {
                    minimum_needed = height;
                }
            }
            return minimum_needed + (parent.pad.top + parent.pad.bottom);
        },
    }
}

/// This event handler repositions a back button into the top left corner
/// when the screen is resized or rotated.
pub fn back_button_resize(display: *Display, element: *Element) bool {
    var updated = false;
    if (element.rect.x != display.safe_area.left) {
        element.rect.x = display.safe_area.left;
        updated = true;
    }
    if (element.rect.y != display.safe_area.top) {
        element.rect.y = display.safe_area.top;
        updated = true;
    }
    return updated;
}

/// Discover the minimum needed for a particular object.
///
/// If the object has children, a `parent` object must check
/// the widths of its children.
///
/// If parent fills children left-to-right, we must add the heights.
/// If parent fills children top-to-bottom simply find the widest item.
fn find_minimum_panel_width(parent: *const Element, display: *Display) f32 {
    std.debug.assert(parent.type == .panel);
    if (parent.visible == .hidden) {
        return 0;
    }
    if (parent.layout.position == .float) {
        return 0;
    }
    switch (parent.type.panel.direction) {
        .left_to_right => {
            // a, next to b, next to c. (left to right)
            //
            // Need to add up the min width of all items
            var minimum_needed: f32 = parent.pad.left + parent.pad.right;
            var first = true;
            for (parent.type.panel.children.items) |element| {
                if (element.layout.position == .float) {
                    continue;
                }
                if (element.visible == .hidden) {
                    continue;
                }
                if (first) {
                    first = false;
                } else {
                    // Add spacing before next element, if needed
                    minimum_needed += parent.type.panel.spacing;
                }
                const width = element.shrink_width(display, parent.rect.width);
                minimum_needed += width;
            }
            // Bound to the minimum/maximum width
            var result = minimum_needed;
            if (parent.maximum.width > 0 and parent.maximum.width < minimum_needed) {
                result = parent.maximum.width;
            }
            result = @max(result, parent.minimum.width);
            return result;
        },
        .centre, .top_to_bottom => {
            // a, centred upon b, centred upon c
            // a, then b underneath, thn c underneath...
            //
            // Need to just find maximum width item
            var minimum_needed: f32 = 0;
            for (parent.type.panel.children.items) |element| {
                if (element.layout.position == .float) {
                    continue;
                }
                if (element.visible == .hidden) {
                    continue;
                }
                const width = element.shrink_width(display, parent.rect.width);
                //debug("seek min width {s} {s} min={d}", .{ element.name, @tagName(element.type), width });
                if (width > minimum_needed) {
                    minimum_needed = width;
                }
            }
            const chose = @max(parent.minimum.width, minimum_needed + (parent.pad.left + parent.pad.right));
            return chose;
        },
    }
}

/// Load and associate an image file with a sprite name.
pub fn create_rect(
    display: *Display,
    settings: Element,
) Allocator.Error!*Element {
    var element = try display.allocator.create(Element);
    element.* = settings;
    element.texture = null;
    element.background_texture = null;
    if (element.focus == .unspecified) {
        element.focus = .never_focus;
    }

    if (element.type != .rectangle) {
        err("create_rect called without config.", .{});
        element.type = .{ .rectangle = .{} };
    }

    return element;
}

/// Load and process text for a label.
pub fn create_label(
    display: *Display,
    background_texture: []const u8,
    settings: Element,
) error{ OutOfMemory, ResourceNotFound, ResourceReadError, UnknownImageFormat }!*Element {
    var element = try display.allocator.create(Element);
    element.* = settings;

    if (element.type != .label) {
        err("create_label called without config.", .{});
        element.type = .{ .label = .{ .text = "" } };
    }
    element.type.label.translated = "";

    if (element.focus == .unspecified) {
        if (element.type.label.on_click != null) {
            element.focus = .can_focus;
        } else {
            element.focus = .accessibility_focus;
        }
    }
    element.texture = null;
    element.background_texture = null;

    element.type.label.elements = ArrayList(TextElement).init(display.allocator);
    try element.set_text(display, element.type.label.text, true);

    // Is there a background for this label?
    if (try display.load_texture_resource(background_texture)) |texture| {
        element.background_texture = texture;
    }

    element.pad.top = display.text_height * display.scale * 0.3;
    element.pad.bottom = display.text_height * display.scale * 0.3;

    return element;
}

/// Load and process text for a label.
pub fn create_checkbox(
    display: *Display,
    background_texture: []const u8,
    settings: Element,
) error{ OutOfMemory, ResourceNotFound, ResourceReadError, UnknownImageFormat }!*Element {
    var element = try display.allocator.create(Element);
    element.* = settings;
    if (element.focus == .unspecified) {
        element.focus = .can_focus;
    }
    element.texture = null;
    element.background_texture = null;

    if (element.type != .checkbox) {
        err("create_checkbox called without config.", .{});
        element.type = .{ .checkbox = .{ .text = "", .translated = "" } };
    }
    element.type.checkbox.translated = "";

    element.type.checkbox.elements = ArrayList(TextElement).init(display.allocator);
    try element.set_text(display, element.type.checkbox.text, true);

    if (try display.load_texture_resource("ios-checkbox-on")) |texture| {
        element.type.checkbox.on_texture = texture;
    }
    if (try display.load_texture_resource("ios-checkbox-off")) |texture| {
        element.type.checkbox.off_texture = texture;
    }

    // Is there a background for this label?
    if (try display.load_texture_resource(background_texture)) |texture| {
        element.background_texture = texture;
    }

    element.pad.left = display.text_height * display.scale * 0.8;
    element.pad.right = display.text_height * display.scale * 0.8;
    element.pad.top = display.text_height * display.scale * 0.3;
    element.pad.bottom = display.text_height * display.scale * 0.3;

    const size = display.checkbox();
    if (element.minimum.height < size.height) {
        element.minimum.height = size.height;
    }
    if (element.minimum.width < size.width) {
        element.minimum.width = size.width;
    }

    return element;
}

/// Load a button with textures for each state
pub fn create_button(
    display: *Display,
    icon_default: []const u8,
    icon_pressed: []const u8,
    icon_hover: []const u8,
    settings: Element,
    background_default: []const u8,
    background_pressed: []const u8,
    background_hover: []const u8,
) error{ OutOfMemory, ResourceNotFound, ResourceReadError, UnknownImageFormat }!*Element {
    var element = try display.allocator.create(Element);
    element.* = settings;
    element.texture = null;
    element.background_texture = null;
    if (element.focus == .unspecified) {
        element.focus = .can_focus;
    }

    if (element.type != .button) {
        err("create_button called without config.", .{});
        element.type = .{ .button = .{ .text = "" } };
    }
    element.type.button.translated = "";
    element.type.button.icon_pressed = null;
    element.type.button.icon_hover = null;
    element.type.button.background_pressed = null;
    element.type.button.background_hover = null;

    try element.set_text(display, element.type.button.text, true);

    if (icon_default.len > 0) {
        if (try display.load_texture_resource(icon_default)) |texture| {
            element.texture = texture;
            if (element.type.button.icon_size.x == 0 or element.type.button.icon_size.y == 0) {
                warn("button {s} has icon {s}, but no icon size.", .{ element.name, icon_default });
            }

            if (icon_pressed.len > 0) {
                if (try display.load_texture_resource(icon_pressed)) |ip| {
                    element.type.button.icon_pressed = ip;
                } else {
                    err("create_button failed to load icon_pressed resource {s}.", .{icon_pressed});
                }
            }
            if (element.type.button.icon_pressed == null) {
                element.type.button.icon_pressed = texture.clone();
            }

            if (icon_hover.len > 0) {
                if (try display.load_texture_resource(icon_hover)) |ih| {
                    element.type.button.icon_hover = ih;
                }
                if (element.type.button.icon_hover == null) {
                    element.type.button.icon_hover = texture.clone();
                }
            }
        } else {
            err("create_button failed to load icon_default resource {s}.", .{icon_default});
        }
    }

    if (background_default.len > 0) {
        if (try display.load_texture_resource(background_default)) |texture| {
            element.background_texture = texture;

            if (background_pressed.len > 0) {
                if (try display.load_texture_resource(background_pressed)) |bp| {
                    element.type.button.background_pressed = bp;
                } else {
                    err("create_button failed to load background_pressed resource {s}.", .{background_pressed});
                }
            }
            if (element.type.button.background_pressed == null) {
                element.type.button.background_pressed = texture.clone();
            }

            if (background_hover.len > 0) {
                if (try display.load_texture_resource(background_hover)) |bh| {
                    element.type.button.background_hover = bh;
                } else {
                    err("create_button failed to load background_hover resource {s}.", .{background_hover});
                }
            }
            if (element.type.button.background_hover == null) {
                element.type.button.background_hover = texture.clone();
            }
        } else {
            err("create_button failed to load background_default resource {s}.", .{background_default});
        }
    }

    return element;
}

/// Load and process text for a label.
pub fn create_text_input(
    display: *Display,
    text: []const u8,
    placeholder_text: []const u8,
    icon: []const u8,
    background: []const u8,
    settings: Element,
) error{ OutOfMemory, ResourceNotFound, ResourceReadError, UnknownImageFormat }!*Element {
    var element = try display.allocator.create(Element);
    element.* = settings;
    element.texture = null;
    element.background_texture = null;
    if (element.focus == .unspecified) {
        element.focus = .can_focus;
    }

    if (element.type != .text_input) {
        err("create_text_input called without config.", .{});
        element.type = .{ .text_input = .{} };
    }

    if (icon.len > 0) {
        if (try display.load_texture_resource(icon)) |texture| {
            element.texture = texture;
        } else {
            err("Failed to load text_input icon texture named \"{s}\"", .{icon});
        }
    }

    if (background.len > 0) {
        if (try display.load_texture_resource(background)) |texture| {
            element.background_texture = texture;
        } else {
            err("Failed to load text_input background texture named \"{s}\"", .{background});
        }
    }

    element.focus = .can_focus;
    element.pad.left = display.text_height * display.scale * 0.6;
    element.pad.right = display.text_height * display.scale * 0.6;
    element.pad.top = display.text_height * display.scale * 0.5;
    element.pad.bottom = display.text_height * display.scale * 0.5;
    element.rect.height = (display.text_height * display.scale) + (element.pad.top + element.pad.bottom);

    element.type.text_input.text = ArrayList(u8).init(display.allocator);
    element.type.text_input.placeholder_text = ArrayList(u8).init(display.allocator);
    element.type.text_input.runes = ArrayList(u21).init(display.allocator);
    try element.set_text(display, text, true);
    try element.set_placeholder_text(display, placeholder_text);

    return element;
}

/// Load a standard progress bar.
pub fn create_progress_bar(
    display: *Display,
    settings: Element,
) error{ OutOfMemory, ResourceNotFound, ResourceReadError, UnknownImageFormat }!*Element {
    var element = try display.allocator.create(Element);
    element.* = settings;
    element.texture = null;
    element.background_texture = null;
    if (element.focus == .unspecified) {
        element.focus = .never_focus;
    }

    if (element.type != .progress_bar) {
        err("create_progress_bar called without config.", .{});
        element.type = .{ .progress_bar = .{} };
    }

    if (try display.load_texture_resource("rounded progress bar")) |texture| {
        element.texture = texture;
    } else {
        err("Failed to load progress_bar texture named \"rounded progress bar\"", .{});
    }

    return element;
}

/// An expander should have a minimum height/width and a weight of zero, or
/// it may have a greater than zero weight.
///
/// When a panel has excess space, thie expander takes a percentage
/// of the space based on its weight.
pub fn create_expander(
    display: *Display,
    settings: Element,
) Allocator.Error!*Element {
    var element = try display.allocator.create(Element);
    element.* = settings;
    element.texture = null;
    element.background_texture = null;
    element.focus = .never_focus;

    if (element.type != .expander) {
        err("create_expander called without config.", .{});
        element.type = .{ .expander = .{} };
    }

    return element;
}

/// Load and associate an image file with a sprite name.
pub fn create_sprite(
    display: *Display,
    image: []const u8,
    settings: Element,
) error{ OutOfMemory, ResourceNotFound, ResourceReadError, UnknownImageFormat }!*Element {
    var element = try display.allocator.create(Element);
    element.* = settings;
    element.texture = null;
    element.background_texture = null;
    if (element.focus == .unspecified) {
        element.focus = .accessibility_focus;
    }

    if (element.type != .sprite) {
        err("create_sprite called without config.", .{});
        element.type = .{ .sprite = .{} };
    }

    if (try display.load_texture_resource(image)) |texture| {
        element.texture = texture;
    } else {
        err("Failed to load sprite texture named \"{s}\"", .{image});
    }

    return element;
}

/// A panel contains child items. The children are usually displayed
/// from left to right or top to bottom. A panel may also contain
/// floating items that appear anywhere on the screen, not just inside
/// the panel.
pub fn create_panel(
    display: *Display,
    background: []const u8,
    settings: Element,
) error{ OutOfMemory, ResourceNotFound, ResourceReadError, UnknownImageFormat }!*Element {
    var element = try display.allocator.create(Element);
    element.* = settings;
    element.texture = null;
    element.background_texture = null;

    if (element.type != .panel) {
        err("create_panel({s}) called without config.", .{element.name});
        element.type = .{ .panel = .{} };
    }

    if (element.focus == .unspecified) {
        if (element.type.panel.on_click != null) {
            element.focus = .can_focus;
        } else {
            element.focus = .never_focus;
        }
    }

    if (background.len > 0) {
        if (try display.load_texture_resource(background)) |texture| {
            element.background_texture = texture;
        } else {
            err("Failed to load panel background texture named \"{any}\"", .{background});
        }
    }

    element.type.panel.children = ArrayList(*Element).init(display.allocator);
    return element;
}

/// Read the first unicode character from a c string,
/// in the form of a slice.
inline fn c_unicode_to_slice(text: [*c]const u8) []const u8 {
    const l = std.unicode.utf8ByteSequenceLength(text[0]) catch return "";
    return text[0..l];
}

/// Read the first unicode character from a zero terminated
/// c string, in the form of an integer.
inline fn c_unicode_to_u21(text: [*c]const u8) u21 {
    const l = std.unicode.utf8ByteSequenceLength(text[0]) catch return text[0];
    return switch (l) {
        1 => text[0],
        2 => std.unicode.utf8Decode2(text[0..2].*),
        3 => std.unicode.utf8Decode3(text[0..3].*),
        4 => std.unicode.utf8Decode4(text[0..4].*),
        else => text[0],
    } catch text[0];
}

/// Return a formatter that outputs the list of available renderers, and
/// marking the current renderer that is in use.
fn driver_formatter(renderer: *sdl.SDL_Renderer) std.fmt.Formatter(list_drivers) {
    return .{ .data = .{ .renderer = renderer } };
}

fn list_drivers(
    context: struct { renderer: *sdl.SDL_Renderer },
    comptime _: []const u8,
    _: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    const current_driver = sdl.SDL_GetRendererName(context.renderer).?;
    const count = sdl.SDL_GetNumRenderDrivers();
    var i: c_int = 0;
    while (i < count) : (i += 1) {
        const driver = sdl.SDL_GetRenderDriver(i).?;
        if (i != 0) try writer.writeAll(", ");
        try writer.writeAll(std.mem.span(driver));
        if (std.mem.orderZ(u8, current_driver, driver) == .eq) {
            try writer.writeAll(" (selected)");
        }
    }
}

/// SDL provides extra information that is sometimes helpful for debugging, lets print this
/// information when we are in debug mode.
///
/// We don't need enums for this, but here is an example of how it could be handled.
/// https://github.com/Gota7/zig-sdl3/blob/9327bd69d7cbac728486d57bec05d35371a17737/src/log.zig
fn sdl_log_callback(
    data: ?*anyopaque,
    category: c_int,
    priority: sdl.SDL_LogPriority,
    message: [*c]const u8,
) callconv(.C) void {
    std.log.scoped(.term_scope).debug("SDL ({s}, {s}) {s}", .{
        @tagName(SdlLogCategory.fromInt(category)),
        @tagName(SdlLogPriority.fromInt(priority)),
        message,
    });
    _ = data;
}

/// Convert the SDL LogPriority into a zig enum. See:
/// https://wiki.libsdl.org/SDL3/SDL_LogCategory
pub const SdlLogPriority = enum(c_uint) {
    invalid = sdl.SDL_LOG_PRIORITY_INVALID,
    trace = sdl.SDL_LOG_PRIORITY_TRACE,
    verbose = sdl.SDL_LOG_PRIORITY_VERBOSE,
    debug = sdl.SDL_LOG_PRIORITY_DEBUG,
    info = sdl.SDL_LOG_PRIORITY_INFO,
    warn = sdl.SDL_LOG_PRIORITY_WARN,
    err = sdl.SDL_LOG_PRIORITY_ERROR,
    critical = sdl.SDL_LOG_PRIORITY_CRITICAL,
    count = sdl.SDL_LOG_PRIORITY_COUNT,
    unknown = 9999,

    pub fn fromInt(priority: c_uint) SdlLogPriority {
        return std.meta.intToEnum(SdlLogPriority, priority) catch .unknown;
    }
};

/// Convert the SDL LogCategory into a zig enum. See:
/// https://wiki.libsdl.org/SDL3/SDL_LogCategory
pub const SdlLogCategory = enum(c_int) {
    application = sdl.SDL_LOG_CATEGORY_APPLICATION,
    @"error" = sdl.SDL_LOG_CATEGORY_ERROR,
    assert = sdl.SDL_LOG_CATEGORY_ASSERT,
    system = sdl.SDL_LOG_CATEGORY_SYSTEM,
    audio = sdl.SDL_LOG_CATEGORY_AUDIO,
    video = sdl.SDL_LOG_CATEGORY_VIDEO,
    render = sdl.SDL_LOG_CATEGORY_RENDER,
    input = sdl.SDL_LOG_CATEGORY_INPUT,
    @"test" = sdl.SDL_LOG_CATEGORY_TEST,
    gpu = sdl.SDL_LOG_CATEGORY_GPU,
    custom = sdl.SDL_LOG_CATEGORY_CUSTOM,
    unknown = 9999,

    pub fn fromInt(category: c_int) SdlLogCategory {
        //return @enumFromInt(category);
        return std.meta.intToEnum(SdlLogCategory, category) catch .unknown;
    }
};

pub inline fn trace(comptime format: []const u8, args: anytype) void {
    if (dev_build and dev_mode) {
        std.log.debug(format, args);
    }
}

pub inline fn debug(comptime format: []const u8, args: anytype) void {
    if (dev_build or dev_mode) {
        std.log.debug(format, args);
    }
}

const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const log = std.log;
pub const info = std.log.info;
pub const warn = std.log.info;
pub const err = std.log.err;
const sdl = @import("sdl");
const builtin = @import("builtin");
pub const engine = @import("engine.zig");
pub const Animator = @import("animator.zig");
const praxis = @import("praxis");
const Lang = @import("praxis").Lang;
pub const Chunker = @import("chunker.zig").Chunker;
pub const Translation = @import("translation.zig").Translation;
const Resources = @import("resources").Resources;
const zigimg = @import("zigimg");

pub const BundleLoader = @import("read_bundle.zig");
pub const init_resource_loader = BundleLoader.init_resource_loader;
pub const sdl_load_bundle = BundleLoader.sdl_load_bundle;
pub const sdl_load_resource = BundleLoader.sdl_load_resource;

pub const std_options: std.Options = .{
    .log_level = .debug,
};

test "sdl_log_priority" {
    try std.testing.expectEqual(.info, SdlLogPriority.fromInt(sdl.SDL_LOG_PRIORITY_INFO));
    try std.testing.expectEqual(.unknown, SdlLogPriority.fromInt(999));
}

test "sdl_log_category" {
    try std.testing.expectEqual(.info, SdlLogPriority.fromInt(sdl.SDL_LOG_PRIORITY_INFO));
    try std.testing.expectEqual(.unknown, SdlLogPriority.fromInt(999));
}

const eq = std.testing.expectEqual;

test "init catch" {
    const allocator = std.testing.allocator;
    // The display takes ownership of the resources object
    //defer resources.destroy();
    var display = try Display.create(allocator, "test", "test", "test", "./test/repo", "test translation", 0);
    defer display.destroy();
}

test "button sizing" {
    const allocator = std.testing.allocator;
    // The display takes ownership of the resources object
    //defer resources.destroy();
    var display = try Display.create(allocator, "test", "test", "test", "./test/repo", "test translation", 0);
    defer display.destroy();

    var panel = try create_panel(display, "", .{
        .minimum = .{ .width = 5, .height = 8 },
        .type = .{ .panel = .{ .spacing = 0, .direction = .left_to_right } },
        .layout = .{ .x = .shrinks, .y = .shrinks },
    });
    try display.add_element(panel);
    try eq(5, panel.shrink_width(display, 500));
    try eq(8, panel.shrink_height(display, 500));

    const button = try create_button(display, "", "", "", .{
        .visible = .visible,
        .rect = .{ .width = 50, .height = 50 },
        .minimum = .{ .width = 42, .height = 41 },
        .maximum = .{ .width = 82, .height = 81 },
        .type = .{ .button = .{ .text = "" } },
    }, "", "", "");
    try eq(50, button.shrink_width(display, 500));
    try eq(50, button.shrink_height(display, 500));
    button.layout.x = .shrinks;
    button.layout.y = .shrinks;
    try eq(42, button.shrink_width(display, 500));
    try eq(41, button.shrink_height(display, 500));
    try panel.add_element(button);
    display.relayout();
    try eq(42, panel.shrink_width(display, 500));
    try eq(42, button.rect.width);
    try eq(5, panel.rect.width);
    try eq(41, button.rect.height);
    try eq(0, panel.rect.height);

    panel.pad.left = 2;
    panel.pad.right = 3;
    panel.pad.top = 4;
    panel.pad.bottom = 5;
    display.relayout();
    try eq(42, button.rect.width);
    try eq(5, panel.rect.width);
    try eq(41, button.rect.height);
    try eq(0, panel.rect.height);

    panel.minimum.width = 100;
    display.relayout();
    try eq(100, panel.shrink_width(display, 500));
    panel.minimum.width = 10;

    // Add test font so we can test label layout
    try std.testing.expect(display.resources.by_uid.count() > 0);
    _ = try display.load_font("Roboto-Light");

    try button.set_text(display, "Hello", true);
    display.relayout();
    try eq(83, @trunc(button.rect.width));
    try eq(100, @trunc(panel.rect.width));
    try eq(44, button.rect.height);
    try eq(0, panel.rect.height);
}

test "text input sizing" {
    const allocator = std.testing.allocator;
    // The display takes ownership of the resources object
    //defer resources.destroy();
    var display = try Display.create(allocator, "test", "test", "test", "./test/repo", "test translation", 0);
    defer display.destroy();

    // Add test font so we can test label layout
    try std.testing.expect(display.resources.by_uid.count() > 0);
    _ = try display.load_font("Roboto-Light");

    {
        // Create a fixed sized label with enough space
        const l = try create_label(display, "", .{
            .name = "hello",
            .rect = .{ .width = 500, .height = 60 },
            .minimum = .{ .width = 300, .height = 50 },
            .maximum = .{ .width = 401, .height = 201 },
            .type = .{ .label = .{ .text = "Hello world" } },
            .layout = .{ .x = .fixed, .y = .grows },
        });
        defer l.destroy(display, display.allocator);
        l.pad = .{ .top = 0, .bottom = 0, .left = 0, .right = 0 };
        try eq(500, l.shrink_width(display, 500));
        try eq(44, l.shrink_height(display, 500));
    }

    {
        // Create a fixed sized label with minimum
        const l = try create_label(display, "", .{
            .name = "hello",
            .rect = .{ .width = 500, .height = 60 },
            .minimum = .{ .width = 300, .height = 55 },
            .maximum = .{ .width = 401, .height = 201 },
            .type = .{ .label = .{ .text = "Hello world" } },
            .layout = .{ .x = .fixed, .y = .fixed },
        });
        defer l.destroy(display, display.allocator);
        l.pad = .{ .top = 0, .bottom = 0, .left = 0, .right = 0 };
        try eq(500, l.shrink_width(display, 500));
        try eq(60, l.shrink_height(display, 500));
    }

    {
        // Create a fixed sized label with minimum
        const l = try create_label(display, "", .{
            .name = "hello",
            .rect = .{ .width = 200, .height = 100 },
            .minimum = .{ .width = 300, .height = 20 },
            .maximum = .{ .width = 401, .height = 201 },
            .type = .{ .label = .{ .text = "Hello world" } },
            .layout = .{ .x = .grows, .y = .shrinks },
        });
        defer l.destroy(display, display.allocator);
        l.pad = .{ .top = 0, .bottom = 0, .left = 0, .right = 0 };
        try eq(300, l.shrink_width(display, 500));
        try eq(44, l.shrink_height(display, 500));
    }

    {
        // Create a fixed sized label with x growth
        const l = try create_label(display, "", .{
            .name = "hello",
            .rect = .{ .width = 1, .height = 1 },
            .minimum = .{ .width = 1, .height = 20 },
            .maximum = .{ .width = 401, .height = 201 },
            .type = .{ .label = .{ .text = "Hello world" } },
            .layout = .{ .x = .grows, .y = .shrinks },
        });
        defer l.destroy(display, display.allocator);
        l.pad = .{ .top = 0, .bottom = 0, .left = 0, .right = 0 };
        try eq(91, @round(l.shrink_width(display, 500)));
        try eq(44, l.shrink_height(display, 500));
    }

    {
        // Create a label with full shrinking
        const l = try create_label(display, "", .{
            .name = "hello",
            .rect = .{ .width = 1, .height = 1 },
            .minimum = .{ .width = 1, .height = 20 },
            .maximum = .{ .width = 401, .height = 201 },
            .type = .{ .label = .{ .text = "Hello world" } },
            .layout = .{ .x = .shrinks, .y = .shrinks },
        });
        defer l.destroy(display, display.allocator);
        l.pad = .{ .top = 0, .bottom = 0, .left = 0, .right = 0 };
        try eq(2, l.type.label.elements.items.len);
        try eq(98, @trunc(l.type.label.elements.items[0].width / display.scale));
        try eq(107, @trunc(l.type.label.elements.items[1].width / display.scale));
        try eq(90, @trunc(l.shrink_width(display, 500)));
        try eq(44, l.shrink_height(display, 500));
        try eq(88, l.shrink_height(display, 115));
    }

    const label = try create_label(display, "", .{
        .name = "hello",
        .rect = .{ .width = 500, .height = 60 },
        .minimum = .{ .width = 300, .height = 100 },
        .maximum = .{ .width = 401, .height = 201 },
        .type = .{ .label = .{ .text = "Hello world" } },
        .layout = .{ .x = .fixed, .y = .fixed },
    });
    label.pad = .{ .top = 0, .bottom = 0, .left = 0, .right = 0 };
    try eq(500, label.shrink_width(display, 500));
    try eq(100, label.shrink_height(display, 500));

    label.minimum.width = 22;
    label.minimum.height = 22;
    label.layout.x = .shrinks;
    label.layout.y = .shrinks;
    try eq(90, @trunc(label.shrink_width(display, 500)));
    try eq(44, @trunc(label.shrink_height(display, 500)));
    label.layout.x = .grows;
    try eq(91, @round(label.shrink_width(display, 500)));

    var panel = try create_panel(display, "", .{
        .rect = .{ .width = 500, .height = 200 },
        .minimum = .{ .width = 5, .height = 8 },
        .type = .{ .panel = .{ .spacing = 0, .direction = .top_to_bottom } },
        .layout = .{ .x = .shrinks, .y = .shrinks },
    });
    try display.add_element(panel);
    try eq(5, panel.shrink_width(display, 500));
    try eq(8, panel.shrink_height(display, 500));

    panel.layout.x = .shrinks;
    panel.layout.y = .shrinks;
    label.layout.x = .grows;
    label.layout.y = .shrinks;
    try panel.add_element(label);
    label.pad.top = 0;
    label.pad.bottom = 0;
    display.relayout();
    debug("size={d}x{d} min={d}x{d}  max={d}x{d} ", .{
        label.rect.width,
        label.rect.height,
        label.minimum.width,
        label.minimum.height,
        label.maximum.width,
        label.maximum.height,
    });
    // Two words wrapped, so the with is the width of the longest word.
    try eq(401, @round(label.rect.width)); // Label has 401 as maximum
    try eq(500, @trunc(panel.rect.width));
    // The height is two lines (44*2)
    try eq(44, @trunc(label.rect.height));
    try eq(200, @trunc(panel.rect.height));
}
