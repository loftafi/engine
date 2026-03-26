/// Sample configuration settings that areonly intended
/// for use by the test case code.
pub const test_config = Config{
    .app_name = "test",
    .app_version = "test",
    .app_id = "test",
    .resource_folder = "./test/repo",
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
    text_size: type,
    width: f32,
    height: f32,
    pixel_scale: f32,
) !*Display(text_size) {
    var display = try Display(text_size).create(allocator, io, test_config);
    _ = try display.loadFont(allocator, io, "Roboto-Light");
    display.root.rect.width = width;
    display.root.rect.height = height;
    display.root.maximum.width = width;
    display.root.maximum.height = height;
    display.root.minimum.width = width;
    display.root.minimum.height = height;

    display.pixel_scale = pixel_scale;
    display.user_scale = 1;
    display.scale = display.pixel_scale * display.user_scale;

    display.root.name = "root";

    return display;
}

const std = @import("std");
const Display = @import("engine.zig").Display;
const TextSize = @import("text_size.zig").TextSize;

const engine = @import("engine.zig");
const Config = engine.Config;
const Translation = engine.Translation;

test {
    @import("std").testing.refAllDecls(@This());
    @import("std").testing.refAllDecls(engine);
}
