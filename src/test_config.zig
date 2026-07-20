/// Sample configuration settings that areonly intended
/// for use by the test case code.
pub const test_config = Config{
    .app_name = "test",
    .app_version = "test",
    .app_id = "test",
    .bundles = &[_]engine.BundleInfo{
        .{ .folder = "./test/repo" },
    },
    .resource_filter = null,
    .translation_filename = "test translation",
    .full_screen = false,
};

/// Sample configuration settings that areonly intended
/// for use by the test case code.
/// Return a `Display` that has not been initialised with SDL. This is
/// convenient for testing in an environment that doesnt support
/// display rendering.
pub fn headless_display(
    allocator: std.mem.Allocator,
    io: std.Io,
    width: f32,
    height: f32,
    display_scale: f32,
) !*Display {
    var display = try Display.create(allocator, io, test_config);

    display.display_scale = display_scale;
    display.user_scale = 1;
    display.scale = display.display_scale * display.user_scale;

    try display.setDefaultFont("Roboto-Light", .unknown, .{});
    try display.setDefaultFont("Roboto-Black", .greek, .{});
    try display.setDefaultFont("Roboto-Black", .english, .{});
    try display.setDefaultFont("Roboto-Bold", .chinese, .{});
    try display.setDefaultFont("Roboto-Thin", .korean, .{});

    display.root.rect.width = width;
    display.root.rect.height = height;
    display.root.maximum.width = width;
    display.root.maximum.height = height;
    display.root.minimum.width = width;
    display.root.minimum.height = height;
    display.safe_area.top = @round(height * 0.1);
    display.safe_area.bottom = 0;
    display.safe_area.left = 0;
    display.safe_area.right = 0;
    display.old_safe_area.x = 0;
    display.old_safe_area.y = 0;
    display.old_safe_area.w = @intFromFloat(width);
    display.old_safe_area.h = @intFromFloat(height);

    display.root.name = "root";

    return display;
}

const std = @import("std");

const engine = @import("engine.zig");
const Config = engine.Config;
const Display = engine.Display;
const TextSize = engine.TextSize;
