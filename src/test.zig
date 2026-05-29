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

/// Return a `Display` that has not been initialised with SDL. This is
/// convenient for testing in an environment that doesnt support
/// display rendering.
pub fn headless_display(
    allocator: std.mem.Allocator,
    io: std.Io,
    width: f32,
    height: f32,
    pixel_scale: f32,
) !*Display {
    var display = try Display.create(allocator, io, test_config);

    display.pixel_scale = pixel_scale;
    display.user_scale = 1;
    display.scale = display.pixel_scale * display.user_scale;

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

    display.root.name = "root";

    return display;
}

const std = @import("std");

const engine = @import("engine.zig");
const Config = engine.Config;
const Display = engine.Display;
const TextSize = engine.TextSize;

test {
    @import("std").testing.refAllDecls(@This());
    @import("std").testing.refAllDecls(engine);
}
