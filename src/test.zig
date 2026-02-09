pub const test_config = Config{
    .app_name = "test",
    .app_version = "test",
    .app_id = "test",
    .resource_folder = "./test/repo",
    .resource_filter = null,
    .translation_filename = "test translation",
    .full_screen = false,
};

const Config = @import("engine.zig").Config;
const engine = @import("engine.zig");

test {
    @import("std").testing.refAllDecls(@This());
}
