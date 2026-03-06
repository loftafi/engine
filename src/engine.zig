/// Comptime known value to allow creation of `if (dev_build)` statements
/// to allow code to be excluded from production releases.
pub const dev_build = (builtin.mode == .Debug);

/// A global variable which can be used to turn on or off live debugging
/// features such as drawing lines around on screen entities and output of
/// `trace` log messages
pub var dev_mode = false;

/// When the `Config` does not contain an organisation name, default
/// to this organisation name.
pub const default_org_name = "Example";

/// When the `Config` does not contain an application name, default
/// to use this application name.
pub const default_app_name = "Engine";

/// Render the font characters with double the pixel density of the
/// `text_height` to ensure screens with double or triple pixel
/// density have clear font edges.
pub const font_pixel_density: f32 = 2.0;

/// Display describes how to draw all visual entities onto the main
/// application window. Typically one app has one display window.
/// Typically a display consists of one or more panels. A background
/// panel, a main panel, and sometimes a user interface overlay.
pub fn Display(comptime T: type) type {
    return struct {
        allocator: Allocator,
        io: std.Io,

        window: *sdl.SDL_Window,
        renderer: *sdl.SDL_Renderer,
        mix: *mixer.MIX_Mixer,

        /// Main game loop runs until quit is requested.
        quit: bool = false,

        /// Some entities are placed, aligned or sized using a layout
        /// algorithm If one of these entities changes, this flag is
        /// set to indicate we must relayout all entities before the
        /// next frame is drawn. See `relayout()` for details.
        need_relayout: bool = true,

        /// Deduplicate safe area change updates by remembering the
        /// old safe area information.
        old_safe_area: sdl.SDL_Rect = undefined,

        /// Normally it is only possible to navigate to, focus, hover,
        /// or tap on `can_focus` items. In `accessibility` mode,
        /// extra entities such as titles or guidance text entities
        /// can also be navigated onto. These special entities must
        /// be given the given `accessibility_focus` option.
        accessibility: bool = false,

        /// Used to calculate frame rate in microseconds.
        last_draw: i64 = 0,

        /// Duration between each frame in microseconds.
        last_delta: i64 = 0,

        /// A list of read only resources is loaded from a resource
        /// bundle, or an on disk development directory. This may
        /// include images, fonts, audio, or text data files.
        resources: *Resources,

        /// A list of all active fonts loaded from the resources bundle.
        fonts: ArrayListUnmanaged(*Font) = .empty,

        font: LanguageFont,

        /// Translates the default provided text into a specific language
        /// using a csv translation file
        translation: Translation = .empty,
        current_language: Lang = .unknown,

        /// Cache of currently loaded textures.
        textures: std.AutoHashMapUnmanaged(u64, *Texture),

        /// Cache of currently loaded audio files.
        audio: std.StringArrayHashMapUnmanaged(*Audio),

        /// Four possible theme options are available.
        themes: []*Theme,

        /// Current theme choice.
        theme: *Theme,

        /// The tab key, arrow keys, or game controler may be used
        /// to switch between focussable user interface entities.
        focussed: ?*Entity(T) = null,

        /// When the mouse is clicked dcown on a scrollable/movable
        /// entities, this is the current entity that is being
        /// scrolled/moved.
        scrolling: ?*Entity(T) = null,

        /// When a user clicks to begin a scroll action, the scroll
        /// movement begins from a specific point on the screen.
        /// This is used to calculate how far an item has been
        /// pushed/dragged
        scroll_start: Vector = .{ .x = 0, .y = 0 },
        scroll_initial_offset: Vector = .{ .x = 0, .y = 0 },

        /// Some devices have screen notches and cutouts.
        safe_area: Clip = .{ .left = 0, .right = 0, .top = 0, .bottom = 0 },

        /// One user interface entity may be marked as selected to recieve
        /// keyboard input
        selected: ?*Entity(T) = null,
        keyboard_activity: bool = false,

        /// One user interface entity may be rendered differently
        /// when the mouse/pointer is floating over that entity.
        /// i.e. A button might light up when the mouse hovers above it.
        hovered: ?*Entity(T) = null,

        // Text height in pixels _before_ display scaling. For example
        // you may choose the `text_height` to be a standard 16 pixels
        // across all device types. If a device has a double or triple
        // pixel density, internally the engine might be drawing your
        // content at 32 (double) or 48 (triple) the number of pixels.
        //
        // The `text_height`may therefore be modified by the
        // `pixel_scale` and/or `user_scale` value.
        text_height: T = .normal,

        /// On some devices, the reported screen size and physical
        /// pixel size may be different. The scale variable is used
        /// to convert between OS reported size, and physical
        /// pixel size. i.e.
        ///
        /// 1.0 = Non retina display, width = 1920, pixel width = 1920.
        /// 2.0 = Retina display,     width = 1920, pixel width = 3840.
        /// 3.0 = iPhone 16 display,  width =  393, pixel width = 1179.
        ///
        /// If the text height is 16 pixels, but the device has a
        /// retina display the actual text height will be
        /// `text_height` * `pixel_scale`.
        pixel_scale: f32 = 0,

        /// Used when user adjusts the global size of the interface
        user_scale: f32 = 1,

        /// The actual scale is the pixel_scale * user_scale
        scale: f32 = 0,

        /// iOS and retina mac displays report the mouse position according
        /// to traditional dimensions (i.e. 1920x1080) rather than actual
        /// pixels (i.e. 3840x2160). A mouse/tap at 100x100, must be
        /// translated to the physical pixel/entity position of 200x200.
        pixel_density: f32 = 1,

        root: Entity(T) = .{
            .name = "root",
            .aria_label = null,
            .focus = .never_focus,
            .rect = .{ .x = 0, .y = 0, .width = 100, .height = 100 },
            .maximum = .{ .width = 100, .height = 100 },
            .layout = .{ .x = .grows, .y = .grows },
            .child_align = .{ .x = .centre, .y = .start },
            .colour = .{},
            .background = .{ .colour = .{ .a = 0 } },
            .pad = .{ .left = 0, .right = 0, .top = 0, .bottom = 0 },
            .border_colour = .{},
            .border_width = 0,
            .type = .{ .panel = .{ .direction = .centre, .spacing = 0 } },
            .on_resized = .empty,
            .on_visibility = .empty,
        },
        animators: ArrayListUnmanaged(*Animator(T)) = .empty,

        keybindings: std.AutoHashMapUnmanaged(c_uint, Entity(T).Callback) = .empty,
        on_resized: Entity(T).BoolCallback,
        event_hook: U32Callback,
        on_panel_change: Entity(T).PanelChangeCallback,

        bucket: StringBucket,
        bundle_filename: ?[]const u8,
        config: Config,

        const Self = @This();

        pub fn create(
            gpa: Allocator,
            io: std.Io,
            config: Config,
        ) (Error || Allocator.Error || Resources.Error || engine.Error ||
            error{ Utf8ExpectedContinuation, Utf8OverlongEncoding, Utf8EncodesSurrogateHalf, Utf8CodepointTooLarge, Utf8InvalidStartByte } ||
            std.Io.Dir.StatError || std.Io.File.StatError ||
            std.Io.File.OpenError)!*Self {
            var bucket = StringBucket.init(gpa);
            errdefer bucket.deinit();

            const bundle_filename = if (config.bundle_filename != null)
                try bucket.add(config.bundle_filename.?)
            else
                null;

            _ = sdl.SDL_SetAppMetadata(
                if (config.app_name != null) try bucket.addZ(config.app_name.?) else "Engine",
                if (config.app_version != null) try bucket.addZ(config.app_version.?) else "0.0.0",
                if (config.app_id != null) try bucket.addZ(config.app_id.?) else "example",
            );

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
            if (!sdl.SDL_Init(sdl.SDL_INIT_VIDEO | sdl.SDL_INIT_EVENTS | sdl.SDL_INIT_AUDIO | sdl.SDL_INIT_HAPTIC)) {
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

            const mix = mixer.MIX_CreateMixerDevice(mixer.SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &a);
            if (mix == null) {
                err("create mixer device failed. {s}", .{sdl.SDL_GetError()});
                return error.AudioInitFailed;
            }
            //mixer.MIX_SetMasterGain(display.mix, DEFAULT_SOUND_VOLUME);

            var gui_flags: u64 = 0;
            if (config.full_screen)
                gui_flags = sdl.SDL_WINDOW_FULLSCREEN |
                    sdl.SDL_WINDOW_BORDERLESS |
                    sdl.SDL_WINDOW_RESIZABLE;

            const window = sdl.SDL_CreateWindow(
                try bucket.addZ(config.app_name orelse "Engine"),
                600,
                800,
                sdl.SDL_WINDOW_RESIZABLE | sdl.SDL_WINDOW_HIGH_PIXEL_DENSITY | gui_flags,
            ) orelse {
                err("No Window created. {s}", .{sdl.SDL_GetError()});
                return error.WindowCreationFailed;
            };

            const renderer = sdl.SDL_CreateRenderer(window, null) orelse {
                err("No Renderer initialised. {s}", .{sdl.SDL_GetError()});
                return error.GraphicsRendererFailed;
            };

            _ = sdl.SDL_SetRenderVSync(renderer, 1);

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

            debug("Initialising resource loader", .{});
            const resources = try initResourcesSdl(
                gpa,
                io,
                config.bundle_filename,
                config.resource_folder,
                config.resource_filter,
            );

            const now = std.Io.Timestamp.now(io, .real).toMilliseconds();

            var themes = try gpa.alloc(*Theme, default_themes.len);
            errdefer gpa.free(themes);
            for (0..themes.len) |x| {
                themes[x] = try gpa.create(Theme);
                errdefer gpa.free(themes[x]);
                themes[x].* = default_themes[x];
            }
            const default_theme = themes[0];

            var display = try gpa.create(Display(T));
            display.* = .{
                .allocator = gpa,
                .io = io,
                .hovered = null,
                .selected = null,
                .keyboard_activity = false,
                .focussed = null,
                .scrolling = null,
                .on_resized = .empty,
                .on_panel_change = .empty,
                .current_language = .unknown,
                .need_relayout = true,
                .quit = false,
                .translation = .empty,
                .accessibility = false,
                .animators = .empty,
                .keybindings = .empty,
                .event_hook = .empty,
                .bucket = bucket,
                .resources = resources,
                .bundle_filename = bundle_filename,
                .config = config,
                .mix = mix.?,
                .renderer = renderer,
                .window = window,
                .font = undefined,
                .fonts = .empty,
                .textures = .empty,
                .themes = themes,
                .theme = default_theme,
                .audio = .empty,
                .last_draw = now,
                .last_delta = now,

                .pixel_density = density,
                .pixel_scale = pixel_scale,
                .user_scale = 1,
                .scale = pixel_scale / 1, // pixel_scale / user_scale

                .root = .{
                    .name = "root",
                    .rect = .{
                        .x = 0,
                        .y = 0,
                        .width = @as(f32, @floatFromInt(window_width)) * density,
                        .height = @as(f32, @floatFromInt(window_height)) * density,
                    },
                    .texture = null,
                    .pad = .{ .left = 0, .right = 0, .top = 0, .bottom = 0 },
                    .minimum = .{
                        .width = @as(f32, @floatFromInt(window_width)) * density,
                        .height = @as(f32, @floatFromInt(window_height)) * density,
                    },
                    .maximum = .{
                        .width = @as(f32, @floatFromInt(window_width)) * density,
                        .height = @as(f32, @floatFromInt(window_height)) * density,
                    },
                    .layout = .{ .x = .grows, .y = .grows },
                    .child_align = .{ .x = .centre, .y = .start },
                    .colour = .{},
                    .background = .{ .colour = Colour.TRANSPARENT },
                    .border_colour = .{},
                    .border_width = 0,
                    .type = .{ .panel = .{
                        .direction = .centre,
                        .spacing = 0,
                        .children = .empty,
                    } },
                    .on_resized = .empty,
                    .on_visibility = .empty,
                },
            };

            zstbi.init(display.allocator, display.io);

            if (config.desktop_icon) |desktop_icon| {
                if (try resources.lookupOne(desktop_icon, .image, gpa)) |resource| {
                    var surface: SurfaceInfo = undefined;
                    try display.loadImage(resources, resource, &surface);
                    defer surface.deinit(gpa);
                    if (!sdl.SDL_SetWindowIcon(window, surface.surface))
                        err("Failed to set set desktop icon", .{})
                    else
                        trace("Successfully set desktop icon", .{});
                } else {
                    err("No 'desktop icon' in resource bundle.", .{});
                }
            } else {
                info("No config.desktop_icon set.", .{});
            }

            if (config.translation_filename) |translation_filename| {
                if (try resources.lookupOne(translation_filename, .csv, gpa)) |resource| {
                    const data = try loadResourceSdl(gpa, io, resources, resource);
                    defer gpa.free(data);
                    try display.translation.load_translation_data(gpa, data);
                    debug("Translation file '{s}' loaded", .{translation_filename});
                } else {
                    err("Translation file '{s}' not found.", .{translation_filename});
                }
            } else {
                info("No config.translation_filename set", .{});
            }

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

            display.update_system_theme();
            display.update_screen_metrics(true);

            return display;
        }

        /// Cleanup memory assocaited with this display.
        pub fn destroy(self: *Self, gpa: Allocator) void {
            trace("Engine cleanup", .{});

            self.root.deinit(gpa, self);

            for (self.themes) |item| {
                gpa.destroy(item);
            }
            gpa.free(self.themes);

            self.bucket.deinit();

            for (self.fonts.items) |item| {
                item.destroy(gpa);
            }
            self.fonts.deinit(gpa);

            var i = self.textures.iterator();
            while (i.next()) |x| {
                if (x.value_ptr.*.references > 0) {
                    warn("texture was not deallocated. {f} has {d} references", .{
                        base62.writer(u64, x.key_ptr.*),
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

            zstbi.deinit();
        }

        pub fn haptic_feedback_available(_: *Self) bool {
            var count: c_int = undefined;
            if (sdl.SDL_GetHaptics(&count) == null) {
                return false;
            }
            return count > 0;
        }

        pub fn haptic_feedback(_: *Self, _: u32) void {
            //
            if (sdl.SDL_OpenHaptic(0)) |haptic| {
                var effect: sdl.SDL_HapticEffect = .{
                    .type = sdl.SDL_HAPTIC_RUMBLE,
                    .condition = .{
                        .length = 1000, //ms
                        .delay = 0,
                    },
                    .ramp = .{},
                };
                sdl.SDL_CreateHapticEffect(haptic, &effect);
                if (!sdl.SDL_RunHapticEffect(haptic, 0, 1)) {
                    warn("haptic vibration failed", .{});
                }
                sdl.SDL_CloseHaptic(haptic);
            }
        }

        /// Check that a theme name is a valid theme name. Return a stack
        /// allocated string version of the name.
        pub fn validate_theme(display: *Self, name: []const u8) []const u8 {
            for (display.themes) |theme| {
                if (std.ascii.eqlIgnoreCase(theme.tag, name)) {
                    return theme.tag;
                }
            }
            return "";
        }

        /// Change the theme. If the theme name is not valid, or empty
        /// use the system preference.
        pub fn set_theme(self: *Self, name: []const u8) bool {
            for (self.themes) |theme| {
                if (std.ascii.eqlIgnoreCase(theme.tag, name)) {
                    self.theme = theme;
                    return true;
                }
            }
            switch (sdl.SDL_GetSystemTheme()) {
                sdl.SDL_SYSTEM_THEME_DARK => self.theme = self.themes[0],
                sdl.SDL_SYSTEM_THEME_LIGHT => self.theme = self.themes[3],
                else => self.theme = self.themes[3],
            }
            return name.len == 0 or std.ascii.eqlIgnoreCase(name, "default");
        }

        /// On initialisation, the display reads the users OS light/dark
        /// theme preference.
        pub fn update_system_theme(self: *Self) void {
            switch (sdl.SDL_GetSystemTheme()) {
                sdl.SDL_SYSTEM_THEME_DARK => self.theme = self.themes[0],
                sdl.SDL_SYSTEM_THEME_LIGHT => self.theme = self.themes[3],
                sdl.SDL_SYSTEM_THEME_UNKNOWN => self.theme = self.themes[3],
                else => self.theme = self.themes[3],
            }
        }

        /// Return pointer to a top level panel if it exists. Can be used
        /// to update the contents of a top level panel.
        pub fn get_panel(self: *Self, name: []const u8) ?*Entity(T) {
            for (self.root.type.panel.children.items) |entity| {
                if (entity.type != .panel) {
                    continue;
                }
                if (std.mem.eql(u8, name, entity.name)) {
                    return entity;
                }
            }
            return null;
        }

        /// Mark a top level panel as visible, and all other
        /// top level panels as not visible. The visibility of the
        /// _background_ and _menu_ panel is not altered.
        pub fn choose_panel(
            self: *Self,
            gpa: Allocator,
            name: []const u8,
        ) Allocator.Error!void {
            const old_panel = self.current_panel();

            var found = false;
            self.update_screen_metrics(false);
            for (self.root.type.panel.children.items) |entity| {
                if (entity.type != .panel) continue;
                if (std.mem.eql(u8, "background", entity.name)) continue;
                if (std.mem.eql(u8, "menu", entity.name)) continue;

                if (std.mem.eql(u8, name, entity.name)) {
                    if (entity.visible != .visible) {
                        if (old_panel) |old| {
                            info("choose panel. {s} -> {s}", .{ old.name, name });
                        } else {
                            info("choose panel. ___ -> {s}", .{name});
                        }
                        try entity.set_visibility(self, .visible);
                        if (entity.on_resized.call(self, entity)) {
                            self.need_relayout = true;
                        }
                        self.on_panel_change.call(gpa, self, old_panel, entity) catch |e| {
                            trace("panel handler error. to {s} {any}", .{ entity.name, e });
                        };
                    }
                } else {
                    // Other panels not matching `name` are hidden.
                    if (entity.visible != .hidden) {
                        debug("choose_panel({s}) hiding panel {s}.", .{ name, entity.name });
                        try entity.set_visibility(self, .hidden);
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
        pub fn current_panel(self: *Self) ?*Entity(T) {
            for (self.root.type.panel.children.items) |entity| {
                if (entity.type != .panel) {
                    err("root panel contains {t} which is not a panel", .{entity.type});
                    continue;
                }
                if (std.mem.eql(u8, "background", entity.name)) continue;
                if (std.mem.eql(u8, "menu", entity.name)) continue;
                if (entity.visible == .visible) return entity;
            }
            trace("current_panel() did not find panel.", .{});
            return null;
        }

        /// Do a draw, but dont block to wait for events. Use to ensure the
        /// window starts being drawn wile starting the app.
        pub fn initial_draw(display: *Self) !void {
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

            // Update and draw all entities
            try display.draw();
        }

        /// Apply the relayout algorithm to the currently visible root
        /// panels/scenes, descending down to each child in the tree.
        ///
        /// If any entity has an on_resized handler, and that handler
        /// returns `true` indicating that the entity size was manually
        /// changed in some way. If one entity changes its size, the
        /// relayout must be completely redone. i.e. If an entity changes
        /// size, its parent and or child entities may all be impacted.
        ///
        /// if an entity continually returns `on_resized` = `true` then an
        /// infinite loop will occur. on_resized=true should be used with
        /// caution.
        pub fn relayout(display: *Self) void {
            if (display.need_relayout == false) return;

            trace("relayout", .{});

            display.need_relayout = false;

            var resized = display.root.type.panel.layout(display, &display.root);
            resized = display.root.type.panel.layout(display, &display.root) or resized;

            if (resized) {
                if (display.on_resized.call(display, &display.root)) {
                    _ = display.root.type.panel.layout(display, &display.root);
                }
                const child_resized = display.propagate_resize_event(&display.root);
                if (child_resized) {
                    display.need_relayout = true;
                    display.relayout();
                }
            }
        }

        pub fn set_language(display: *Self, allocator: Allocator, language: Lang) !void {
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
            for (display.root.type.panel.children.items) |entity| {
                switch (entity.type) {
                    .label => try entity.language_changed(allocator, display, language),
                    .checkbox => try entity.language_changed(allocator, display, language),
                    .button => try entity.language_changed(allocator, display, language),
                    .panel => try entity.language_changed(allocator, display, language),
                    else => {},
                }
            }
            display.need_relayout = true;
        }

        /// Update and draw all entities on the display.
        pub fn draw(display: *Self) Allocator.Error!void {
            const now = std.Io.Timestamp.now(display.io, .real).toMilliseconds();
            display.last_delta = now - display.last_draw;
            display.last_draw = now;
            //info("animate delta={d}", .{delta});
            var i: usize = 0;
            while (i < display.animators.items.len) {
                const animator = display.animators.items[i];
                const done = try animator.animate(now);
                // TODO: relayout is not always needed
                display.need_relayout = true;
                if (done) {
                    const old = display.animators.swapRemove(i);
                    trace("animate complete for {s} start={d} end={d}", .{
                        old.target.name,
                        old.internal.start_time,
                        old.internal.end_time,
                    });
                    if (animator.mode == .visibility) {
                        try animator.target.set_visibility(display, animator.mode.visibility.end);
                    }
                    try old.on_end.call(display.allocator, display, old.target);
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

            // Step 2: Update and draw all entities to the screen
            display.root.update(display);
            display.relayout();
            display.root.draw(display, .{ .x = 0, .y = 0 }, null);

            // Step 3: Send everything to the display.
            _ = sdl.SDL_RenderPresent(display.renderer);
        }

        /// Load and associate a font file with a font name.
        pub fn loadFont(
            self: *Self,
            allocator: Allocator,
            io: std.Io,
            name: []const u8,
        ) (Error || Allocator.Error || Resources.Error)!*Font {
            assert(self.pixel_scale > 0);

            const resource = try self.resources.lookupOne(name, .font, allocator);
            if (resource == null) {
                err("loadFont({s}) Font not in resource folder", .{name});
                return error.ResourceNotFound;
            }
            const font_buffer = try loadResourceSdl(allocator, io, self.resources, resource.?);

            const fio = sdl.SDL_IOFromConstMem(font_buffer.ptr, font_buffer.len) orelse {
                err("SDL_IOFromConstMem: {s}", .{sdl.SDL_GetError()});
                return error.ResourceReadError;
            };
            const font_pixel_height = self.text_height.pixel_height(self.pixel_scale) * font_pixel_density;
            const myfont = sdl.TTF_OpenFontIO(fio, true, font_pixel_height) orelse {
                err("open font failed. size = {d}*{d}*2={d} error = {s}", .{
                    self.text_height,
                    self.scale,
                    font_pixel_height,
                    sdl.SDL_GetError(),
                });
                return error.ResourceReadError;
            };
            const font_ascent = sdl.TTF_GetFontAscent(myfont);
            const font_height = sdl.TTF_GetFontHeight(myfont);
            const font_descent = sdl.TTF_GetFontDescent(myfont);
            const font_size = sdl.TTF_GetFontSize(myfont);

            info("font '{s}' ascent={d} descent={d} height={d}, font_pixel_height={d} font_size={d} pixel_scale={d} user_scale={d} scale={d} screen_size={d}", .{
                name,
                font_ascent,
                font_descent,
                font_height,
                font_pixel_height,
                font_size,
                self.pixel_scale,
                self.user_scale,
                self.scale,
                self.text_height.pixel_height(1),
            });
            //sdl.TTF_SetFontHinting(myfont, 0);

            const font_info = try Font.create(allocator, name, myfont, font_buffer);
            errdefer font_info.destroy(allocator);
            try self.fonts.append(allocator, font_info);

            if (self.fonts.items.len == 1) {
                self.font.default = font_info;
                self.font.english = font_info;
                self.font.greek = font_info;
                self.font.chinese = font_info;
                self.font.korean = font_info;
            }

            if (self.fonts.items.len > 1) {
                const i = self.fonts.items.len - 2;
                _ = sdl.TTF_AddFallbackFont(self.fonts.items[i].font, self.fonts.items[i + 1].font);
            }

            return font_info;
        }

        /// Load image data from a resource bucket into a `si` SurfaceInfo
        /// struct.
        fn loadImage(
            self: *Self,
            bucket: *Resources,
            resource: *Resource,
            si: *SurfaceInfo,
        ) (Error || Allocator.Error)!void {
            si.buffer = try loadResourceSdl(self.allocator, self.io, bucket, resource);
            errdefer self.allocator.free(si.buffer);

            si.img = zstbi.Image.loadFromMemory(si.buffer, 4) catch |e| {
                if (e == error.OutOfMemory) return error.OutOfMemory;
                return error.UnknownImageFormat;
            };
            errdefer si.img.deinit(self.gpa);

            const sdl_format: sdl.SDL_PixelFormat = sdl.SDL_PIXELFORMAT_RGBA32;
            const row_size: c_int = @intCast(si.img.width * 4);

            si.surface = sdl.SDL_CreateSurfaceFrom(
                @intCast(si.img.width),
                @intCast(si.img.height),
                sdl_format,
                si.img.data.ptr,
                row_size,
            );
        }

        /// Add an animator that points to a currently active/valid entity.
        /// The entity must not be destroyed for the lifetime of the animation.
        pub inline fn add_animator(
            self: *Self,
            allocator: Allocator,
            animator: Animator(T),
        ) Allocator.Error!void {
            const new_animator = try Animator(T).create(allocator, &animator);
            try self.animators.append(allocator, new_animator);
        }

        /// Attach a child entity to the main display panel (root) entity. The
        /// main display panel should only contain panels as children
        pub inline fn add_panel(
            self: *Self,
            allocator: Allocator,
            entity: Entity(T),
        ) (Allocator.Error || Resources.Error || Error)!*Entity(T) {
            if (entity.type != .panel) {
                warn("parent display should contan panels. Not {s} {s}", .{
                    @tagName(entity.type),
                    entity.name,
                });
                return Error.RootAcceptsPanelsOnly;
            }

            return self.root.add(allocator, self, entity);
        }

        /// Convert a text string into an image that is sent as a texture to
        /// the graphics card.
        pub fn generate_text_texture(
            self: *Self,
            text: []const u8,
            myfont: *Font,
        ) ?*sdl.SDL_Texture {

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
        /// entities. This releases a texture, only when all references to
        /// a texture no longer exist.
        pub fn release_texture_resource(
            self: *Self,
            allocator: Allocator,
            ti: *Texture,
        ) void {
            if (ti.references == 0) {
                err("Attempt to release resource with no references", .{});
                return;
            }
            ti.references -= 1;
            if (ti.references != 0) {
                if (ti.references < 0) {
                    err("free texture \"{f}\" (duplicate free)", .{base62.writer(u64, ti.uid)});
                } else {
                    trace("free texture \"{f}\" (not yet {d})", .{ base62.writer(u64, ti.uid), ti.references });
                }
                return;
            }
            trace("free texture \"{f}\" (now)", .{base62.writer(u64, ti.uid)});
            _ = self.textures.remove(ti.uid);
            ti.destroy(allocator);
        }

        /// A texture resource may be referenced by multiple on screen
        /// entities. This releases a texture, only when all references to
        /// a texture no longer exist.
        pub fn release_audio_resource(
            self: *Self,
            allocator: Allocator,
            ai: *Audio,
        ) void {
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
            _ = self.audio.swapRemove(ai.name);
            ai.destroy(allocator);

            self.clearUnusedAudio(allocator);
        }

        /// Load an image from the default resource bundle.
        pub inline fn load_texture(
            self: *Self,
            gpa: Allocator,
            name: []const u8,
        ) (Error || Allocator.Error || Resources.Error)!?*Texture {
            return self.load_bundle_texture(gpa, self.resources, name);
        }

        /// Load an image from a specific resource bundle.
        pub fn load_bundle_texture(
            self: *Self,
            gpa: Allocator,
            bundle: *Resources,
            name: []const u8,
        ) (Error || Allocator.Error || Resources.Error)!?*Texture {
            if (name.len == 0) return null;

            var start = std.Io.Timestamp.now(self.io, .real).toMilliseconds();
            const resource = try bundle.lookupOne(name, .image, gpa);
            if (resource == null) return null;

            if (self.textures.get(resource.?.uid)) |texture| {
                trace("cache hit looking up {s} with uid {d}", .{ name, resource.?.uid });
                texture.references += 1;
                return texture;
            }

            var end = std.Io.Timestamp.now(self.io, .real).toMilliseconds();
            trace("search image named \"{s}\" in {d}ms", .{ name, end - start });
            start = end;

            var si: SurfaceInfo = undefined;
            try self.loadImage(bundle, resource.?, &si);
            defer si.deinit(gpa);
            end = std.Io.Timestamp.now(self.io, .real).toMilliseconds();
            trace("made surface named \"{s}\" in {d}ms", .{ name, end - start });

            start = std.Io.Timestamp.now(self.io, .real).toMilliseconds();
            const texture = sdl.SDL_CreateTextureFromSurface(self.renderer, si.surface);
            end = std.Io.Timestamp.now(self.io, .real).toMilliseconds();
            trace("sdl create texture in {d}ms", .{end - start});

            const ti = try Texture.create(gpa, resource.?.uid, texture);
            ti.references += 1;
            try self.textures.put(gpa, ti.uid, ti);
            return ti;
        }

        /// Load an image from the formatted_default resource bundle.
        pub inline fn playResource(
            self: *Self,
            gpa: Allocator,
            io: std.Io,
            name: []const u8,
            autorelease: Retain,
            volume: f32,
        ) (Error || Allocator.Error || Resources.Error)!?*Audio {
            return self.playBundleResource(gpa, io, self.resources, name, autorelease, volume);
        }

        /// Load an image from a specific resource bundle.
        pub fn playBundleResource(
            self: *Self,
            gpa: Allocator,
            io: std.Io,
            bundle: *Resources,
            name: []const u8,
            autorelease: Retain,
            volume: f32,
        ) (Error || Allocator.Error || Resources.Error)!?*Audio {
            if (name.len == 0) {
                err("play_bundle_resource(\"{s}\") resource name empty", .{name});
                return null;
            }

            self.clearUnusedAudio(gpa);

            // Load audio from memory cache if possible
            var item: ?*Audio = null;
            if (self.audio.get(name)) |i| {
                // Audio already in memory cache
                if (autorelease == .retain and i.autorelease == .autorelease) {
                    // This audio item is converting to permanent memory
                    debug("cache hit on audio named \"{s}\" convert to `retain`", .{name});
                    i.autorelease = .retain;
                    i.references += 1;
                }
                debug("cache hit on audio named \"{s}\" (pre ref count={d})", .{ name, i.references });
                item = i;
            } else {
                // Load audio from resource bundle
                var start = std.Io.Timestamp.now(self.io, .real).toMilliseconds();
                const resource = try bundle.lookupOne(name, .audio, gpa);
                if (resource == null) {
                    err("search audio named \"{s}\" not found.", .{name});
                    return null;
                }
                var end = std.Io.Timestamp.now(self.io, .real).toMilliseconds();
                debug("search audio named \"{s}\" in {d}ms", .{ name, end - start });

                start = end;
                const audio = try loadResourceSdl(gpa, io, bundle, resource.?);
                errdefer gpa.free(audio);
                end = std.Io.Timestamp.now(self.io, .real).toMilliseconds();

                debug("read audio named \"{s}\" size {d} in {d}ms", .{
                    name,
                    audio.len,
                    end - start,
                });

                const ai = try Audio.create(gpa, name, audio, autorelease);
                ai.resource = resource;
                if (autorelease == .retain) ai.autorelease = .retain;
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

            item.?.references += 1;

            _ = mixer.MIX_SetTrackAudio(track, buff.?);
            _ = mixer.MIX_SetTrackGain(track, volume);
            _ = mixer.MIX_SetTrackStoppedCallback(track, audio_playback_complete, item);
            _ = mixer.MIX_PlayTrack(
                track,
                0, // used to request looping or play starting point
            );
            //_ = mixer.MIX_PlayAudio(self.mix, buff.?);

            return item;
        }

        pub fn clearUnusedAudio(self: *Self, gpa: Allocator) void {
            // Remove any no longer used audio
            const old = self.audio.values();
            for (0..old.len) |i| {
                const a = old[i];
                if (a.references == 0 and a.autorelease == .autorelease) {
                    debug("cleanup/dealloc audio {s}", .{a.name});
                    _ = self.audio.swapRemove(a.name);
                    a.destroy(gpa);
                }
            }
        }

        pub fn select_first_entity(
            self: *Self,
            entities: []*Entity(T),
            gpa: Allocator,
        ) bool {
            for (entities) |entity| {
                if (entity.visible != .visible) continue;

                if (entity.type == .panel) {
                    if (self.select_first_entity(entity.type.panel.children.items, gpa))
                        return true;

                    if (entity.type.panel.on_click.func == null)
                        continue;
                }
                if (entity.focus == .never_focus or entity.focus == .unspecified)
                    continue;

                if (entity.focus == .accessibility_focus and self.accessibility == false)
                    continue;

                entity.selected(self, gpa);
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

        pub fn select_next_entity(self: *Self, gpa: Allocator) void {
            trace("select_next_entity() find next entity", .{});
            var state = SelectState.no_selectable_items;
            var previous: ?*Entity(T) = null;
            const entity = self.do_select_next_entity(
                self.root.type.panel.children.items,
                &state,
                &previous,
            );
            if (entity) |found| {
                found.selected(self, gpa);
                return;
            }
            if (state == .has_selectable_item or state == .found_currently_selected_item) {
                _ = self.select_first_entity(self.root.type.panel.children.items, gpa);
            } else {
                debug("select_next_entity() no entity found. {s}", .{@tagName(state)});
            }
        }

        pub fn select_previous_entity(self: *Self, gpa: Allocator) void {
            trace("select_previous_entity() find previous entity", .{});
            var state = SelectState.no_selectable_items;
            var previous: ?*Entity(T) = null;
            _ = self.do_select_next_entity(self.root.type.panel.children.items, &state, &previous);
            if (previous) |found| {
                found.selected(self, gpa);
                return;
            }
            if (state == .has_selectable_item or state == .found_currently_selected_item) {
                _ = self.select_first_entity(self.root.type.panel.children.items, gpa);
            } else {
                debug("select_next_entity() no entity found. {s}", .{@tagName(state)});
            }
        }

        fn do_select_next_entity(
            self: *Self,
            entities: []*Entity(T),
            state: *SelectState,
            previous: *?*Entity(T),
        ) ?*Entity(T) {
            for (entities) |entity| {
                trace("search: {s} inspect {s}/{s}/{s}", .{
                    @tagName(state.*),
                    @tagName(entity.type),
                    @tagName(entity.focus),
                    entity.name,
                });
                if (entity.visible != .visible) {
                    trace("     skip not visible {s}/{s}", .{ @tagName(entity.type), entity.name });
                    continue;
                }
                if (entity.type == .panel) {
                    if (self.do_select_next_entity(entity.type.panel.children.items, state, previous)) |found| {
                        return found;
                    }
                    if (entity.type.panel.on_click.func == null)
                        continue;
                }
                if (entity.focus == .never_focus or entity.focus == .unspecified)
                    continue;

                if (entity.focus == .accessibility_focus) {
                    if (self.accessibility == false) {
                        trace("     skip no accessibility {s}/{s}", .{ @tagName(entity.type), entity.name });
                        continue;
                    }
                    if (entity.type == .label and entity.type.label.translated.len == 0) {
                        continue;
                    }
                }
                // We found a selectable entity
                if (state.* == .no_selectable_items) {
                    state.* = .has_selectable_item;
                    //debug("    --> {any}\n", .{state.*});
                }
                if (state.* == .has_selectable_item) {
                    if (entity == self.selected) {
                        state.* = .found_currently_selected_item;
                        //debug("    --> {any}\n", .{state.*});
                        continue;
                    }
                    previous.* = entity;
                    continue;
                }
                state.* = .selected_item;
                //debug("    --> {any}\n", .{state.*});
                return entity;
            }
            return null;
        }

        pub const FindQuery = enum { any, clickable, scrollable };

        // Find what entity appears directly under the cursor.
        //
        // Because the first entity in the entity list are drawn first,
        // the first entities appear below entities later on in the list.
        //
        // When searching for buttons to click on, we are seeking the top
        // most (last drawn) items.
        //
        // When searching for panels to grab and scroll with, we are seeking
        // the panel surface under the button. We are seeking the bottom most
        // (first drawn) items. (Because on mouse down is not a button click
        // we dont need to handle this special case.)
        pub fn find_under_cursor(
            display: *Self,
            entities: []*Entity(T),
            cursor: Vector,
            scroll_offset: Vector,
            comptime query: FindQuery,
        ) ?*Entity(T) {
            var i = entities.len;
            while (i > 0) : (i -= 1) {
                const entity: *Entity(T) = entities[i - 1];
                //debug("seek={s} visible={any} {s} {s}", .{ @tagName(query), entity.visible, @tagName(entity.type), entity.name });
                if (entity.visible != .visible) continue;

                const is_under_cursor = entity.at_point(cursor, scroll_offset);
                if (!is_under_cursor and entity.type != .panel) continue;

                //debug("under cursor {s}.{s}", .{ @tagName(entity.type), entity.name });
                if (entity.type == .panel) {
                    const so = scroll_offset.add(entity.offset);
                    if (display.find_under_cursor(entity.type.panel.children.items, cursor, so, query)) |found| {
                        return found;
                    }
                }
                // This item is under the cursor
                if (query == .any) {
                    // Search for any entity
                    if (entity.focus == .never_focus) continue;

                    // Panels get special handling,
                    if (entity.type != .panel) return entity;

                    if (is_under_cursor) {
                        if (entity.type.panel.on_click.func != null)
                            return entity;

                        if (entity.type.panel.scrollable.scroll.x == true or entity.type.panel.scrollable.scroll.y == true)
                            return entity;
                    }
                }

                if (query == .clickable) {
                    // Search only clickable entities
                    if (entity.focus == .never_focus) continue;

                    switch (entity.type) {
                        .text_input, .checkbox => return entity,
                        .button => {
                            if (entity.type.button.toggle == .no_toggle or entity.type.button.toggle == .on or entity.type.button.toggle == .off or entity.type.button.toggle == .disabled)
                                return entity;
                        },
                        .label => if (entity.type.label.on_click.func != null) {
                            return entity;
                        },
                        .sprite => if (entity.type.sprite.on_click.func != null) {
                            return entity;
                        },
                        .panel => if (is_under_cursor and entity.type.panel.on_click.func != null) {
                            return entity;
                        },
                        .rectangle, .progress_bar, .expander => {},
                    }
                } else if (query == .scrollable) {
                    if (entity.type == .panel and is_under_cursor) {
                        if (entity.type.panel.scrollable.scroll.x or entity.type.panel.scrollable.scroll.y) {
                            return entity;
                        }
                    }
                }
            }
            return null;
        }

        /// Switch from the current theme to the next theme. This is a keypress
        /// event handler that expects `display`, `entity` and `allocator`.
        pub fn rotate_theme(
            self: *Self,
            _: *Self,
            _: *Entity(T),
            _: Allocator,
        ) void {
            var index: usize = 0;

            // Find the current theme
            for (self.themes) |theme| {
                if (theme == self.theme) break;
                index += 1;
            }
            index += 1;
            if (index >= self.themes.len) {
                index = 0;
            }
            self.theme = self.themes[index];
        }

        /// Update the quit flag to indicate to the main loop that
        /// it should exit after processing the current event.
        pub fn end_main_loop(display: *Self) void {
            info("Ending main loop.", .{});
            display.quit = true;
        }

        /// Draw all entities. Used in conjunction with SDL_AppIterate
        pub fn iterate(display: *Self) !void {
            try display.draw();
        }

        /// Enters the main run loop and only returns when quit has been
        /// requested. Use in conjunction with SDL_Main
        pub fn main(display: *Self, allocator: Allocator) !void {
            info("Main loop starting", .{});
            display.quit = false;

            while (!display.quit) {
                // Update and draw all entities
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
            display: *Self,
            gpa: Allocator,
            e: *sdl.SDL_Event,
        ) !void {
            trace("handle_key_up_event({any})", .{e.key.key});
            if (e.key.key == sdl.SDLK_TAB) {
                if (e.key.mod == sdl.SDL_KMOD_SHIFT or e.key.mod == sdl.SDL_KMOD_LSHIFT or e.key.mod == sdl.SDL_KMOD_RSHIFT) {
                    display.select_previous_entity(gpa);
                } else {
                    display.select_next_entity(gpa);
                }
                if (display.selected != null) display.keyboard_activity = true;
                return;
            }
            if (e.key.key == sdl.SDLK_UP) {
                display.select_previous_entity(gpa);
                if (display.selected != null) display.keyboard_activity = true;
                return;
            }
            if (e.key.key == sdl.SDLK_LEFT) {
                display.select_previous_entity(gpa);
                if (display.selected != null) display.keyboard_activity = true;
                return;
            }
            if (e.key.key == sdl.SDLK_DOWN) {
                display.select_next_entity(gpa);
                if (display.selected != null) display.keyboard_activity = true;
                return;
            }
            if (e.key.key == sdl.SDLK_RIGHT) {
                display.select_next_entity(gpa);
                if (display.selected != null) display.keyboard_activity = true;
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
                                        try selected.type.button.on_click.call(gpa, display, selected);
                                    },
                                    else => {},
                                }
                            },
                            sdl.SDLK_ESCAPE => if (display.keybindings.get(sdl.SDLK_ESCAPE)) |f| {
                                try f.call(gpa, display, &display.root);
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
                    k.value_ptr.*.call(gpa, display, &display.root) catch |f| {
                        trace("keypress handler error: {d} {any}", .{ e.key.key, f });
                    };
                    trace("keypress special handler complete: {d}", .{e.key.key});
                }
            }
        }

        /// Handle key down events. Usually no action is triggered until the
        /// key is released.
        inline fn handle_key_down_event(_: *Self, _: Allocator, _: *sdl.SDL_Event) !void {
            //
        }

        /// Refresh the window size information, then refresh the
        /// safe area information.
        pub inline fn update_screen_metrics(display: *Self, forced: bool) void {
            var updated = false;

            var rwidth: c_int = 0;
            var rheight: c_int = 0;
            _ = sdl.SDL_GetRenderOutputSize(display.renderer, &rwidth, &rheight);
            if (display.root.rect.width != @as(f32, @floatFromInt(rwidth)))
                updated = true;
            if (display.root.rect.height != @as(f32, @floatFromInt(rheight)))
                updated = true;
            if (display.root.minimum.width != @as(f32, @floatFromInt(rwidth)))
                updated = true;
            if (display.root.minimum.height != @as(f32, @floatFromInt(rheight)))
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
            display.root.minimum.width = display.root.rect.width;
            display.root.maximum.width = display.root.rect.width;
            display.root.minimum.height = display.root.rect.height;
            display.root.maximum.height = display.root.rect.height;

            if (display.recalculate_safe_area()) {
                updated = true;
            }

            if (updated or forced) {
                display.need_relayout = true;
            }
        }

        /// Trigger `on_resized` events on each node in the tree.
        fn propagate_resize_event(self: *Self, entity: *Entity(T)) bool {
            var updated = false;
            if (entity.visible == .visible)
                updated = entity.on_resized.call(self, entity);

            if (entity.type == .panel) {
                for (entity.type.panel.children.items) |child| {
                    if (child.visible == .visible) {
                        updated = self.propagate_resize_event(child) or updated;
                    }
                }
            }

            return updated;
        }

        /// Handle events that impact the usable area of the screen.
        fn recalculate_safe_area(self: *Self) bool {
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
        inline fn handle_mouse_up_event(
            display: *Self,
            gpa: Allocator,
            _: *sdl.SDL_Event,
        ) !void {
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
                    display.scrolling.?.offset.x = @round(display.scrolling.?.offset.x);
                    display.scrolling.?.offset.y = @round(display.scrolling.?.offset.y);

                    // If scrolling occurred, this cant be a click
                    trace("tap became scroll. proper movement on {s} at cursor={any}. offset={d}x{d}", .{
                        display.scrolling.?.name,
                        cursor,
                        display.scrolling.?.offset.x,
                        display.scrolling.?.offset.y,
                    });
                    display.scrolling = null;
                    return;
                }
                trace("tap is not scroll. minimal movement on {s} at {any}", .{
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
                            try found.type.panel.on_click.call(gpa, display, found);
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

        /// Event handler for mouse down events. This begins a scroll event,
        /// or converts to a click on mouse up event later.
        inline fn handle_mouse_down_event(
            display: *Self,
            _: Allocator,
            _: *sdl.SDL_Event,
        ) !void {
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

        /// When the user is dragging a scrollable panel, it starts with
        /// an offset `value` of zero. If the panel overflows its box,
        /// then the offset value may decrease to the `min` offset or
        /// increase to the `max` offset.
        fn limit_scroll(min: f32, value: f32, max: f32) f32 {
            std.debug.assert(min <= max);
            if (value < min) return min;
            if (value > max) return max;
            return value;
        }

        /// Event handler for mouse motion
        inline fn handle_mouse_motion_event(
            display: *Self,
            _: *sdl.SDL_Event,
        ) !void {
            var cursor: Vector = undefined;
            _ = sdl.SDL_GetMouseState(&cursor.x, &cursor.y);
            // Translate cursor position to pixel position
            cursor = cursor.multiply(display.pixel_density);

            if (display.scrolling) |entity| {
                // If mouse is down while movement is detected, and mouse was
                // down on a movable item, we are in scrolling/moving mode.
                switch (entity.type) {
                    .panel => |*panel| {

                        // How far has the mouse/finger moved the item
                        entity.offset = cursor.minus(display.scroll_start).add(display.scroll_initial_offset);

                        // Clamp offset so we cant scroll past end at all
                        switch (entity.child_align.x) {
                            .centre => {
                                // allowable scroll offset (negative number)
                                const allowable_x_scroll = @min(0, entity.rect.width - panel.scrollable.size.width) / 2;
                                entity.offset.x = limit_scroll(allowable_x_scroll, entity.offset.x, -allowable_x_scroll);
                            },
                            else => {
                                // allowable scroll offset (negative number)
                                const allowable_x_scroll = @min(0, entity.rect.width - panel.scrollable.size.width);
                                entity.offset.x = limit_scroll(allowable_x_scroll, entity.offset.x, 0);
                            },
                        }

                        // Clamp offset so we cant scroll past start at all
                        switch (entity.child_align.y) {
                            .centre => {
                                const allowable_y_scroll = @min(0, entity.rect.height - panel.scrollable.size.height) / 2;
                                entity.offset.y = limit_scroll(allowable_y_scroll, entity.offset.y, -allowable_y_scroll);
                            },
                            else => {
                                const allowable_y_scroll = @min(0, entity.rect.height - panel.scrollable.size.height);
                                entity.offset.y = limit_scroll(allowable_y_scroll, entity.offset.y, 0);
                            },
                        }

                        if (!panel.scrollable.scroll.y)
                            entity.offset.y = 0;

                        if (!panel.scrollable.scroll.x)
                            entity.offset.x = 0;

                        trace("scrolling panel {s}. scrollable.size={d}x{d} panel.size={d}x{d}. draw.offset={d}x{d}", .{
                            entity.name,
                            panel.scrollable.size.width,
                            panel.scrollable.size.height,
                            entity.rect.width,
                            entity.rect.height,
                            entity.offset.x,
                            entity.offset.y,
                        });
                    },
                    else => {
                        err("Cant scroll {s}. Not a panel.", .{entity.name});
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
        pub fn handle_event(
            display: *Self,
            allocator: Allocator,
            e: *sdl.SDL_Event,
        ) !void {
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
                            err("sdl text input event on non text_input entity.", .{});
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
                    _ = try display.event_hook.call(allocator, e.type);
                    // Other SDL events are not handled
                },
            }
        }

        /// Set the user preferred screen scale.
        pub fn set_scale(display: *Self, scale: Scale) void {
            display.user_scale = scale.float();
            display.scale = display.pixel_scale * display.user_scale;
        }

        /// Lookoup the user preferred screen scale.
        pub fn user_scale_setting(display: *Self) Scale {
            return Scale.from_float(display.user_scale);
        }

        /// Keypress event handler expects `display`, `entity` and `allocator`.
        pub fn increase_size(
            _: *Self,
            display: *Self,
            _: *Entity(T),
            _: Allocator,
        ) void {
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

        /// Keypress event handler expects `display`, `entity` and `allocator`.
        pub fn decrease_size(
            display: *Self,
            _: *Self,
            _: *Entity(T),
            _: Allocator,
        ) void {
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

        /// Keypress event handler expects `display`, `entity` and `allocator`.
        fn make_bundle(
            display: *Self,
            _: *Self,
            _: *Entity(T),
            _: Allocator,
        ) error{OutOfMemory}!void {
            if (!dev_build) return;

            if (display.bundle_filename == null) {
                info("no config.bundle_filename. Not making bundle.", .{});
                return;
            }

            if (display.resources.used_resources == null) {
                info("no resources in manifest, nothing to bundle.", .{});
                return;
            }

            const manifest = display.resources.used_resources.?;
            if (manifest.count() == 0) {
                info("no used resources in manifest, nothing to bundle.", .{});
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
                return Allocator.Error.OutOfMemory;
            };
            buffer.appendSlice(display.bundle_filename.?) catch {
                return std.mem.Allocator.Error.OutOfMemory;
            };
            info("making resource bundle: {s}", .{buffer.slice()});

            display.resources.saveBundle(
                display.io,
                buffer.slice(),
                manifest,
                &.{},
                "/tmp",
            ) catch |e| {
                info("save resource bundle failed. {s} {any}", .{ buffer.slice(), e });
            };
        }

        /// Provides a standardised way to place a back button in the top left
        /// corner of the screen.
        pub fn add_back_button(
            display: *Self,
            allocator: Allocator,
            parent: *Entity(T),
            close_fn: Entity(T).Callback,
        ) (Error || Allocator.Error || Resources.Error)!*Entity(T) {
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

        /// This event handler repositions a back button into the top left corner
        /// when the screen is resized or rotated.
        pub fn back_button_resize(
            _: *Display(T),
            display: *Display(T),
            entity: *Entity(T),
        ) bool {
            var updated = false;
            if (entity.rect.x != display.safe_area.left) {
                entity.rect.x = display.safe_area.left;
                updated = true;
            }
            if (entity.rect.y != display.safe_area.top) {
                entity.rect.y = display.safe_area.top;
                updated = true;
            }
            return updated;
        }

        /// Add an empty panel that keeps a space open in a list of entities.
        pub fn add_spacer(
            display: *Self,
            allocator: Allocator,
            parent: *Entity(T),
            size: f32,
        ) (Error || Allocator.Error || Resources.Error)!*Entity(T) {
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
            display: *Self,
            allocator: Allocator,
            parent: *Entity(T),
            size: T,
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

        /// Keypress `Callback` handler to toggle dev mode.
        fn toggle_dev_mode(_: *Self, _: Allocator, _: *Display(T)) Allocator.Error!void {
            engine.dev_mode = !engine.dev_mode;
            info("Dev mode: {any}", .{engine.dev_mode});
        }

        pub const Callback = struct {
            func: ?*const fn (ptr: *anyopaque, *Display(T)) Allocator.Error!void = null,
            ptr: *anyopaque = undefined,

            pub const empty = .{ .func = null };

            pub fn call(
                self: Callback,
                allocator: Allocator,
                display: *Display(T),
            ) Allocator.Error!void {
                if (self.func) |f| return f(self.ptr, allocator, display);
            }
        };
    };
}

fn audio_playback_complete(audio: ?*anyopaque, _: ?*mixer.MIX_Track) callconv(.c) void {
    const audio_ref: ?*Audio = @ptrCast(@alignCast(audio));
    if (audio_ref) |a| {
        std.log.info("playback complete {s} refs {d} ({t})", .{ a.name, a.references, a.autorelease });

        if (a.references > 0) a.references -= 1;
        std.log.info("   refs {d}", .{audio_ref.?.references});

        if (a.references == 0)
            if (a.autorelease == .retain)
                std.log.info("playback complete {s}. autorelease unexpectedly hit 0 refs ({t})", .{ a.name, a.autorelease });

        return;
    }
    std.log.info("playback complete [unknown].", .{});
}

pub const U32Callback = struct {
    func: ?*const fn (ptr: *anyopaque, allocator: Allocator, e: u32) Allocator.Error!void = null,
    ptr: *anyopaque = undefined,

    pub const empty: @This() = .{ .func = null };

    pub fn call(
        self: @This(),
        allocator: Allocator,
        value: u32,
    ) Allocator.Error!void {
        if (self.func) |f| return f(self.ptr, allocator, value);
    }
};

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
    FontRequired,
    RootAcceptsPanelsOnly,
};

pub const LanguageFont = struct {
    default: *Font,
    english: *Font,
    greek: *Font,
    korean: *Font,
    chinese: *Font,
};

pub const SurfaceInfo = struct {
    buffer: []const u8,
    img: zstbi.Image,
    surface: *sdl.SDL_Surface,

    pub fn deinit(si: *@This(), gpa: Allocator) void {
        gpa.free(si.buffer);
        si.img.deinit();
        sdl.SDL_DestroySurface(si.surface);
    }
};

/// Draw an outline of a rectangle. Used in debug mode to highlight where
/// items appear on the screen.
pub fn draw_rectangle(
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

/// Draw an outline of a rectangle. Used in debug mode to highlight where
/// items appear on the screen.
pub fn draw_line(
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

/// When the display loads a resource, it may be retained for as long as
/// there is a reference held to this resource. Alternatively, a resource
/// may be marked as retained, effectively causing it to be cached until a
/// manual release is requested.
pub const Retain = enum {
    autorelease,
    retain,
};

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
        return std.enums.fromInt(SdlLogPriority, priority) orelse .unknown;
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
        return std.enums.fromInt(SdlLogCategory, category) orelse .unknown;
    }
};

/// A `trace` message can be used liberally and should only be used for
/// log messages in programs that are under active development. Is never
/// included in a production ready build of an application.
pub inline fn trace(comptime format: []const u8, args: anytype) void {
    if (dev_build)
        if (dev_mode)
            formatted_log_output(.trace, .engine, format, args);
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

/// Tell zig to pass log messages to a custom `log_output_handler`
pub const std_options: std.Options = .{
    .log_level = .debug,
    .logFn = log_output_handler,
};

/// Zig log output handler captures zig log calls
pub fn log_output_handler(
    comptime level: std.log.Level,
    comptime scope: @EnumLiteral(),
    comptime format: []const u8,
    args: anytype,
) void {
    // Map the limit zig log options to proper log levels.
    switch (level) {
        .debug => formatted_log_output(.debug, scope, format, args),
        .info => formatted_log_output(.info, scope, format, args),
        .warn => formatted_log_output(.warn, scope, format, args),
        .err => formatted_log_output(.err, scope, format, args),
    }
}

/// Write a log message to stderr in debug mode or to SDL in release mode
pub fn formatted_log_output(
    comptime level: LogLevel,
    comptime scope: @EnumLiteral(),
    comptime format: []const u8,
    args: anytype,
) void {
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
        //var buffer: [1024 * 5]u8 = undefined;
        //var stderr_writer = std.Io.File.stderr().writer(std.Options.debug_io, &buffer);
        //const stderr = &stderr_writer.interface;
        var stderr = std.debug.lockStderr(&.{}).terminal().writer;
        defer std.debug.unlockStderr();
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
            var buffer: [1024 * 5]u8 = undefined;
            if (std.fmt.bufPrintZ(&buffer, prefix ++ format, args)) |f| {
                sdl.SDL_LogInfo(@intFromEnum(SdlLogCategory.application), f.ptr);
            } else |_| {
                sdl.SDL_LogInfo(@intFromEnum(SdlLogCategory.application), prefix ++ format);
            }
        }
    }
}

pub const Config = struct {
    app_name: ?[]const u8 = null,
    app_version: ?[]const u8 = null,
    app_id: ?[]const u8 = null,
    app_org: ?[]const u8 = null,
    app_build: ?[]const u8 = null,
    app_icon_name: ?[]const u8 = null,
    bundle_filename: ?[]const u8 = null,
    resource_folder: ?[]const u8 = null,
    resource_filter: ?*const fn (name: []const u8, extension: FileType) bool = null,
    translation_filename: ?[]const u8 = null,
    desktop_icon: ?[]const u8 = null,
    full_screen: bool = false,
};

pub inline fn clamp(min: f32, value: f32, max: f32) f32 {
    if (value < min) return min;
    if (max <= 0) return value;
    if (value > max) return max;
    return value;
}

pub fn directional_clamp(mode: LayoutSize, min: f32, value: f32, max: f32) f32 {
    if (mode == .grows)
        if (max > 0) return max;
    if (mode == .shrinks)
        if (min > 0) return min;
    return clamp(min, value, max);
}

test "clamp" {
    try eq(10, clamp(10, 0, 30));
    try eq(20, clamp(10, 20, 30));
    try eq(30, clamp(10, 40, 30));

    try eq(10, clamp(10, 0, 0));
    try eq(20, clamp(10, 20, 0));
    try eq(40, clamp(10, 40, 0));

    try eq(10, clamp(10, 0, -10));
    try eq(20, clamp(10, 20, -10));
    try eq(40, clamp(10, 40, -10));
}

test "directional_clamp" {
    try eq(10, directional_clamp(.fixed, 10, 0, 30));
    try eq(20, directional_clamp(.fixed, 10, 20, 30));
    try eq(30, directional_clamp(.fixed, 10, 40, 30));

    try eq(10, directional_clamp(.fixed, 10, 0, 0));
    try eq(20, directional_clamp(.fixed, 10, 20, 0));
    try eq(40, directional_clamp(.fixed, 10, 40, 0));

    try eq(10, directional_clamp(.fixed, 10, 0, -10));
    try eq(20, directional_clamp(.fixed, 10, 20, -10));
    try eq(40, directional_clamp(.fixed, 10, 40, -10));

    try eq(10, directional_clamp(.shrinks, 10, 0, 30));
    try eq(10, directional_clamp(.shrinks, 10, 20, 30));
    try eq(10, directional_clamp(.shrinks, 10, 40, 30));

    try eq(10, directional_clamp(.shrinks, 10, 0, 0));
    try eq(10, directional_clamp(.shrinks, 10, 20, 0));
    try eq(10, directional_clamp(.shrinks, 10, 40, 0));

    try eq(10, directional_clamp(.shrinks, 10, 0, -10));
    try eq(10, directional_clamp(.shrinks, 10, 20, -10));
    try eq(10, directional_clamp(.shrinks, 10, 40, -10));

    try eq(30, directional_clamp(.grows, 10, 0, 30));
    try eq(30, directional_clamp(.grows, 10, 20, 30));
    try eq(30, directional_clamp(.grows, 10, 40, 30));

    try eq(10, directional_clamp(.grows, 10, 0, 0));
    try eq(20, directional_clamp(.grows, 10, 20, 0));
    try eq(40, directional_clamp(.grows, 10, 40, 0));

    try eq(10, directional_clamp(.grows, 10, 0, -10));
    try eq(20, directional_clamp(.grows, 10, 20, -10));
    try eq(40, directional_clamp(.grows, 10, 40, -10));
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
    const io = std.testing.io;
    // The display takes ownership of the resources object
    var display = try Display(TextSize(22)).create(allocator, io, test_config);
    defer display.destroy(allocator);
}

test "button sizing" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var display = try headless_display(allocator, io, TextSize(22), 1024, 720, 2);
    defer display.destroy(allocator);

    const panel = try display.add_panel(allocator, .{
        .minimum = .{ .width = 5, .height = 8 },
        .type = .{ .panel = .{ .spacing = 0, .direction = .left_to_right } },
        .layout = .{ .x = .shrinks, .y = .shrinks },
    });
    try eq(5, panel.minimum_needed_width(display, 500));
    try eq(8, panel.minimum_needed_height(display, 500));

    const not_quite_one_line = display.text_height.pixel_height(display.scale) - 5;
    const not_quite_two_lines = display.text_height.pixel_height(display.scale) * 2 - 5;

    var button = try panel.add(allocator, display, .{
        .visible = .visible,
        .rect = .{ .width = 50, .height = 50 },
        .minimum = .{ .width = 30, .height = not_quite_one_line },
        .maximum = .{ .width = 82, .height = not_quite_two_lines },
        .type = .{ .button = .{ .text = "" } },
    });
    display.need_relayout = true;
    display.relayout();
    try eq(50, button.minimum_needed_width(display, 500));
    try eq(50, button.minimum_needed_height(display, 500));
    button.layout.x = .shrinks;
    button.layout.y = .shrinks;
    try eq(30, button.minimum_needed_width(display, 500));
    // The words will overflow the bottom of the box
    try eq(not_quite_one_line, button.minimum_needed_height(display, 500));

    display.need_relayout = true;
    display.relayout();
    try eq(30, panel.minimum_needed_width(display, 500));
    try eq(30, button.rect.width);
    // panel has min width 5, but button pushes it out to 30
    try eq(30, panel.rect.width);
    try eq(not_quite_one_line, button.rect.height);
    try eq(not_quite_one_line, panel.rect.height);

    panel.pad.left = 2;
    panel.pad.right = 3;
    panel.pad.top = 4;
    panel.pad.bottom = 5;
    display.relayout();
    try eq(30, button.rect.width);
    try eq(30, panel.rect.width);
    try eq(not_quite_one_line, button.rect.height);
    try eq(not_quite_one_line, panel.rect.height);

    panel.minimum.width = 100;
    display.relayout();
    try eq(100, panel.minimum_needed_width(display, 500));
    panel.minimum.width = 10;

    // Add test font so we can test label layout
    try std.testing.expect(display.resources.by_uid.count() > 0);
    _ = try display.loadFont(allocator, io, "Roboto-Light");

    try button.set_text(allocator, display, "Hello");
    display.need_relayout = true;
    display.relayout();
    try eq(42, @round(button.rect.width / display.pixel_density));
    // Does the width grow more than 10 (minimum) because of the button size.
    try eq(88, @round(panel.rect.width));
    // Minimum height was not_quite_one_line, expect it grew to font height.
    try eq(display.text_height.pixel_height(1), button.rect.height / display.pixel_density);
    try eq(display.text_height.pixel_height(2) + 4 + 5, panel.rect.height);

    // Buttons cant wrap, hight will only change with padding.
    button.maximum.height = 500;
    try button.set_text(allocator, display, "Hello Defragment");
    display.relayout();
    try eq(display.text_height.pixel_height(1), button.rect.height / display.pixel_density);
    button.pad.top = 4;
    button.pad.bottom = 5;
    display.need_relayout = true;
    display.relayout();
    try eq(display.text_height.pixel_height(1), (button.rect.height - 4 - 5) / display.pixel_density);
}

fn create_label(
    allocator: Allocator,
    display: *Display(TextSize(22)),
    settings: Entity(TextSize(22)),
) (Error || Allocator.Error || Resources.Error)!*Entity(TextSize(22)) {
    const entity = try display.allocator.create(Entity(TextSize(22)));
    entity.* = settings;
    try display.setup_entity(allocator, entity);
    return entity;
}

test "text input sizing" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var display = try headless_display(allocator, io, TextSize(22), 1000, 1600, 2);
    defer display.destroy(allocator);

    var panel = try display.add_panel(allocator, .{
        .type = .{ .panel = .{ .direction = .top_to_bottom } },
        .layout = .{ .x = .grows, .y = .grows },
    });

    // Add test font so we can test label layout
    try std.testing.expect(display.resources.by_uid.count() > 0);
    _ = try display.loadFont(allocator, io, "Roboto-Light");

    {
        // Create a fixed sized label with enough space
        const l = try panel.add(allocator, display, .{
            .name = "hello",
            .rect = .{ .width = 500, .height = 60 },
            .minimum = .{ .width = 300, .height = 50 },
            .maximum = .{ .width = 401, .height = 201 },
            .type = .{ .label = .{ .text = "Hello world" } },
            .layout = .{ .x = .fixed, .y = .grows },
        });
        l.pad = .{ .top = 0, .bottom = 0, .left = 0, .right = 0 };
        try eq(500, l.minimum_needed_width(display, 500));
        try eq(50, l.minimum_needed_height(display, 500));
        panel.remove_entities(allocator, display);
    }

    {
        // Create a fixed sized label with minimum
        const l = try panel.add(allocator, display, .{
            .name = "hello",
            .rect = .{ .width = 500, .height = 60 },
            .minimum = .{ .width = 300, .height = 55 },
            .maximum = .{ .width = 401, .height = 201 },
            .type = .{ .label = .{ .text = "Hello world" } },
            .layout = .{ .x = .fixed, .y = .fixed },
        });
        l.pad = .{ .top = 0, .bottom = 0, .left = 0, .right = 0 };
        try eq(500, l.minimum_needed_width(display, 500));
        try eq(60, l.minimum_needed_height(display, 500));
        panel.remove_entities(allocator, display);
    }

    {
        // Create a fixed sized label with minimum
        const l = try panel.add(allocator, display, .{
            .name = "hello",
            .rect = .{ .width = 200, .height = 100 },
            .minimum = .{ .width = 300, .height = 20 },
            .maximum = .{ .width = 401, .height = 201 },
            .type = .{ .label = .{ .text = "Hello world" } },
            .layout = .{ .x = .grows, .y = .shrinks },
        });
        l.pad = .{ .top = 0, .bottom = 0, .left = 0, .right = 0 };
        try eq(300, l.minimum_needed_width(display, 500));
        try eq(display.text_height.pixel_height(display.scale), l.minimum_needed_height(display, 500));
        panel.remove_entities(allocator, display);
    }

    {
        // Create a fixed sized label with x growth
        const l = try panel.add(allocator, display, .{
            .name = "hello",
            .rect = .{ .width = 1, .height = 1 },
            .minimum = .{ .width = 1, .height = 20 },
            .maximum = .{ .width = 401, .height = 201 },
            .type = .{ .label = .{ .text = "Hello world" } },
            .layout = .{ .x = .grows, .y = .shrinks },
        });
        l.pad = .{ .top = 0, .bottom = 0, .left = 0, .right = 0 };
        // Minimum is not the actual width, but the smallest it could do.
        try eq(187, @round(l.minimum_needed_width(display, 500)));
        try eq(display.text_height.pixel_height(display.pixel_scale), l.minimum_needed_height(display, 500));
        panel.remove_entities(allocator, display);
    }

    {
        // Create a label with full shrinking
        const l = try panel.add(allocator, display, .{
            .name = "hello",
            .rect = .{ .width = 1, .height = 1 },
            .minimum = .{ .width = 1, .height = 20 },
            .maximum = .{ .width = 401, .height = 201 },
            .type = .{ .label = .{ .text = "Hello world" } },
            .layout = .{ .x = .shrinks, .y = .shrinks },
            .pad = .{ .top = 0, .bottom = 0, .left = 0, .right = 0 },
        });
        l.pad = .{ .top = 0, .bottom = 0, .left = 0, .right = 0 };
        display.need_relayout = true;
        display.relayout();
        try eq(2, l.type.label.elements.items.len);
        // Bitmap/Pixel width of first word in this font is 197 pixels
        try eq(99, @round(l.type.label.elements.items[0].width / display.pixel_scale));
        // Bitmap/Pixel width of second word in this font is 197 pixels
        try eq(107, @round(l.type.label.elements.items[1].width / display.pixel_scale));

        try eq(0, @round(l.type.label.elements.items[0].location.x));
        try eq(0, @round(l.type.label.elements.items[0].location.y));

        try eq(96, @round(l.type.label.elements.items[1].location.x));
        try eq(0, @round(l.type.label.elements.items[1].location.y));

        // Display width of the words when rendered to the physical display
        try eq(91, @round(l.minimum_needed_width(display, 500)));
        // TODO: Is this correct? Why is it * 2 ?
        try eq(
            2 * display.text_height.pixel_height(display.pixel_scale),
            l.minimum_needed_height(display, 500),
        );
        // Display width on physical display with word wrap
        try eq(
            2 * display.text_height.pixel_height(display.pixel_scale),
            l.minimum_needed_height(display, 40 * display.pixel_scale),
        );
        panel.remove_entities(allocator, display);
    }

    panel = try display.add_panel(allocator, .{
        .rect = .{ .width = 500, .height = 200 },
        .minimum = .{ .width = 5, .height = 8 },
        .type = .{ .panel = .{ .spacing = 0, .direction = .top_to_bottom } },
        .layout = .{ .x = .shrinks, .y = .shrinks },
    });
    try eq(5, panel.minimum_needed_width(display, 500));
    try eq(8, panel.minimum_needed_height(display, 500));

    // Fixed width and height cant be shrunk or grown, except if minimum
    // or maximum override it.
    var label = try panel.add(allocator, display, .{
        .name = "hello",
        .rect = .{ .width = 500, .height = 60 },
        .minimum = .{ .width = 300, .height = 10 },
        .maximum = .{ .width = 600, .height = 200 },
        .type = .{ .label = .{ .text = "Hello world" } },
        .layout = .{ .x = .fixed, .y = .fixed },
    });
    label.pad = .{ .top = 0, .bottom = 0, .left = 0, .right = 0 };
    try eq(500, label.minimum_needed_width(display, 500));
    try eq(60, label.minimum_needed_height(display, 500));

    // Fixed width and height cant be shrunk or grown, except if minimum
    // or maximum override it.
    label = try panel.add(allocator, display, .{
        .name = "hello",
        .rect = .{ .width = 295, .height = 60 },
        .minimum = .{ .width = 300, .height = 100 },
        .maximum = .{ .width = 401, .height = 201 },
        .type = .{ .label = .{ .text = "Hello world" } },
        .layout = .{ .x = .fixed, .y = .fixed },
    });
    label.pad = .{ .top = 0, .bottom = 0, .left = 0, .right = 0 };
    try eq(300, label.minimum_needed_width(display, 500));
    try eq(100, label.minimum_needed_height(display, 500));

    label.minimum.width = display.text_height.pixel_height(1);
    label.minimum.height = display.text_height.pixel_height(1);
    label.layout.x = .shrinks;
    label.layout.y = .shrinks;
    // TODo: 94 or 46?
    try eq(46, @round(label.minimum_needed_width(display, 500) / display.pixel_scale));
    try eq(display.text_height.pixel_height(2), @round(label.minimum_needed_height(display, 500) / display.pixel_scale));
    label.layout.x = .grows;
    try eq(187, @round(label.minimum_needed_width(display, 500)));

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
    try eq(display.text_height.pixel_height(1), @round(label.rect.height / display.pixel_scale));
    try eq(200, @trunc(panel.rect.height));
}

test "test_init" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var display: *Display(TextSize(22)) = try .create(allocator, io, test_config);
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
const assert = std.debug.assert;

const zstbi = @import("zstbi");

pub const engine = @import("engine.zig");
pub const Animator = @import("animator.zig").Animator;
pub const Font = @import("font.zig");
pub const Texture = @import("texture.zig");
pub const Audio = @import("audio.zig");
pub const seconds = @import("animator.zig").seconds;

const praxis = @import("praxis");
const Lang = @import("praxis").Lang;
const BoundedArray = praxis.BoundedArray;
const mixer = @import("mixer");

pub const Chunker = @import("chunker.zig").Chunker;
pub const Translation = @import("translation.zig").Translation;
pub const StringBucket = @import("string_bucket.zig").StringBucket;
pub const TextSize = @import("text_size.zig").TextSize;

const base62 = @import("resources").base62;
const Resources = @import("resources").Resources;
const Resource = @import("resources").Resource;
const FileType = @import("resources").FileType;

const random = praxis.random;
const seed = random.seed;

pub const Background = @import("entity.zig").Background;
pub const Clip = @import("entity.zig").Clip;
pub const Entity = @import("entity.zig").Entity;
pub const Fit = @import("entity.zig").Fit;
pub const LayoutSize = @import("entity.zig").LayoutSize;
pub const LayoutAlign = @import("entity.zig").LayoutAlign;
pub const LayoutMode = @import("entity.zig").LayoutMode;
pub const Rect = @import("entity.zig").Rect;
pub const Scale = @import("entity.zig").Scale;
pub const Size = @import("entity.zig").Size;
pub const TextElement = @import("entity.zig").TextElement;
pub const ToggleState = @import("entity.zig").ToggleState;
pub const Vector = @import("entity.zig").Vector;
pub const Visibility = @import("entity.zig").Visibility;

pub const Button = @import("button.zig").Button;
pub const Checkbox = @import("checkbox.zig").Checkbox;
pub const Expander = @import("expander.zig").Expander;
pub const Label = @import("label.zig").Label;
pub const Panel = @import("panel.zig").Panel;
pub const Rectangle = @import("rectangle.zig").Rectangle;
pub const Sprite = @import("sprite.zig").Sprite;
pub const TextInput = @import("text_input.zig").TextInput;

const default_themes = @import("theme.zig").default_themes;
pub const Theme = @import("theme.zig").Theme;
pub const ThemeColour = @import("theme.zig").ThemeColour;
pub const Colour = @import("theme.zig").Colour;
pub const BoxLayout = @import("box_layout.zig").BoxLayout;

const test_config = @import("test.zig").test_config;
const headless_display = @import("test.zig").headless_display;
pub const resources_sdl = @import("resources_sdl.zig");
pub const initResourcesSdl = resources_sdl.initResourcesSdl;
pub const loadBundleSdl = resources_sdl.loadBundleSdl;
pub const loadResourceSdl = resources_sdl.loadResourceSdl;
pub const loadPreferenceData = resources_sdl.loadPreferenceData;
pub const deletePreferenceData = resources_sdl.deletePreferenceData;
pub const savePreferenceData = resources_sdl.savePreferenceData;
pub const remove_preference_data = resources_sdl.remove_preference_data;
