/// Describe an entity that will be rendered on the screen during a draw
/// loop. See `EntityType` for the types of entities that may be rendered.
pub fn Entity(comptime T: type) type {
    return struct {
        pub const Self = @This();

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

        style: ThemeColour = .normal,
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

        on_resized: Self.BoolCallback = .empty,
        on_visibility: Self.Callback = .empty,

        type: union(EntityType) {
            button: Button(T),
            checkbox: Checkbox(T),
            expander: Expander(T),
            label: Label(T),
            panel: Panel(T),
            progress_bar: ProgressBar(T),
            rectangle: Rectangle(T),
            sprite: Sprite(T),
            text_input: TextInput(T),
        },

        /// Cleanup memory associated with this entity. This is automatically
        /// called on all entities inside the display when the display is destroyed.
        ///
        /// Never call `destroy()` unless you know the entity is not inside the
        /// display tree.
        pub fn destroy(self: *Self, allocator: Allocator, display: *Display(T)) void {
            self.deinit(allocator, display);
            allocator.destroy(self);
        }

        /// Cleanup memory associated with this entity. This is automatically
        /// called on all entities inside the display when the display is destroyed.
        ///
        /// Never call `deinit()` unless you know the entity is not inside the
        /// display tree.
        pub fn deinit(self: *Self, allocator: Allocator, display: *Display(T)) void {
            // Cleanup shared attributes

            if (self.texture) |texture| {
                display.release_texture_resource(allocator, texture);
                self.texture = null;
            }

            if (self.background.image) |texture| {
                display.release_texture_resource(allocator, texture);
                self.background.image = null;
            }

            // Cleanup entity type specific attributes
            switch (self.type) {
                .panel => |*i| {
                    for (i.*.children.items) |child| {
                        child.destroy(allocator, display);
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

        /// Find a direct child of this entity by the name attached to
        /// the entity.
        pub fn get_child_by_name(self: *Self, name: []const u8) ?*Self {
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

        /// Return true if this entity appears under this point on the screen.
        pub fn at_point(self: *Self, cursor: Vector, parent_scroll_offset: Vector) bool {
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

        pub inline fn apply_background_tint(
            self: *Self,
            display: *Display(T),
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
        pub inline fn set_placeholder_text(
            self: *Self,
            _: Allocator,
            display: *Display(T),
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

        // Find the avaialble inner width of this entity. This is the
        // width of the entity minus any padding.
        pub inline fn inner_width(self: *const Self) f32 {
            const padding = self.pad.left + self.pad.right;

            return engine.clamp(
                self.minimum.width - padding,
                self.rect.width - padding,
                self.maximum.width - padding,
            );
        }

        // Find the avaialble inner height of this entity. This is the
        // height of the entity minus any padding.
        pub inline fn inner_height(self: *const Self) f32 {
            const padding = self.pad.top + self.pad.bottom;

            return engine.clamp(
                self.minimum.height - padding,
                self.rect.height - padding,
                self.maximum.height - padding,
            );
        }

        pub fn format(self: *const Self, out: *std.Io.Writer) std.Io.Writer.Error!void {
            _ = try out.write(@tagName(self.type));
            if (self.name.len > 0) {
                _ = try out.write(" name=");
                _ = try out.write(self.name);
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
                if (self.type.label.on_click.func != null) {
                    _ = try out.write(" on_click");
                }
            } else if (self.type == .button) {
                if (self.type.button.text.len > 0) {
                    _ = try out.write(" text=");
                    _ = try out.write(self.type.button.text);
                }
                if (!std.mem.eql(u8, self.type.button.text, self.type.button.translated) and self.type.button.translated.len > 0) {
                    _ = try out.write(" translated=");
                    _ = try out.write(self.type.button.translated);
                }
                if (self.type.button.icon_size.height > 0 or self.type.button.icon_size.width > 0) {
                    _ = try out.print(" icon_size={d:1.0}x{d:1.0}", .{
                        self.type.button.icon_size.width,
                        self.type.button.icon_size.height,
                    });
                }
                if (self.type.button.font_name) |font| {
                    if (font.len > 0) {
                        _ = try out.write(" font=");
                        _ = try out.write(font);
                    }
                }
                if (self.type.button.on_click.func != null) {
                    _ = try out.write(" on_click");
                }
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

        /// Show or hide this entity. If the visibliity is changed a relayout
        /// will be triggerd, and the `on_visibility` callback will be triggered
        /// if a callback is specified.
        pub inline fn set_visibility(self: *Self, display: *Display(T), visible: Visibility) Allocator.Error!void {
            if (self.visible == visible) return;
            self.visible = visible;
            display.need_relayout = true;
            try self.on_visibility.call(display.allocator, display, self);
        }

        /// Replace the foreground texture with an image resource found
        /// in the default resource bundle.
        ///
        /// `set_texture` is only valid on entities that permit a
        /// foreground texture.
        pub inline fn set_texture(
            self: *Self,
            allocator: Allocator,
            display: *Display(T),
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
        /// `set_background_texture` is only valid on entities that permit a
        /// background texture.
        pub inline fn set_background_texture(
            self: *Self,
            allocator: Allocator,
            display: *Display(T),
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
            self: *Self,
            gpa: Allocator,
            display: *Display(T),
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
            self: *Self,
            gpa: Allocator,
            display: *Display(T),
        ) void {
            if (self.texture != null) {
                display.release_texture_resource(gpa, self.texture.?);
                self.texture = null;
            }
        }

        pub inline fn set_background_image(
            self: *Self,
            gpa: Allocator,
            display: *Display(T),
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
            self: *Self,
            gpa: Allocator,
            display: *Display(T),
        ) void {
            if (self.background.image != null) {
                display.release_texture_resource(gpa, self.background.image.?);
                self.background.image = null;
            }
        }

        /// Change the default font belonging to this entity
        pub inline fn set_font(
            self: *Self,
            display: *Display(T),
            name: []const u8,
        ) Allocator.Error!void {
            const which: **Font = switch (self.type) {
                .button => &self.type.button.font,
                .label => &self.type.label.font,
                .checkbox => &self.type.checkbox.font,
                .text_input => &self.type.text_input.font,
                else => {
                    warn("set_font invalid on entity {t} {s}", .{ self.type, self.name });
                    return;
                },
            };
            const fname: *?[]const u8 = switch (self.type) {
                .button => &self.type.button.font_name,
                .label => &self.type.label.font_name,
                .checkbox => &self.type.checkbox.font_name,
                .text_input => &self.type.text_input.font_name,
                else => {
                    warn("set_font invalid on entity {t} {s}", .{ self.type, self.name });
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

        /// set_text updates the `text` and `translation` fields of labels,
        /// checkboxes and buttons, and regenerates the grahpics/image
        /// textures for each word if the text was changed.
        ///
        /// The memory behind the `new_text` must remain valid while the entity
        /// exists and is displaying this string.
        pub inline fn set_text(
            self: *Self,
            allocator: Allocator,
            display: *Display(T),
            new_text: []const u8,
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
            if (std.mem.eql(u8, new_translated, old_translated)) {
                // Do nothing if the text has not changed. This assumes that
                // the original text buffer was not modified.
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
                            self.type.text_input.cursor_pixels = T.normal.pixel_size(display.scale, texture).width;
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
                        if (self.type.label.font_name) |_| {
                            while (data.next(&display.font)) |word| {
                                if (display.generate_text_texture(word.text, self.type.label.font)) |texture| {
                                    try self.type.label.elements.append(allocator, .{
                                        .text = word.text,
                                        .width = @floatFromInt(texture.*.w),
                                        .texture = texture,
                                        .font = word.font,
                                    });
                                }
                            }
                        } else {
                            while (data.next(&display.font)) |word| {
                                if (display.generate_text_texture(word.text, word.font)) |texture| {
                                    try self.type.label.elements.append(allocator, .{
                                        .text = word.text,
                                        .width = @floatFromInt(texture.*.w),
                                        .texture = texture,
                                        .font = word.font,
                                    });
                                }
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
                        if (self.type.checkbox.font_name) |_| {
                            while (data.next(&display.font)) |text| {
                                if (display.generate_text_texture(text.text, self.type.checkbox.font)) |texture| {
                                    try self.type.checkbox.elements.append(allocator, .{
                                        .text = text.text,
                                        .width = @floatFromInt(texture.*.w),
                                        .texture = texture,
                                        .font = text.font,
                                    });
                                }
                            }
                        } else {
                            while (data.next(&display.font)) |text| {
                                if (display.generate_text_texture(text.text, text.font)) |texture| {
                                    try self.type.checkbox.elements.append(allocator, .{
                                        .text = text.text,
                                        .width = @floatFromInt(texture.*.w),
                                        .texture = texture,
                                        .font = text.font,
                                    });
                                }
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
                        if (self.type.button.font_name != null) {
                            trace("use requested font '{s}' for {s}", .{ self.type.button.font_name.?, self.type.button.translated });
                            if (display.generate_text_texture(self.type.button.translated, self.type.button.font)) |texture| {
                                self.type.button.text_texture = texture;
                            }
                        } else {
                            const font = @import("chunker.zig").guess_language(self.type.button.translated, &display.font);
                            trace("use detected font '{s}' for {s}", .{ font.name, self.type.button.translated });
                            if (display.generate_text_texture(self.type.button.translated, font)) |texture| {
                                self.type.button.text_texture = texture;
                            }
                        }
                    }
                },
                else => {
                    warn("set_text({s}) invalid for {s}", .{ @tagName(self.type), new_text });
                },
            }
            if (self.visible != .hidden) display.need_relayout = true;
        }

        /// `add` a child entity to this panel and return the entity. Only
        /// permitted for the `panel` entity type.
        pub inline fn add(
            self: *Self,
            allocator: Allocator,
            display: *Display(T),
            conf: Self,
        ) (Error || Allocator.Error || Resources.Error)!*Self {
            std.debug.assert(self.type == .panel);
            const child = try allocator.create(Self);
            child.* = conf;
            try display.setup_entity(allocator, child);
            try self.type.panel.children.append(allocator, child);
            if (child.visible != .hidden and self.visible != .hidden)
                display.need_relayout = true;
            return child;
        }

        /// Use `insert_entity` to insert a child entity in a specific location
        /// in this panel. Only permitted for the `panel` entity type.
        pub inline fn insert_entity(
            self: *Self,
            allocator: Allocator,
            display: *Display(T),
            conf: Self,
            location: usize,
        ) (Error || Allocator.Error || Resources.Error)!*Self {
            std.debug.assert(self.type == .panel);
            std.debug.assert(location <= self.type.panel.children.items.len);
            const child = try allocator.create(Self);
            child.* = conf;
            try display.setup_entity(allocator, child);
            try self.type.panel.children.insert(allocator, location, child);
            if (child.visible != .hidden and self.visible != .hidden)
                display.need_relayout = true;
            return child;
        }

        /// Swap the ordering of two child entities belonging to this panel.
        pub inline fn swap(self: *Self, from: usize, to: usize) void {
            std.debug.assert(self.type == .panel);
            std.debug.assert(from < self.type.panel.children.items.len);
            std.debug.assert(to < self.type.panel.children.items.len);
            const s = self.type.panel.children.items[from];
            self.type.panel.children.items[from] = self.type.panel.children.items[to];
            self.type.panel.children.items[to] = s;
        }

        /// Use `remove_entity_at` to attach a child entity in a specific location
        /// in this panel. Only permitted for the `panel` entity type.
        pub inline fn remove_entity_at(self: *Self, display: *Display(T), location: usize) *Self {
            std.debug.assert(self.type == .panel);
            std.debug.assert(location < self.type.panel.children.items.len);
            const item = self.type.panel.children.orderedRemove(location);
            if (item.visible != .hidden) display.need_relayout = true;
            return item;
        }

        /// Use `remove_entity` to remove a panel that is a
        /// child of this entity.
        pub inline fn remove_entity(
            self: *Self,
            display: *Display(T),
            child: *Self,
        ) ?*Self {
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

        /// Use `remove_entities` to remove all childr entities in a panel.
        pub inline fn remove_entities(
            self: *Self,
            allocator: Allocator,
            display: *Display(T),
        ) void {
            std.debug.assert(self.type == .panel);
            for (0..self.type.panel.children.items.len) |i| {
                const item = self.type.panel.children.items[i];
                if (item.visible != .hidden) display.need_relayout = true;
                item.destroy(allocator, display);
                debug("removed child panel {s}", .{item.name});
            }
            self.type.panel.children.clearRetainingCapacity();
        }

        /// Make sure nothing is holding a reference to an entity that
        /// is being removed from the display.
        fn clear_display_pointers(self: *Self, display: *Display(T)) void {
            if (display.selected == self) display.selected = null;
            if (display.hovered == self) display.hovered = null;
            if (self.type == .panel) {
                for (self.type.panel.children.items) |entity| {
                    entity.clear_display_pointers(display);
                }
            }
        }

        /// Animations, and used provided code may be updated inside the
        /// update function. This is called prior to the `draw` function.
        pub fn update(self: *Self, display: *Display(T)) void {
            if (self.type == .sprite) self.type.sprite.update.call(display, self);

            if (display.need_relayout) display.relayout();

            if (self.velocity.x > 0) self.rect.x += self.velocity.x;

            if (self.velocity.y > 0) self.rect.y += self.velocity.y;

            if (self.type == .panel) {
                self.type.panel.update.call(display, self);
                for (self.type.panel.children.items) |child|
                    child.update(display);
            }
        }

        /// Shrink to the smallest height this object is allowed to
        /// shrink to based on the children. If children wrap according
        /// to the width of the parent, then the parent width is needed
        /// to calculate the height
        pub fn minimum_needed_height(self: *Self, display: *Display(T), parent_width: f32) f32 {
            if (self.visible == .hidden)
                return 0;
            if (self.layout.y == .fixed)
                return @max(self.minimum.height, self.rect.height);

            const height = switch (self.type) {
                .button => return self.type.button.minimum_needed_height(display, self, parent_width),
                .checkbox => return self.type.checkbox.minimum_needed_height(display, self, parent_width),
                .expander => return self.minimum.height,
                .label => return self.type.label.minimum_needed_height(display, self, parent_width),
                .panel => return self.type.panel.minimum_needed_height(display, self, parent_width),
                .text_input => return self.type.text_input.minimum_needed_height(display, self, parent_width),
                else => self.rect.height,
            };
            return @max(self.minimum.height, height);
        }

        /// Return the smallest width this entity permits.
        /// .
        /// Some entities grow to the `parent_width`, which is usually the
        /// `parent.rect.width` minus any internal padding.
        pub fn minimum_needed_width(self: *Self, display: *Display(T), parent_inner_width: f32) f32 {
            if (self.visible == .hidden)
                return 0;

            if (self.layout.x == .fixed)
                return @max(self.minimum.width, self.rect.width);

            return switch (self.type) {
                .panel => self.type.panel.minimum_needed_width(display, self, parent_inner_width),
                .button => self.type.button.minimum_needed_width(display, self, parent_inner_width),
                .expander => self.type.expander.minimum_needed_width(display, self, parent_inner_width),
                .label => self.type.label.minimum_needed_width(display, self, parent_inner_width),
                .checkbox => self.type.checkbox.minimum_needed_width(display, self, parent_inner_width),
                else => @max(self.minimum.width, self.rect.width),
            };
        }

        /// Handle the langauge change event and propogate the event
        /// downwards to each child entity, so that each child has
        /// a chance to regenerate its translation and text texture.
        pub fn language_changed(self: *Self, allocator: Allocator, display: *Display(T), lang: Lang) !void {
            switch (self.type) {
                .label => try self.set_text(allocator, display, self.type.label.text),
                .checkbox => try self.set_text(allocator, display, self.type.checkbox.text),
                .button => try self.set_text(allocator, display, self.type.button.text),
                .panel => for (self.type.panel.children.items) |child| {
                    try child.language_changed(allocator, display, lang);
                },
                else => {},
            }
        }

        /// Draw the current entity, along with any children entity.
        pub fn draw(entity: *Self, display: *Display(T), parent_scroll_offset: Vector, parent_clip: ?Clip) void {
            if (entity.visible == .hidden)
                return;

            const scroll_offset: Vector = entity.offset.add(parent_scroll_offset);

            // Mark visible entities as culled or not culled depending on
            // the parent_clip.
            if (parent_clip) |clip| {
                if (entity.rect.x + scroll_offset.x + entity.rect.width < clip.left) {
                    entity.visible = .culled;
                    return;
                }
                if (entity.rect.y + scroll_offset.y + (entity.rect.height / 2) + 1 < clip.top) {
                    entity.visible = .culled;
                    return;
                }
                if (entity.rect.x + scroll_offset.x > clip.right) {
                    entity.visible = .culled;
                    return;
                }
                if (entity.rect.y + scroll_offset.y > clip.bottom) {
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
                    if (entity.flip.x) {
                        dest.x += dest.width;
                        dest.width = 0 - dest.width;
                    }
                    if (entity.flip.y) {
                        dest.y += dest.height;
                        dest.height = 0 - dest.height;
                    }
                    entity.apply_background_tint(display, texture.texture);
                    if (entity.background.image_corner_radius == 0) {
                        _ = sdl.SDL_RenderTexture(display.renderer, texture.texture, null, @ptrCast(&dest));
                    } else {
                        var corner: f32 = entity.background.corner_radius;
                        if (corner * 2 > dest.height) corner = dest.height / 2;
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
                engine.draw_rectangle(
                    display.renderer,
                    2,
                    colour,
                    entity.rect.move(scroll_offset),
                    .{},
                );
                if (entity.type == .panel and (entity.type.panel.scrollable.scroll.x or entity.type.panel.scrollable.scroll.y)) {
                    engine.draw_rectangle(
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
                    entity.draw_padding_markers(display, scroll_offset);
                } else if (entity.type == .button) {
                    // inner padding line
                    colour = display.theme.tinted_text_colour;
                    engine.draw_rectangle(display.renderer, 2, colour, .{
                        .x = entity.rect.x + scroll_offset.x + entity.pad.left,
                        .y = entity.rect.y + scroll_offset.y + entity.pad.top,
                        .width = entity.rect.width - (entity.pad.left + entity.pad.right),
                        .height = entity.rect.height - (entity.pad.top + entity.pad.bottom),
                    }, .{});
                    entity.draw_padding_markers(display, scroll_offset);
                }
            } else if (entity.border_width > 0 and entity.border_colour.a > 0) {
                engine.draw_rectangle(
                    display.renderer,
                    entity.border_width,
                    entity.border_colour,
                    entity.rect.move(scroll_offset),
                    .{},
                );
            }

            // Any entity can have a selection underline
            if (display.selected != null and display.selected == entity) {
                if (entity.type != .text_input) {
                    if (display.keyboard_activity) {
                        draw_selection_marker(
                            display,
                            display.theme.cursor_colour,
                            entity.rect.move(scroll_offset),
                        );
                    }
                }
            }
        }

        fn draw_padding_markers(entity: *Entity(T), display: *Display(T), scroll_offset: Vector) void {
            const length = 20;
            engine.draw_line(
                display.renderer,
                3,
                Colour.RED,
                entity.rect.location().move(entity.pad.left, entity.pad.top),
                entity.rect.location().move(entity.pad.left + length, entity.pad.top),
                scroll_offset,
            );
            engine.draw_line(
                display.renderer,
                3,
                Colour.RED,
                entity.rect.location().move(entity.pad.left, entity.pad.top),
                entity.rect.location().move(entity.pad.left, entity.pad.top + length),
                scroll_offset,
            );
            engine.draw_line(
                display.renderer,
                3,
                Colour.RED,
                entity.rect.location().move(entity.rect.width - entity.pad.right - length, entity.rect.height - entity.pad.bottom),
                entity.rect.location().move(entity.rect.width - entity.pad.right, entity.rect.height - entity.pad.bottom),
                scroll_offset,
            );
            engine.draw_line(
                display.renderer,
                3,
                Colour.RED,
                entity.rect.location().move(entity.rect.width - entity.pad.right, entity.rect.height - entity.pad.bottom),
                entity.rect.location().move(entity.rect.width - entity.pad.right, entity.rect.height - entity.pad.bottom - length),
                scroll_offset,
            );
        }

        /// Draw a visual indication that an entity is currently selected.
        pub fn draw_selection_marker(
            self: *Display(T),
            colour: Colour,
            rect: Rect,
        ) void {
            const border_width = 2 * self.user_scale;
            if (border_width > 0 and colour.a > 0) {
                _ = sdl.SDL_SetRenderDrawColor(self.renderer, 255, 255, 255, 255);
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
                    self.renderer,
                    colour.r,
                    colour.g,
                    colour.b,
                    colour.a,
                );
                _ = sdl.SDL_RenderFillRect(self.renderer, @ptrCast(&dest));
            }
        }

        /// Calculate the layout of all entities, and optionally render every entity.
        ///
        /// Normally text is converted to an image and rendered left to right, starting
        /// at the top left corner of the entity (including padding).
        ///
        /// If the text is centred or right aligned, then each line must be pushed along
        /// by a certain offset amount.
        ///
        /// `parent_inner_width` should be the actual width the parent is
        /// willing/able to down to this child entity, minus the parent
        /// left and right padding, and clamped to the min/max
        /// width (including padding)
        pub inline fn layout_label(
            entity: *const Self,
            display_scale: f32,
            maximum_width: f32,
        ) Size {
            std.debug.assert(entity.type == .label or entity.type == .checkbox);

            const empty: Size = .{
                .width = entity.pad.left + entity.pad.right,
                .height = entity.pad.top + entity.pad.bottom,
            };
            if (entity.type == .label and entity.type.label.text.len == 0) return empty;
            if (entity.type == .checkbox and entity.type.checkbox.text.len == 0) return empty;

            const children = switch (entity.type) {
                .label => entity.type.label.elements.items,
                .checkbox => entity.type.checkbox.elements.items,
                else => unreachable,
            };
            if (children.len == 0) return empty;

            const text_height = switch (entity.type) {
                .label => entity.type.label.text_size,
                .checkbox => entity.type.checkbox.text_size,
                else => unreachable,
            };

            // Track the minimum needed width. Remember the longest line. Include
            // any left/right padding.
            var needed_width: f32 = 0;

            const word_spacing = text_height.word_spacing(display_scale);

            var x: f32 = 0;
            var y: f32 = 0;

            // A line must have at least one word before a line break is inserted
            // otherwise we are just drawing pointless broken blank lines.
            var line_word_count: usize = 0;
            var current_child: usize = 0;

            // Lay down each word one by one and wrap before we hit the
            // `wrap_at` boundary.
            for (children, 0..) |*item, i| {
                const is_cr = item.text.len == 1 and item.text[0] == '\n';
                const size = text_height.pixel_size(display_scale, item.texture);
                // Would drawing this word overflow?
                if ((x + word_spacing + size.width > maximum_width and line_word_count > 0) or is_cr) {
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
                    .width = if (is_cr) 0 else @round(size.width),
                    .height = size.height,
                };

                if (!is_cr) x += @round(size.width);
                if (!is_cr) line_word_count += 1;
            }
            needed_width = @max(needed_width, x);

            if (children.len > 0) {
                if (current_child != children.len) {
                    const size = text_height.pixel_size(display_scale, children[current_child].texture);
                    y += size.height;
                }
            }

            // Add y padding at the bottom so that we can calculate the final height.
            const needed_height = @round(y);

            needed_width = @round(needed_width);

            // Align words to centre or right if requested.
            // centre and end alignment might need the `grows`
            // full width, or the `shrinks` minimum width.
            if (entity.child_align.x == .centre or entity.child_align.x == .end) {
                var line_start: usize = 0;
                var line_end: usize = 0;
                const usable_width = switch (entity.layout.x) {
                    .grows => maximum_width,
                    .shrinks => needed_width,
                    .fixed => maximum_width,
                };
                while (true) : (line_end += 1) {
                    if (line_end + 1 == children.len) {
                        entity.do_line_justification(
                            children[line_end].location.x + children[line_end].location.width,
                            usable_width,
                            children[line_start .. line_end + 1],
                        );
                        break;
                    }
                    if (children[line_end].location.x >= children[line_end + 1].location.x) {
                        entity.do_line_justification(
                            children[line_end].location.x + children[line_end].location.width,
                            usable_width,
                            children[line_start .. line_end + 1],
                        );
                        line_start = line_end + 1;
                        continue;
                    }
                }
            }

            return .{ .width = needed_width, .height = needed_height };
        }

        pub fn keypress(
            self: *Self,
            allocator: Allocator,
            display: *Display(T),
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
                            try self.type.text_input.on_submit.call(allocator, display, self);
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
                        self.type.text_input.cursor_pixels = T.normal.pixel_size(display.scale, texture).width;
                    }
                } else {
                    self.type.text_input.cursor_pixels = 0;
                }

                // Optionally, a text_input may have an `on_change` callback function.
                if (self.type.text_input.on_change.func != null) {
                    trace("text_input calling on_change", .{});
                    try self.type.text_input.on_change.call(allocator, display, self);
                    trace("text_input called on_change", .{});
                }
            }
        }

        /// Handle when a user chooses an entity like a button, using
        /// the mouse or the keyboard.
        pub fn chosen(
            self: *Self,
            display: *Display(T),
            gpa: Allocator,
        ) Allocator.Error!void {
            trace("chosen entity {s}", .{self.name});
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
                    try self.type.button.on_click.call(gpa, display, self);
                },
                .panel => try self.type.panel.on_click.call(gpa, display, self),
                .label => try self.type.label.on_click.call(gpa, display, self),
                .sprite => try self.type.sprite.on_click.call(gpa, display, self),
                .checkbox => {
                    self.type.checkbox.checked = !self.type.checkbox.checked;
                    try self.type.checkbox.on_change.call(gpa, display, self);
                },
                .progress_bar, .text_input, .rectangle, .expander => {},
            }
        }

        /// Handle when a user clicks into or tabs into this entity.
        pub fn selected(self: *Self, display: *Display(T), _: Allocator) void {
            if (self.focus == .never_focus or self.focus == .unspecified) return;

            if (display.selected != null and self != display.selected)
                display.selected.?.deselected(display);

            display.selected = self;

            const content = self.describe_content();
            trace("selected {s} {s} = {s}", .{ @tagName(self.type), self.name, content });

            // Enter editing mode if we just selected a text entity
            if (self.type == .text_input)
                _ = sdl.SDL_StartTextInput(display.window);
        }

        /// Describe content for a screen reader
        fn describe_content(self: *Self) []const u8 {
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

        /// Handle when a user clicks or tabs out of this entity.
        pub fn deselected(self: *Self, display: *Display(T)) void {
            const content = self.describe_content();
            trace("deselected {s} {s} = {s}", .{ @tagName(self.type), self.name, content });

            if (self.type == .text_input) {
                _ = sdl.SDL_StopTextInput(display.window);
            }
            display.keyboard_activity = false;
            display.selected = null;
        }

        fn text_runes_to_data(self: *Self, allocator: Allocator) void {
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

        fn text_data_to_runes(self: *Self, allocator: Allocator) void {
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
        inline fn do_line_justification(
            entity: *const Self,
            line_width: f32,
            usable_width: f32,
            children: []TextElement,
        ) void {
            // How much whitespace was left over at the end of this line.
            const trailing_whitespace = usable_width - line_width;

            if (trailing_whitespace <= 0) return;

            switch (entity.child_align.x) {
                .start => {
                    // No adjustment needed
                    return;
                },
                .centre => {
                    // Shuffle words into centre
                    const adjust_by = @round(trailing_whitespace / 2);
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
        /// the next line. By default the width is whatever the parent entity
        /// has room for.
        fn word_wrap_line(entity: *const Self, max_parent_width: f32) f32 {
            var entity_padding: f32 = 0;
            if (entity.type == .checkbox) entity_padding += entity.type.checkbox.checkbox_size.width;

            // If a fixed width is specified, clamp to the fixed width
            const wrap = switch (entity.layout.x) {
                .grows, .fixed => @max(max_parent_width, entity.maximum.width) - entity_padding,
                .shrinks => @max(max_parent_width, entity.minimum.width) - entity_padding,
            };

            return wrap;
        }

        pub fn setup_rect(
            entity: *Self,
            _: Allocator,
        ) (Error || Allocator.Error || Resources.Error)!void {
            entity.texture = null;
            entity.background.image = null;
            if (entity.focus == .unspecified) {
                entity.focus = .never_focus;
            }
        }

        pub fn setup_panel(
            entity: *Self,
            allocator: Allocator,
            display: *Display(T),
        ) (Error || Allocator.Error || Resources.Error)!void {
            entity.texture = null;
            entity.background.image = null;

            if (entity.focus == .unspecified) {
                if (entity.type.panel.on_click.func != null) {
                    entity.focus = .can_focus;
                } else {
                    entity.focus = .never_focus;
                }
            }

            if (entity.background.image_name) |name| {
                if (try display.load_texture(allocator, name)) |texture| {
                    entity.background.image = texture;
                } else {
                    err("Failed to load panel background image named \"{s}\"", .{name});
                }
            }

            entity.type.panel.children = .empty;
        }

        pub fn setup_progress_bar(
            entity: *Self,
            allocator: Allocator,
            display: *Display(T),
        ) (Error || Allocator.Error || Resources.Error)!void {
            entity.texture = null;
            entity.background.image = null;
            if (entity.focus == .unspecified)
                entity.focus = .never_focus;

            if (entity.type != .progress_bar) {
                err("create_progress_bar called without config.", .{});
                entity.type = .{ .progress_bar = .{} };
            }

            if (try display.load_texture(allocator, "rounded progress bar")) |texture| {
                entity.texture = texture;
            } else {
                err("Failed to load progress_bar texture named \"rounded progress bar\"", .{});
            }
        }

        pub fn setup_checkbox(
            entity: *Self,
            allocator: Allocator,
            display: *Display(T),
        ) (Error || Allocator.Error || Resources.Error)!void {
            entity.texture = null;
            entity.background.image = null;
            entity.type.checkbox.translated = "";
            entity.type.checkbox.elements = .empty;
            entity.type.checkbox.font = try select_font(display.fonts.items, entity.type.checkbox.font_name);

            if (entity.focus == .unspecified)
                entity.focus = .can_focus;

            try entity.set_text(allocator, display, entity.type.checkbox.text);

            if (try display.load_texture(allocator, "ios-checkbox-on")) |texture| {
                entity.type.checkbox.on_texture = texture;
            }
            if (try display.load_texture(allocator, "ios-checkbox-off")) |texture| {
                entity.type.checkbox.off_texture = texture;
            }

            // Is there a background for this checkbox
            if (entity.background.image_name) |name| {
                if (try display.load_texture(allocator, name)) |texture|
                    entity.background.image = texture;
            }

            if (entity.pad.top == 0 and entity.pad.bottom == 0 and entity.pad.left == 0 and entity.pad.right == 0) {
                //TODO:REMOVE!
                entity.pad.left = display.text_height.pixel_height(display.scale * 0.8);
                entity.pad.right = display.text_height.pixel_height(display.scale * 0.8);
                entity.pad.top = display.text_height.pixel_height(display.scale * 0.3);
                entity.pad.bottom = display.text_height.pixel_height(display.scale * 0.3);
            }

            if (entity.type.checkbox.checkbox_size.width == 0 or entity.type.checkbox.checkbox_size.height == 0) {
                entity.type.checkbox.checkbox_size.width = display.text_height.pixel_height(display.pixel_scale);
                entity.type.checkbox.checkbox_size.height = display.text_height.pixel_height(display.pixel_scale);
            }

            const size = entity.type.checkbox.checkbox_size;
            if (entity.minimum.height < size.height)
                entity.minimum.height = size.height;

            if (entity.minimum.width < size.width)
                entity.minimum.width = size.width;
        }

        pub fn setup_expander(
            entity: *Self,
            _: Allocator,
            _: *Display(T),
        ) (Error || Allocator.Error || Resources.Error)!void {
            entity.texture = null;
            entity.background.image = null;
            entity.focus = .never_focus;
        }

        pub fn setup_label(
            entity: *Self,
            allocator: Allocator,
            self: *Display(T),
        ) (Error || Allocator.Error || Resources.Error)!void {
            entity.texture = null;
            entity.background.image = null;
            entity.type.label.translated = "";
            entity.type.label.elements = .empty;
            entity.type.label.font = try select_font(self.fonts.items, entity.type.label.font_name);

            if (entity.focus == .unspecified) {
                if (entity.type.label.on_click.func != null)
                    entity.focus = .can_focus
                else
                    entity.focus = .accessibility_focus;
            }
            try entity.set_text(allocator, self, entity.type.label.text);

            // Is there a background for this label?
            if (entity.background.image_name) |name| {
                if (try self.load_texture(allocator, name)) |texture|
                    entity.background.image = texture;
            }

            if (entity.pad.top == 0 and entity.pad.bottom == 0 and entity.pad.left == 0 and entity.pad.right == 0) {
                entity.pad.top = self.text_height.pixel_height(self.scale * 0.3);
                entity.pad.bottom = self.text_height.pixel_height(self.scale * 0.3);
            }
        }

        pub fn setup_text_input(
            entity: *Self,
            allocator: Allocator,
            display: *Display(T),
        ) (Error || Allocator.Error || Resources.Error)!void {
            entity.texture = null;
            entity.background.image = null;
            if (entity.focus == .unspecified)
                entity.focus = .can_focus;

            entity.type.text_input.font = try select_font(display.fonts.items, entity.type.text_input.font_name);

            if (entity.type.text_input.icon_texture_name) |icon| {
                if (try display.load_texture(allocator, icon)) |texture| {
                    entity.texture = texture;
                } else {
                    err("Failed to load text_input icon texture named \"{s}\"", .{icon});
                }
            }

            if (entity.background.image_name) |background| {
                if (try display.load_texture(allocator, background)) |texture| {
                    entity.background.image = texture;
                } else {
                    err("Failed to load text_input background image named \"{s}\"", .{background});
                }
            }

            if (entity.pad.top == 0 and entity.pad.bottom == 0) {
                entity.pad.left = display.text_height.pixel_height(display.scale * 0.6);
                entity.pad.right = display.text_height.pixel_height(display.scale * 0.6);
                entity.pad.top = display.text_height.pixel_height(display.scale * 0.5);
                entity.pad.bottom = display.text_height.pixel_height(display.scale * 0.5);
            }

            entity.focus = .can_focus;
            entity.rect.height = (display.text_height.pixel_height(display.scale)) + (entity.pad.top + entity.pad.bottom);

            entity.type.text_input.text = .empty;
            entity.type.text_input.runes = .empty;
            if (entity.type.text_input.initial_text) |text| {
                try entity.set_text(allocator, display, text);
            } else {
                try entity.set_text(allocator, display, "");
            }
            if (entity.type.text_input.placeholder_text) |text| {
                try entity.set_placeholder_text(allocator, display, text);
            } else {
                try entity.set_placeholder_text(allocator, display, "");
            }
        }

        pub fn setup_sprite(
            entity: *Self,
            allocator: Allocator,
            display: *Display(T),
        ) (Error || Allocator.Error || Resources.Error)!void {
            entity.texture = null;
            entity.background.image = null;
            if (entity.focus == .unspecified)
                entity.focus = .accessibility_focus;

            if (entity.texture_name) |image| {
                if (try display.load_texture(allocator, image)) |texture| {
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
                if (try display.load_texture(allocator, image)) |texture| {
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

        fn select_font(fonts: []*Font, name: ?[]const u8) error{FontRequired}!*Font {
            if (name) |font_name| {
                for (fonts) |font| {
                    if (std.mem.eql(u8, font.name, font_name)) {
                        return font;
                    }
                }
                err("select_font({s}) called, but no fonts have been loaded.", .{name.?});
            }
            if (fonts.len > 0) return fonts[0];

            return Error.FontRequired;
        }

        pub fn setup_button(
            entity: *Self,
            allocator: Allocator,
            display: *Display(T),
        ) (Error || Allocator.Error || Resources.Error)!void {
            entity.type.button.translated = "";
            entity.texture = null;
            entity.background.image = null;
            entity.type.button.icon_pressed = null;
            entity.type.button.icon_hover = null;
            entity.type.button.icon_disabled = null;
            entity.type.button.background_pressed = null;
            entity.type.button.background_hover = null;
            entity.type.button.background_disabled = null;
            entity.type.button.text_size = .normal;
            entity.type.button.font = try select_font(display.fonts.items, entity.type.button.font_name);

            if (entity.focus == .unspecified)
                entity.focus = .can_focus;

            if (entity.texture_name != null)
                warn("button `{s}` has texture_name `{s}`. Buttons use `icon_default_name`", .{
                    entity.name,
                    entity.texture_name.?,
                });

            if (entity.background.image_name != null)
                warn("button `{s}` has background.image_name `{s}`. Buttons do not use `background.image_name`", .{
                    entity.name,
                    entity.background.image_name.?,
                });

            try entity.set_text(allocator, display, entity.type.button.text);

            if (entity.type.button.icon_default_name) |icon_default| {
                if (try display.load_texture(allocator, icon_default)) |texture| {
                    entity.texture = texture;
                    if (entity.type.button.icon_size.width == 0 or entity.type.button.icon_size.height == 0)
                        warn("button `{s}` has icon `{s}`, but no icon size.", .{
                            entity.name,
                            icon_default,
                        });
                }
            }

            if (entity.type.button.icon_pressed_name) |icon_pressed| {
                if (try display.load_texture(allocator, icon_pressed)) |ip|
                    entity.type.button.icon_pressed = ip
                else
                    err("setup_button failed to load icon_pressed resource {s}.", .{icon_pressed});

                if (entity.type.button.icon_pressed == null and entity.texture != null)
                    entity.type.button.icon_pressed = entity.texture.?.clone();
            }

            if (entity.type.button.icon_hover_name) |icon_hover| {
                if (try display.load_texture(allocator, icon_hover)) |ih|
                    entity.type.button.icon_hover = ih
                else
                    err("setup_button failed to load icon_hover resource {s}.", .{icon_hover});

                if (entity.type.button.icon_hover == null and entity.texture != null)
                    entity.type.button.icon_hover = entity.texture.?.clone();
            }

            if (entity.type.button.icon_disabled_name) |icon_disabled| {
                if (try display.load_texture(allocator, icon_disabled)) |ih|
                    entity.type.button.icon_disabled = ih
                else
                    err("setup_button failed to load icon_disabled resource {s}.", .{icon_disabled});

                if (entity.type.button.icon_disabled == null and entity.texture != null)
                    entity.type.button.icon_disabled = entity.texture.?.clone();
            }

            if (entity.type.button.background_default_name) |background_default| {
                if (try display.load_texture(allocator, background_default)) |texture|
                    entity.background.image = texture
                else
                    err("setup_button failed to load background_default resource {s}.", .{background_default});
            }

            if (entity.type.button.background_pressed_name) |background_pressed| {
                if (try display.load_texture(allocator, background_pressed)) |bp|
                    entity.type.button.background_pressed = bp
                else
                    err("setup_button background_pressed resource resource `{s}` not loaded.", .{background_pressed});

                if (entity.type.button.background_pressed == null and entity.background.image != null)
                    entity.type.button.background_pressed = entity.background.image.?.clone();
            }

            if (entity.type.button.background_hover_name) |background_hover| {
                if (try display.load_texture(allocator, background_hover)) |bh|
                    entity.type.button.background_hover = bh
                else
                    err("setup_button background_hover resource `{s}` not loaded.", .{background_hover});

                if (entity.type.button.background_hover == null and entity.background.image != null)
                    entity.type.button.background_hover = entity.background.image.?.clone();
            }

            if (entity.type.button.background_disabled_name) |background_disabled| {
                if (try display.load_texture(allocator, background_disabled)) |bh|
                    entity.type.button.background_disabled = bh
                else
                    err("setup_button background_disabled resource `{s}` not loaded.", .{background_disabled});

                if (entity.type.button.background_disabled == null and entity.background.image != null)
                    entity.type.button.background_disabled = entity.background.image.?.clone();
            }
        }

        pub const Callback = struct {
            func: ?*const fn (
                ptr: *anyopaque,
                allocator: Allocator,
                display: *Display(T),
                entity: *Self,
            ) Allocator.Error!void = null,
            ptr: *anyopaque = undefined,

            pub const empty: @This() = .{
                .func = null,
                .ptr = undefined,
            };

            pub fn call(
                self: @This(),
                allocator: Allocator,
                display: *Display(T),
                entity: *Self,
            ) Allocator.Error!void {
                if (self.func) |f| return f(self.ptr, allocator, display, entity);
            }
        };

        pub const UpdateCallback = struct {
            func: ?*const fn (
                ptr: *anyopaque,
                display: *Display(T),
                entity: *Self,
            ) void = null,
            ptr: *anyopaque = undefined,

            pub const empty: @This() = .{
                .func = null,
                .ptr = undefined,
            };

            pub fn call(
                self: @This(),
                display: *Display(T),
                entity: *Self,
            ) void {
                if (self.func) |f| f(self.ptr, display, entity);
            }
        };

        pub const PanelChangeCallback = struct {
            func: ?*const fn (
                ptr: *anyopaque,
                allocator: Allocator,
                display: *Display(T),
                from: ?*Self,
                to: *Self,
            ) Allocator.Error!void = null,
            ptr: *anyopaque = undefined,

            pub const empty: @This() = .{
                .func = null,
                .ptr = undefined,
            };

            pub fn call(
                self: @This(),
                allocator: Allocator,
                display: *Display(T),
                from: ?*Self,
                to: *Self,
            ) Allocator.Error!void {
                if (self.func) |f| return f(self.ptr, allocator, display, from, to);
            }
        };

        pub const BoolCallback = struct {
            func: ?*const fn (
                ptr: *anyopaque,
                display: *Display(T),
                entity: *Self,
            ) bool = null,
            ptr: *anyopaque = undefined,

            pub const empty: @This() = .{
                .func = null,
                .ptr = undefined,
            };

            pub fn call(
                self: @This(),
                display: *Display(T),
                entity: *Self,
            ) bool {
                if (self.func) |f| return f(self.ptr, display, entity);
                return false;
            }
        };
    };
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

pub const TextElement = struct {
    text: []const u8 = "",
    font: *Font,
    width: f32 = 0, // compared to default height
    texture: *sdl.SDL_Texture,
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
};

/// Describe a bounding box or padding area.
pub const Clip = struct {
    top: f32 = 0,
    bottom: f32 = 0,
    left: f32 = 0,
    right: f32 = 0,
};

/// Describe the size of an entity.
pub const Size = struct {
    width: f32 = 0,
    height: f32 = 0,
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

/// If an entity is not a fixed size, it may choose
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
    /// `entity.rect`.
    stretch,

    /// Maintaining the image aspect ratio, enlarge the textue image to
    /// the full width and height of the `entity.rect`, and crop off
    /// any overflow.
    fill,

    /// Maintaining the image aspect ratio, enlarge the texture image to
    /// exactly fit within the boundary of the `entity.rect` This will leave
    /// some horizontal or vertical space. Use `child_align` to place
    /// the texture at the `start`, `centre` or `end` of the entity rect.
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
pub const EntityType = enum {
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
const directional_clamp = engine.directional_clamp;

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

const Button = @import("button.zig").Button;
const Checkbox = @import("checkbox.zig").Checkbox;
const Expander = @import("expander.zig").Expander;
const Panel = @import("panel.zig").Panel;
const ProgressBar = @import("progress_bar.zig").ProgressBar;
const Sprite = @import("sprite.zig").Sprite;
const Label = @import("label.zig").Label;
const Rectangle = @import("rectangle.zig").Rectangle;
const TextInput = @import("text_input.zig").TextInput;
