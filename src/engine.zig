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
    InvalidUtf8,
};

/// Capture _all_ zig log messages for the engine log system.
pub const std_options: std.Options = .{
    .log_level = .debug,
    .logFn = @import("log.zig").log_capture,
};

/// Engine and Display configuration options
pub const Config = struct {
    app_name: ?[]const u8 = null,
    app_version: ?[]const u8 = null,
    app_id: ?[]const u8 = null,
    app_org: ?[]const u8 = null,
    app_build: ?[]const u8 = null,
    app_icon_name: ?[]const u8 = null,
    bundles: []const BundleInfo = &.{},
    app_bundle_output: ?[]const u8 = null,
    resource_filter: ?*const fn (name: []const u8, extension: Type) bool = null,
    translation_filename: ?[]const u8 = null,
    desktop_icon: ?[]const u8 = null,
    full_screen: bool = false,
    width: usize = 0,
    height: usize = 0,
};

pub const BundleInfo = struct {
    // Name of the bundle file when using a release mode packaged bundle.
    filename: ?[]const u8 = null,
    // Name of the resource folder (pre-bundling) when in development mode.
    folder: ?[]const u8 = null,

    pub fn format(self: *const BundleInfo, out: *std.Io.Writer) std.Io.Writer.Error!void {
        if (self.filename != null and self.filename.?.len > 0) {
            _ = try out.write(self.filename.?);
        } else if (self.folder != null and self.folder.?.len > 0) {
            _ = try out.write(self.folder.?);
        } else {
            _ = try out.write("null");
        }
    }
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

const eq = std.testing.expectEqual;

test "init catch" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    // The display takes ownership of the resources object
    var display = try Display.create(allocator, io, test_config);
    defer display.destroy();
}

fn create_label(
    allocator: Allocator,
    display: *Display,
    settings: Entity,
) (Error || Allocator.Error || Resources.Error)!*Entity {
    const entity = try display.allocator.create(Entity);
    entity.* = settings;
    try display.setup_entity(allocator, entity);
    return entity;
}

