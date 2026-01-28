pub const test_config = Config{
    .app_name = "test",
    .app_version = "test",
    .app_id = "test",
    .resource_folder = "./test/repo",
    .resource_filter = null,
    .translation_filename = "test translation",
    .gui_flags = 0,
};

const Config = @import("engine.zig").Config;
