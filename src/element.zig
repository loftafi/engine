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
    colour: Colour = Colour.WHITE,

    background: engine.Background = .{
        .colour = Colour.TRANSPARENT,
        .image = null,
        .image_name = null,
        .corner_radius = 0,
        .image_corner_radius = 0,
    },

    border_colour: Colour = Colour.TRANSPARENT,
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

    // Find the avaialble inner width of this element.
    pub inline fn inner_width(self: *const Element) f32 {
        const padding = self.pad.left - self.pad.right;
        var available = self.rect.width - padding;

        if (self.maximum.width > 0)
            available = @min(self.maximum.width - padding, available);

        available = @max(available, self.minimum.width - padding);

        return available;
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
        if (engine.dev_build and engine.dev_mode) {
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
    pub fn shrink_height(self: *Element, display: *Display, parent_width: f32) f32 {
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

    /// Return the smallest width this element permits.
    /// .
    /// Some elements grow to the `parent_width`, which is usually the
    /// `parent.rect.width` minus any internal padding.
    pub fn shrink_width(self: *Element, display: *Display, parent_inner_width: f32) f32 {
        if (self.visible == .hidden)
            return 0;

        if (self.layout.x == .fixed)
            return @max(self.minimum.width, self.rect.width);

        switch (self.type) {
            .panel => {
                return @max(self.minimum.width, find_minimum_panel_width(self, display));
            },
            .button => {
                // Buttons may contain padding, icon, text, and icon-text spacing.
                var needed_width: f32 = self.pad.left + self.pad.right;

                needed_width += self.type.button.icon_size.width;

                // If button has icon _and_ text, add button spacing
                if (self.type.button.icon_size.width > 0 and self.type.button.text.len > 0) {
                    needed_width += self.type.button.spacing;
                }

                // Add the width of the button text
                if (self.type.button.text_texture) |t| {
                    const size = self.type.button.text_size.pixel_size(display, t);
                    needed_width += size.width;
                }
                return @max(self.minimum.width, needed_width);
            },
            .expander => {
                return self.minimum.width;
            },
            .label => {
                switch (self.layout.x) {
                    .shrinks, .grows => {
                        // Growing or shrinking, our task here is to find
                        // the minimum that would be needed.
                        self.layout_label(display, parent_inner_width);
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
                        self.layout_label(display, parent_inner_width);
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
    pub fn language_changed(self: *Element, allocator: Allocator, display: *Display, lang: Lang) !void {
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
        if (engine.dev_mode) {
            var colour = display.theme.emphasised_text_colour;
            if (element.type == .panel) {
                colour = display.theme.tinted_text_colour;
            }
            engine.draw_rectangle(
                display.renderer,
                2,
                colour,
                element.rect.move(&scroll_offset),
                .{},
            );
            if (element.type == .panel and (element.type.panel.scrollable.scroll.x or element.type.panel.scrollable.scroll.y)) {
                engine.draw_rectangle(
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
                engine.draw_rectangle(
                    display.renderer,
                    2,
                    display.theme.faded_text_colour,
                    pad_line,
                    .{},
                );
            } else if (element.type == .button) {
                // inner padding line
                colour = display.theme.tinted_text_colour;
                engine.draw_rectangle(display.renderer, 2, colour, .{
                    .x = element.rect.x + scroll_offset.x + element.pad.left,
                    .y = element.rect.y + scroll_offset.y + element.pad.top,
                    .width = element.rect.width - (element.pad.left + element.pad.right),
                    .height = element.rect.height - (element.pad.top + element.pad.bottom),
                }, .{});
            }
        } else if (element.border_width > 0 and element.border_colour.a > 0) {
            engine.draw_rectangle(
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
                    engine.draw_selection_marker(
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
        parent_inner_width: f32,
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

        const wrap_at: f32 = word_wrap_line(element, display, parent_inner_width);

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
            if ((x + word_spacing + size.width > wrap_at and line_word_count > 0) or is_cr) {
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
                element.rect.width = @max(element.rect.width, parent_inner_width);
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
                        element.rect.width - element.pad.left - element.pad.right,
                        children[line_start .. line_end + 1],
                    );
                    break;
                }
                if (children[line_end].location.x >= children[line_end + 1].location.x) {
                    element.do_word_alignment(
                        children[line_end].location.x + children[line_end].location.width,
                        element.rect.width - element.pad.left - element.pad.right,
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
            parent_inner_width,
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

        const available_width = parent.inner_width();

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
                    if (element.type == .expander) continue;

                    // Add space between each element.
                    if (first)
                        first = false
                    else
                        minimum_needed += parent.type.panel.spacing;

                    const width = element.shrink_width(display, available_width);
                    minimum_needed += width;
                }
                // Bound to the minimum/maximum width
                if (parent.maximum.width > 0)
                    minimum_needed = @min(parent.maximum.width, minimum_needed);

                return @max(minimum_needed, parent.minimum.width);
            },
            .left_to_right_wrap => {
                var minimum_needed: f32 = parent.pad.left + parent.pad.right;
                var first = true;
                for (parent.type.panel.children.items) |element| {
                    if (element.layout.position == .float) continue;
                    if (element.visible == .hidden) continue;
                    if (element.type == .expander) continue;

                    // Add space between each element.
                    if (first)
                        first = false
                    else
                        minimum_needed += parent.type.panel.spacing;

                    const width = element.shrink_width(display, available_width);
                    minimum_needed = @max(minimum_needed, width);
                }
                // Bound to the minimum/maximum width
                if (parent.maximum.width > 0)
                    minimum_needed = @min(parent.maximum.width, minimum_needed);
                return @max(minimum_needed, parent.minimum.width);
            },
            .centre, .top_to_bottom, .top_left, .top_right => {
                // a, centred upon b, centred upon c
                // a, then b underneath, thn c underneath...
                //
                // Need to just find maximum width item
                var minimum_needed: f32 = 0;
                for (parent.type.panel.children.items) |element| {
                    if (element.layout.position == .float) continue;
                    if (element.visible == .hidden) continue;
                    if (element.type == .expander) continue;

                    const child_width = element.shrink_width(display, available_width);
                    if (false) {
                        debug("seek min width {s}->{s}/{t} curent_min={d} child_min={d} parent_inner={d}", .{
                            parent.name,
                            element.name,
                            element.type,
                            minimum_needed,
                            child_width,
                            available_width,
                        });
                    }
                    minimum_needed = @max(minimum_needed, child_width);
                }
                return @max(parent.minimum.width, minimum_needed + (parent.pad.left + parent.pad.right));
            },
        }
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

        const available_width = parent.inner_width();

        switch (parent.type.panel.direction) {
            .top_to_bottom => {
                // a, above b, above c. (top to bottom)
                var minimum_needed: f32 = parent.pad.top + parent.pad.bottom;
                // Add the size needed for each inline child.
                var first = true;
                for (parent.type.panel.children.items) |element| {
                    if (element.layout.position == .float) continue;
                    if (element.visible == .hidden) continue;
                    if (element.type == .expander) continue;
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

            .centre, .left_to_right, .left_to_right_wrap, .top_left, .top_right => {
                // centred all together
                // a, next to b, next c.
                //
                // Just need to know the highest/tallest child.
                var minimum_needed: f32 = 0;
                for (parent.type.panel.children.items) |element| {
                    if (element.layout.position == .float) continue;

                    const height = element.shrink_height(display, available_width);
                    if (height > minimum_needed)
                        minimum_needed = height;
                }
                return minimum_needed + (parent.pad.top + parent.pad.bottom);
            },
        }
    }
};

const TextElement = struct {
    text: ?[]const u8,
    width: f32, // compared to default height
    texture: *sdl.SDL_Texture,
    location: Rect,
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
    position: LayoutMode = .@"inline",
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

/// The `x` and `y` position of an element is either automatically
/// generated `inline` relative to its parent and sibiling elements;
/// or the `x` and `y` position is manually specified to `float` freely
/// outside of the element tree.
pub const LayoutMode = enum {
    @"inline",
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

/// Information about the location and visibility of an element.
pub const Box = struct {};

pub const FocusOption = enum(u2) {
    unspecified,
    /// never_focus don't allow _tab into_ or _hover over_
    never_focus,
    /// can_focus allow _tab into_ or _hover over_ with a mouse.
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

const std = @import("std");
const ArrayListUnmanaged = std.ArrayListUnmanaged;
const Allocator = std.mem.Allocator;

const sdl = @import("sdl");

const engine = @import("engine.zig");
const err = engine.err;
const warn = engine.warn;
const info = engine.info;
const debug = engine.debug;
const trace = engine.trace;
const Display = engine.Display;
const Callback = engine.Callback;
const BoolCallback = engine.BoolCallback;
const UpdateCallback = engine.UpdateCallback;
const Error = engine.Error;
const Font = engine.Font;
const TextSize = engine.TextSize;

const resources = @import("resources");
const Resources = resources.Resources;
const Resource = resources.Resource;

const praxis = @import("praxis");
const Lang = @import("praxis").Lang;

const Chunker = @import("chunker.zig").Chunker;
const Texture = @import("texture.zig");
const Colour = @import("theme.zig").Colour;
const Theme = @import("theme.zig").Theme;
const ThemeColour = @import("theme.zig").ThemeColour;