test "text input sizing" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var display = try headless_display(allocator, io, 1000, 1600, 2);
    defer display.destroy();

    var panel = try display.addPanel(.{
        .type = .{ .panel = .{ .direction = .top_to_bottom } },
        .layout = .{ .x = .grows, .y = .grows },
    });

    // Add test font so we can test label layout
    try std.testing.expect(display.resources.by_uid.count() > 0);
    try display.setDefaultFont("Roboto-Light", .unknown);

    {
        // Create a fixed sized label with enough space
        const l = try panel.add(.{
            .name = "hello",
            .rect = .{ .width = 500, .height = 60 },
            .minimum = .{ .width = 300, .height = 50 },
            .maximum = .{ .width = 401, .height = 201 },
            .type = .{ .label = .{ .text = "Hello world" } },
            .layout = .{ .x = .fixed, .y = .grows },
        }, display);
        l.pad = .{ .top = 0, .bottom = 0, .left = 0, .right = 0 };
        try eq(500, l.minimum_needed_width(display, 500));
        try eq(50, l.minimum_needed_height(display, 500));
        panel.removeEntities(display);
    }

    {
        // Create a fixed sized label with minimum
        const l = try panel.add(.{
            .name = "hello",
            .rect = .{ .width = 500, .height = 60 },
            .minimum = .{ .width = 300, .height = 55 },
            .maximum = .{ .width = 401, .height = 201 },
            .type = .{ .label = .{ .text = "Hello world" } },
            .layout = .{ .x = .fixed, .y = .fixed },
        }, display);
        l.pad = .{ .top = 0, .bottom = 0, .left = 0, .right = 0 };
        try eq(500, l.minimum_needed_width(display, 500));
        try eq(60, l.minimum_needed_height(display, 500));
        panel.removeEntities(display);
    }

    {
        // Create a fixed sized label with minimum
        const l = try panel.add(.{
            .name = "hello",
            .rect = .{ .width = 200, .height = 100 },
            .minimum = .{ .width = 300, .height = 20 },
            .maximum = .{ .width = 401, .height = 201 },
            .type = .{ .label = .{ .text = "Hello world" } },
            .layout = .{ .x = .grows, .y = .shrinks },
        }, display);
        l.pad = .{ .top = 0, .bottom = 0, .left = 0, .right = 0 };
        try eq(300, l.minimum_needed_width(display, 500));
        try eq(TextSize.normal.pixel_height(display.scale), l.minimum_needed_height(display, 500));
        panel.removeEntities(display);
    }

    {
        // Create a fixed sized label with x growth
        const l = try panel.add(.{
            .name = "hello",
            .rect = .{ .width = 1, .height = 1 },
            .minimum = .{ .width = 1, .height = 20 },
            .maximum = .{ .width = 401, .height = 201 },
            .type = .{ .label = .{ .text = "Hello world" } },
            .layout = .{ .x = .grows, .y = .shrinks },
        }, display);
        l.pad = .{ .top = 0, .bottom = 0, .left = 0, .right = 0 };
        // Minimum is not the actual width, but the smallest it could do.
        try eq(187, @round(l.minimum_needed_width(display, 500)));
        try eq(TextSize.normal.pixel_height(display.pixel_scale), l.minimum_needed_height(display, 500));
        panel.removeEntities(display);
    }

    {
        // Create a label with full shrinking
        const l = try panel.add(.{
            .name = "hello",
            .rect = .{ .width = 1, .height = 1 },
            .minimum = .{ .width = 1, .height = 20 },
            .maximum = .{ .width = 401, .height = 201 },
            .type = .{ .label = .{ .text = "Hello world" } },
            .layout = .{ .x = .shrinks, .y = .shrinks },
            .pad = .{ .top = 0, .bottom = 0, .left = 0, .right = 0 },
        }, display);
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
            2 * TextSize.normal.pixel_height(display.pixel_scale),
            l.minimum_needed_height(display, 500),
        );
        // Display width on physical display with word wrap
        try eq(
            2 * TextSize.normal.pixel_height(display.pixel_scale),
            l.minimum_needed_height(display, 40 * display.pixel_scale),
        );
        panel.removeEntities(display);
    }

    panel = try display.addPanel(.{
        .rect = .{ .width = 500, .height = 200 },
        .minimum = .{ .width = 5, .height = 8 },
        .type = .{ .panel = .{ .spacing = 0, .direction = .top_to_bottom } },
        .layout = .{ .x = .shrinks, .y = .shrinks },
    });
    try eq(5, panel.minimum_needed_width(display, 500));
    try eq(8, panel.minimum_needed_height(display, 500));

    // Fixed width and height cant be shrunk or grown, except if minimum
    // or maximum override it.
    var label = try panel.add(.{
        .name = "hello",
        .rect = .{ .width = 500, .height = 60 },
        .minimum = .{ .width = 300, .height = 10 },
        .maximum = .{ .width = 600, .height = 200 },
        .type = .{ .label = .{ .text = "Hello world" } },
        .layout = .{ .x = .fixed, .y = .fixed },
    }, display);
    label.pad = .{ .top = 0, .bottom = 0, .left = 0, .right = 0 };
    try eq(500, label.minimum_needed_width(display, 500));
    try eq(60, label.minimum_needed_height(display, 500));

    // Fixed width and height cant be shrunk or grown, except if minimum
    // or maximum override it.
    label = try panel.add(.{
        .name = "hello",
        .rect = .{ .width = 295, .height = 60 },
        .minimum = .{ .width = 300, .height = 100 },
        .maximum = .{ .width = 401, .height = 201 },
        .type = .{ .label = .{ .text = "Hello world" } },
        .layout = .{ .x = .fixed, .y = .fixed },
    }, display);
    label.pad = .{ .top = 0, .bottom = 0, .left = 0, .right = 0 };
    try eq(300, label.minimum_needed_width(display, 500));
    try eq(100, label.minimum_needed_height(display, 500));

    label.minimum.width = TextSize.normal.pixel_height(1);
    label.minimum.height = TextSize.normal.pixel_height(1);
    label.layout.x = .shrinks;
    label.layout.y = .shrinks;
    // TODo: 94 or 46?
    try eq(46, @round(label.minimum_needed_width(display, 500) / display.pixel_scale));
    try eq(TextSize.normal.pixel_height(2), @round(label.minimum_needed_height(display, 500) / display.pixel_scale));
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
    try eq(TextSize.normal.pixel_height(1), @round(label.rect.height / display.pixel_scale));
    try eq(200, @trunc(panel.rect.height));
}

test "test_init" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var display: *Display = try .create(allocator, io, test_config);
    defer display.destroy();

    var panel = try display.addPanel(.{
        .rect = .{ .width = 500, .height = 200 },
        .minimum = .{ .width = 5, .height = 8 },
        .type = .{ .panel = .{ .spacing = 0, .direction = .top_to_bottom } },
        .layout = .{ .x = .shrinks, .y = .shrinks },
    });

    try eq(1, display.root.type.panel.children.items.len);
    _ = try panel.add(.{
        .name = "menu_bg",
        .rect = .{ .x = 0, .y = 0, .width = 550, .height = 100 },
        .minimum = .{ .width = 300, .height = 130 },
        .layout = .{ .x = .fixed, .y = .fixed, .position = .float },
        .background = .{ .colour = .{ .r = 99, .g = 150, .b = 50, .a = 255 } },
        .style = .background,
        .type = .{ .rectangle = .{} },
    }, display);
    try eq(1, display.root.type.panel.children.items[0].type.panel.children.items.len);
}

