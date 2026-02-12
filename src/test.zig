pub const test_config = Config{
    .app_name = "test",
    .app_version = "test",
    .app_id = "test",
    .resource_folder = "./test/repo",
    .resource_filter = null,
    .translation_filename = "test translation",
    .full_screen = false,
};

pub fn headless_display(allocator: std.mem.Allocator, text_size: type, width: f32, height: f32, pixel_scale: f32) !*Display(text_size) {
    var display = try Display(text_size).create(allocator, test_config);
    _ = try display.load_font(allocator, "Roboto-Light");
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

const Config = @import("engine.zig").Config;
const engine = @import("engine.zig");

test {
    @import("std").testing.refAllDecls(@This());
}
