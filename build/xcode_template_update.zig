/// Update the xcode project variables.
pub fn main(init: std.process.Init) !void {
    const args = try init.minimal.args.toSlice(init.arena.allocator());

    if (args.len != 6) {
        std.debug.print("usage: /path/to/install_dir /subfolder/App.xcodeproj/project.pbxfile app_name app_version app_id", .{});
        std.debug.print("\nFound {d} arguments: ", .{args.len});
        for (args) |arg| {
            std.debug.print(" {s} ", .{arg});
        }
        std.debug.print("\n", .{});
        std.process.exit(1);
    }
    std.debug.print("\nFound {d} arguments: ", .{args.len});
    for (args) |arg| {
        std.debug.print(" {s} ", .{arg});
    }
    std.debug.print("\n", .{});

    const install_path = args[1];
    const pbxfile = args[2];
    const app_name = args[3];
    const app_version = args[4];
    const app_id = args[5];

    update_xcode_variables(
        init.arena.allocator(),
        init.io,
        install_path,
        pbxfile,
        app_name,
        app_version,
        app_id,
    ) catch |e| {
        std.debug.print("Update XCode PBX file failed. {t}", .{e});
        std.process.exit(1);
    };

    std.process.exit(0);
}

pub fn update_xcode_variables(
    allocator: std.mem.Allocator,
    io: std.Io,
    install_path: []const u8,
    pbx_file: []const u8,
    app_name: []const u8,
    app_version: []const u8,
    app_id: []const u8,
) !void {
    var file_buffer: [1024 * 100]u8 = undefined;
    const dir = try std.Io.Dir.cwd().openDir(io, install_path, .{});
    if (dir.readFile(io, pbx_file, &file_buffer)) |data| {
        const out1 = try replace_variable(allocator, data, "MARKETING_VERSION", app_version);
        defer allocator.free(out1);

        const out2 = try replace_variable(allocator, out1, "INFOPLIST_KEY_CFBundleDisplayName", app_name);
        defer allocator.free(out2);
        const out3 = try replace_variable(allocator, out2, "PRODUCT_BUNDLE_IDENTIFIER", app_id);
        defer allocator.free(out3);
        const out4 = try replace_variable(allocator, out3, "CURRENT_PROJECT_VERSION", app_id);
        defer allocator.free(out4);

        if (!std.mem.eql(u8, data, out4)) {
            //std.log.info("Updated pbxfile: {s}", .{pbx_file});
            const file = try dir.createFile(io, pbx_file, .{});
            defer file.close(io);
            try file.writeStreamingAll(io, out4);
        }
    } else |e| {
        std.debug.print("Error reading xcode pbxfile. {t}\n", .{e});
    }
}

/// Use to update the xcode `project.pbxproj`
pub fn update_xcode_variable(
    allocator: std.mem.Allocator,
    data: []const u8,
    comptime key: []const u8,
    value: []const u8,
) ![]const u8 {
    std.debug.assert(value.len >= 0);
    return try replace_variable(allocator, data, key, value);
}

pub fn replace_variable(
    allocator: std.mem.Allocator,
    data: []const u8,
    variable: []const u8,
    value: []const u8,
) ![]const u8 {
    const value_start = try std.fmt.allocPrint(allocator, "{s} = ", .{variable});
    defer allocator.free(value_start);
    var out: std.ArrayListUnmanaged(u8) = .empty;
    errdefer out.deinit(allocator);
    var i = std.mem.tokenizeSequence(u8, data, value_start);
    var first = true;
    while (i.next()) |v| {
        var part = v;
        if (!first) {
            if (std.mem.indexOf(u8, v, ";")) |x| {
                part = v[x..];
            }
        } else {
            first = false;
        }
        try out.appendSlice(allocator, part);
        if (i.peek() != null) {
            try out.appendSlice(allocator, value_start);
            if (is_string(value)) {
                try out.print(allocator, "\"{s}\"", .{value});
            } else {
                try out.print(allocator, "{s}", .{value});
            }
        }
    }
    return out.toOwnedSlice(allocator);
}

fn is_string(value: []const u8) bool {
    _ = std.fmt.parseFloat(f64, value) catch return true;
    return false;
}

const std = @import("std");
const Allocator = std.mem.Allocator;
const expect = std.testing.expect;

test "is_string" {
    try expect(is_string("1.2.3"));
    try expect(is_string("abc"));
    try expect(is_string("1 3"));
    try expect(!is_string("123"));
    try expect(!is_string("1.2"));
    try expect(!is_string("1."));
}

test "basic_version_update" {
    {
        const sample = "this is a \n test CURRENT_PROJECT_VERSION = 123;\nbye";
        const updated = "this is a \n test CURRENT_PROJECT_VERSION = \"abc\";\nbye";
        const result = try replace_variable(std.testing.allocator, sample, "CURRENT_PROJECT_VERSION", "abc");
        defer std.testing.allocator.free(result);
        try std.testing.expectEqualStrings(updated, result);
    }
    {
        const sample = "this is a \n test CURRENT_PROJECT_VERSION = 123;\nbye";
        const updated = "this is a \n test CURRENT_PROJECT_VERSION = 1.2;\nbye";
        const result = try replace_variable(std.testing.allocator, sample, "CURRENT_PROJECT_VERSION", "1.2");
        defer std.testing.allocator.free(result);
        try std.testing.expectEqualStrings(updated, result);
    }

    {
        const sample = "this is a \n test CURRENT_PROJECT_VERSION = 123;\nbye\n\nCURRENT_PROJECT_VERSION = 332;\n\n";
        const updated = "this is a \n test CURRENT_PROJECT_VERSION = 999;\nbye\n\nCURRENT_PROJECT_VERSION = 999;\n\n";
        const result = try replace_variable(std.testing.allocator, sample, "CURRENT_PROJECT_VERSION", "999");
        defer std.testing.allocator.free(result);
        try std.testing.expectEqualStrings(updated, result);
    }
}