test "font_loading" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var display = try headless_display(allocator, io, 1000, 1600, 2);
    defer display.destroy();

    // Initial headless display font
    try expectEqual(1, display.fonts.items.len);
    const first_font = display.fonts.items[0];
    try expectEqual(first_font, display.font.default);
    try expectEqual(first_font, display.font.greek);
    try expectEqual(first_font, display.font.english);
    try expectEqual(first_font, display.font.korean);
    try expectEqual(first_font, display.font.chinese);

    try display.setDefaultFont("Roboto-Bold", .unknown);
    try expectEqual(2, display.fonts.items.len);
    const second_font = display.fonts.items[1];

    try expectEqual(second_font, display.font.default);
    try expectEqual(first_font, display.font.greek);
    try expectEqual(first_font, display.font.english);
    try expectEqual(first_font, display.font.korean);
    try expectEqual(first_font, display.font.chinese);

    try display.setDefaultFont("Roboto-Bold", .greek);
    try display.setDefaultFont("Roboto-Bold", .english);
    try display.setDefaultFont("Roboto-Bold", .korean);
    try expectEqual(2, display.fonts.items.len);
    try display.setDefaultFont("Roboto-Bold", .chinese);
    try expectEqual(1, display.fonts.items.len);

    try std.testing.expectError(error.ResourceNotFound, display.setDefaultFont("UnknownFont", .greek));
}

const std = @import("std");
const ArrayListUnmanaged = std.ArrayListUnmanaged;
const Allocator = std.mem.Allocator;
const expectEqual = std.testing.expectEqual;
const builtin = @import("builtin");
const assert = std.debug.assert;

pub const sdl = @cImport({
    if (builtin.target.os.tag == .windows and builtin.target.abi == .msvc) { // 0.16-dev regression workaround
        @cDefine("SIZE_MAX", "((size_t)-1)");
    }
    if (builtin.target.os.tag == .emscripten) { // 0.16-dev regression workaround
        @cDefine("wint_t", "int");
        @cDefine("__DEFINED_wint_t", {});
    }
    @cDefine("SDL_DISABLE_OLD_NAMES", {});
    @cInclude("SDL3/SDL.h");
    @cInclude("SDL3/SDL_revision.h");
    @cDefine("SDL_MAIN_HANDLED", {}); // We are providing our own entry point
    @cInclude("SDL3/SDL_main.h");
    @cInclude("SDL_mixer.h");
    @cInclude("SDL_ttf.h");
});

const zstbi = @import("zstbi");

pub const engine = @import("engine.zig");
pub const Animator = @import("Animator.zig");
pub const Font = @import("Font.zig");
pub const Display = @import("Display.zig");
pub const Texture = @import("Texture.zig");
pub const Audio = @import("Audio.zig");
pub const Event = @import("Event.zig");
pub const seconds = Animator.seconds;

const praxis = @import("praxis");
const Lang = @import("praxis").Lang;
const BoundedArray = praxis.BoundedArray;
const mixer = @import("mixer");

pub const Chunker = @import("Chunker.zig");
pub const StringBucket = @import("string_bucket.zig").StringBucket;
pub const TextSize = @import("TextSize.zig").TextSize(22);

const base62 = @import("resources").base62;
const Resources = @import("resources").Resources;
const Resource = @import("resources").Resource;
const Type = @import("resources").Type;

const random = praxis.random;
const seed = random.seed;

pub const Entity = @import("Entity.zig");
const Background = Entity.Background;
const Clip = Entity.Clip;
const Fit = Entity.Fit;
const LayoutSize = Entity.LayoutSize;
const LayoutAlign = Entity.LayoutAlign;
const LayoutMode = Entity.LayoutMode;
pub const Rect = Entity.Rect;
const Scale = Entity.Scale;
const Size = Entity.Size;
const TextElement = Entity.TextElement;
const ToggleState = Entity.ToggleState;
pub const Vector = Entity.Vector;

pub const log = @import("log.zig");
const trace = log.trace;
const debug = log.debug;
const err = log.err;
const warn = log.warn;
const info = log.info;
const notice = log.notice;

pub const Theme = @import("Theme.zig");
pub const Colour = @import("Colour.zig");
pub const BoxLayout = @import("BoxLayout.zig");

const test_config = @import("test.zig").test_config;
const headless_display = @import("test.zig").headless_display;
pub const resources_sdl = @import("resources_sdl.zig");
pub const initResourcesSdl = resources_sdl.initResourcesSdl;
pub const loadBundleSdl = resources_sdl.loadBundleSdl;
pub const loadResourceSdl = resources_sdl.loadResourceSdl;
pub const loadPreferenceData = resources_sdl.loadPreferenceData;
pub const deletePreferenceData = resources_sdl.deletePreferenceData;
pub const savePreferenceData = resources_sdl.savePreferenceData;
