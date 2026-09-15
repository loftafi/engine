/// Update the android project variables.
pub fn main(init: std.process.Init) !void {
    const args = try init.minimal.args.toSlice(init.arena.allocator());

    if (args.len < 4 or (args.len % 2 == 1)) {
        std.debug.print("usage: /path/to/file from to", .{});
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

    const filename = args[1];

    //var original_file = try std.Io.Dir.cwd().openFile(init.io, filename, .{});
    var data = std.Io.Dir.cwd().readFileAlloc(init.io, filename, init.gpa, .unlimited) catch |e| {
        std.log.warn("Error reading android file='{s}'. {any}", .{ filename, e });
        std.process.exit(1);
    };
    defer init.gpa.free(data);

    var i: usize = 2;
    while (i < args.len) : (i += 2) {
        const from = args[i];
        const to = args[i + 1];

        const new_len = std.mem.replacementSize(u8, data, from, to);
        const new_data = try init.gpa.alloc(u8, new_len);
        errdefer init.gpa.free(new_data);

        const count = std.mem.replace(u8, data, from, to, new_data);
        if (count == 0) {
            std.log.info("String \"{s}\" not found in \"{s}\"", .{ from, filename });
            std.process.exit(1);
        }
        std.log.info("Replaced \"{s}\" with \"{s}\" in \"{s}\" {d} times.", .{ from, to, filename, count });

        init.gpa.free(data);
        data = new_data;
    }

    var updated_file = try std.Io.Dir.cwd().openFile(init.io, filename, .{ .mode = .write_only });
    defer updated_file.close(init.io);
    _ = try updated_file.writeStreamingAll(init.io, data);
    std.process.exit(0);
}

const std = @import("std");
const Allocator = std.mem.Allocator;
