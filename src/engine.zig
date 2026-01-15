pub const dev_build = (builtin.mode == .Debug);
pub var dev_mode = false;

pub const FONT_SIZE: f32 = 22.0;
pub const FONT_MUL: f32 = 2.0;
pub const RESOURCE_BUNDLE_FILENAME = "resources.bd";

/// Errors specific to engine module
pub const Error = error{
    ResourceReadError,
    ResourceNotFound,
    UnknownImageFormat,
    AudioInitFailed,
    FontInitFailed,
    GraphicsInitFailed,
    WindowCreationFailed,
    GraphicsRendererFailed,
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
};

/// A rectangle desribes a point and an area.
pub const Rect = extern struct {
    x: f32 = 0,
    y: f32 = 0,
    width: f32 = 0,
    height: f32 = 0,

    /// Add the x and y value from the `other` vector to this vector.
    pub fn move(self: *Rect, offset: *const Vector) Rect {
        return .{
            .x = self.x + offset.x,
            .y = self.y + offset.y,
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
    x: bool = false,
    y: bool = false,
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

pub const Fit = enum {
    /// Stretch the image texture to the exact width and height of the
    /// `element.rect`.
    stretch,

    /// Maintaining the image aspect ratio, enlarge the textue image to
    /// the full width and height of the `element.rect`, and crop off
    /// any overflow.
    fill,

    /// Maintaining the image aspect ratio, enlarge the texture image to
    /// exactly fit within the boundary of the `element.rect` This will leave
    /// some horizontal or vertical space. Use `child_align` to place
    /// the texture at the `start`, `centre` or `end` of the element rect.
    fit,
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
    /// Starting at the top, place each element under the previous element.
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
    disabled,
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
    progress_bar,
    expander,
};

pub const Colour = struct {
    r: u8 = 0,
    g: u8 = 0,
    b: u8 = 0,
    a: u8 = 0,
};

pub const Background = struct {
    colour: Colour = TRANSPARENT,

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

pub const TRANSPARENT: Colour = .{ .r = 0, .g = 0, .b = 0, .a = 0 };
pub const WHITE: Colour = .{ .r = 255, .g = 255, .b = 255, .a = 255 };
pub const BLACK: Colour = .{ .r = 0, .g = 0, .b = 0, .a = 255 };

pub const Callback = struct {
    func: ?*const fn (ptr: *anyopaque, display: *Display, element: *Element, gpa: Allocator) Allocator.Error!void = null,
    ptr: *anyopaque = undefined,
};

pub const DisplayCallback = struct {
    func: ?*const fn (ptr: *anyopaque, display: *Display) Allocator.Error!void = null,
    ptr: *anyopaque = undefined,
};

pub const PanelChangeCallback = struct {
    func: ?*const fn (ptr: *anyopaque, display: *Display, from: ?*Element, to: *Element, gpa: Allocator) Allocator.Error!void = null,
    ptr: *anyopaque = undefined,
};

pub const BoolCallback = struct {
    func: ?*const fn (ptr: *anyopaque, display: *Display, element: *Element) bool = null,
    ptr: *anyopaque = undefined,
};

pub const U32Callback = struct {
    func: ?*const fn (ptr: *anyopaque, display: *Display, e: u32) Allocator.Error!void = null,
    ptr: *anyopaque = undefined,
};

pub const UpdateCallback = struct {
    func: ?*const fn (ptr: *anyopaque, display: *Display, element: *Element) void = null,
    ptr: *anyopaque = undefined,
};

/// Describe an element that will be rendered on the screen during a draw
/// loop. See `ElementType` for the types of elements that may be rendered.
pub const Element = struct {
    /// The `name` is not intended to be shown to the user. This name can
    /// be used by log and debug code to describe the element.
    name: []const u8 = "",

    /// Usually the `visibie` value is `.hidden` or `.visible`. If the
    /// element is inside a scroll panel, `.visible` elements may become
    /// `.clipped` when they are _visible_ do not need to be drawn.
    visible: Visibility = .visible,

    /// The size and posiiton if this element. If this element is
    /// inside the element heirachy, the position and size is automatically
    /// updated when the window is updated or resized. The `layout` variable
    /// determins if these values are automatically updated or remain fixed.
    rect: Rect = .{ .x = 0, .y = 0, .width = 0, .height = 0 },

    /// If this element is inside the element heirachy, this is a hard
    /// limit on how small the `rect` may be.
    minimum: Size = .{ .width = 0, .height = 0 },

    /// If this element is inside the element heirachy, this is a hard
    /// limit on how large the `rect` may be.
    maximum: Size = .{ .width = 0, .height = 0 },

    /// The `layout` settings determine if the `rect` is a fixed size
    /// and position, or if the `rect` size and position is autoatically
    /// updated inside the element heirachy.
    layout: Layout = .{ .x = .fixed, .y = .fixed },

    /// Panels contain child elements, and text elmeents contain words, and
    /// sprites contain an image. the `child_align` setting indicates if the
    /// child contents are drawn at the start, centre or end of this element.
    child_align: ChildLayout = .{ .x = .start, .y = .start },

    /// Scroll panels use 'offset` to track how far it has scrolled.
    offset: Vector = .{ .x = 0, .y = 0 },

    /// Padding is used to add space _inside_ the `rect` of this element.
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

    style: ThemeColour = .normal,
    colour: Colour = WHITE,

    background: Background = .{
        .colour = TRANSPARENT,
        .image = null,
        .image_name = null,
        .corner_radius = 0,
        .image_corner_radius = 0,
    },

    border_colour: Colour = TRANSPARENT,
    border_width: f32 = 0,

    on_resized: BoolCallback = .{ .func = null },
    on_visibility: Callback = .{ .func = null },

    type: union(ElementType) {
        panel: struct {
            children: ArrayListUnmanaged(*Element) = .empty,
            direction: LayoutDirection = .centre,
            spacing: f32 = 0,
            on_click: Callback = .{ .func = null },
            update: UpdateCallback = .{ .func = null },
            scrollable: Scroller = .{
                .scroll = .{ .x = false, .y = false },
                .size = .{ .width = 0, .height = 0 },
            },
            overflow: Vector = .{ .x = 0, .y = 0 },
        },
        sprite: struct {
            on_click: Callback = .{ .func = null },
            update: UpdateCallback = .{ .func = null },
            scale: Fit = .stretch,
        },
        label: struct {
            font: *Font = undefined,
            font_name: ?[]const u8 = null,
            text: []const u8 = "",
            translated: []const u8 = "",
            elements: ArrayListUnmanaged(TextElement) = .empty,
            line_height: f32 = 1,
            text_size: TextSize = .normal,
            on_click: Callback = .{ .func = null },
        },
        checkbox: struct {
            checked: bool = false,
            font: *Font = undefined,
            font_name: ?[]const u8 = null,
            text_size: TextSize = .normal,
            text: []const u8 = "",
            translated: []const u8 = "",
            elements: ArrayListUnmanaged(TextElement) = .empty,
            line_height: f32 = 1,
            on_texture: ?*Texture = null,
            off_texture: ?*Texture = null,
            on_change: Callback = .{ .func = null },
        },
        text_input: struct {
            font: *Font = undefined,
            font_name: ?[]const u8 = null,
            texture: ?*sdl.SDL_Texture = null,
            initial_text: ?[]const u8 = "",
            icon_texture_name: ?[]const u8 = "",
            text: ArrayListUnmanaged(u8) = .empty,
            runes: ArrayListUnmanaged(u21) = .empty,
            max_runes: usize = 0,
            cursor_character: usize = 0,
            cursor_pixels: f32 = 0,
            on_change: Callback = .{ .func = null },
            on_submit: Callback = .{ .func = null },
            placeholder_texture: ?*sdl.SDL_Texture = null,
            placeholder_text: ?[]const u8 = "",
            placeholder_translate: []const u8 = "",
        },
        rectangle: struct {},
        button: struct {
            font: *Font = undefined,
            font_name: ?[]const u8 = null,
            text_size: TextSize = .normal,
            text: []const u8 = "",
            translated: []const u8 = "",
            text_texture: ?*sdl.SDL_Texture = null,
            icon_size: Size = .{ .width = 0, .height = 0 },
            spacing: f32 = 0,
            icon_default_name: ?[]const u8 = null,
            icon_hover: ?*Texture = null,
            icon_hover_name: ?[]const u8 = null,
            icon_pressed: ?*Texture = null,
            icon_pressed_name: ?[]const u8 = null,
            icon_disabled: ?*Texture = null,
            icon_disabled_name: ?[]const u8 = null,
            background_default_name: ?[]const u8 = null,
            background_hover: ?*Texture = null,
            background_hover_name: ?[]const u8 = null,
            background_pressed: ?*Texture = null,
            background_pressed_name: ?[]const u8 = null,
            background_disabled: ?*Texture = null,
            background_disabled_name: ?[]const u8 = null,
            on_click: Callback = .{ .func = null },
            toggle: ToggleState = .no_toggle,
        },
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
            display.release_texture_resource(allocator, texture);
            self.texture = null;
        }

        if (self.background.image) |texture| {
            display.release_texture_resource(allocator, texture);
            self.background.image = null;
        }

        // Cleanup element type specific attributes
        switch (self.type) {
            .panel => |*i| {
                for (i.*.children.items) |child| {
                    child.destroy(display, allocator);
                }
                i.*.children.deinit(allocator);
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
                i.*.runes.deinit(allocator);
                i.*.text.deinit(allocator);
            },
            .label => |*i| {
                for (i.*.elements.items) |item| {
                    sdl.SDL_DestroyTexture(item.texture);
                }
                i.*.elements.deinit(allocator);
            },
            .checkbox => |*i| {
                for (i.*.elements.items) |item| {
                    sdl.SDL_DestroyTexture(item.texture);
                }
                if (i.*.on_texture) |texture| {
                    display.release_texture_resource(allocator, texture);
                    i.*.on_texture = null;
                }
                if (i.*.off_texture) |texture| {
                    display.release_texture_resource(allocator, texture);
                    i.*.off_texture = null;
                }
                i.*.elements.deinit(allocator);
            },
            .rectangle => {},
            .sprite => {},
            .button => |*i| {
                if (i.*.text_texture) |texture| {
                    sdl.SDL_DestroyTexture(texture);
                }
                if (i.*.icon_hover) |texture| {
                    display.release_texture_resource(allocator, texture);
                }
                if (i.*.icon_pressed) |texture| {
                    display.release_texture_resource(allocator, texture);
                }
                if (i.*.background_hover) |texture| {
                    display.release_texture_resource(allocator, texture);
                }
                if (i.*.background_pressed) |texture| {
                    display.release_texture_resource(allocator, texture);
                }
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
        if (self.type == .panel and
            (self.type.panel.scrollable.scroll.x or self.type.panel.scrollable.scroll.y))
        {
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

    inline fn button_text_tint(self: *Element, theme: *Theme) Colour {
        if (self.style == .success) return theme.success_text_colour;
        if (self.style == .failed) return theme.failed_text_colour;
        if (self.style == .custom) return self.colour;
        if (self.pressed) return theme.tinted_text_colour;
        if (self.hovered) return theme.tinted_text_colour;

        return theme.text_colour;
    }

    inline fn apply_background_tint(
        self: *Element,
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
                    if (self.background.colour.a != engine.TRANSPARENT.a)
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
                .no_toggle, .disabled => tint_texture(texture, engine.WHITE),
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
                    tint_texture(texture, engine.WHITE);
                },
            }
            return;
        }

        if (self.type == .sprite) {
            if (self.background.colour.a != 0) {
                tint_texture(texture, self.background.colour);
            } else {
                tint_texture(texture, engine.WHITE);
            }
            return;
        }

        if (self.type == .label) {
            tint_texture(texture, display.theme.label_background_colour);
            return;
        }

        tint_texture(texture, engine.WHITE);
    }

    fn tint_texture(texture: *sdl.SDL_Texture, colour: Colour) void {
        _ = sdl.SDL_SetTextureAlphaMod(texture, colour.a);
        _ = sdl.SDL_SetTextureColorMod(texture, colour.r, colour.g, colour.b);
    }

    /// An icon may have different background textures for hovered,
    /// pressed and normal state. Return the background that is valid
    /// for the current state.
    inline fn current_background(self: *Element) ?*sdl.SDL_Texture {
        if (self.type == .button) {
            if (self.type.button.toggle == .disabled)
                return self.type.button.background_disabled.?.texture;
            if (self.pressed and self.type.button.background_pressed != null)
                return self.type.button.background_pressed.?.texture;
            if (self.hovered and self.type.button.background_hover != null)
                return self.type.button.background_hover.?.texture;
        }
        if (self.background.image != null)
            return self.background.image.?.texture;
        return null;
    }

    /// An icon may have different image textures for hovered, pressed
    /// and normal state. Return the image that is valid for the current state.
    inline fn current_icon(self: *Element) ?*sdl.SDL_Texture {
        if (self.type == .button) {
            if (self.pressed and self.type.button.icon_pressed != null)
                return self.type.button.icon_pressed.?.texture;
            if (self.hovered and self.type.button.icon_hover != null)
                return self.type.button.icon_hover.?.texture;
        }
        if (self.texture != null)
            return self.texture.?.texture;
        return null;
    }

    /// The text_input element may display placeholder text when there
    /// is no text in the text_input. Placeholder text should be less
    /// visibily prominent.
    pub inline fn set_placeholder_text(
        self: *Element,
        _: Allocator,
        display: *Display,
        text: []const u8,
    ) !void {
        debug(
            "set_placeholder_text({s}.{s}) {s}",
            .{ @tagName(self.type), self.name, text },
        );
        switch (self.type) {
            .text_input => {
                if (self.type.text_input.placeholder_texture) |texture| {
                    sdl.SDL_DestroyTexture(texture);
                    self.texture = null;
                }
                if (text.len == 0) return;
                self.type.text_input.placeholder_text = text;
                if (display.generate_text_texture(self.type.text_input.placeholder_text.?, self.type.text_input.font)) |texture| {
                    self.type.text_input.placeholder_texture = texture;
                }
            },
            else => {
                info("set_placeholder_text({s}.{s}) invalid", .{ @tagName(self.type), text });
            },
        }
    }

    /// Show or hide this element. If the visibliity is changed a relayout
    /// will be triggerd, and the `on_visibility` callback will be triggered
    /// if a callback is specified.
    pub inline fn set_visibility(self: *Element, display: *Display, visible: Visibility) Allocator.Error!void {
        if (self.visible == visible) return;
        self.visible = visible;
        display.need_relayout = true;
        if (self.on_visibility.func != null) {
            try self.on_visibility.func.?(self.on_visibility.ptr, display, self, display.allocator);
        }
    }

    /// Replace the foreground texture with an image resource found
    /// in the default resource bundle.
    ///
    /// `set_texture` is only valid on elements that permit a
    /// foreground texture.
    pub inline fn set_texture(
        self: *Element,
        allocator: Allocator,
        display: *Display,
        name: []const u8,
    ) error{OutOfMemory}!void {
        const texture = display.load_texture(allocator, name) catch |f| {
            err("set_texture({s}) error loading texture. {any}", .{ name, f });
            return;
        };
        if (texture != null) {
            if (self.texture != null) {
                display.release_texture_resource(allocator, self.texture.?);
            }
            self.texture = texture.?;
        } else {
            err("set_texture({s}) resource not found", .{name});
        }
    }

    /// Replace the current background texture with an image resource
    /// found in the default resource bundle.
    ///
    /// `set_background_texture` is only valid on elements that permit a
    /// background texture.
    pub inline fn set_background_texture(
        self: *Element,
        allocator: Allocator,
        display: *Display,
        name: []const u8,
    ) error{OutOfMemory}!void {
        const texture = display.load_texture(allocator, name) catch |f| {
            err("set_background_texture({s}) error loading texture. {any}", .{ name, f });
            return;
        };
        if (texture != null) {
            if (self.background.image != null)
                display.release_texture_resource(allocator, self.background.image.?);
            self.background.image = texture.?;
        } else {
            err("set_background_texture({s}) resource not found", .{name});
        }
    }

    /// Replace the current image texture with a a texture from a resource
    /// bundle. Returns null if the resource name does not exist.
    pub inline fn set_image(
        self: *Element,
        gpa: Allocator,
        display: *Display,
        repository: *Resources,
        name: []const u8,
    ) (Allocator.Error || Resources.Error || engine.Error)!?*Texture {
        const start = std.time.milliTimestamp();
        const texture = try display.load_bundle_texture(gpa, repository, name);
        if (texture == null) {
            info("set_image failed to find image resource named \"{s}\"", .{name});
            return null;
        }
        const end = std.time.milliTimestamp();
        debug("set_image loaded image named \"{s}\" in {d}ms", .{ name, end - start });
        self.texture_name = name;

        if (self.texture != null) {
            display.release_texture_resource(gpa, self.texture.?);
            self.texture = null;
        }
        self.texture = texture.?;
        return texture;
    }

    /// Remove the foreground texture if a texture has been set.
    pub inline fn clear_image(
        self: *Element,
        gpa: Allocator,
        display: *Display,
    ) void {
        if (self.texture != null) {
            display.release_texture_resource(gpa, self.texture.?);
            self.texture = null;
        }
    }

    pub inline fn set_background_image(
        self: *Element,
        gpa: Allocator,
        display: *Display,
        repository: *Resources,
        name: []const u8,
    ) (Allocator.Error || Resources.Error || engine.Error)!?*Texture {
        const texture = try display.load_bundle_texture(gpa, repository, name);
        if (texture == null) {
            info("set_image failed to find image resource named \"{s}\"", .{name});
            return null;
        }
        debug("set_background_image loaded image named \"{s}\"", .{name});

        if (self.background.image != null) {
            display.release_texture_resource(gpa, self.background.image.?);
            self.background.image = null;
        }
        self.background.image = texture.?;
        return texture;
    }

    /// Remove the background texture if a texture has been set.
    pub inline fn clear_background_image(
        self: *Element,
        gpa: Allocator,
        display: *Display,
    ) void {
        if (self.background.image != null) {
            display.release_texture_resource(gpa, self.background.image.?);
            self.background.image = null;
        }
    }

    /// set_text updates the `text` and `translation` fields of labels,
    /// checkboxes and buttons, and regenerates the grahpics/image
    /// textures for each word if the text was changed or `forced`
    /// is requested.
    pub inline fn set_text(
        self: *Element,
        allocator: Allocator,
        display: *Display,
        new_text: []const u8,
        forced: bool,
    ) error{OutOfMemory}!void {
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
            // TODO: This should not be needed
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
                    try self.type.text_input.text.appendSlice(allocator, new_text);
                    self.text_data_to_runes(allocator);
                    if (display.generate_text_texture(self.type.text_input.text.items, self.type.text_input.font)) |texture| {
                        self.type.text_input.cursor_pixels = TextSize.normal.pixel_size(display, texture).width;
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
                        if (display.generate_text_texture(text, self.type.label.font)) |texture| {
                            try self.type.label.elements.append(allocator, .{
                                .text = text,
                                .width = @floatFromInt(texture.*.w),
                                .texture = texture,
                                .location = .{}, // Location of each element is unknown at this point
                            });
                        }
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
                        if (display.generate_text_texture(text, self.type.checkbox.font)) |texture| {
                            try self.type.checkbox.elements.append(allocator, .{
                                .text = text,
                                .width = @floatFromInt(texture.*.w),
                                .texture = texture,
                                .location = .{}, // Location of each element is unknown at this point
                            });
                        }
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
                    if (display.generate_text_texture(self.type.button.translated, self.type.button.font)) |texture| {
                        self.type.button.text_texture = texture;
                    }
                }
            },
            else => {
                warn("set_text({s}) invalid for {s}", .{ @tagName(self.type), new_text });
            },
        }
        if (self.visible != .hidden) display.need_relayout = true;
    }

    /// `add` a child element to this panel and return the element. Only
    /// permitted for the `panel` element type.
    pub inline fn add(
        self: *Element,
        allocator: Allocator,
        display: *Display,
        conf: Element,
    ) (Error || Allocator.Error || Resources.Error)!*Element {
        std.debug.assert(self.type == .panel);
        const child = try allocator.create(Element);
        child.* = conf;
        try display.setup_element(allocator, child);
        try self.type.panel.children.append(allocator, child);
        if (child.visible != .hidden and self.visible != .hidden)
            display.need_relayout = true;
        return child;
    }

    /// Use `insert_element` to insert a child element in a specific location
    /// in this panel. Only permitted for the `panel` element type.
    pub inline fn insert_element(
        self: *Element,
        allocator: Allocator,
        display: *Display,
        conf: Element,
        location: usize,
    ) (Error || Allocator.Error || Resources.Error)!*Element {
        std.debug.assert(self.type == .panel);
        std.debug.assert(location <= self.type.panel.children.items.len);
        const child = try allocator.create(Element);
        child.* = conf;
        try display.setup_element(allocator, child);
        try self.type.panel.children.insert(allocator, location, child);
        if (child.visible != .hidden and self.visible != .hidden)
            display.need_relayout = true;
        return child;
    }

    /// Swap the ordering of two child elements belonging to this panel.
    pub inline fn swap(self: *Element, from: usize, to: usize) void {
        std.debug.assert(self.type == .panel);
        std.debug.assert(from < self.type.panel.children.items.len);
        std.debug.assert(to < self.type.panel.children.items.len);
        const s = self.type.panel.children.items[from];
        self.type.panel.children.items[from] = self.type.panel.children.items[to];
        self.type.panel.children.items[to] = s;
    }

    /// Use `remove_element_at` to attach a child element in a specific location
    /// in this panel. Only permitted for the `panel` element type.
    pub inline fn remove_element_at(self: *Element, display: *Display, location: usize) *Element {
        std.debug.assert(self.type == .panel);
        std.debug.assert(location < self.type.panel.children.items.len);
        const item = self.type.panel.children.orderedRemove(location);
        if (item.visible != .hidden) display.need_relayout = true;
        return item;
    }

    /// Use `remove_element` to remove a panel that is a
    /// child of this element.
    pub inline fn remove_element(
        self: *Element,
        display: *Display,
        child: *Element,
    ) ?*Element {
        std.debug.assert(self.type == .panel);
        child.clear_display_pointers(display);
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

    /// Make sure nothing is holding a reference to an element that
    /// is being removed from the display.
    fn clear_display_pointers(self: *Element, display: *Display) void {
        if (display.selected == self) display.selected = null;
        if (display.hovered == self) display.hovered = null;
        if (self.type == .panel) {
            for (self.type.panel.children.items) |element| {
                element.clear_display_pointers(display);
            }
        }
    }

    /// Animations, and used provided code may be updated inside the
    /// update function. This is called prior to the `draw` function.
    pub fn update(self: *Element, display: *Display) void {
        if (self.type == .sprite) {
            if (self.type.sprite.update.func) |f|
                f(self.type.sprite.update.ptr, display, self);
        }
        if (display.need_relayout) display.relayout();

        if (self.velocity.x > 0)
            self.rect.x += self.velocity.x;

        if (self.velocity.y > 0)
            self.rect.y += self.velocity.y;

        if (self.type == .panel) {
            if (self.type.panel.update.func) |f|
                f(self.type.panel.update.ptr, display, self);
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
        if (self.visible == .hidden)
            return 0;
        if (self.layout.y == .fixed)
            return @max(self.minimum.height, self.rect.height);

        const height = switch (self.type) {
            .label, .checkbox => {
                // Simulate a draw of this element to see how many lines it
                // would take. This is done when the label is created but also
                // needs to be done here as the width of the label may have changed.
                switch (self.layout.y) {
                    .shrinks, .grows => {
                        self.layout_label(display, parent_width);
                        //err("{s} {s} use grows height {d} (parent_width={d})", .{ self.name, @tagName(self.type), mm.max_height, parent_width });
                        return self.rect.height;
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
                height = @max(self.type.button.icon_size.height, height);
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
        if (self.visible == .hidden)
            return 0;

        if (self.layout.x == .fixed)
            return @max(self.minimum.width, self.rect.width);

        switch (self.type) {
            .panel => {
                return @max(self.minimum.width, find_minimum_panel_width(self, display));
            },
            .button => {
                var width: f32 = self.pad.left + self.pad.right;

                width += self.type.button.icon_size.width;

                // Do we need to pad between icon and text?
                if (self.type.button.icon_size.width > 0 and self.type.button.text.len > 0) {
                    width += self.type.button.spacing;
                }

                if (self.type.button.text_texture) |t| {
                    const size = self.type.button.text_size.pixel_size(display, t);
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
                        self.layout_label(display, parent_width);
                        return self.rect.width;
                    },
                    .fixed => {
                        return self.rect.width;
                    },
                }
            },
            .checkbox => {
                switch (self.layout.x) {
                    .shrinks, .grows => {
                        // Growing or shrinking, our task here is to find
                        // the minimum that would be needed.
                        self.layout_label(display, parent_width);
                        //err("{s} {s} use width {d}", .{ self.name, @tagName(self.type), choose });
                        return self.rect.width + self.pad.left + display.checkbox().width;
                    },
                    .fixed => {
                        //err("{s} {s} use width {d}", .{ self.name, @tagName(self.type), choose });
                        return self.rect.width;
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
    fn language_changed(self: *Element, allocator: Allocator, display: *Display, lang: Lang) !void {
        switch (self.type) {
            .label => try self.set_text(allocator, display, self.type.label.text, false),
            .checkbox => try self.set_text(allocator, display, self.type.checkbox.text, false),
            .button => try self.set_text(allocator, display, self.type.button.text, false),
            .panel => for (self.type.panel.children.items) |child| {
                try child.language_changed(allocator, display, lang);
            },
            else => {},
        }
    }

    /// Draw the current element, along with any children elements.
    pub fn draw(element: *Element, display: *Display, parent_scroll_offset: Vector, parent_clip: ?Clip) void {
        if (element.visible == .hidden)
            return;

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
        if (element.visible == .culled)
            element.visible = .visible;

        // Elements may optionally have a background texture or a simple
        // filled background.
        if (element.background.image) |texture| {
            // Buttons do not use the background.image or backgroud.image_name
            // field, so don't draw background image for buttons.
            if (element.type != .button) {
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
                if (element.background.image_corner_radius == 0) {
                    _ = sdl.SDL_RenderTexture(display.renderer, texture.texture, null, @ptrCast(&dest));
                } else {
                    var corner: f32 = element.background.corner_radius;
                    if (corner * 2 > dest.height) corner = dest.height / 2;
                    _ = sdl.SDL_RenderTexture9Grid(
                        display.renderer,
                        texture.texture,
                        null,
                        element.background.image_corner_radius,
                        element.background.image_corner_radius,
                        element.background.image_corner_radius,
                        element.background.image_corner_radius,
                        corner / element.background.image_corner_radius,
                        @ptrCast(&dest),
                    );
                }
            }
        } else if (element.background.colour.a > 0 and element.type != .rectangle and element.type != .sprite) {
            // If there is no background image, but there is a background
            // colour, draw the background as a simple rectangle (except for
            // sprites and rectangles).
            _ = sdl.SDL_SetRenderDrawColor(
                display.renderer,
                element.background.colour.r,
                element.background.colour.g,
                element.background.colour.b,
                element.background.colour.a,
            );
            _ = sdl.SDL_RenderFillRect(display.renderer, @ptrCast(&element.rect));
        }

        switch (element.type) {
            .panel => element.draw_panel(display, parent_scroll_offset, parent_clip, scroll_offset),
            .button => element.draw_button(display, parent_scroll_offset, parent_clip, scroll_offset),
            .checkbox => element.draw_checkbox(display, parent_scroll_offset, parent_clip, scroll_offset),
            .text_input => element.draw_text_input(display, parent_scroll_offset, parent_clip),
            .sprite => element.draw_sprite(display, parent_scroll_offset, parent_clip, scroll_offset),
            .rectangle => element.draw_rectangle_element(display, parent_scroll_offset, parent_clip, scroll_offset),
            .label => element.draw_label(display, parent_scroll_offset, parent_clip),
            .progress_bar => element.draw_progress_bar(display, parent_scroll_offset, parent_clip),
            .expander => {},
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
                .{},
            );
            if (element.type == .panel and (element.type.panel.scrollable.scroll.x or element.type.panel.scrollable.scroll.y)) {
                draw_rectangle(
                    display.renderer,
                    2,
                    display.theme.success_panel_colour,
                    element.rect,
                    .{},
                );
            } else if (element.type == .label) {
                var pad_line = element.rect.move(&scroll_offset);
                pad_line.x += element.pad.left;
                pad_line.y += element.pad.top;
                pad_line.width -= (element.pad.left + element.pad.right);
                pad_line.height -= (element.pad.top + element.pad.bottom);
                draw_rectangle(
                    display.renderer,
                    2,
                    display.theme.faded_text_colour,
                    pad_line,
                    .{},
                );
            } else if (element.type == .button) {
                // inner padding line
                colour = display.theme.tinted_text_colour;
                draw_rectangle(display.renderer, 2, colour, .{
                    .x = element.rect.x + scroll_offset.x + element.pad.left,
                    .y = element.rect.y + scroll_offset.y + element.pad.top,
                    .width = element.rect.width - (element.pad.left + element.pad.right),
                    .height = element.rect.height - (element.pad.top + element.pad.bottom),
                }, .{});
            }
        } else if (element.border_width > 0 and element.border_colour.a > 0) {
            draw_rectangle(
                display.renderer,
                element.border_width,
                element.border_colour,
                element.rect.move(&scroll_offset),
                .{},
            );
        }

        // Any element can have a selection underline
        if (display.selected != null and display.selected == element) {
            if (element.type != .text_input) {
                if (display.keyboard_selected) {
                    draw_selection_marker(
                        display,
                        display.renderer,
                        display.theme.cursor_colour,
                        element.rect.move(&scroll_offset),
                    );
                }
            }
        }
    }

    /// Draw the contents of a panel.
    inline fn draw_panel(
        element: *Element,
        display: *Display,
        _: Vector,
        parent_clip: ?Clip,
        scroll_offset: Vector,
    ) void {
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

    /// Draw a basic rectangle.
    inline fn draw_rectangle_element(
        element: *Element,
        display: *Display,
        _: Vector,
        _: ?Clip,
        scroll_offset: Vector,
    ) void {
        const colour = element.style.panel(display.theme, element.background.colour);
        _ = sdl.SDL_SetRenderDrawColor(
            display.renderer,
            colour.r,
            colour.g,
            colour.b,
            colour.a,
        );
        var dest = element.rect.move(&scroll_offset);
        _ = sdl.SDL_RenderFillRect(display.renderer, @ptrCast(&dest));
    }

    /// Draw a text input box along with any text or cursor that
    /// may appear inside the text input box.
    inline fn draw_text_input(
        element: *Element,
        display: *Display,
        _: Vector,
        _: ?Clip,
    ) void {
        var x = element.rect.x + element.pad.left;
        const y = element.rect.y + element.pad.top;
        const word_spacing = display.text_height / 4.0 * display.scale;

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
                const size = TextSize.normal.pixel_size(display, texture);
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
                const size = TextSize.normal.pixel_size(display, texture);
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

    /// Draw the foreground image `texture` of the sprite loaded from the
    /// `texture_name` string. Does not draw the `background.image` texture.
    /// The background image is drawn in the generic background drawing function.
    inline fn draw_sprite(
        element: *Element,
        display: *Display,
        _: Vector,
        _: ?Clip,
        scroll_offset: Vector,
    ) void {
        //debug("ds {s} {d}x{d}", .{ element.name, element.rect.width, element.rect.height });
        if (element.texture) |texture| {
            var dest: Rect = .{
                .x = element.rect.x + element.pad.left,
                .y = element.rect.y + element.pad.top,
                .width = element.rect.width - element.pad.left - element.pad.right,
                .height = element.rect.height - element.pad.top - element.pad.bottom,
            };
            dest = dest.move(&scroll_offset);

            if (dest.height <= 0 or dest.width <= 0) return;

            if (element.flip.x) {
                dest.x += dest.width;
                dest.width = 0 - dest.width;
            }
            if (element.flip.y) {
                dest.y += dest.height;
                dest.height = 0 - dest.height;
            }

            // TODO: Sprites might have frames

            // Stretch the full image onto the drawing area
            const image_width = @as(f32, @floatFromInt(texture.texture.w));
            const image_height = @as(f32, @floatFromInt(texture.texture.h));
            var source: sdl.SDL_FRect = undefined;
            switch (element.type.sprite.scale) {
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
                    const dst_scale: f32 = element.rect.width / element.rect.height;
                    const src_scale: f32 = image_width / image_height;
                    if (src_scale >= dst_scale) {
                        // image too wide, hight will have blank space
                        dest.height = dest.width / src_scale;
                        // sprite is drawn at top of its rect, unless a
                        // different child alignment is chosen.
                        switch (element.child_align.y) {
                            .start => {}, // already at top
                            .centre => dest.y += ((element.rect.height - dest.height) / 2) - element.pad.top,
                            .end => dest.y += (element.rect.height - dest.height),
                        }
                    } else {
                        // image too tall/high, width will have blank space
                        dest.width = dest.height * src_scale;
                        // sprite is drawn at start/left of its rect, unless
                        // a different child alignment is chosen.
                        switch (element.child_align.x) {
                            .start => {}, // already at top
                            .centre => dest.x += ((element.rect.width - dest.width) / 2) - element.pad.left,
                            .end => dest.x += (element.rect.width - dest.width),
                        }
                    }
                },
                .fill => {
                    // We need a slice of the source image that fits the
                    // ratio of the destination area.
                    const dst_scale: f32 = element.rect.width / element.rect.height;
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

            if (element.style == .custom)
                tint_texture(texture.texture, element.colour);

            _ = sdl.SDL_RenderTexture(display.renderer, texture.texture, @ptrCast(&source), @ptrCast(&dest));
        }
    }

    /// Calculate the layout of all elements, and optionally render every element.
    ///
    /// Normally text is converted to an image and rendered left to right, starting
    /// at the top left corner of the element (including padding).
    ///
    /// If the text is centred or right aligned, then each line must be pushed along
    /// by a certain offset amount.
    inline fn draw_label(
        element: *Element,
        display: *Display,
        scroll_offset: Vector,
        parent_clip: ?Clip,
    ) void {
        std.debug.assert(element.type == .label or element.type == .checkbox);

        const children = switch (element.type) {
            .label => element.type.label.elements.items,
            .checkbox => element.type.checkbox.elements.items,
            else => unreachable,
        };
        var loc = Vector{
            .x = element.rect.x + element.pad.left + scroll_offset.x,
            .y = element.rect.y + element.pad.top + scroll_offset.y,
        };
        for (children) |*item| {
            const pos = item.location.move(&loc);
            if (parent_clip) |clip| {
                if (pos.x + pos.width < clip.left) continue;
                if (pos.y + pos.height + 1 < clip.top) continue;
                if (pos.x > clip.right) continue;
                if (pos.y > clip.bottom) continue;
            }

            // Only render text if display parameter is provided
            const current_colour = element.style.text(display.theme, element.colour);
            _ = sdl.SDL_SetTextureColorMod(
                item.texture,
                current_colour.r,
                current_colour.g,
                current_colour.b,
            );
            _ = sdl.SDL_SetTextureAlphaMod(item.texture, current_colour.a);
            _ = sdl.SDL_RenderTexture(
                display.renderer,
                item.texture,
                null,
                @ptrCast(&pos),
            );
        }
    }

    /// Calculate the layout of all elements, and optionally render every element.
    ///
    /// Normally text is converted to an image and rendered left to right, starting
    /// at the top left corner of the element (including padding).
    ///
    /// If the text is centred or right aligned, then each line must be pushed along
    /// by a certain offset amount.
    inline fn layout_label(
        element: *Element,
        display: *Display,
        max_parent_width: f32,
    ) void {
        std.debug.assert(element.type == .label or element.type == .checkbox);

        if (element.type == .label and element.type.label.text.len == 0) return;
        if (element.type == .checkbox and element.type.checkbox.text.len == 0) return;

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

        // Track the minimum needed width. Remember the longest line. Include
        // any left/right padding.
        var needed_width: f32 = 0;

        const word_spacing = display.text_height * display.scale * text_height.height() / 3.5;

        var x: f32 = 0;
        var y: f32 = 0;

        const wrap_at: f32 = word_wrap_line(element, display, max_parent_width);

        // A line must have at least one word before a line break is inserted
        // otherwise we are just drawing pointless broken blank lines.
        var line_word_count: usize = 0;
        var current_child: usize = 0;

        // Lay down each word one by one and wrap before we hit the
        // `wrap_at` boundary.
        for (children, 0..) |*item, i| {
            const is_cr = item.text != null and item.text.?.len == 1 and item.text.?[0] == '\n';
            const size = text_height.pixel_size(display, item.texture);
            // Would drawing this word overflow?
            if ((x + size.width > wrap_at and line_word_count > 0) or is_cr) {
                needed_width = @max(needed_width, x);
                // Wrap to next line
                x = 0;
                y += size.height;
                line_word_count = 0;
                current_child = i;
            }

            if (line_word_count > 0 and !is_cr) x += word_spacing;

            item.location = .{
                .x = @round(x),
                .y = @round(y),
                .width = if (is_cr) 0 else size.width,
                .height = size.height,
            };

            if (!is_cr) x += size.width;
            if (!is_cr) line_word_count += 1;
        }
        needed_width = @max(needed_width, x);

        if (children.len > 0) {
            if (current_child != children.len) {
                const size = text_height.pixel_size(display, children[current_child].texture);
                y += size.height;
            }
        }

        // Add y padding at the bottom so that we can calculate the final height.
        var needed_height = y + element.pad.top + element.pad.bottom;
        needed_height = @ceil(needed_height);

        switch (element.layout.y) {
            .shrinks => {
                // Shrinkable means take the smallest size it needs
                element.rect.height = @max(needed_height, element.minimum.height);
                if (element.maximum.height > 0)
                    element.rect.height = @min(element.rect.height, element.maximum.height);
            },
            .grows => {
                // Growable must use at least the size it needs
                element.rect.height = @max(needed_height, element.minimum.height);
                if (element.maximum.height > 0)
                    element.rect.height = @min(element.rect.height, element.maximum.height);
            },
            .fixed => {
                // Fixed sized objects are ignored by the layout
                // algorithm. Keep the requested fixed height.
            },
        }

        needed_width += element.pad.left + element.pad.right;
        needed_width = @ceil(needed_width);

        switch (element.layout.x) {
            .shrinks => {
                // Shrinkable means take the smallest size it needs
                element.rect.width = @max(needed_width, element.minimum.width);
                if (element.maximum.width > 0)
                    element.rect.width = @min(element.rect.width, element.maximum.width);
            },
            .grows => {
                // Growable must use at least the size it needs
                element.rect.width = @max(needed_width, element.minimum.width);
                element.rect.width = @max(element.rect.width, max_parent_width);
                if (element.maximum.width > 0)
                    element.rect.width = @min(element.rect.width, element.maximum.width);
            },
            .fixed => {
                // Fixed sized objects are ignored by the layout
                // algorithm. Keep the reqeusted fixed width.
            },
        }

        // Align words to centre or right if requested.
        if (children.len == 0) return;
        if (element.child_align.x == .centre or element.child_align.x == .end) {
            var line_start: usize = 0;
            var line_end: usize = 0;
            while (true) : (line_end += 1) {
                if (line_end + 1 == children.len) {
                    element.do_word_alignment(
                        children[line_end].location.x + children[line_end].location.width,
                        element.rect.width,
                        children[line_start .. line_end + 1],
                    );
                    break;
                }
                if (children[line_end].location.x >= children[line_end + 1].location.x) {
                    element.do_word_alignment(
                        children[line_end].location.x + children[line_end].location.width,
                        element.rect.width,
                        children[line_start .. line_end + 1],
                    );
                    line_start = line_end + 1;
                    continue;
                }
            }
        }

        const t = switch (element.type) {
            .button => element.type.button.translated,
            .label => element.type.label.translated,
            .checkbox => element.type.checkbox.translated,
            else => "",
        };
        trace("label {s} {t} \"{s}\" wrap={d} need={d} selected={d} (max_parent_width={d})", .{
            element.name,
            element.layout.x,
            t,
            wrap_at,
            needed_width,
            element.rect.width,
            max_parent_width,
        });
    }

    /// Draw a radio box combined with a text label.
    inline fn draw_checkbox(element: *Element, display: *Display, _: Vector, _: ?Clip, scroll_offset: Vector) void {
        const checkbox = display.checkbox();
        element.draw_label(display, scroll_offset, null);
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

    /// Draw a progress bar.
    inline fn draw_progress_bar(element: *Element, display: *Display, _: Vector, _: ?Clip) void {
        // Draw the background matching the  current button state
        if (element.texture) |texture| {
            // Progress bar background
            var tint = display.theme.progress_bar_background;
            var dest: Rect = .{
                .x = element.rect.x + element.pad.left,
                .y = element.rect.y + element.pad.top,
                .width = element.rect.width - element.pad.left - element.pad.right,
                .height = element.rect.height - element.pad.top - element.pad.bottom,
            };
            _ = sdl.SDL_SetTextureAlphaMod(texture.texture, tint.a);
            _ = sdl.SDL_SetTextureColorMod(texture.texture, tint.r, tint.g, tint.b);
            var corner: f32 = element.background.corner_radius;
            if (corner * 2 > dest.height) corner = dest.height / 2;

            // Progress bar background
            if (element.background.image_corner_radius == 0) {
                _ = sdl.SDL_RenderTexture(display.renderer, texture.texture, null, @ptrCast(&dest));
            } else {
                _ = sdl.SDL_RenderTexture9Grid(
                    display.renderer,
                    texture.texture,
                    null,
                    element.background.image_corner_radius,
                    element.background.image_corner_radius,
                    element.background.image_corner_radius,
                    element.background.image_corner_radius,
                    corner / element.background.image_corner_radius,
                    @ptrCast(&dest),
                );
            }

            // Progress bar foreground
            if (element.type.progress_bar.progress > 0.01) {
                tint = display.theme.progress_bar_foreground;
                dest.width *= element.type.progress_bar.progress;
                _ = sdl.SDL_SetTextureAlphaMod(texture.texture, tint.a);
                _ = sdl.SDL_SetTextureColorMod(texture.texture, tint.r, tint.g, tint.b);
                if (element.background.image_corner_radius == 0) {
                    _ = sdl.SDL_RenderTexture(display.renderer, texture.texture, null, @ptrCast(&dest));
                } else {
                    _ = sdl.SDL_RenderTexture9Grid(
                        display.renderer,
                        texture.texture,
                        null,
                        element.background.image_corner_radius,
                        element.background.image_corner_radius,
                        element.background.image_corner_radius,
                        element.background.image_corner_radius,
                        corner / element.background.image_corner_radius,
                        @ptrCast(&dest),
                    );
                }
            }
        } else {
            err("progress bar image missing.", .{});
        }
    }

    /// Draw a button with its text and/or icon. Mouse hover, mouse click
    /// and the disabled status may change the picture or icon
    /// displayed in the button.
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
            if (element.background.image_corner_radius == 0) {
                _ = sdl.SDL_RenderTexture(display.renderer, background_image, null, @ptrCast(&dest));
            } else {
                var corner: f32 = element.background.corner_radius;
                if (corner * 2 > dest.height) corner = dest.height / 2;
                _ = sdl.SDL_RenderTexture9Grid(
                    display.renderer,
                    background_image,
                    null,
                    element.background.image_corner_radius,
                    element.background.image_corner_radius,
                    element.background.image_corner_radius,
                    element.background.image_corner_radius,
                    corner / element.background.image_corner_radius,
                    @ptrCast(&dest),
                );
            }
        }

        // The inner content can contain a button and/or text texture.
        var content_width = element.type.button.icon_size.width;
        if (element.type.button.text_texture) |texture| {
            const size = element.type.button.text_size.pixel_size(display, texture);

            // Do we need space between text and icon?
            if (content_width > 0)
                content_width += element.type.button.spacing;

            content_width += size.width;
        }
        content_width += element.pad.left + element.pad.right;

        const content_offset = switch (element.child_align.x) {
            .start => 0,
            .centre => (element.rect.width - content_width) / 2.0,
            .end => element.rect.width - content_width,
        };

        const tint = element.button_text_tint(display.theme);
        var has_icon = false;
        if (element.current_icon()) |icon_image| {
            has_icon = true;
            {
                var dest: Rect = .{
                    .x = element.rect.x + element.pad.left + content_offset,
                    .y = element.rect.y + element.pad.top,
                    .width = element.type.button.icon_size.width,
                    .height = element.type.button.icon_size.height,
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
                if (element.style != .custom) {
                    _ = sdl.SDL_SetTextureColorMod(
                        icon_image,
                        tint.r,
                        tint.g,
                        tint.b,
                    );
                } else {
                    _ = sdl.SDL_SetTextureColorMod(
                        icon_image,
                        element.colour.r,
                        element.colour.g,
                        element.colour.b,
                    );
                }
                _ = sdl.SDL_RenderTexture(display.renderer, icon_image, null, @ptrCast(&dest));
            }
        }
        if (element.type.button.text_texture) |texture| {
            const size = element.type.button.text_size.pixel_size(display, texture);
            var dest: Rect = .{
                .x = element.rect.x + element.type.button.icon_size.width + element.pad.left + content_offset,
                .y = element.rect.y + (element.rect.height / 2.0) - (size.height / 2),
                .width = size.width,
                .height = size.height,
            };
            if (element.type.button.icon_size.width == 0 or element.type.button.icon_size.height == 0) {
                dest.x = element.rect.x + element.rect.width / 2 - size.width / 2;
            }
            dest = dest.move(&scroll_offset);
            if (has_icon or element.type.button.icon_size.width > 0) {
                dest.x += element.type.button.spacing;
            }
            _ = sdl.SDL_SetTextureColorMod(texture, tint.r, tint.g, tint.b);
            _ = sdl.SDL_RenderTexture(display.renderer, texture, null, @ptrCast(&dest));
        }
    }

    pub fn keypress(
        self: *Element,
        allocator: Allocator,
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
                    if (self.type.text_input.on_submit.func != null) {
                        try self.type.text_input.on_submit.func.?(self.type.text_input.on_submit.ptr, display, self, allocator);
                    }
                    return;
                },
                sdl.SDLK_BACKSPACE => {
                    if (self.type.text_input.runes.items.len == 0) {
                        return;
                    }
                    _ = self.type.text_input.runes.pop();
                    self.text_runes_to_data(allocator);
                    self.type.text_input.cursor_character -= 1;
                },
                else => {
                    if (self.type.text_input.runes.items.len >= self.type.text_input.max_runes) {
                        trace("Ignoring {u}. Input limited to {d} characters", .{
                            key,
                            self.type.text_input.max_runes,
                        });
                        return;
                    }
                    self.type.text_input.text.appendSlice(allocator, slice) catch {};
                    self.type.text_input.runes.append(allocator, key) catch {};
                    self.type.text_input.cursor_character += 1;
                },
            }
            self.text_data_to_runes(allocator);

            // Update the text texture image.
            if (self.type.text_input.texture) |texture| {
                sdl.SDL_DestroyTexture(texture);
                self.type.text_input.texture = null;
            }
            if (self.type.text_input.text.items.len > 0) {
                if (display.generate_text_texture(self.type.text_input.text.items, self.type.text_input.font)) |texture| {
                    self.type.text_input.texture = texture;
                    // For now, the cursor position is simply the end of the text.
                    self.type.text_input.cursor_pixels = TextSize.normal.pixel_size(display, texture).width;
                }
            } else {
                self.type.text_input.cursor_pixels = 0;
            }

            // Optionally, a text_input may have an `on_change` callback function.
            if (self.type.text_input.on_change.func) |f| {
                trace("text_input calling on_change", .{});
                try f(self.type.text_input.on_change.ptr, display, self, allocator);
                trace("text_input called on_change", .{});
            } else {
                debug("text_input no on_change", .{});
            }
        }
    }

    /// Handle when a user chooses an element like a button, using
    /// the mouse or the keyboard.
    pub fn chosen(self: *Element, display: *Display, gpa: Allocator) Allocator.Error!void {
        trace("chosen element {s}", .{self.name});
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
                    .no_toggle,
                    .correct,
                    .incorrect,
                    .locked_off,
                    .disabled,
                    => {},
                }
                if (self.type.button.on_click.func) |f| {
                    try f(self.type.button.on_click.ptr, display, self, gpa);
                    return;
                }
            },
            .panel => {
                if (self.type.panel.on_click.func) |f| {
                    try f(self.type.panel.on_click.ptr, display, self, gpa);
                    return;
                }
            },
            .label => {
                if (self.type.label.on_click.func) |f| {
                    try f(self.type.label.on_click.ptr, display, self, gpa);
                    return;
                }
            },
            .sprite => {
                if (self.type.sprite.on_click.func) |f| {
                    try f(self.type.sprite.on_click.ptr, display, self, gpa);
                    return;
                }
            },
            .checkbox => {
                self.type.checkbox.checked = !self.type.checkbox.checked;
                if (self.type.checkbox.on_change.func) |f| {
                    try f(self.type.checkbox.on_change.ptr, display, self, gpa);
                    return;
                }
            },
            .progress_bar, .text_input, .rectangle, .expander => {},
        }
    }

    /// Handle when a user clicks into or tabs into this element.
    pub fn selected(self: *Element, display: *Display, _: Allocator) void {
        if (self.focus == .never_focus or self.focus == .unspecified) return;

        if (display.selected != null and self != display.selected)
            display.selected.?.deselected(display);

        display.selected = self;

        const content = self.describe_content();
        trace("selected {s} {s} = {s}", .{ @tagName(self.type), self.name, content });

        // Enter editing mode if we just selected a text element
        if (self.type == .text_input)
            _ = sdl.SDL_StartTextInput(display.window);
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
        trace("deselected {s} {s} = {s}", .{ @tagName(self.type), self.name, content });

        if (self.type == .text_input) {
            _ = sdl.SDL_StopTextInput(display.window);
        }
        display.keyboard_selected = false;
        display.selected = null;
    }

    fn text_runes_to_data(self: *Element, allocator: Allocator) void {
        std.debug.assert(self.type == .text_input);
        self.type.text_input.text.clearRetainingCapacity();
        for (self.type.text_input.runes.items) |rune| {
            var buff: [4]u8 = undefined;
            const len = std.unicode.utf8Encode(rune, &buff) catch {
                return;
            };
            self.type.text_input.text.appendSlice(allocator, buff[0..len]) catch {
                return;
            };
        }
    }

    fn text_data_to_runes(self: *Element, allocator: Allocator) void {
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
            self.type.text_input.runes.append(allocator, rune) catch {
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
    }

    /// Align a single line of TextElement's belonging to a label
    /// or a checkbox.
    inline fn do_word_alignment(
        element: *Element,
        line_width: f32,
        element_width: f32,
        children: []TextElement,
    ) void {
        // How much whitespace was left over at the end of this line.
        const trailing_whitespace = element_width - line_width;

        if (trailing_whitespace <= 0) return;

        switch (element.child_align.x) {
            .start => {
                // No adjustment needed
                return;
            },
            .centre => {
                // Shuffle words into centre
                const adjust_by = trailing_whitespace / 2;
                for (children) |*child| child.location.x += adjust_by;
            },
            .end => {
                // Shuffle words to the end
                const adjust_by = trailing_whitespace;
                for (children) |*child| child.location.x += adjust_by;
            },
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

/// Calculate how many pixels of text we can draw until we must wrap to
/// the next line. By default the width is whatever the parent element
/// has room for.
fn word_wrap_line(element: *Element, display: *Display, max_parent_width: f32) f32 {
    var element_padding = element.pad.left + element.pad.right;
    if (element.type == .checkbox) element_padding += display.checkbox().width;

    // If a fixed width is specified, clamp to the fixed width
    const wrap = switch (element.layout.x) {
        .grows, .fixed => @max(max_parent_width, element.maximum.width) - element_padding,
        .shrinks => @max(max_parent_width, element.minimum.width) - element_padding,
    };

    return wrap;
}

const TextElement = struct {
    text: ?[]const u8,
    width: f32, // compared to default height
    texture: *sdl.SDL_Texture,
    location: Rect,
};

pub const Retain = enum {
    autorelease,
    retain,
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

    pub fn pixel_size(size: TextSize, display: *const Display, texture: *const sdl.SDL_Texture) Size {
        const height_adjusted = display.text_height * display.scale * size.height();
        return .{
            .height = height_adjusted,
            .width = height_adjusted * @as(f32, @floatFromInt(texture.*.w)) / @as(f32, @floatFromInt(texture.*.h)),
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
    mix: *mixer.MIX_Mixer,
    allocator: Allocator,
    quit: bool = false,
    need_relayout: bool = true,
    old_safe_area: sdl.SDL_Rect = undefined,
    accessibility: bool = false,
    last_draw: i64 = 0,
    last_delta: i64 = 0,

    // Text height in pixels _before_ display scaling. i.e.
    // 16 on normal screens,
    // 32 on retina screens (16 * 2)
    text_height: f32 = FONT_SIZE,

    /// A list of read only resources is loaded from a resource
    /// bundle, or an on disk development directory. This may
    /// include images, fonts, audio, or text data files.
    resources: *Resources,

    /// A list of all active fonts loaded from the resources bundle.
    fonts: ArrayListUnmanaged(*Font) = .empty,

    /// Translates the default provided text into a specific language
    /// using a csv translation file
    translation: Translation,
    current_language: Lang = .unknown,

    /// Cache of currently loaded textures.
    textures: std.AutoHashMapUnmanaged(u64, *Texture),

    /// Cache of currently loaded audio files.
    audio: std.StringHashMapUnmanaged(*Audio),

    /// Four possible theme options are available.
    themes: ArrayListUnmanaged(Theme) = .empty,

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
        .background = .{ .colour = .{ .a = 0 } },
        .border_colour = .{},
        .border_width = 0,
        .type = .{ .panel = .{ .direction = .centre, .spacing = 0 } },
        .on_resized = .{ .func = null },
        .on_visibility = .{ .func = null },
    },
    animators: ArrayListUnmanaged(*Animator) = .empty,

    keybindings: std.AutoHashMapUnmanaged(c_uint, Callback) = .empty,
    on_resized: BoolCallback,
    event_hook: U32Callback,
    on_panel_change: PanelChangeCallback,

    pub fn create(
        gpa: Allocator,
        app_name: [:0]const u8,
        app_version: [:0]const u8,
        app_id: [:0]const u8,
        dev_resource_folder: []const u8,
        dev_resource_filter: ?fn (name: []const u8, extension: FileType) bool,
        translation_filename: []const u8,
        gui_flags: usize,
    ) (Error || Allocator.Error || Resources.Error || engine.Error || error{ Utf8ExpectedContinuation, Utf8OverlongEncoding, Utf8EncodesSurrogateHalf, Utf8CodepointTooLarge, Utf8InvalidStartByte } || std.fs.Dir.StatError || std.fs.File.StatError || std.fs.File.OpenError)!*Display {
        var display = try gpa.create(Display);
        errdefer gpa.destroy(display);
        display.allocator = gpa;
        display.hovered = null;
        display.selected = null;
        display.keyboard_selected = false;
        display.focussed = null;
        display.scrolling = null;
        display.text_height = FONT_SIZE;
        display.on_resized = .{ .func = null };
        display.on_panel_change = .{ .func = null };
        display.current_language = .unknown;
        display.need_relayout = true;
        display.quit = false;
        display.translation = .empty;
        display.accessibility = false;
        display.animators = .empty;
        display.keybindings = .empty;
        display.event_hook = .{ .func = null };

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
            return error.GraphicsInitFailed;
        }

        if (!sdl.TTF_Init()) {
            err("ttf setup font failed. {s}", .{sdl.SDL_GetError()});
            return error.FontInitFailed;
        }

        if (!mixer.MIX_Init()) {
            err("mixer setup failed. {s}", .{sdl.SDL_GetError()});
            return error.AudioInitFailed;
        }
        const a: mixer.SDL_AudioSpec = .{
            .freq = 44100,
            .format = mixer.SDL_AUDIO_S16LE,
            .channels = 2,
        };

        const md = mixer.MIX_CreateMixerDevice(mixer.SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &a);
        if (md == null) {
            err("create mixer device failed. {s}", .{sdl.SDL_GetError()});
            return error.AudioInitFailed;
        }
        display.mix = md.?;
        //mixer.MIX_SetMasterGain(display.mix, DEFAULT_SOUND_VOLUME);

        debug("Initialising resource loader", .{});
        display.resources = try init_resource_loader(
            gpa,
            engine.RESOURCE_BUNDLE_FILENAME,
            dev_resource_folder,
            dev_resource_filter,
        );
        if (try display.resources.lookupOne(translation_filename, .csv, gpa)) |resource| {
            const data = try sdl_load_resource(display.resources, resource, gpa);
            defer gpa.free(data);
            try display.translation.load_translation_data(gpa, data);
            debug("Translation file '{s}' loaded", .{translation_filename});
        } else {
            err("Translation file '{s}' not found.", .{translation_filename});
        }

        const window = sdl.SDL_CreateWindow(
            app_name,
            600,
            800,
            sdl.SDL_WINDOW_RESIZABLE | sdl.SDL_WINDOW_HIGH_PIXEL_DENSITY | sdl.SDL_WINDOW_RESIZABLE | gui_flags,
        ) orelse {
            err("No Window created. {s}", .{sdl.SDL_GetError()});
            return error.WindowCreationFailed;
        };

        const renderer = sdl.SDL_CreateRenderer(window, null) orelse {
            err("No Renderer initialised. {s}", .{sdl.SDL_GetError()});
            return error.GraphicsRendererFailed;
        };

        const current_driver = sdl.SDL_GetRendererName(renderer).?;
        const count = sdl.SDL_GetNumRenderDrivers();
        var renderer_info: ArrayListUnmanaged(u8) = .empty;
        defer renderer_info.deinit(gpa);
        var i: c_int = 0;
        while (i < count) : (i += 1) {
            const driver = sdl.SDL_GetRenderDriver(i).?;
            try renderer_info.print(gpa, " {s}", .{std.mem.span(driver)});
            if (std.mem.orderZ(u8, current_driver, driver) == .eq)
                try renderer_info.appendSlice(gpa, " (selected)");
        }
        info("Renderer:{s}", .{renderer_info.items});

        trace("Checking for desktop icon", .{});
        if (try display.resources.lookupOne("desktop icon", .image, gpa)) |resource| {
            var surface: SurfaceInfo = undefined;
            try display.make_surface_from_resource(display.resources, resource, gpa, &surface);
            defer surface.deinit(gpa);
            if (!sdl.SDL_SetWindowIcon(window, surface.surface)) {
                err("Failed to set set desktop icon", .{});
            } else {
                trace("Successfully set desktop icon", .{});
            }
        } else {
            err("No 'desktop icon' in resource bundle.", .{});
        }

        const pixel_scale = sdl.SDL_GetWindowDisplayScale(window);
        info("WindowDisplayScale: {d}", .{pixel_scale});

        var pixel_width: c_int = 0;
        var pixel_height: c_int = 0;
        _ = sdl.SDL_GetWindowSizeInPixels(window, &pixel_width, &pixel_height);
        info("WindowSizeInPixels: {d}x{d}", .{ pixel_width, pixel_height });

        var window_width: c_int = 0;
        var window_height: c_int = 0;
        _ = sdl.SDL_GetWindowSize(window, &window_width, &window_height);
        info("GetWindowSize: {d}x{d}", .{ window_width, window_height });

        const density = sdl.SDL_GetWindowPixelDensity(window);
        info("WindowPixelDensity: {d}", .{density});

        _ = sdl.SDL_SetRenderVSync(renderer, 1);

        display.renderer = renderer;
        display.window = window;
        display.pixel_density = density;
        display.pixel_scale = pixel_scale;
        display.user_scale = 1;
        display.scale = display.pixel_scale / display.user_scale;

        // App can accept these keybindings or replace them
        try display.keybindings.put(gpa, sdl.SDLK_D, .{ .func = @ptrCast(&toggle_dev_mode), .ptr = display });
        try display.keybindings.put(gpa, sdl.SDLK_K, .{ .func = @ptrCast(&rotate_theme), .ptr = display });
        try display.keybindings.put(gpa, sdl.SDLK_X, .{ .func = @ptrCast(&increase_size), .ptr = display });
        try display.keybindings.put(gpa, sdl.SDLK_PLUS, .{ .func = @ptrCast(&increase_size), .ptr = display });
        try display.keybindings.put(gpa, sdl.SDLK_EQUALS, .{ .func = @ptrCast(&increase_size), .ptr = display });
        try display.keybindings.put(gpa, sdl.SDLK_MINUS, .{ .func = @ptrCast(&decrease_size), .ptr = display });
        try display.keybindings.put(gpa, sdl.SDLK_KP_PLUS, .{ .func = @ptrCast(&increase_size), .ptr = display });
        try display.keybindings.put(gpa, sdl.SDLK_KP_MINUS, .{ .func = @ptrCast(&decrease_size), .ptr = display });
        if (engine.dev_build) {
            try display.keybindings.put(gpa, sdl.SDLK_B, .{ .func = @ptrCast(&make_bundle), .ptr = display });
        }

        display.themes = .empty;
        for (&default_themes) |*theme| {
            try display.themes.append(gpa, theme.*);
        }
        display.update_system_theme();

        display.fonts = .empty;
        display.textures = .empty;
        display.audio = .empty;

        display.last_draw = std.time.microTimestamp();
        display.last_delta = display.last_draw;

        display.root = .{
            .name = "root",
            .rect = .{ .x = 0, .y = 0, .width = 100, .height = 100 },
            .pad = .{ .left = 0, .right = 0, .top = 0, .bottom = 0 },
            .maximum = .{ .width = 100, .height = 100 },
            .layout = .{ .x = .grows, .y = .grows },
            .child_align = .{ .x = .centre, .y = .start },
            .colour = .{},
            .background = .{ .colour = .{ .a = 0 } },
            .border_colour = .{},
            .border_width = 0,
            .type = .{ .panel = .{ .direction = .centre, .spacing = 0 } },
            .on_resized = .{ .func = null },
            .on_visibility = .{ .func = null },
        };
        display.root.rect.width = @as(f32, @floatFromInt(window_width)) * display.pixel_density;
        display.root.rect.height = @as(f32, @floatFromInt(window_height)) * display.pixel_density;
        display.root.texture = null;
        display.root.type.panel.children = .empty;

        display.update_screen_metrics(true);

        return display;
    }

    /// Cleanup memory assocaited with this display.
    pub fn destroy(self: *Display, gpa: Allocator) void {
        trace("Engine cleanup", .{});

        self.root.deinit(self, gpa);
        self.themes.deinit(gpa);

        for (self.fonts.items) |item| {
            item.destroy(gpa);
        }
        self.fonts.deinit(gpa);

        var i = self.textures.iterator();
        while (i.next()) |x| {
            if (x.value_ptr.*.references > 0) {
                warn("texture was not deallocated. {d} has {d} references", .{
                    x.key_ptr.*,
                    x.value_ptr.*.references,
                });
            }
            x.value_ptr.*.destroy(gpa);
        }
        self.textures.deinit(gpa);

        var a = self.audio.iterator();
        while (a.next()) |x| {
            if (x.value_ptr.*.references > 0 and x.value_ptr.*.autorelease == .autorelease) {
                warn("audio file was not deallocated. {s} has {d} references", .{
                    x.key_ptr.*,
                    x.value_ptr.*.references,
                });
            }
            x.value_ptr.*.destroy(gpa);
        }
        self.audio.deinit(gpa);

        self.resources.destroy();
        for (self.animators.items) |animator| {
            gpa.destroy(animator);
        }
        self.animators.deinit(gpa);

        sdl.SDL_DestroyRenderer(self.renderer);
        sdl.SDL_DestroyWindow(self.window);
        mixer.MIX_DestroyMixer(self.mix);
        mixer.MIX_Quit();
        sdl.TTF_Quit();
        sdl.SDL_Quit();

        self.keybindings.deinit(gpa);
        self.translation.deinit(gpa);
        gpa.destroy(self);
    }

    /// Check that a theme name is a valid theme name. Return a stack
    /// allocated string version of the name.
    pub fn validate_theme(display: *Display, name: []const u8) []const u8 {
        for (display.themes.items) |theme| {
            if (std.ascii.eqlIgnoreCase(theme.tag, name)) {
                return theme.tag;
            }
        }
        return "";
    }

    /// Change the theme. If the theme name is not valid, or empty
    /// use the system preference.
    pub fn set_theme(self: *Display, name: []const u8) bool {
        for (self.themes.items) |*theme| {
            if (std.ascii.eqlIgnoreCase(theme.*.tag, name)) {
                self.theme = theme;
                return true;
            }
        }
        switch (sdl.SDL_GetSystemTheme()) {
            sdl.SDL_SYSTEM_THEME_DARK => {
                self.theme = &self.themes.items[0];
            },
            sdl.SDL_SYSTEM_THEME_LIGHT => {
                self.theme = &self.themes.items[3];
            },
            else => {
                self.theme = &self.themes.items[3];
            },
        }
        return name.len == 0 or std.ascii.eqlIgnoreCase(name, "default");
    }

    /// On initialisation, the display reads the users OS light/dark
    /// theme preference.
    pub fn update_system_theme(self: *Display) void {
        switch (sdl.SDL_GetSystemTheme()) {
            sdl.SDL_SYSTEM_THEME_DARK => self.theme = &self.themes.items[0],
            sdl.SDL_SYSTEM_THEME_LIGHT => self.theme = &self.themes.items[3],
            sdl.SDL_SYSTEM_THEME_UNKNOWN => self.theme = &self.themes.items[3],
            else => self.theme = &self.themes.items[3],
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
    pub fn choose_panel(self: *Display, gpa: Allocator, name: []const u8) Allocator.Error!void {
        const old_panel = self.current_panel();

        var found = false;
        self.update_screen_metrics(false);
        for (self.root.type.panel.children.items) |element| {
            if (element.type != .panel) continue;
            if (std.mem.eql(u8, "background", element.name)) continue;
            if (std.mem.eql(u8, "menu", element.name)) continue;

            if (std.mem.eql(u8, name, element.name)) {
                if (element.visible != .visible) {
                    if (old_panel) |old| {
                        info("choose panel. {s} -> {s}", .{ old.name, name });
                    } else {
                        info("choose panel. ___ -> {s}", .{name});
                    }
                    try element.set_visibility(self, .visible);
                    if (element.on_resized.func != null) {
                        self.need_relayout = true;
                        _ = element.on_resized.func.?(element.on_resized.ptr, self, element);
                    }
                    if (self.on_panel_change.func) |f| {
                        f(self.on_panel_change.ptr, self, old_panel, element, gpa) catch |e| {
                            trace("panel handler error. to {s} {any}", .{ element.name, e });
                        };
                    }
                }
            } else {
                // Other panels not matching `name` are hidden.
                if (element.visible != .hidden) {
                    debug("choose_panel({s}) hiding panel {s}.", .{ name, element.name });
                    try element.set_visibility(self, .hidden);
                }
            }
            found = true;
        }
        if (self.selected) |selected| {
            selected.deselected(self);
        }
        self.update_screen_metrics(true);
        if (!found and name.len > 0) {
            warn("choose_panel() did not find panel. name={s}", .{name});
        }
    }

    /// Get the name of the currently visible top panel that isn't
    /// the background or menu panel.
    pub fn current_panel(self: *Display) ?*Element {
        for (self.root.type.panel.children.items) |element| {
            if (element.type != .panel) continue;
            if (std.mem.eql(u8, "background", element.name)) continue;
            if (std.mem.eql(u8, "menu", element.name)) continue;
            if (element.visible == .visible) return element;
        }
        trace("current_panel() did not find panel.", .{});
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

    /// Apply the relayout algorithm to the currently visible root
    /// panels/scenes, then descend to relayout each of the child panels.
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
                    scene.*.rect.width = @min(
                        display.root.rect.width,
                        scene.*.maximum.width,
                    );
                } else {
                    scene.*.rect.width = display.root.rect.width;
                }
            }
            if (scene.*.layout.y == .grows) {
                if (scene.*.maximum.height > 0) {
                    scene.*.rect.height = @min(
                        scene.*.rect.height,
                        scene.*.maximum.height,
                    );
                } else {
                    scene.*.rect.height = display.root.rect.height;
                }
            }
            // Clamp minimum width and height
            if (scene.*.layout.x == .shrinks and scene.*.minimum.width > 0)
                scene.*.rect.width = @max(scene.*.rect.width, scene.*.minimum.width);
            if (scene.*.layout.y == .shrinks and scene.*.maximum.height > 0)
                scene.*.rect.height = @max(scene.*.rect.height, scene.*.minimum.height);

            // Place panel at start, centre or end.
            switch (scene.*.child_align.x) {
                .start => scene.*.rect.x = 0,
                .end => scene.*.rect.x = display.root.rect.width - scene.*.rect.width,
                .centre => scene.*.rect.x = display.root.rect.width / 2 - scene.*.rect.width / 2,
            }
            switch (scene.*.child_align.y) {
                .start => scene.*.rect.y = 0,
                .end => scene.*.rect.y = display.root.rect.height - scene.*.rect.height,
                .centre => scene.*.rect.y = display.root.rect.height / 2 - scene.*.rect.height / 2,
            }

            // After root panel sizes are established, the child elements
            // are layed out inside the panel.
            relayout_panel(display, scene.*);
            display.propogate_resize_event(scene.*);
            relayout_panel(display, scene.*); //TODO: fix

            // Children are given opportunity to resize themselves
            // in response to the resize event.
            var did_resize = false;
            if (display.on_resized.func != null) {
                if (display.on_resized.func.?(display.on_resized.ptr, display, scene.*)) {
                    did_resize = true;
                }
            }
            if (did_resize)
                relayout_panel(display, scene.*);

            scene.*.pad = user_pad;
        }
    }

    /// Relayout the contents of an individual panel that is sitting
    /// somewhere n the tree below the root panel (scene).
    fn relayout_panel(self: *Display, parent: *Element) void {
        std.debug.assert(parent.type == .panel);

        // Keep track of each expander in the panel. At the end, expand
        // each expander according to the leftover space.
        var expanders = BoundedArray(*Element, 10){};
        var expander_weights: f32 = 0;

        // Make sure this element never exceeds its maximum.
        var panel_resized = false;
        if (parent.layout.x == .grows and parent.maximum.width > 0) {
            const new_width = @min(parent.rect.width, parent.maximum.width);
            if (parent.rect.width != new_width) {
                parent.rect.width = new_width;
                panel_resized = true;
            }
        }
        if (parent.layout.y == .grows and parent.maximum.height > 0) {
            const new_height = @min(parent.rect.height, parent.maximum.height);
            if (parent.rect.height != new_height) {
                parent.rect.height = new_height;
                panel_resized = true;
            }
        }

        // # Step 1
        //
        // Children of this panel are either fixed positioned, growing, or shrinking.
        //
        // - `.fixed` elements are not altered, keep retain their requested `rect` size.
        // - `.shrinks` elements shrink to the `minimum` space they need.
        // - `.grows` enlarges the width or height of the parent `rect`.
        //
        for (parent.type.panel.children.items) |element| {
            if (element.visible == .hidden) continue;

            const available_width = parent.rect.width - parent.pad.left - parent.pad.right;

            var child_resized = false;
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
                    // Grow to the parent width, not including padding.
                    element.rect.x = 0;
                    var new_width = parent.rect.width - (parent.pad.left + parent.pad.right);
                    if (element.maximum.width > 0 and new_width > element.maximum.width) {
                        new_width = element.maximum.width;
                    }
                    if (element.rect.width != new_width) {
                        element.rect.width = new_width;
                        child_resized = true;
                    }
                },
                .shrinks => {
                    // Shrink to the smallest the children will allow.
                    const new_width = element.shrink_width(self, available_width);
                    if (element.rect.width != new_width) {
                        element.rect.width = new_width;
                        child_resized = true;
                    }
                    // Shrink to the left, centre, or right.
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
                    // Grow to the parent height, not including padding.
                    element.rect.y = 0;
                    element.rect.height = parent.rect.height - (parent.pad.top + parent.pad.bottom);
                    if (element.maximum.height > 0 and element.rect.height > element.maximum.height) {
                        element.rect.height = element.maximum.height;
                    }
                },
                .shrinks => {
                    // Shrink to the smallest the children will allow
                    const new_height = element.shrink_height(self, available_width);
                    if (element.rect.height != new_height) {
                        element.rect.height = new_height;
                        child_resized = true;
                    }
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

            if (child_resized and element.on_resized.func != null) {
                trace("element {s} resized. callback = {any}", .{ element.name, element.on_resized.func != null });
                _ = element.on_resized.func.?(element.on_resized.ptr, self, element);
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
            .left_to_right => place_children_left_to_right(self, parent, expanders.slice(), expander_weights),
            .left_to_right_wrap => place_children_left_to_right_wrap(self, parent),
            .top_to_bottom => place_children_top_to_bottom(self, parent, expanders.slice(), expander_weights),
            .centre => place_children_centred(self, parent),
            .top_left => place_children_top_left(self, parent),
        }

        // Descend into child elements to allow child panels to also resize.
        for (parent.type.panel.children.items) |child| {
            if (child.type == .panel)
                self.relayout_panel(child);
        }

        if (panel_resized and parent.on_resized.func != null) {
            _ = parent.on_resized.func.?(parent.on_resized.ptr, self, parent);
        }
    }

    inline fn place_children_centred(_: *Display, parent: *Element) void {
        const parent_width = parent.rect.width - parent.pad.left - parent.pad.right;
        const parent_height = parent.rect.height - parent.pad.top - parent.pad.bottom;

        // First pass just does a layout assuming top/left positioning.
        for (parent.type.panel.children.items) |child| {
            if (child.layout.position == .float) continue;
            if (child.visible == .hidden) continue;
            if (child.type == .expander) {
                warn("expander panel '{s}' ignored due to centre layout.", .{parent.name});
                continue;
            }

            child.rect.x = parent.rect.x + parent.pad.left + (parent_width / 2 - child.rect.width / 2);
            child.rect.y = parent.rect.y + parent.pad.top + (parent_height / 2 - child.rect.height / 2);
        }
        //TODO: Im not sure scroller detection is needed here or not

        //const needed_height = current.y - parent.y;
        //const overflow_height = (parent.y + parent.height) - current.y;
        //parent.type.panel.scrollable.size.height = @max(needed_height, parent.height);
    }

    inline fn place_children_top_left(_: *Display, parent: *Element) void {
        for (parent.type.panel.children.items) |child| {
            if (child.layout.position == .float) continue;
            if (child.visible == .hidden) continue;
            if (child.type == .expander) {
                warn("expander panel '{s}' ignored due to centre layout.", .{parent.name});
                continue;
            }
            child.rect.x = parent.rect.x + parent.pad.left;
            child.rect.y = parent.rect.y + parent.pad.top;
        }
    }

    inline fn place_children_top_to_bottom(
        _: *Display,
        parent: *Element,
        expanders: []*Element,
        expander_weights: f32,
    ) void {
        // Layout each item from top to bottom, initially ignoring
        // the need to centre the items or expand any expanders.
        var current: Vector = .{
            .x = parent.rect.x + parent.pad.left,
            .y = parent.rect.y + parent.pad.top,
        };
        var i: usize = 0;
        for (parent.type.panel.children.items) |child| {
            // Layout the clipped and visible items, but not the hidden items.
            if (child.visible == .hidden) continue;
            if (child.layout.position == .float) continue;

            // Only apply spacing in-between items
            if (i > 0)
                current.y += parent.type.panel.spacing;

            child.rect.x = current.x;
            child.rect.y = current.y;

            if (child.type != .expander)
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

        //info(" top to bottom layout {s} {s} - need {d} overflow {d}", .{ parent.name, @tagName(parent.type), needed_height, overflow_height });

        // If there are expanders, expand them, otherwise,
        // do start/centre/end alignment.
        if (expanders.len > 0) {
            // Relayout the children with expanders
            trace("expanders: {s} has {any}.  needed_height: {d} available_height: {d}", .{
                parent.name,
                expanders.len,
                needed_height,
                parent.rect.height,
            });

            if (parent.rect.height > needed_height) {
                // Give each expander a percentage of the spare height area
                const spare_height = parent.rect.height - needed_height;
                for (expanders) |expander| {
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
                // Re-update each child panels y position based on the
                // update to each expanders size.
                var new_y: f32 = parent.rect.y + parent.pad.top;
                for (parent.type.panel.children.items) |child| {
                    // Relayout top to bottom using expander sizes
                    if (child.visible == .hidden) continue;
                    if (child.layout.position == .float) continue;
                    child.rect.y = new_y;
                    new_y += child.rect.height + parent.type.panel.spacing;
                    trace("expanding. {t} {s} y={d} height={d}", .{
                        child.type,
                        child.name,
                        child.rect.y,
                        child.rect.height,
                    });
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
                    parent.type.panel.scrollable.size.width = @max(
                        needed_height,
                        parent.rect.height,
                    );
                },
            }
        }
    }

    /// Draw panel children from top left corner of the panel
    /// assuming no scrolling of the child elements. Offsets
    /// applied at runtime.
    inline fn place_children_left_to_right(
        _: *Display,
        parent: *Element,
        expanders: []*Element,
        expanders_weight: f32,
    ) void {
        var current: Vector = .{
            .x = parent.rect.x + parent.pad.left,
            .y = parent.rect.y + parent.pad.top,
        };
        var i: usize = 0;
        for (parent.type.panel.children.items) |child| {
            // Layout the clipped and visible items, but not the hidden items.
            if (child.visible == .hidden) continue;
            if (child.layout.position == .float) continue;

            // Only apply spacing in-between items
            if (i > 0)
                current.x += parent.type.panel.spacing;

            child.rect.x = current.x;
            child.rect.y = current.y;

            if (child.type != .expander)
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

        //info(" left to right layout {s} {s} - need {d} overflow {d}", .{ parent.name, @tagName(parent.type), needed_width, overflow_width });

        if (expanders.len > 0 or expanders_weight > 0) {
            // TODO: Apply expanders. Left_to_right doesnt currently support
            // expanders. Transfer top_to_bottom expander code here
            warn("panel {s} left to right doesnt support expanders", .{parent.name});
        }

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

    // Draw panel children from top left corner of the panel
    // assuming no scrolling of the child elements. Offsets
    // applied at runtime. Track the height of each element
    // so wrapping can occur down to the next line.
    inline fn place_children_left_to_right_wrap(
        _: *Display,
        parent: *Element,
    ) void {
        var current: Vector = .{
            .x = parent.rect.x + parent.pad.left,
            .y = parent.rect.y + parent.pad.top,
        };

        // Track how much hight the current line needs
        var line_height: f32 = 0;

        // Draw along the line, and wrap when we hit the end of the line
        const line_end: f32 = parent.rect.x + parent.rect.width - parent.pad.right;

        var i: usize = 0;
        for (parent.type.panel.children.items) |child| {
            if (child.visible == .hidden) continue;
            if (child.layout.position == .float) continue;
            if (child.type == .expander) continue;

            if (i > 0)
                current.x += parent.type.panel.spacing;
            i += 1;

            if (current.x + child.rect.width > line_end) {
                current.x = parent.rect.x + parent.pad.left;
                current.y += line_height + parent.type.panel.spacing;
                line_height = 0;
                i = 0;
                //TODO: We could y grow the elements that want grow.
                //TODO We could centre the items on this line `parent.child_align.x`
            }

            child.rect.x = current.x;
            child.rect.y = current.y;
            current.x += child.rect.width;
            const item_height = @max(child.rect.height, child.minimum.height);
            line_height = @max(item_height, line_height);
        }
        current.y += parent.pad.bottom;
        const needed_height = current.y - parent.rect.y;
        parent.type.panel.scrollable.size.height = @max(needed_height, parent.rect.height);
        //const overflow_height = parent.rect.height - needed_height;
    }

    pub fn set_language(display: *Display, allocator: Allocator, language: Lang) !void {
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
                .label => try element.language_changed(allocator, display, language),
                .checkbox => try element.language_changed(allocator, display, language),
                .button => try element.language_changed(allocator, display, language),
                .panel => try element.language_changed(allocator, display, language),
                else => {},
            }
        }
        display.need_relayout = true;
    }

    /// Update and draw all elements on the display.
    pub fn draw(display: *Display) !void {
        const now = std.time.microTimestamp();
        display.last_delta = now - display.last_draw;
        display.last_draw = now;
        //info("animate delta={d}", .{delta});
        var i: usize = 0;
        while (i < display.animators.items.len) {
            const animator = display.animators.items[i];
            const done = animator.animate(display, now);
            // TODO: relayout is not always needed
            display.need_relayout = true;
            if (done) {
                const old = display.animators.swapRemove(i);
                trace("animate complete for {s} start={d} end={d}", .{
                    old.target.name,
                    old.start_time,
                    old.end_time,
                });
                if (old.on_end.func) |callback| {
                    try callback(old.on_end.ptr, display, old.target, display.allocator);
                }
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
    pub fn load_font(
        self: *Display,
        allocator: Allocator,
        name: []const u8,
    ) (Error || Allocator.Error || Resources.Error)!*Font {
        const resource = try self.resources.lookupOne(name, .font, allocator);
        if (resource == null) {
            err("load_font({s}) Font not in resource folder", .{name});
            return error.ResourceNotFound;
        }
        const font_buffer = try sdl_load_resource(self.resources, resource.?, allocator);

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

        const font_info = try Font.create(allocator, name, myfont, font_buffer);
        errdefer font_info.destroy(allocator);
        try self.fonts.append(allocator, font_info);

        if (self.fonts.items.len > 1) {
            const i = self.fonts.items.len - 2;
            _ = sdl.TTF_AddFallbackFont(self.fonts.items[i].font, self.fonts.items[i + 1].font);
        }

        return font_info;
    }

    /// Add an animator that points to a currently active/valid element.
    /// The element must not be destroyed for the lifetime of the animation.
    pub inline fn add_animator(self: *Display, allocator: Allocator, animator: Animator) Allocator.Error!void {
        //err("add animator: {t} {d}x{d} -> {d}x{d}", .{
        //    animator.mode,
        //    animator.start.x,
        //    animator.start.y,
        //    animator.end.x,
        //    animator.end.y,
        //});
        var new_animator = try allocator.create(Animator);
        new_animator.* = animator;
        new_animator.setup = false;
        if (new_animator.duration == 0) {
            warn("add_animator called with duration of 0", .{});
            new_animator.duration = 10;
        }
        try self.animators.append(allocator, new_animator);
    }

    /// Attach a child element to the main display panel (root) element. The
    /// main display panel should only contain panels as children
    pub inline fn add_panel(
        self: *Display,
        allocator: Allocator,
        element: Element,
    ) (Allocator.Error || Resources.Error || Error)!*Element {
        if (element.type != .panel) {
            warn("parent display should contan panels. Not {s} {s}", .{
                @tagName(element.type),
                element.name,
            });
            unreachable; // add_panel only accepts panels
        }
        return self.root.add(allocator, self, element);
    }

    /// Convert a text string into an image that is sent as a texture to
    /// the graphics card.
    fn generate_text_texture(self: *Display, text: []const u8, myfont: *Font) ?*sdl.SDL_Texture {

        // Step 1: Create a surface (a bitmap) that holds the text.
        //
        // The text colour is set to white, so that it can be tinted to
        // match the current theme.
        const surface = sdl.TTF_RenderText_Blended(
            myfont.font,
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
    pub fn release_texture_resource(self: *Display, allocator: Allocator, ti: *Texture) void {
        if (ti.references == 0) {
            err("Attempt to release resource with no references", .{});
            return;
        }
        ti.references -= 1;
        if (ti.references != 0) {
            if (ti.references < 0) {
                err("free texture \"{d}\" (duplicate free)", .{ti.uid});
            } else {
                trace("free texture \"{d}\" (not yet {d})", .{ ti.uid, ti.references });
            }
            return;
        }
        trace("free texture \"{d}\" (now)", .{ti.uid});
        _ = self.textures.remove(ti.uid);
        ti.destroy(allocator);
    }

    /// A texture resource may be referenced by multiple on screen
    /// elements. This releases a texture, only when all references to
    /// a texture no longer exist.
    pub fn release_audio_resource(self: *Display, allocator: Allocator, ai: *Audio) void {
        if (ai.references == 0) {
            err("Attempt to release resource with no references", .{});
            return;
        }
        ai.references -= 1;
        if (ai.references != 0) {
            if (ai.references < 0) {
                err("free audio \"{s}\" (duplicate free)", .{ai.name});
            } else {
                trace("free audio \"{s}\" (not yet {d})", .{ ai.name, ai.references });
            }
            return;
        }
        trace("free audio \"{s}\" (now)", .{ai.name});
        _ = self.audio.remove(ai.name);
        ai.destroy(allocator);
    }

    /// Load an image from the default resource bundle.
    pub inline fn load_texture(
        self: *Display,
        gpa: Allocator,
        name: []const u8,
    ) (Error || Allocator.Error || Resources.Error)!?*Texture {
        return self.load_bundle_texture(gpa, self.resources, name);
    }

    /// Load an image from a specific resource bundle.
    pub fn load_bundle_texture(
        self: *Display,
        gpa: Allocator,
        bundle: *Resources,
        name: []const u8,
    ) (Error || Allocator.Error || Resources.Error)!?*Texture {
        if (name.len == 0) return null;

        var start = std.time.milliTimestamp();
        const resource = try bundle.lookupOne(name, .image, gpa);
        if (resource == null) return null;

        if (self.textures.get(resource.?.uid)) |texture| {
            trace("cache hit looking up {s} with uid {d}", .{ name, resource.?.uid });
            texture.references += 1;
            return texture;
        }

        var end = std.time.milliTimestamp();
        trace("search image named \"{s}\" in {d}ms", .{ name, end - start });
        start = end;

        var si: SurfaceInfo = undefined;
        try self.make_surface_from_resource(bundle, resource.?, gpa, &si);
        defer si.deinit(gpa);
        end = std.time.milliTimestamp();
        trace("made surface named \"{s}\" in {d}ms", .{ name, end - start });

        start = std.time.milliTimestamp();
        const texture = sdl.SDL_CreateTextureFromSurface(self.renderer, si.surface);
        end = std.time.milliTimestamp();
        trace("sdl create texture in {d}ms", .{end - start});

        const ti = try Texture.create(gpa, resource.?.uid, texture);
        ti.references += 1;
        try self.textures.put(gpa, ti.uid, ti);
        return ti;
    }

    /// Load an image from the default resource bundle.
    pub inline fn play_resource(
        self: *Display,
        gpa: Allocator,
        name: []const u8,
        autorelease: Retain,
        volume: f32,
    ) (Error || Allocator.Error || Resources.Error)!?*Audio {
        return self.play_bundle_resource(gpa, self.resources, name, autorelease, volume);
    }

    /// Load an image from a specific resource bundle.
    pub fn play_bundle_resource(
        self: *Display,
        gpa: Allocator,
        bundle: *Resources,
        name: []const u8,
        autorelease: Retain,
        volume: f32,
    ) (Error || Allocator.Error || Resources.Error)!?*Audio {
        if (name.len == 0) {
            err("play_bundle_resource(\"{s}\") resource name empty", .{name});
            return null;
        }

        // Load audio from memory cache if possible
        var item: ?*Audio = null;
        if (self.audio.get(name)) |i| {
            if (autorelease == .retain and i.autorelease == .autorelease) {
                // This audio item is converting to permanent memory
                i.autorelease = .retain;
                i.references += 1;
            }
            i.references += 1;
            item = i;
        } else {
            // Load audio from resource bundle
            var start = std.time.milliTimestamp();
            const resource = try bundle.lookupOne(name, .audio, gpa);
            if (resource == null) {
                err("search audio named \"{s}\" not found.", .{name});
                return null;
            }
            var end = std.time.milliTimestamp();
            debug("search audio named \"{s}\" in {d}ms", .{ name, end - start });

            start = end;
            const audio = try sdl_load_resource(bundle, resource.?, gpa);
            errdefer gpa.free(audio);
            end = std.time.milliTimestamp();

            debug("read audio named \"{s}\" size {d} in {d}ms", .{
                name,
                audio.len,
                end - start,
            });

            const ai = try Audio.create(gpa, name, audio, autorelease);
            ai.references += 1;
            ai.resource = resource;
            try self.audio.put(gpa, ai.name, ai);
            item = ai;
        }

        const amem = mixer.SDL_IOFromConstMem(item.?.audio.ptr, item.?.audio.len);
        const buff = mixer.MIX_LoadAudio_IO(self.mix, amem, true, true);
        if (buff == null) {
            err("loadaudio_io for \"{s}\" failed", .{name});
            return null;
        }

        const track = mixer.MIX_CreateTrack(self.mix);
        if (track == null) {
            err("create track for \"{s}\" failed", .{name});
            return null;
        }
        _ = mixer.MIX_SetTrackAudio(track, buff.?);
        _ = mixer.MIX_SetTrackGain(track, volume);
        //_ = mixer.MIX_SetTrackStoppedCallback(track, cb: ?*const fn (?*anyopaque, ?*struct_MIX_Track) void, userdata: ?*anyopaque);
        _ = mixer.MIX_PlayTrack(
            track,
            0, // used to request looping or play starting point
        );
        //_ = mixer.MIX_PlayAudio(self.mix, buff.?);

        return item;
    }

    pub const SurfaceInfo = struct {
        buffer: []const u8,
        img: zigimg.Image,
        surface: *sdl.SDL_Surface,

        pub fn deinit(si: *@This(), gpa: Allocator) void {
            gpa.free(si.buffer);
            si.img.deinit(gpa);
            sdl.SDL_DestroySurface(si.surface);
        }
    };

    fn make_surface_from_resource(
        _: *Display,
        bucket: *Resources,
        resource: *Resource,
        allocator: Allocator,
        si: *SurfaceInfo,
    ) (Error || Allocator.Error)!void {
        si.buffer = try sdl_load_resource(bucket, resource, allocator);
        errdefer allocator.free(si.buffer);
        si.img = zigimg.Image.fromMemory(allocator, si.buffer[0..]) catch |e| {
            if (e == error.OutOfMemory) return error.OutOfMemory;
            return error.UnknownImageFormat;
        };
        errdefer si.img.deinit(allocator);

        var row_size: c_int = 0;
        var sdl_format: sdl.SDL_PixelFormat = sdl.SDL_PIXELFORMAT_UNKNOWN;
        switch (si.img.pixels) {
            //1 => //PIXELFORMAT_UNCOMPRESSED_GRAYSCALE,
            //2 => //PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA,
            .rgb24 => {
                sdl_format = sdl.SDL_PIXELFORMAT_RGB24;
                row_size = @intCast(si.img.width * 3);
            },
            .rgba32 => {
                sdl_format = sdl.SDL_PIXELFORMAT_ABGR8888;
                row_size = @intCast(si.img.width * 4);
            },
            else => {
                if (resource.filename) |name| {
                    warn("unknown file format. Loading {s} format {s}", .{ name, @tagName(si.img.pixels) });
                } else if (resource.sentences.items.len > 0) {
                    warn("unknown file format. Loading {s} format {s}", .{
                        resource.sentences.items[0],
                        @tagName(si.img.pixels),
                    });
                }
                return error.UnknownImageFormat;
            },
        }

        const img_width: c_int = @intCast(si.img.width);
        const img_height: c_int = @intCast(si.img.height);
        si.surface = sdl.SDL_CreateSurfaceFrom(
            img_width,
            img_height,
            sdl_format,
            si.img.pixels.asBytes().ptr,
            row_size,
        );
    }

    pub fn select_first_element(self: *Display, elements: []*Element, gpa: Allocator) bool {
        for (elements) |element| {
            if (element.visible != .visible) {
                continue;
            }
            if (element.type == .panel) {
                if (self.select_first_element(element.type.panel.children.items, gpa)) {
                    return true;
                }
                if (element.type.panel.on_click.func == null) {
                    continue;
                }
            }
            if (element.focus == .never_focus or element.focus == .unspecified) {
                continue;
            }
            if (element.focus == .accessibility_focus and self.accessibility == false) {
                continue;
            }
            element.selected(self, gpa);
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

    pub fn select_next_element(self: *Display, gpa: Allocator) void {
        trace("select_next_element() find next element", .{});
        var state = SelectState.no_selectable_items;
        var previous: ?*Element = null;
        const element = self.do_select_next_element(
            self.root.type.panel.children.items,
            &state,
            &previous,
        );
        if (element) |found| {
            found.selected(self, gpa);
            return;
        }
        if (state == .has_selectable_item or state == .found_currently_selected_item) {
            _ = self.select_first_element(self.root.type.panel.children.items, gpa);
        } else {
            debug("select_next_element() no element found. {s}", .{@tagName(state)});
        }
    }

    pub fn select_previous_element(self: *Display, gpa: Allocator) void {
        trace("select_previous_element() find previous element", .{});
        var state = SelectState.no_selectable_items;
        var previous: ?*Element = null;
        _ = self.do_select_next_element(self.root.type.panel.children.items, &state, &previous);
        if (previous) |found| {
            found.selected(self, gpa);
            return;
        }
        if (state == .has_selectable_item or state == .found_currently_selected_item) {
            _ = self.select_first_element(self.root.type.panel.children.items, gpa);
        } else {
            debug("select_next_element() no element found. {s}", .{@tagName(state)});
        }
    }

    fn do_select_next_element(
        self: *Display,
        elements: []*Element,
        state: *SelectState,
        previous: *?*Element,
    ) ?*Element {
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
                if (element.type.panel.on_click.func == null) {
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
                    if (element.type.panel.on_click.func != null) {
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
                        if (element.type.button.toggle == .no_toggle or element.type.button.toggle == .on or element.type.button.toggle == .off or element.type.button.toggle == .disabled) {
                            return element;
                        }
                    },
                    .label => if (element.type.label.on_click.func != null) {
                        return element;
                    },
                    .sprite => if (element.type.sprite.on_click.func != null) {
                        return element;
                    },
                    .panel => if (is_under_cursor and element.type.panel.on_click.func != null) {
                        return element;
                    },
                    .rectangle, .progress_bar, .expander => {},
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

    /// Switch from the current theme to the next theme. This is a keypress
    /// event handler that expects `display`, `element` and `allocator`.
    pub fn rotate_theme(self: *Display, _: *Display, _: *Element, _: Allocator) void {
        var index: usize = 0;

        // Find the current theme
        for (self.themes.items) |*theme| {
            if (theme == self.theme) {
                break;
            }
            index += 1;
        }
        index += 1;
        if (index >= self.themes.items.len) {
            index = 0;
        }
        self.theme = &self.themes.items[index];
    }

    /// Update the quit flag to indicate to the main loop that
    /// it should exit after processing the current event.
    pub fn end_main_loop(display: *Display) void {
        info("Ending main loop.", .{});
        display.quit = true;
    }

    /// Draw all entities. Used in conjunction with SDL_AppIterate
    pub fn iterate(display: *Display) !void {
        try display.draw();
    }

    /// Enters the main run loop and only returns when quit has been
    /// requested. Use in conjunction with SDL_Main
    pub fn main(display: *Display, allocator: Allocator) !void {
        info("Main loop starting", .{});
        display.quit = false;

        while (!display.quit) {
            // Update and draw all elements
            try display.draw();

            // Handle any outstanding events on the event queue
            var e: sdl.SDL_Event = undefined;
            while (sdl.SDL_PollEvent(&e)) {
                try display.handle_event(allocator, &e);
                if (display.quit) break;
            }
        }

        debug("Main loop ended", .{});
    }

    inline fn handle_key_up_event(
        display: *Display,
        gpa: Allocator,
        e: *sdl.SDL_Event,
    ) !void {
        trace("handle_key_up_event({any})", .{e.key.key});
        if (e.key.key == sdl.SDLK_TAB) {
            if (e.key.mod == sdl.SDL_KMOD_SHIFT or e.key.mod == sdl.SDL_KMOD_LSHIFT or e.key.mod == sdl.SDL_KMOD_RSHIFT) {
                display.select_previous_element(gpa);
            } else {
                display.select_next_element(gpa);
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
                        try selected.chosen(display, gpa);
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
                        try selected.chosen(display, gpa);
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
                        try selected.chosen(display, gpa);
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
                        try selected.chosen(display, gpa);
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
                        try selected.chosen(display, gpa);
                        return; // keypress handled
                    }
                },
                .text_input => {
                    switch (e.key.key) {
                        sdl.SDLK_BACKSPACE,
                        sdl.SDLK_DELETE,
                        sdl.SDLK_KP_BACKSPACE,
                        => try selected.keypress(gpa, display, sdl.SDLK_BACKSPACE, ""),
                        sdl.SDLK_RETURN,
                        sdl.SDLK_KP_ENTER,
                        sdl.SDLK_RETURN2,
                        => {
                            switch (selected.type) {
                                .text_input => {
                                    try selected.keypress(gpa, display, 10, "");
                                },
                                .button => {
                                    if (selected.type.button.on_click.func != null) {
                                        try selected.type.button.on_click.func.?(selected.type.button.on_click.ptr, display, selected, gpa);
                                    }
                                },
                                else => {},
                            }
                        },
                        sdl.SDLK_ESCAPE => if (display.keybindings.get(sdl.SDLK_ESCAPE)) |f| {
                            try f.func.?(f.ptr, display, &display.root, gpa);
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
                trace("keypress has special handler: {d}", .{e.key.key});
                k.value_ptr.*.func.?(k.value_ptr.*.ptr, display, &display.root, gpa) catch |f| {
                    trace("keypress handler error: {d} {any}", .{ e.key.key, f });
                };
                trace("keypress special handler complete: {d}", .{e.key.key});
            }
        }
    }

    /// Handle key down events. Usually no action is triggered until the
    /// key is released.
    inline fn handle_key_down_event(_: *Display, _: Allocator, _: *sdl.SDL_Event) !void {
        //
    }

    /// Refresh the window size information, then refresh the
    /// safe area information.
    pub inline fn update_screen_metrics(display: *Display, forced: bool) void {
        var updated = false;

        var rwidth: c_int = 0;
        var rheight: c_int = 0;
        _ = sdl.SDL_GetRenderOutputSize(display.renderer, &rwidth, &rheight);
        if (display.root.rect.width != @as(f32, @floatFromInt(rwidth)))
            updated = true;
        if (display.root.rect.height != @as(f32, @floatFromInt(rheight)))
            updated = true;

        if (!updated) return;

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
        if (parent.on_resized.func) |on_resized| {
            if (parent.visible == .visible) {
                _ = on_resized(parent.on_resized.ptr, self, parent);
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
        if (!sdl.SDL_GetRenderSafeArea(self.renderer, &area)) {
            err("SDL_GetRenderSafeArea() failed", .{});
            return false;
        }

        if (self.old_safe_area.x != area.x or
            self.old_safe_area.y != area.y or
            self.old_safe_area.w != area.w or
            self.old_safe_area.h != area.h)
        {
            // Log when change is detected
            info("System reported safe area: {d}x{d} {d}x{d}", .{
                area.x,
                area.y,
                area.w,
                area.h,
            });
            self.old_safe_area = area;
        }

        // SDL_GetRenderSafeArea returns physical display pixels, not
        // window pretend pixels.
        const left_pad = @as(f32, @floatFromInt(area.x));
        const right_pad = self.root.rect.width - left_pad - @as(f32, @floatFromInt(area.w));
        var top_pad = @as(f32, @floatFromInt(area.y));
        var bottom_pad = self.root.rect.height - top_pad - @as(f32, @floatFromInt(area.h));

        if (builtin.abi.isAndroid()) {
            if (top_pad > 0 and bottom_pad > 0) {
                if (top_pad > bottom_pad) {
                    info("Android safe area hack {d},{d} -=> {d},{d}", .{
                        top_pad, bottom_pad,
                        0,       bottom_pad,
                    });
                    top_pad = 0;
                } else {
                    info("Android safe area hack {d},{d} -=> {d},{d}", .{
                        top_pad, bottom_pad,
                        top_pad, 0,
                    });
                    bottom_pad = 0;
                }
            }
        }

        var updated = false;
        if (!std.math.approxEqAbs(f32, self.safe_area.left, left_pad, 0.01)) updated = true;
        if (!std.math.approxEqAbs(f32, self.safe_area.top, top_pad, 0.01)) updated = true;
        if (!std.math.approxEqAbs(f32, self.safe_area.right, right_pad, 0.01)) updated = true;
        if (!std.math.approxEqAbs(f32, self.safe_area.bottom, bottom_pad, 0.01)) updated = true;

        if (updated) {
            info("safe area changed: {d} {d} {d} {d} -=> {d} {d} {d} {d}", .{
                self.safe_area.left,  self.safe_area.top,
                self.safe_area.right, self.safe_area.bottom,
                left_pad,             top_pad,
                right_pad,            bottom_pad,
            });
            self.safe_area.left = left_pad;
            self.safe_area.right = right_pad;
            self.safe_area.top = top_pad;
            self.safe_area.bottom = bottom_pad;
        } else if (dev_build and dev_mode) {
            info("current safe area: {d} {d} {d} {d} -=> {d} {d} {d} {d}", .{
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
        return updated;
    }

    /// The mouse up event idicates a mouse click, or the end of a mouse
    /// scroll/drag action.
    inline fn handle_mouse_up_event(display: *Display, gpa: Allocator, _: *sdl.SDL_Event) !void {
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
            found.selected(display, gpa);
            display.hovered = found;
            switch (found.type) {
                .panel => {
                    if (found.type.panel.on_click.func != null) {
                        try found.type.panel.on_click.func.?(found.type.panel.on_click.ptr, display, found, gpa);
                    } else if (found.type.panel.scrollable.scroll.x or found.type.panel.scrollable.scroll.y) {
                        display.scrolling = found;
                        display.scroll_start = cursor;
                        trace("begin scrolling {s} at {any}", .{ found.name, cursor });
                    }
                },
                .button => try found.chosen(display, gpa),
                .label => try found.chosen(display, gpa),
                .sprite => try found.chosen(display, gpa),
                .checkbox => try found.chosen(display, gpa),
                .text_input => found.selected(display, gpa),
                .rectangle, .progress_bar, .expander => {
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
    inline fn handle_mouse_down_event(display: *Display, _: Allocator, _: *sdl.SDL_Event) !void {
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

    /// When the user is dragging a scrollable panel, it starts with an offset
    /// `value` of zero. If the panel overflows its box, then the offset
    /// value may decrease to the `min` offset or increase to the `max` offset.
    fn limit_scroll(min: f32, value: f32, max: f32) f32 {
        std.debug.assert(min <= max);
        if (value < min) return min;
        if (value > max) return max;
        return value;
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

                    // Clamp offset so we cant scroll past end at all
                    switch (element.child_align.x) {
                        .centre => {
                            // allowable scroll offset (negative number)
                            const allowable_x_scroll = @min(0, element.rect.width - panel.scrollable.size.width) / 2;
                            element.offset.x = limit_scroll(allowable_x_scroll, element.offset.x, -allowable_x_scroll);
                        },
                        else => {
                            // allowable scroll offset (negative number)
                            const allowable_x_scroll = @min(0, element.rect.width - panel.scrollable.size.width);
                            element.offset.x = limit_scroll(allowable_x_scroll, element.offset.x, 0);
                        },
                    }

                    // Clamp offset so we cant scroll past start at all
                    switch (element.child_align.y) {
                        .centre => {
                            const allowable_y_scroll = @min(0, element.rect.height - panel.scrollable.size.height) / 2;
                            element.offset.y = limit_scroll(allowable_y_scroll, element.offset.y, -allowable_y_scroll);
                        },
                        else => {
                            const allowable_y_scroll = @min(0, element.rect.height - panel.scrollable.size.height);
                            element.offset.y = limit_scroll(allowable_y_scroll, element.offset.y, 0);
                        },
                    }

                    if (!panel.scrollable.scroll.y)
                        element.offset.y = 0;

                    if (!panel.scrollable.scroll.x)
                        element.offset.x = 0;

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
                    trace("entered panel hover({s} {s}) panel content {d}x{d}.  usable area: {d}x{d}", .{
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
    pub fn handle_event(display: *Display, allocator: Allocator, e: *sdl.SDL_Event) !void {
        switch (e.type) {
            sdl.SDL_EVENT_TEXT_INPUT => {
                if (display.selected) |selected| {
                    if (selected.type == .text_input) {
                        try selected.keypress(
                            allocator,
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
            sdl.SDL_EVENT_KEY_UP => try display.handle_key_up_event(allocator, e),
            sdl.SDL_EVENT_KEY_DOWN => try display.handle_key_down_event(allocator, e),
            sdl.SDL_EVENT_MOUSE_BUTTON_DOWN => try display.handle_mouse_down_event(allocator, e),
            sdl.SDL_EVENT_MOUSE_BUTTON_UP => try display.handle_mouse_up_event(allocator, e),
            sdl.SDL_EVENT_MOUSE_MOTION => try display.handle_mouse_motion_event(e),

            sdl.SDL_EVENT_SYSTEM_THEME_CHANGED => display.update_system_theme(),
            sdl.SDL_EVENT_WINDOW_RESIZED,
            sdl.SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED,
            sdl.SDL_EVENT_DISPLAY_ORIENTATION,
            sdl.SDL_EVENT_WINDOW_SAFE_AREA_CHANGED,
            => display.update_screen_metrics(false),

            sdl.SDL_EVENT_QUIT => display.end_main_loop(),

            sdl.SDL_EVENT_TERMINATING => {},
            sdl.SDL_EVENT_LOW_MEMORY => {},
            sdl.SDL_EVENT_WILL_ENTER_BACKGROUND => {},
            sdl.SDL_EVENT_DID_ENTER_BACKGROUND => {},
            sdl.SDL_EVENT_WILL_ENTER_FOREGROUND => {},
            sdl.SDL_EVENT_DID_ENTER_FOREGROUND => {},

            else => {
                if (display.event_hook.func) |eh| {
                    try eh(display.event_hook.ptr, display, e.type);
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

    /// Keypress event handler expects `display`, `element` and `allocator`.
    pub fn increase_size(_: *Display, display: *Display, _: *Element, _: Allocator) void {
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

    /// Keypress event handler expects `display`, `element` and `allocator`.
    pub fn decrease_size(display: *Display, _: *Display, _: *Element, _: Allocator) void {
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

    /// Keypress event handler expects `display`, `element` and `allocator`.
    fn make_bundle(display: *Display, _: *Display, _: *Element, _: Allocator) error{OutOfMemory}!void {
        if (!dev_build) {
            return;
        }
        //const allocator = app_context.?.allocator;
        if (display.resources.used_resource_list) |manifest| {
            if (manifest.items.len == 0) {
                info("no resources in manifest, nothing to bundle.", .{});
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
            var buffer = BoundedArray(u8, 1000){};
            buffer.appendSlice(base_folder) catch {
                return std.mem.Allocator.Error.OutOfMemory;
            };
            buffer.appendSlice(RESOURCE_BUNDLE_FILENAME) catch {
                return std.mem.Allocator.Error.OutOfMemory;
            };
            info("making resource bundle: {s}", .{buffer.slice()});

            display.resources.save_bundle(buffer.slice(), manifest.items, .{}, "/tmp") catch |e| {
                info("save resource bundle failed. {s} {any}", .{ buffer.slice(), e });
            };
        } else {
            info("no resource bundle manifest", .{});
        }
    }

    /// Provides a standardised way to place a back button in the top left
    /// corner of the screen.
    pub fn add_back_button(
        display: *Display,
        allocator: Allocator,
        parent: *Element,
        close_fn: Callback,
    ) (Error || Allocator.Error || Resources.Error)!*Element {
        return try parent.add(
            allocator,
            display,
            .{
                .name = "back",
                .focus = .can_focus,
                .rect = .{ .x = 20, .y = 20, .width = 120, .height = 120 },
                .pad = .{ .left = 20, .right = 20, .top = 20, .bottom = 20 },
                .layout = .{ .x = .fixed, .y = .fixed, .position = .float },
                .type = .{ .button = .{
                    .icon_default_name = "icon-back",
                    .icon_pressed_name = "icon-back",
                    .icon_hover_name = "icon-back",
                    .text = "",
                    .translated = "",
                    .on_click = close_fn,
                    .icon_size = .{ .width = 70, .height = 70 },
                } },
                .on_resized = .{ .func = @ptrCast(&back_button_resize), .ptr = display },
            },
        );
    }

    /// Add an empty panel that keeps a space open in a list of elements.
    pub fn add_spacer(
        display: *Display,
        allocator: Allocator,
        parent: *Element,
        size: f32,
    ) (Error || Allocator.Error || Resources.Error)!*Element {
        return try parent.add(allocator, display, .{
            .name = "spacer",
            .rect = .{ .width = size, .height = size },
            .layout = .{ .x = .shrinks, .y = .shrinks },
            .minimum = .{ .width = size, .height = size },
            .type = .{ .panel = .{} },
        });
    }

    /// Add a label with generic settings needed for a paragraph.
    pub fn add_paragraph(
        display: *Display,
        allocator: Allocator,
        parent: *Element,
        size: TextSize,
        name: []const u8,
        text: []const u8,
    ) (Error || Allocator.Error || Resources.Error)!void {
        _ = try parent.add(allocator, display, .{
            .name = name,
            .style = .normal,
            .focus = .accessibility_focus,
            .rect = .{ .x = 250, .y = 50, .width = 500, .height = 80 },
            .layout = .{ .y = .shrinks, .x = .grows },
            .child_align = .{ .x = .start, .y = .start },
            .type = .{ .label = .{
                .text = text,
                .translated = "",
                .text_size = size,
            } },
        });
    }

    pub fn setup_element(
        self: *Display,
        allocator: Allocator,
        element: *Element,
    ) (Error || Allocator.Error || Resources.Error)!void {
        switch (element.type) {
            .panel => try setup_panel(self, allocator, element),
            .button => try setup_button(self, allocator, element),
            .label => try setup_label(self, allocator, element),
            .rectangle => try setup_rect(self, allocator, element),
            .checkbox => try setup_checkbox(self, allocator, element),
            .sprite => try setup_sprite(self, allocator, element),
            .progress_bar => try setup_progress_bar(self, allocator, element),
            .expander => try setup_expander(self, allocator, element),
            .text_input => try setup_text_input(self, allocator, element),
        }
    }
};

fn toggle_dev_mode(_: *Display, _: *Element, _: Allocator) error{OutOfMemory}!void {
    engine.dev_mode = !engine.dev_mode;
    info("Dev mode: {any}", .{engine.dev_mode});
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
    if (parent.visible == .hidden) return 0;
    if (parent.layout.position == .float) return 0;

    const available_width = parent.rect.width - parent.pad.left - parent.pad.right;

    switch (parent.type.panel.direction) {
        .top_to_bottom => {
            // a, above b, above c. (top to bottom)
            var minimum_needed: f32 = parent.pad.top + parent.pad.bottom;
            // Add the size needed for each inline child.
            var first = true;
            for (parent.type.panel.children.items) |element| {
                if (element.layout.position == .float) continue;
                if (element.visible == .hidden) continue;
                if (first) {
                    first = false;
                } else {
                    // Add spacing before next element, if needed
                    minimum_needed += parent.type.panel.spacing;
                }
                const height = element.shrink_height(display, available_width);
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

        .centre, .left_to_right, .left_to_right_wrap, .top_left => {
            // centred all together
            // a, next to b, next c.
            //
            // Just need to know the highest/tallest child.
            var minimum_needed: f32 = 0;
            for (parent.type.panel.children.items) |element| {
                if (element.layout.position == .float) {
                    continue;
                }
                const height = element.shrink_height(display, available_width);
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
pub fn back_button_resize(_: *Display, display: *Display, element: *Element) bool {
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
    if (parent.visible == .hidden) return 0;
    if (parent.layout.position == .float) return 0;

    const available_width = parent.rect.width - parent.pad.left - parent.pad.right;

    switch (parent.type.panel.direction) {
        .left_to_right => {
            // a, next to b, next to c. (left to right)
            //
            // Need to add up the min width of all items
            var minimum_needed: f32 = parent.pad.left + parent.pad.right;
            var first = true;
            for (parent.type.panel.children.items) |element| {
                if (element.layout.position == .float) continue;
                if (element.visible == .hidden) continue;

                // Add space between each element.
                if (first)
                    first = false
                else
                    minimum_needed += parent.type.panel.spacing;

                const width = element.shrink_width(display, available_width);
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
        .left_to_right_wrap => {
            var minimum_needed: f32 = parent.pad.left + parent.pad.right;
            var first = true;
            for (parent.type.panel.children.items) |element| {
                if (element.layout.position == .float) continue;
                if (element.visible == .hidden) continue;

                // Add space between each element.
                if (first)
                    first = false
                else
                    minimum_needed += parent.type.panel.spacing;

                const width = element.shrink_width(display, available_width);
                minimum_needed = @max(minimum_needed, width);
            }
            // Bound to the minimum/maximum width
            minimum_needed += parent.pad.left + parent.pad.right;
            if (parent.maximum.width > 0 and parent.maximum.width < minimum_needed) {
                minimum_needed = parent.maximum.width;
            }
            return @max(minimum_needed, parent.minimum.width);
        },
        .centre, .top_to_bottom, .top_left => {
            // a, centred upon b, centred upon c
            // a, then b underneath, thn c underneath...
            //
            // Need to just find maximum width item
            var minimum_needed: f32 = 0;
            for (parent.type.panel.children.items) |element| {
                if (element.layout.position == .float) continue;
                if (element.visible == .hidden) continue;

                const width = element.shrink_width(display, available_width);
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

pub fn setup_rect(
    _: *Display,
    _: Allocator,
    element: *Element,
) (Error || Allocator.Error || Resources.Error)!void {
    element.texture = null;
    element.background.image = null;
    if (element.focus == .unspecified) {
        element.focus = .never_focus;
    }
}

pub fn setup_panel(
    self: *Display,
    allocator: Allocator,
    element: *Element,
) (Error || Allocator.Error || Resources.Error)!void {
    element.texture = null;
    element.background.image = null;

    if (element.focus == .unspecified) {
        if (element.type.panel.on_click.func != null) {
            element.focus = .can_focus;
        } else {
            element.focus = .never_focus;
        }
    }

    if (element.background.image_name) |name| {
        if (try self.load_texture(allocator, name)) |texture| {
            element.background.image = texture;
        } else {
            err("Failed to load panel background image named \"{s}\"", .{name});
        }
    }

    element.type.panel.children = .empty;
}

pub fn setup_progress_bar(
    self: *Display,
    allocator: Allocator,
    element: *Element,
) (Error || Allocator.Error || Resources.Error)!void {
    element.texture = null;
    element.background.image = null;
    if (element.focus == .unspecified) {
        element.focus = .never_focus;
    }

    if (element.type != .progress_bar) {
        err("create_progress_bar called without config.", .{});
        element.type = .{ .progress_bar = .{} };
    }

    if (try self.load_texture(allocator, "rounded progress bar")) |texture| {
        element.texture = texture;
    } else {
        err("Failed to load progress_bar texture named \"rounded progress bar\"", .{});
    }
}

pub fn setup_checkbox(
    self: *Display,
    allocator: Allocator,
    element: *Element,
) (Error || Allocator.Error || Resources.Error)!void {
    element.texture = null;
    element.background.image = null;
    element.type.checkbox.translated = "";
    element.type.checkbox.elements = .empty;
    element.type.checkbox.font = select_font(self.fonts.items, element.type.checkbox.font_name);

    if (element.focus == .unspecified)
        element.focus = .can_focus;

    try element.set_text(allocator, self, element.type.checkbox.text, true);

    if (try self.load_texture(allocator, "ios-checkbox-on")) |texture| {
        element.type.checkbox.on_texture = texture;
    }
    if (try self.load_texture(allocator, "ios-checkbox-off")) |texture| {
        element.type.checkbox.off_texture = texture;
    }

    // Is there a background for this checkbox
    if (element.background.image_name) |name| {
        if (try self.load_texture(allocator, name)) |texture|
            element.background.image = texture;
    }

    if (element.pad.top == 0 and element.pad.bottom == 0 and element.pad.left == 0 and element.pad.right == 0) {
        element.pad.left = self.text_height * self.scale * 0.8;
        element.pad.right = self.text_height * self.scale * 0.8;
        element.pad.top = self.text_height * self.scale * 0.3;
        element.pad.bottom = self.text_height * self.scale * 0.3;
    }

    const size = self.checkbox();
    if (element.minimum.height < size.height)
        element.minimum.height = size.height;

    if (element.minimum.width < size.width)
        element.minimum.width = size.width;
}

pub fn setup_expander(
    _: *Display,
    _: Allocator,
    element: *Element,
) (Error || Allocator.Error || Resources.Error)!void {
    element.texture = null;
    element.background.image = null;
    element.focus = .never_focus;
}

pub fn setup_label(
    self: *Display,
    allocator: Allocator,
    element: *Element,
) (Error || Allocator.Error || Resources.Error)!void {
    element.texture = null;
    element.background.image = null;
    element.type.label.translated = "";
    element.type.label.elements = .empty;
    element.type.label.font = select_font(self.fonts.items, element.type.label.font_name);

    if (element.focus == .unspecified) {
        if (element.type.label.on_click.func != null)
            element.focus = .can_focus
        else
            element.focus = .accessibility_focus;
    }
    try element.set_text(allocator, self, element.type.label.text, true);

    // Is there a background for this label?
    if (element.background.image_name) |name| {
        if (try self.load_texture(allocator, name)) |texture|
            element.background.image = texture;
    }

    if (element.pad.top == 0 and element.pad.bottom == 0 and element.pad.left == 0 and element.pad.right == 0) {
        element.pad.top = self.text_height * self.scale * 0.3;
        element.pad.bottom = self.text_height * self.scale * 0.3;
    }
}

pub fn setup_text_input(
    self: *Display,
    allocator: Allocator,
    element: *Element,
) (Error || Allocator.Error || Resources.Error)!void {
    element.texture = null;
    element.background.image = null;
    if (element.focus == .unspecified) {
        element.focus = .can_focus;
    }
    element.type.text_input.font = select_font(self.fonts.items, element.type.text_input.font_name);

    if (element.type.text_input.icon_texture_name) |icon| {
        if (try self.load_texture(allocator, icon)) |texture| {
            element.texture = texture;
        } else {
            err("Failed to load text_input icon texture named \"{s}\"", .{icon});
        }
    }

    if (element.background.image_name) |background| {
        if (try self.load_texture(allocator, background)) |texture| {
            element.background.image = texture;
        } else {
            err("Failed to load text_input background image named \"{s}\"", .{background});
        }
    }

    if (element.pad.top == 0 and element.pad.bottom == 0) {
        element.pad.left = self.text_height * self.scale * 0.6;
        element.pad.right = self.text_height * self.scale * 0.6;
        element.pad.top = self.text_height * self.scale * 0.5;
        element.pad.bottom = self.text_height * self.scale * 0.5;
    }

    element.focus = .can_focus;
    element.rect.height = (self.text_height * self.scale) + (element.pad.top + element.pad.bottom);

    element.type.text_input.text = .empty;
    element.type.text_input.runes = .empty;
    if (element.type.text_input.initial_text) |text| {
        try element.set_text(allocator, self, text, true);
    } else {
        try element.set_text(allocator, self, "", true);
    }
    if (element.type.text_input.placeholder_text) |text| {
        try element.set_placeholder_text(allocator, self, text);
    } else {
        try element.set_placeholder_text(allocator, self, "");
    }
}

pub fn setup_sprite(
    self: *Display,
    allocator: Allocator,
    element: *Element,
) (Error || Allocator.Error || Resources.Error)!void {
    element.texture = null;
    element.background.image = null;
    if (element.focus == .unspecified)
        element.focus = .accessibility_focus;

    if (element.texture_name) |image| {
        if (try self.load_texture(allocator, image)) |texture| {
            element.texture = texture;
            if (element.rect.width == 0)
                element.rect.width = @floatFromInt(texture.texture.w);
            if (element.rect.height == 0)
                element.rect.height = @floatFromInt(texture.texture.h);
        } else {
            err("Failed to load sprite texture named \"{s}\"", .{image});
        }
    }

    if (element.background.image_name) |image| {
        if (try self.load_texture(allocator, image)) |texture| {
            element.background.image = texture;
            if (element.rect.width == 0)
                element.rect.width = @floatFromInt(texture.texture.w);
            if (element.rect.height == 0)
                element.rect.height = @floatFromInt(texture.texture.h);
        } else {
            err("Failed to load sprite background image named \"{s}\" for button \"{s}\"", .{ image, element.name });
        }
    }

    if (element.texture_name != null)
        trace("sprite {s} fg {s}", .{ element.name, element.texture_name.? });
    if (element.background.image_name != null)
        trace("sprite {s} bg {s}", .{ element.name, element.background.image_name.? });
}

fn select_font(fonts: []*Font, name: ?[]const u8) *Font {
    if (name) |font_name| {
        for (fonts) |font| {
            if (std.mem.eql(u8, font.name, font_name)) {
                return font;
            }
        }
        err("select_font({s}) called, but no fonts have been loaded.", .{name.?});
    }
    if (fonts.len > 0) return fonts[0];

    std.debug.assert(fonts.len > 0);
    unreachable; // select_font requires at least one font
}

pub fn setup_button(
    display: *Display,
    allocator: Allocator,
    element: *Element,
) (Error || Allocator.Error || Resources.Error)!void {
    element.type.button.translated = "";
    element.texture = null;
    element.background.image = null;
    element.type.button.icon_pressed = null;
    element.type.button.icon_hover = null;
    element.type.button.icon_disabled = null;
    element.type.button.background_pressed = null;
    element.type.button.background_hover = null;
    element.type.button.background_disabled = null;
    element.type.button.text_size = .normal;
    element.type.button.font = select_font(display.fonts.items, element.type.button.font_name);

    if (element.focus == .unspecified)
        element.focus = .can_focus;

    if (element.texture_name != null)
        warn("button `{s}` has texture_name `{s}`. Buttons use `icon_default_name`", .{
            element.name,
            element.texture_name.?,
        });

    if (element.background.image_name != null)
        warn("button `{s}` has background.image_name `{s}`. Buttons do not use `background.image_name`", .{
            element.name,
            element.background.image_name.?,
        });

    try element.set_text(allocator, display, element.type.button.text, true);

    if (element.type.button.icon_default_name) |icon_default| {
        if (try display.load_texture(allocator, icon_default)) |texture| {
            element.texture = texture;
            if (element.type.button.icon_size.width == 0 or element.type.button.icon_size.height == 0)
                warn("button `{s}` has icon `{s}`, but no icon size.", .{
                    element.name,
                    icon_default,
                });
        }
    }

    if (element.type.button.icon_pressed_name) |icon_pressed| {
        if (try display.load_texture(allocator, icon_pressed)) |ip|
            element.type.button.icon_pressed = ip
        else
            err("setup_button failed to load icon_pressed resource {s}.", .{icon_pressed});

        if (element.type.button.icon_pressed == null and element.texture != null)
            element.type.button.icon_pressed = element.texture.?.clone();
    }

    if (element.type.button.icon_hover_name) |icon_hover| {
        if (try display.load_texture(allocator, icon_hover)) |ih|
            element.type.button.icon_hover = ih
        else
            err("setup_button failed to load icon_hover resource {s}.", .{icon_hover});

        if (element.type.button.icon_hover == null and element.texture != null)
            element.type.button.icon_hover = element.texture.?.clone();
    }

    if (element.type.button.icon_disabled_name) |icon_disabled| {
        if (try display.load_texture(allocator, icon_disabled)) |ih|
            element.type.button.icon_disabled = ih
        else
            err("setup_button failed to load icon_disabled resource {s}.", .{icon_disabled});

        if (element.type.button.icon_disabled == null and element.texture != null)
            element.type.button.icon_disabled = element.texture.?.clone();
    }

    if (element.type.button.background_default_name) |background_default| {
        if (try display.load_texture(allocator, background_default)) |texture|
            element.background.image = texture
        else
            err("setup_button failed to load background_default resource {s}.", .{background_default});
    }

    if (element.type.button.background_pressed_name) |background_pressed| {
        if (try display.load_texture(allocator, background_pressed)) |bp|
            element.type.button.background_pressed = bp
        else
            err("setup_button background_pressed resource resource `{s}` not loaded.", .{background_pressed});

        if (element.type.button.background_pressed == null and element.background.image != null)
            element.type.button.background_pressed = element.background.image.?.clone();
    }

    if (element.type.button.background_hover_name) |background_hover| {
        if (try display.load_texture(allocator, background_hover)) |bh|
            element.type.button.background_hover = bh
        else
            err("setup_button background_hover resource `{s}` not loaded.", .{background_hover});

        if (element.type.button.background_hover == null and element.background.image != null)
            element.type.button.background_hover = element.background.image.?.clone();
    }

    if (element.type.button.background_disabled_name) |background_disabled| {
        if (try display.load_texture(allocator, background_disabled)) |bh|
            element.type.button.background_disabled = bh
        else
            err("setup_button background_disabled resource `{s}` not loaded.", .{background_disabled});

        if (element.type.button.background_disabled == null and element.background.image != null)
            element.type.button.background_disabled = element.background.image.?.clone();
    }
}

/// Load and associate an image file with a sprite name.
pub fn create_sprite(
    allocator: Allocator,
    display: *Display,
    settings: Element,
) (Error || Allocator.Error || Resources.Error)!*Element {
    const element = try allocator.create(Element);
    element.* = settings;
    try display.setup_element(allocator, element);
    return element;
}

/// Load and associate an image file with a sprite name.
pub fn create_rect(
    display: *Display,
    allocator: Allocator,
    settings: Element,
) Allocator.Error!*Element {
    const element = try display.allocator.create(Element);
    element.* = settings;
    try display.setup_element(allocator, element);
    return element;
}

/// Load and process text for a label.
pub fn create_label(
    allocator: Allocator,
    display: *Display,
    settings: Element,
) (Error || Allocator.Error || Resources.Error)!*Element {
    const element = try display.allocator.create(Element);
    element.* = settings;
    try display.setup_element(allocator, element);
    return element;
}

/// Load and process text for a label.
pub fn create_checkbox(
    allocator: Allocator,
    display: *Display,
    settings: Element,
) (Error || Allocator.Error || Resources.Error)!*Element {
    const element = try allocator.create(Element);
    element.* = settings;
    try display.setup_element(allocator, element);
    return element;
}

/// Load a button with textures for each state
pub fn create_button(
    allocator: Allocator,
    display: *Display,
    settings: Element,
) (Error || Allocator.Error || Resources.Error)!*Element {
    const element = try allocator.create(Element);
    element.* = settings;
    try display.setup_element(allocator, element);
    return element;
}

/// Load and process text for a label.
pub fn create_text_input(
    allocator: Allocator,
    display: *Display,
    settings: Element,
) (Error || Allocator.Error || Resources.Error)!*Element {
    const element = try allocator.create(Element);
    element.* = settings;
    try display.setup_element(allocator, element);
    return element;
}

/// Load a standard progress bar.
pub fn create_progress_bar(
    allocator: Allocator,
    display: *Display,
    settings: Element,
) (Error || Allocator.Error || Resources.Error)!*Element {
    const element = try allocator.create(Element);
    element.* = settings;
    try display.setup_element(allocator, element);
    return element;
}

/// An expander should have a minimum height/width and a weight of zero, or
/// it may have a greater than zero weight.
///
/// When a panel has excess space, thie expander takes a percentage
/// of the space based on its weight.
pub fn create_expander(
    allocator: Allocator,
    display: *Display,
    settings: Element,
) (Error || Allocator.Error || Resources.Error)!*Element {
    const element = try allocator.create(Element);
    element.* = settings;
    try display.setup_element(allocator, element);
    return element;
}

/// A panel contains child items. The children are usually displayed
/// from left to right or top to bottom. A panel may also contain
/// floating items that appear anywhere on the screen, not just inside
/// the panel.
pub fn create_panel(
    allocator: Allocator,
    display: *Display,
    settings: Element,
) (Allocator.Error || Error || Resources.Error)!*Element {
    const element = try allocator.create(Element);
    element.* = settings;
    try display.setup_element(allocator, element);
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
) callconv(.c) void {
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
        return std.meta.intToEnum(SdlLogCategory, category) catch .unknown;
    }
};

/// A `trace` message can be used liberally and should only be used for
/// log messages in programs that are under active development. Is never
/// included in a production ready build of an application.
pub inline fn trace(comptime format: []const u8, args: anytype) void {
    if (dev_build)
        if (dev_mode)
            log_output(.trace, .engine, format, args);
}

/// A `debug` message should only be used when it is generally useful for
/// helping track down abnormal program behaviour. A debug message is usually
/// interesting even in a production ready build of an application.
///
/// Examples of this would include: reporting when a user changes their font
/// size or screen resolution to allow support staff to understand what
/// actions might have lead to an unexpected program state.
pub inline fn debug(comptime format: []const u8, args: anytype) void {
    if (dev_build or dev_mode) {
        log_output_handler(.debug, .engine, format, args);
    }
}

/// Log general information that might be useful for collection or human
/// review at some point in the future.
///
/// Examples of this might include reporting creation of a new user account.
pub inline fn info(comptime format: []const u8, args: anytype) void {
    log_output_handler(.info, .engine, format, args);
}

/// A `notice` info log message is like a regular `info` log message but
/// it may be particularly important and might need to be brought to the
/// attention of a human at a higher priority than a regular `info` message.
///
/// Examples of this might be reporting the normal activity of creation
/// of a new user account, but with an IP address of a country that is not
/// expected to be accessing the application.
pub inline fn notice(comptime format: []const u8, args: anytype) void {
    log_output_handler(.notice, .engine, format, args);
}

/// A `warn` indicates something unexpected or unusual that might not
/// be an error.
pub inline fn warn(comptime format: []const u8, args: anytype) void {
    log_output_handler(.warn, .engine, format, args);
}

/// An `err` indicates abnormal behaviour that requires attention at
/// some point in the future, but might not be urgent. An error would _not_
/// typically be linked to an SMS or pager system for developer review. Use
/// this when you do _not_ need support staff to be immediately notified.
///
/// Examples of this might include: an app that cant find an image resource
/// to display but will continue to function correctly;
pub inline fn err(comptime format: []const u8, args: anytype) void {
    log_output_handler(.err, .engine, format, args);
}

/// An `alert` is an error that may require immediate or high priority
/// human attention. An alert would typically be linked to an SMS or
/// pager system. Only use this if support staff should be woken up in the
/// middle of the night to resolve this.
///
/// Examples of this might include: a web server unable to contact the
/// database; or actvity that is indicative of a security intrusion.
pub inline fn alert(comptime format: []const u8, args: anytype) void {
    log_output_handler(.alert, .engine, format, args);
}

/// A log level enum that adds `trace`, `notice`, and `alert`
///
/// Zig log levels allow `err` but dont allow flagging an error `alert`
/// that requires immediate action/intervention.
/// Zig also does not distinguish between a general info log message and an
/// info `notice` that might require immediate action.
pub const LogLevel = enum {
    trace,
    debug,
    info,
    notice,
    warn,
    err,
    alert,
};

/// Write a log message to stderr in debug mode or to SDL in release mode
pub fn log_output(
    comptime level: LogLevel,
    comptime scope: @Type(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    var buffer: [1024 * 5]u8 = undefined;
    var stderr_writer = std.fs.File.stderr().writer(&buffer);
    const stderr = &stderr_writer.interface;

    if (builtin.mode == .Debug) {
        const prefix = switch (level) {
            .trace => "\x1B[90m[\x1B[1mtrace\x1B[22m] ",
            .debug => "\x1B[34m[\x1B[1mdebug\x1B[22m] ",
            .info => "\x1B[36m[\x1B[1minfo\x1B[22m]  ",
            .notice => "\x1B[91m[\x1B[1minfo\x1B[22m] ",
            .warn => "\x1B[33m[\x1B[1mwarn\x1B[22m]  ",
            .err => "\x1B[31m[\x1B[1merror\x1B[22m] ",
            .alert => "\x1B[31m[\x1B[1malert\x1B[22m] ",
        };
        // Log to terminal in debug mode
        std.debug.lockStdErr();
        defer std.debug.unlockStdErr();
        nosuspend stderr.print(prefix ++ format ++ "\x1B[0m\n", args) catch return;
        stderr.flush() catch {};
    } else {
        const prefix = switch (level) {
            .trace => "[trace] ",
            .debug => "[debug] ",
            .info => "[info] ",
            .notice => "[info] ",
            .warn => "[warn] ",
            .err => "[error] ",
            .alert => "[alert] ",
        };
        // Log using SDL when in release mode
        if (scope != .term_scope) {
            if (std.fmt.bufPrintZ(&buffer, prefix ++ format, args)) |f| {
                sdl.SDL_LogInfo(@intFromEnum(SdlLogCategory.application), f.ptr);
            } else |_| {
                sdl.SDL_LogInfo(@intFromEnum(SdlLogCategory.application), prefix ++ format);
            }
        }
    }
}

/// Tell zig to pass log messages to a custom `log_output_handler`
pub const std_options: std.Options = .{
    .log_level = .debug,
    .logFn = log_output_handler,
};

/// Zig log output handler captures zig log calls
pub fn log_output_handler(
    comptime level: std.log.Level,
    comptime scope: @Type(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    // Map the limit zig log options to proper log levels.
    switch (level) {
        .debug => log_output(.debug, scope, format, args),
        .info => log_output(.info, scope, format, args),
        .warn => log_output(.warn, scope, format, args),
        .err => log_output(.err, scope, format, args),
    }
}

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
    var display = try Display.create(allocator, "test", "test", "test", "./test/repo", null, "test translation", 0);
    defer display.destroy(allocator);
}

test "button sizing" {
    const allocator = std.testing.allocator;
    // The display takes ownership of the resources object
    var display = try Display.create(allocator, "test", "test", "test", "./test/repo", null, "test translation", 0);
    defer display.destroy(allocator);
    _ = try display.load_font(allocator, "Roboto-Light");
    try eq(1, display.fonts.items.len);

    const panel = try display.add_panel(allocator, .{
        .minimum = .{ .width = 5, .height = 8 },
        .type = .{ .panel = .{ .spacing = 0, .direction = .left_to_right } },
        .layout = .{ .x = .shrinks, .y = .shrinks },
    });
    try eq(5, panel.shrink_width(display, 500));
    try eq(8, panel.shrink_height(display, 500));

    var button = try panel.add(allocator, display, .{
        .visible = .visible,
        .rect = .{ .width = 50, .height = 50 },
        .minimum = .{ .width = 42, .height = 41 },
        .maximum = .{ .width = 82, .height = 81 },
        .type = .{ .button = .{ .text = "" } },
    });
    display.relayout();
    try eq(50, button.shrink_width(display, 500));
    try eq(50, button.shrink_height(display, 500));
    button.layout.x = .shrinks;
    button.layout.y = .shrinks;
    try eq(42, button.shrink_width(display, 500));
    try eq(41, button.shrink_height(display, 500));
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
    _ = try display.load_font(allocator, "Roboto-Light");

    try button.set_text(allocator, display, "Hello", true);
    display.relayout();
    try eq(83, @trunc(button.rect.width));
    try eq(100, @trunc(panel.rect.width));
    try eq(44, button.rect.height);
    try eq(0, panel.rect.height);
}

test "text input sizing" {
    const allocator = std.testing.allocator;
    // The display takes ownership of the resources object
    var display = try Display.create(allocator, "test", "test", "test", "./test/repo", null, "test translation", 0);
    defer display.destroy(allocator);

    // Add test font so we can test label layout
    try std.testing.expect(display.resources.by_uid.count() > 0);
    _ = try display.load_font(allocator, "Roboto-Light");

    {
        // Create a fixed sized label with enough space
        const l = try create_label(allocator, display, .{
            .name = "hello",
            .rect = .{ .width = 500, .height = 60 },
            .minimum = .{ .width = 300, .height = 50 },
            .maximum = .{ .width = 401, .height = 201 },
            .type = .{ .label = .{ .text = "Hello world" } },
            .layout = .{ .x = .fixed, .y = .grows },
        });
        defer l.destroy(display, allocator);
        l.pad = .{ .top = 0, .bottom = 0, .left = 0, .right = 0 };
        try eq(500, l.shrink_width(display, 500));
        try eq(50, l.shrink_height(display, 500));
    }

    {
        // Create a fixed sized label with minimum
        const l = try create_label(allocator, display, .{
            .name = "hello",
            .rect = .{ .width = 500, .height = 60 },
            .minimum = .{ .width = 300, .height = 55 },
            .maximum = .{ .width = 401, .height = 201 },
            .type = .{ .label = .{ .text = "Hello world" } },
            .layout = .{ .x = .fixed, .y = .fixed },
        });
        defer l.destroy(display, allocator);
        l.pad = .{ .top = 0, .bottom = 0, .left = 0, .right = 0 };
        try eq(500, l.shrink_width(display, 500));
        try eq(60, l.shrink_height(display, 500));
    }

    {
        // Create a fixed sized label with minimum
        const l = try create_label(allocator, display, .{
            .name = "hello",
            .rect = .{ .width = 200, .height = 100 },
            .minimum = .{ .width = 300, .height = 20 },
            .maximum = .{ .width = 401, .height = 201 },
            .type = .{ .label = .{ .text = "Hello world" } },
            .layout = .{ .x = .grows, .y = .shrinks },
        });
        defer l.destroy(display, allocator);
        l.pad = .{ .top = 0, .bottom = 0, .left = 0, .right = 0 };
        try eq(300, l.shrink_width(display, 500));
        try eq(44, l.shrink_height(display, 500));
    }

    {
        // Create a fixed sized label with x growth
        const l = try create_label(allocator, display, .{
            .name = "hello",
            .rect = .{ .width = 1, .height = 1 },
            .minimum = .{ .width = 1, .height = 20 },
            .maximum = .{ .width = 401, .height = 201 },
            .type = .{ .label = .{ .text = "Hello world" } },
            .layout = .{ .x = .grows, .y = .shrinks },
        });
        defer l.destroy(display, allocator);
        l.pad = .{ .top = 0, .bottom = 0, .left = 0, .right = 0 };
        try eq(91, @round(l.shrink_width(display, 500)));
        try eq(44, l.shrink_height(display, 500));
    }

    {
        // Create a label with full shrinking
        const l = try create_label(allocator, display, .{
            .name = "hello",
            .rect = .{ .width = 1, .height = 1 },
            .minimum = .{ .width = 1, .height = 20 },
            .maximum = .{ .width = 401, .height = 201 },
            .type = .{ .label = .{ .text = "Hello world" } },
            .layout = .{ .x = .shrinks, .y = .shrinks },
        });
        defer l.destroy(display, allocator);
        l.pad = .{ .top = 0, .bottom = 0, .left = 0, .right = 0 };
        try eq(2, l.type.label.elements.items.len);
        try eq(98, @trunc(l.type.label.elements.items[0].width / display.scale));
        try eq(107, @trunc(l.type.label.elements.items[1].width / display.scale));
        try eq(90, @trunc(l.shrink_width(display, 500)));
        try eq(44, l.shrink_height(display, 500));
        try eq(88, l.shrink_height(display, 115));
    }

    var panel = try display.add_panel(allocator, .{
        .rect = .{ .width = 500, .height = 200 },
        .minimum = .{ .width = 5, .height = 8 },
        .type = .{ .panel = .{ .spacing = 0, .direction = .top_to_bottom } },
        .layout = .{ .x = .shrinks, .y = .shrinks },
    });
    try eq(5, panel.shrink_width(display, 500));
    try eq(8, panel.shrink_height(display, 500));

    var label = try panel.add(allocator, display, .{
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

    panel.layout.x = .shrinks;
    panel.layout.y = .shrinks;
    label.layout.x = .grows;
    label.layout.y = .shrinks;

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

test "test_init" {
    const allocator = std.testing.allocator;
    var display = try Display.create(allocator, "test", "test", "test", "./test/repo", null, "test translation", 0);
    defer display.destroy(allocator);
    var panel = try display.add_panel(allocator, .{
        .rect = .{ .width = 500, .height = 200 },
        .minimum = .{ .width = 5, .height = 8 },
        .type = .{ .panel = .{ .spacing = 0, .direction = .top_to_bottom } },
        .layout = .{ .x = .shrinks, .y = .shrinks },
    });

    try eq(1, display.root.type.panel.children.items.len);
    _ = try panel.add(allocator, display, .{
        .name = "menu_bg",
        .rect = .{ .x = 0, .y = 0, .width = 550, .height = 100 },
        .minimum = .{ .width = 300, .height = 130 },
        .layout = .{ .x = .fixed, .y = .fixed, .position = .float },
        .background = .{ .colour = .{ .r = 99, .g = 150, .b = 50, .a = 255 } },
        .style = .background,
        .type = .{ .rectangle = .{} },
    });
    try eq(1, display.root.type.panel.children.items[0].type.panel.children.items.len);
}

const std = @import("std");
const ArrayListUnmanaged = std.ArrayListUnmanaged;
const Allocator = std.mem.Allocator;
const sdl = @import("sdl");
const builtin = @import("builtin");

const zigimg = @import("zigimg");

pub const engine = @import("engine.zig");
pub const Animator = @import("animator.zig");
pub const Font = @import("font.zig");
pub const Texture = @import("texture.zig");
pub const Audio = @import("audio.zig");

const praxis = @import("praxis");
const Lang = @import("praxis").Lang;
const BoundedArray = praxis.BoundedArray;
const mixer = @import("mixer");

pub const Chunker = @import("chunker.zig").Chunker;
pub const Translation = @import("translation.zig").Translation;

const Resources = @import("resources").Resources;
const Resource = @import("resources").Resource;
const FileType = @import("resources").FileType;

const default_themes = @import("theme.zig").default_themes;
const Theme = @import("theme.zig").Theme;
const ThemeColour = @import("theme.zig").ThemeColour;

pub const BundleLoader = @import("read_write.zig");
pub const init_resource_loader = BundleLoader.init_resource_loader;
pub const sdl_load_bundle = BundleLoader.sdl_load_bundle;
pub const sdl_load_resource = BundleLoader.sdl_load_resource;
pub const load_preference_data = BundleLoader.load_preference_data;
pub const save_preference_data = BundleLoader.save_preference_data;
pub const remove_preference_data = BundleLoader.remove_preference_data;
pub const random_string = BundleLoader.random_string;
