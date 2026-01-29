/// Comptime known value to allow creation of `if (dev_build)` statements
/// to allow code to be excluded from production releases.
pub const dev_build = (builtin.mode == .Debug);

/// A global variable which can be used to turn on or off live debugging
/// features such as drawing lines around on screen elements and output of
/// `trace` log messages
pub var dev_mode = false;

/// When the `Config` does not contain an organisation name, default
/// to this organisation name.
pub const default_org_name = "Example";

/// When the `Config` does not contain an application name, default
/// to use this application name.
pub const default_app_name = "Engine";

/// Height of text in pixels not accounting for retina density
pub const default_font_size: f32 = 22.0;

/// Render the font characters with double the pixel density of the
/// `default_font_size` to ensure screens with double or triple pixel
/// density have clear font edges.
pub const font_pixel_density: f32 = 2.0;

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

/// Display describes how to draw all visual elements onto the main
/// application window. Typically one app has one display window.
/// Typically a display consists of one or more panels. A background
/// panel, a main panel, and sometimes a user interface overlay.
pub const Display = struct {
    allocator: Allocator,

    window: *sdl.SDL_Window,
    renderer: *sdl.SDL_Renderer,
    mix: *mixer.MIX_Mixer,

    /// Main game loop runs until quit is requested.
    quit: bool = false,

    /// Some elements are placed, aligned or sized using a layout algorithm
    /// If one of these elements changes, this flag is set to indicate we
    /// must relayout all elements before the next frame is drawn. See
    /// `relayout()` for details.
    need_relayout: bool = true,

    /// Deduplicate safe area change updates by remembering the old safe
    /// area information.
    old_safe_area: sdl.SDL_Rect = undefined,

    /// Normally it is only possible to navigate to, focus, hover, or tap
    /// on `can_focus` items. In `accessibility` mode, extra elements such as
    /// titles or guidance text elements can also be navigated onto. These
    /// special elements must be given the given `accessibility_focus` option.
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

    font: struct {
        default: *Font,
        english: *Font,
        greek: *Font,
        korean: *Font,
        chinese: *Font,
    },

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

    // Text height in pixels _before_ display scaling. For example, you may
    // choose the `text_height` to be a standard 16 pixels across all device
    // types. If a device has a double or triple pixel density, internally the
    // engine might be drawing your content at 32 (double) or 48 (triple) the
    // number of pixels.
    //
    // The `text_height`may therefore be modified by the `pixel_scale` and/or
    // `user_scale` value.
    text_height: f32 = default_font_size,

    /// On some devices, the reported screen size and physical pixel size
    /// may be different. The scale variable is used to convert between
    /// OS reported size, and physical pixel size. i.e.
    ///
    /// 1.0 = Non retina display, width = 1920, pixel width = 1920.
    /// 2.0 = Retina display,     width = 1920, pixel width = 3840.
    /// 3.0 = iPhone 16 display,  width =  393, pixel width = 1179.
    ///
    /// If the text height is 16 pixels, but the device has a retina display
    /// the actual text height will be `text_height` * `pixel_scale`.
    pixel_scale: f32 = 0,

    /// Used when user adjusts the global size of the interface
    user_scale: f32 = 1,

    /// The actual scale is the pixel_scale * user_scale
    scale: f32 = 0,

    /// iOS and retina mac displays report the mouse position according
    /// to traditional dimensions (i.e. 1920x1080) rather than actual
    /// pixels (i.e. 3840x2160). A mouse/tap at 100x100, must be
    /// translated to the physical pixel/element position of 200x200.
    pixel_density: f32 = 1,

    root: Element = .{
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
        .on_resized = .{ .func = null },
        .on_visibility = .{ .func = null },
    },
    animators: ArrayListUnmanaged(*Animator) = .empty,

    keybindings: std.AutoHashMapUnmanaged(c_uint, Callback) = .empty,
    on_resized: BoolCallback,
    event_hook: U32Callback,
    on_panel_change: PanelChangeCallback,

    bucket: StringBucket = undefined,
    bundle_filename: ?[]const u8,
    config: Config = .{},

    pub fn create(
        gpa: Allocator,
        config: Config,
    ) (Error || Allocator.Error || Resources.Error || engine.Error || error{ Utf8ExpectedContinuation, Utf8OverlongEncoding, Utf8EncodesSurrogateHalf, Utf8CodepointTooLarge, Utf8InvalidStartByte } || std.fs.Dir.StatError || std.fs.File.StatError || std.fs.File.OpenError)!*Display {
        var display = try gpa.create(Display);
        errdefer gpa.destroy(display);
        display.allocator = gpa;
        display.hovered = null;
        display.selected = null;
        display.keyboard_selected = false;
        display.focussed = null;
        display.scrolling = null;
        display.text_height = default_font_size;
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
        display.bucket = StringBucket.init(gpa);
        display.bundle_filename = null;
        display.config = config;
        if (config.bundle_filename != null)
            display.bundle_filename = try display.bucket.add(config.bundle_filename.?);

        _ = sdl.SDL_SetAppMetadata(
            if (config.app_name != null) try display.bucket.addZ(config.app_name.?) else "Engine",
            if (config.app_version != null) try display.bucket.addZ(config.app_version.?) else "0.0.0",
            if (config.app_id != null) try display.bucket.addZ(config.app_id.?) else "example",
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
            config.bundle_filename,
            config.resource_folder,
            config.resource_filter,
        );
        if (config.translation_filename) |translation_filename| {
            if (try display.resources.lookupOne(translation_filename, .csv, gpa)) |resource| {
                const data = try sdl_load_resource(display.resources, resource, gpa);
                defer gpa.free(data);
                try display.translation.load_translation_data(gpa, data);
                debug("Translation file '{s}' loaded", .{translation_filename});
            } else {
                err("Translation file '{s}' not found.", .{translation_filename});
            }
        } else {
            info("No config.translation_filename set", .{});
        }

        const window = sdl.SDL_CreateWindow(
            try display.bucket.addZ(config.app_name orelse "Engine"),
            600,
            800,
            sdl.SDL_WINDOW_RESIZABLE | sdl.SDL_WINDOW_HIGH_PIXEL_DENSITY | sdl.SDL_WINDOW_RESIZABLE | config.gui_flags,
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

        if (config.desktop_icon) |desktop_icon| {
            if (try display.resources.lookupOne(desktop_icon, .image, gpa)) |resource| {
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
        } else {
            info("No config.desktop_icon set.", .{});
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
        self.bucket.deinit();

        for (self.fonts.items) |item| {
            item.destroy(gpa);
        }
        self.fonts.deinit(gpa);

        var i = self.textures.iterator();
        while (i.next()) |x| {
            if (x.value_ptr.*.references > 0) {
                warn("texture was not deallocated. {f} has {d} references", .{
                    uid_writer(u64, x.key_ptr.*),
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

    pub fn haptic_feedback_available(_: *Display) bool {
        var count: c_int = undefined;
        if (sdl.SDL_GetHaptics(&count) == null) {
            return false;
        }
        return count > 0;
    }

    pub fn haptic_feedback(_: *Display, _: u32) void {
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

            const available_width = parent.inner_width();

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
            .top_right => place_children_top_right(self, parent),
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
                warn("expander panel '{s}' ignored due to top_left layout.", .{parent.name});
                continue;
            }
            child.rect.x = parent.rect.x + parent.pad.left;
            child.rect.y = parent.rect.y + parent.pad.top;
        }
    }

    inline fn place_children_top_right(_: *Display, parent: *Element) void {
        for (parent.type.panel.children.items) |child| {
            if (child.layout.position == .float) continue;
            if (child.visible == .hidden) continue;
            if (child.type == .expander) {
                warn("expander panel '{s}' ignored due to top_right layout.", .{parent.name});
                continue;
            }
            child.rect.x = parent.rect.x + parent.rect.width - parent.pad.right - child.rect.width;
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
        var first = true;
        for (parent.type.panel.children.items) |child| {
            // Layout the clipped and visible items, but not the hidden items.
            if (child.visible == .hidden) continue;
            if (child.layout.position == .float) continue;

            // Only apply spacing in-between items
            if (!first and child.type != .expander)
                current.y += parent.type.panel.spacing;

            child.rect.x = current.x;
            child.rect.y = current.y;

            if (child.type != .expander)
                current.y += child.rect.height;

            if (child.type != .expander) first = false;

            if (child.layout.x == .grows) {
                child.rect.width = parent.rect.width - parent.pad.left - parent.pad.right;
                if (child.maximum.width > 0)
                    child.rect.width = @min(child.maximum.width, child.rect.width);
            }
        }
        const needed_height = current.y - parent.rect.y - parent.pad.top;
        const overflow_height = (parent.rect.y + parent.rect.height - parent.pad.bottom) - current.y;
        parent.type.panel.scrollable.size.height = @max(needed_height, parent.rect.height);

        //info(" top to bottom layout {s} {s} - need {d} overflow {d}", .{ parent.name, @tagName(parent.type), needed_height, overflow_height });

        // If there are expanders, expand them, otherwise,
        // do start/centre/end alignment.
        if (expanders.len > 0 or expander_weights > 0) {
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
                    if (expander.type.expander.weight <= 0) continue;

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
                first = true;
                for (parent.type.panel.children.items) |child| {
                    // Relayout top to bottom using expander sizes
                    if (child.visible == .hidden) continue;
                    if (child.layout.position == .float) continue;
                    if (!first and child.type != .expander)
                        new_y += parent.type.panel.spacing;
                    child.rect.y = new_y;
                    new_y += child.rect.height;
                    if (child.type != .expander) first = false;
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
                    first = true;
                    for (parent.type.panel.children.items) |child| {
                        if (child.visible == .hidden) continue;
                        if (child.layout.position == .float) continue;
                        if (!first and child.type != .expander)
                            new_y += parent.type.panel.spacing;
                        child.rect.y = new_y;
                        new_y += child.rect.height;
                        if (child.type != .expander) first = false;
                    }
                },
                .end => {
                    // Workout the offset between the initial draw position
                    // and the overflow (underflow) to adjust for.
                    var new_y: f32 = parent.rect.y + parent.pad.top + overflow_height;
                    first = true;
                    for (parent.type.panel.children.items) |child| {
                        if (child.visible == .hidden) continue;
                        if (child.layout.position == .float) continue;
                        if (!first and child.type != .expander)
                            new_y += parent.type.panel.spacing;
                        child.rect.y = new_y;
                        new_y += child.rect.height;
                        if (child.type != .expander) first = false;
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
        expander_weights: f32,
    ) void {
        var current: Vector = .{
            .x = parent.rect.x + parent.pad.left,
            .y = parent.rect.y + parent.pad.top,
        };
        // On first pass, we don't know the stretch size of the expanders
        // so first pass ignores expander width to find only the "needed" space.
        var first = true;
        for (parent.type.panel.children.items) |child| {
            if (child.visible == .hidden) continue;
            if (child.layout.position == .float) continue;
            if (!first and child.type != .expander)
                current.x += parent.type.panel.spacing;

            child.rect.x = current.x;
            child.rect.y = current.y;

            if (child.type != .expander)
                current.x += child.rect.width;

            if (child.type != .expander) first = false;

            if (child.layout.y == .grows) {
                child.rect.height = parent.rect.height - parent.pad.top - parent.pad.bottom;
                if (child.maximum.height > 0)
                    child.rect.height = @min(child.maximum.height, child.rect.height);
            }
        }
        const needed_width = current.x - parent.rect.x - parent.pad.left;
        const overflow_width = (parent.rect.x + parent.rect.width - parent.pad.right) - current.x;
        parent.type.panel.scrollable.size.width = @max(needed_width, parent.rect.width);

        // On second pass, we can add in the expanders.
        if (expanders.len > 0 or expander_weights > 0) {
            trace("expanders: {s} has {any} expanders.  needed_width={d} available_width={d}", .{
                parent.name,
                expanders.len,
                needed_width,
                parent.rect.width,
            });
            if (parent.rect.width > needed_width) {
                // Give each expander a percentage of the spare width area
                const spare_width = parent.rect.width - needed_width;
                for (expanders) |expander| {
                    if (expander.type.expander.weight <= 0) continue;

                    const percent = expander.type.expander.weight / expander_weights;
                    expander.rect.width = @trunc(spare_width * percent);
                    trace("   expander: weight {d} given: {d}", .{
                        percent,
                        expander.rect.width,
                    });
                }
                // Re-update each child panels x position based on the
                // update to each expanders size.
                var new_x: f32 = parent.rect.x + parent.pad.left;
                first = true;
                for (parent.type.panel.children.items) |child| {
                    // Relayout left to right using expander sizes
                    if (child.visible == .hidden) continue;
                    if (child.layout.position == .float) continue;
                    if (!first and child.type != .expander)
                        new_x += parent.type.panel.spacing;
                    child.rect.x = new_x;
                    new_x += child.rect.width;
                    if (child.type != .expander) first = false;

                    trace("expanding. {t} {s} x={d} width={d}", .{
                        child.type,
                        child.name,
                        child.rect.x,
                        child.rect.width,
                    });
                }
            }
        } else {
            // Alternatively, if there are no expanders, we can align
            // the children.
            //
            // If there is remaining space at end of children, maybe we
            // need to centre or right align.
            switch (parent.child_align.x) {
                .start => {},
                .centre => {
                    // Align from top to work out how much space is left
                    var new_x: f32 = parent.rect.x + parent.pad.left + (overflow_width / 2.0);
                    for (parent.type.panel.children.items) |child| {
                        if (child.visible == .hidden) continue;
                        if (child.layout.position == .float) continue;
                        child.rect.x = new_x;
                        new_x += child.rect.width + parent.type.panel.spacing;
                    }
                },
                .end => {
                    // Workout the offset between the initial draw position
                    // and the overflow (underflow) to adjust for.
                    var new_x: f32 = parent.rect.x + parent.pad.left + overflow_width;
                    for (parent.type.panel.children.items) |child| {
                        if (child.visible == .hidden) continue;
                        if (child.layout.position == .float) continue;
                        child.rect.x = new_x;
                        new_x += child.rect.width + parent.type.panel.spacing;
                    }
                    parent.type.panel.scrollable.size.width = @max(
                        needed_width,
                        parent.rect.width,
                    );
                },
            }
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

        var first = true;
        for (parent.type.panel.children.items) |child| {
            if (child.visible == .hidden) continue;
            if (child.layout.position == .float) continue;

            if (!first and child.type != .expander)
                current.x += parent.type.panel.spacing;

            if (child.type != .expander) first = false;

            if (current.x + child.rect.width > line_end) {
                current.x = parent.rect.x + parent.pad.left;
                current.y += line_height + parent.type.panel.spacing;
                line_height = 0;
                first = true;
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
    pub fn draw(display: *Display) Allocator.Error!void {
        const now = std.time.microTimestamp();
        display.last_delta = now - display.last_draw;
        display.last_draw = now;
        //info("animate delta={d}", .{delta});
        var i: usize = 0;
        while (i < display.animators.items.len) {
            const animator = display.animators.items[i];
            const done = try animator.animate(display, now);
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
        assert(self.pixel_scale > 0);
        assert(self.text_height > 0);

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
        var font_pixel_height = self.text_height * self.pixel_scale * font_pixel_density;
        if (self.scale == 0) {
            err("load_font called before screen scale detected. Font texture not optimized.", .{});
            font_pixel_height = self.text_height * font_pixel_density;
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
            self.text_height * self.scale,
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

    /// Add an animator that points to a currently active/valid element.
    /// The element must not be destroyed for the lifetime of the animation.
    pub inline fn add_animator(self: *Display, allocator: Allocator, animator: Animator) Allocator.Error!void {
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
            return Error.RootAcceptsPanelsOnly;
        }
        return self.root.add(allocator, self, element);
    }

    /// Convert a text string into an image that is sent as a texture to
    /// the graphics card.
    pub fn generate_text_texture(self: *Display, text: []const u8, myfont: *Font) ?*sdl.SDL_Texture {

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
            if (element.visible != .visible) continue;

            const is_under_cursor = element.at_point(cursor, scroll_offset);
            if (!is_under_cursor and element.type != .panel) continue;

            //debug("under cursor {s}.{s}", .{ @tagName(element.type), element.name });
            if (element.type == .panel) {
                const so = scroll_offset.add(element.offset);
                if (display.find_under_cursor(element.type.panel.children.items, cursor, so, query)) |found| {
                    return found;
                }
            }
            // This item is under the cursor
            if (query == .any) {
                // Search for any element
                if (element.focus == .never_focus) continue;

                // Panels get special handling,
                if (element.type != .panel) return element;

                if (is_under_cursor) {
                    if (element.type.panel.on_click.func != null)
                        return element;

                    if (element.type.panel.scrollable.scroll.x == true or element.type.panel.scrollable.scroll.y == true)
                        return element;
                }
            }

            if (query == .clickable) {
                // Search only clickable elements
                if (element.focus == .never_focus) continue;

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

        if (display.bundle_filename == null) {
            info("no config.bundle_filename. Not making bundle.", .{});
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
                return Allocator.Error.OutOfMemory;
            };
            buffer.appendSlice(display.bundle_filename.?) catch {
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

    /// Keypress `Callback` handler to toggle dev mode.
    fn toggle_dev_mode(_: *Display, _: *Element, _: Allocator) Allocator.Error!void {
        engine.dev_mode = !engine.dev_mode;
        info("Dev mode: {any}", .{engine.dev_mode});
    }
};

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

/// Draw a visual indication that an element is currently selected.
pub fn draw_selection_marker(
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

/// When the display loads a resource, it may be retained for as long as
/// there is a reference held to this resource. Alternatively, a resource
/// may be marked as retained, effectively causing it to be cached until a
/// manual release is requested.
pub const Retain = enum {
    autorelease,
    retain,
};

/// Elements that contain text can specify which pre-defined height the
/// text should be rendered at.
pub const TextSize = enum {
    small,
    normal,
    subheading,
    heading,
    footnote,

    /// Return the height of the text relative to the `normal`
    /// text height for this display.
    pub fn height(self: TextSize) f32 {
        return switch (self) {
            .small => 0.75,
            .normal => 1.0,
            .heading => 1.5,
            .subheading => 1.25,
            .footnote => 0.75,
        };
    }

    /// Return the pixel height of the text based on the display pixel
    /// density and the requested height scale.
    pub fn pixel_size(self: TextSize, display: *const Display, texture: *const sdl.SDL_Texture) Size {

        // How tall the text should actually appear on the screen
        const height_adjusted = display.text_height * display.scale * self.height();

        return .{
            .height = height_adjusted,
            .width = height_adjusted * @as(f32, @floatFromInt(texture.*.w)) / @as(f32, @floatFromInt(texture.*.h)),
        };
    }
};

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
    element.type.checkbox.font = try select_font(self.fonts.items, element.type.checkbox.font_name);

    if (element.focus == .unspecified)
        element.focus = .can_focus;

    try element.set_text(allocator, self, element.type.checkbox.text);

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
    element.type.label.font = try select_font(self.fonts.items, element.type.label.font_name);

    if (element.focus == .unspecified) {
        if (element.type.label.on_click.func != null)
            element.focus = .can_focus
        else
            element.focus = .accessibility_focus;
    }
    try element.set_text(allocator, self, element.type.label.text);

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
    element.type.text_input.font = try select_font(self.fonts.items, element.type.text_input.font_name);

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
        try element.set_text(allocator, self, text);
    } else {
        try element.set_text(allocator, self, "");
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
    element.type.button.font = try select_font(display.fonts.items, element.type.button.font_name);

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

    try element.set_text(allocator, display, element.type.button.text);

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
    gui_flags: usize = 0,
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
    var display = try Display.create(allocator, test_config);
    defer display.destroy(allocator);
}

test "button sizing" {
    const allocator = std.testing.allocator;
    // The display takes ownership of the resources object
    var display = try Display.create(allocator, test_config);
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

    const not_quite_one_line = default_font_size * 2 - 5;
    const not_quite_two_lines = default_font_size * 2 - 5;

    var button = try panel.add(allocator, display, .{
        .visible = .visible,
        .rect = .{ .width = 50, .height = 50 },
        .minimum = .{ .width = 30, .height = not_quite_one_line },
        .maximum = .{ .width = 82, .height = not_quite_two_lines },
        .type = .{ .button = .{ .text = "" } },
    });
    display.relayout();
    try eq(50, button.shrink_width(display, 500));
    try eq(50, button.shrink_height(display, 500));
    button.layout.x = .shrinks;
    button.layout.y = .shrinks;
    try eq(30, button.shrink_width(display, 500));
    // The words will overflow the bottom of the box
    try eq(not_quite_one_line, button.shrink_height(display, 500));

    display.relayout();
    try eq(30, panel.shrink_width(display, 500));
    try eq(30, button.rect.width);
    try eq(5, panel.rect.width);
    try eq(not_quite_one_line, button.rect.height);
    try eq(0, panel.rect.height);

    panel.pad.left = 2;
    panel.pad.right = 3;
    panel.pad.top = 4;
    panel.pad.bottom = 5;
    display.relayout();
    try eq(30, button.rect.width);
    try eq(5, panel.rect.width);
    try eq(not_quite_one_line, button.rect.height);
    try eq(0, panel.rect.height);

    panel.minimum.width = 100;
    display.relayout();
    try eq(100, panel.shrink_width(display, 500));
    panel.minimum.width = 10;

    // Add test font so we can test label layout
    try std.testing.expect(display.resources.by_uid.count() > 0);
    _ = try display.load_font(allocator, "Roboto-Light");

    try button.set_text(allocator, display, "Hello");
    display.relayout();
    try eq(42, @round(button.rect.width / display.pixel_density));
    try eq(100, @round(panel.rect.width));
    try eq(not_quite_two_lines, button.rect.height / display.pixel_density);
    try eq(0, panel.rect.height);

    try button.set_text(allocator, display, "Hello Defragment");
    display.relayout();
    try eq(default_font_size * 2, button.rect.height / display.pixel_density);
    panel.pad.top = 4;
    panel.pad.bottom = 5;
    display.relayout();
    try eq(default_font_size * 2 + 4 + 5, button.rect.height / display.pixel_density);
}

test "text input sizing" {
    const allocator = std.testing.allocator;
    // The display takes ownership of the resources object
    var display = try Display.create(allocator, test_config);
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
        try eq(401, l.shrink_width(display, 500));
        try eq(default_font_size * display.pixel_scale, l.shrink_height(display, 500));
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
        try eq(401, @round(l.shrink_width(display, 500)));
        try eq(default_font_size * display.pixel_scale, l.shrink_height(display, 500));
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
        // Bitmap/Pixel width of first word in this font is 197 pixels
        try eq(99, @round(l.type.label.elements.items[0].width / display.pixel_scale));
        // Bitmap/Pixel width of second word in this font is 197 pixels
        try eq(107, @round(l.type.label.elements.items[1].width / display.pixel_scale));

        // Display width of the words when rendered to the physical display
        try eq(94, @round(l.shrink_width(display, 500) / display.pixel_scale));
        try eq(default_font_size * display.pixel_scale, l.shrink_height(display, 500));
        // Display width on physical display with word wrap
        try eq(2 * default_font_size * display.pixel_scale, l.shrink_height(display, 40 * display.pixel_scale));
    }

    var panel = try display.add_panel(allocator, .{
        .rect = .{ .width = 500, .height = 200 },
        .minimum = .{ .width = 5, .height = 8 },
        .type = .{ .panel = .{ .spacing = 0, .direction = .top_to_bottom } },
        .layout = .{ .x = .shrinks, .y = .shrinks },
    });
    try eq(5, panel.shrink_width(display, 500));
    try eq(8, panel.shrink_height(display, 500));

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
    try eq(500, label.shrink_width(display, 500));
    try eq(60, label.shrink_height(display, 500));

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
    try eq(300, label.shrink_width(display, 500));
    try eq(100, label.shrink_height(display, 500));

    label.minimum.width = default_font_size;
    label.minimum.height = default_font_size;
    label.layout.x = .shrinks;
    label.layout.y = .shrinks;
    try eq(94, @round(label.shrink_width(display, 500) / display.pixel_scale));
    try eq(default_font_size, @round(label.shrink_height(display, 500) / display.pixel_scale));
    label.layout.x = .grows;
    try eq(401, @round(label.shrink_width(display, 500)));

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
    try eq(default_font_size, @round(label.rect.height / display.pixel_scale));
    try eq(200, @trunc(panel.rect.height));
}

test "test_init" {
    const allocator = std.testing.allocator;
    var display = try Display.create(allocator, test_config);
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
pub const StringBucket = @import("string_bucket.zig").StringBucket;

const uid_writer = @import("resources").uid_writer;
const Resources = @import("resources").Resources;
const Resource = @import("resources").Resource;
const FileType = @import("resources").FileType;

pub const Clip = @import("element.zig").Clip;
pub const Background = @import("element.zig").Background;
pub const Element = @import("element.zig").Element;
pub const Rect = @import("element.zig").Rect;
pub const Scale = @import("element.zig").Scale;
pub const Size = @import("element.zig").Size;
pub const Vector = @import("element.zig").Vector;
pub const Visibility = @import("element.zig").Visibility;
pub const LayoutAlign = @import("element.zig").LayoutAlign;

const default_themes = @import("theme.zig").default_themes;
pub const Theme = @import("theme.zig").Theme;
pub const ThemeColour = @import("theme.zig").ThemeColour;
pub const Colour = @import("theme.zig").Colour;

const test_config = @import("test.zig").test_config;
pub const BundleLoader = @import("read_write.zig");
pub const init_resource_loader = BundleLoader.init_resource_loader;
pub const sdl_load_bundle = BundleLoader.sdl_load_bundle;
pub const sdl_load_resource = BundleLoader.sdl_load_resource;
pub const load_preference_data = BundleLoader.load_preference_data;
pub const save_preference_data = BundleLoader.save_preference_data;
pub const remove_preference_data = BundleLoader.remove_preference_data;
pub const random_string = BundleLoader.random_string;
