/// Hold basic RGB and Alpha colour information.
pub const Colour = @This();

r: u8 = 0,
g: u8 = 0,
b: u8 = 0,
a: u8 = 0,

pub const TRANSPARENT: Colour = .{ .r = 0, .g = 0, .b = 0, .a = 0 };
pub const WHITE: Colour = .{ .r = 255, .g = 255, .b = 255, .a = 255 };
pub const BLACK: Colour = .{ .r = 0, .g = 0, .b = 0, .a = 255 };
pub const RED: Colour = .{ .r = 255, .g = 0, .b = 0, .a = 255 };

pub fn parse(value: []const u8) ?Colour {
    if (value.len < 7) return null;
    if (value[0] == '#') {
        if (value.len == 7) {
            const r = std.fmt.parseInt(u8, value[1..3], 16) catch return null;
            const g = std.fmt.parseInt(u8, value[3..5], 16) catch return null;
            const b = std.fmt.parseInt(u8, value[5..7], 16) catch return null;
            return .{ .r = r, .g = g, .b = b, .a = 255 };
        }
        if (value.len == 9) {
            const r = std.fmt.parseInt(u8, value[1..3], 16) catch return null;
            const g = std.fmt.parseInt(u8, value[3..5], 16) catch return null;
            const b = std.fmt.parseInt(u8, value[5..7], 16) catch return null;
            const a = std.fmt.parseInt(u8, value[7..9], 16) catch return null;
            return .{ .r = r, .g = g, .b = b, .a = a };
        }
    }
    return null;
}

test parse {
    const colour: Colour = Colour.parse("#112233") orelse unreachable;
    try std.testing.expectEqual(0x11, colour.r);
    try std.testing.expectEqual(0x22, colour.g);
    try std.testing.expectEqual(0x33, colour.b);

    const colour2: Colour = Colour.parse("#112233aa") orelse unreachable;
    try std.testing.expectEqual(0x11, colour2.r);
    try std.testing.expectEqual(0x22, colour2.g);
    try std.testing.expectEqual(0x33, colour2.b);
    try std.testing.expectEqual(0xaa, colour2.a);
}

test "validate" {
    try std.testing.expectEqual(null, Colour.parse(""));
    try std.testing.expectEqual(null, Colour.parse("#"));
    try std.testing.expectEqual(null, Colour.parse("#1"));
    try std.testing.expectEqual(null, Colour.parse("#12"));
    try std.testing.expectEqual(null, Colour.parse("#123"));
    try std.testing.expectEqual(null, Colour.parse("#1234"));
    try std.testing.expectEqual(null, Colour.parse("#12345"));
    try std.testing.expectEqual(null, Colour.parse("#1234567"));
    try std.testing.expectEqual(null, Colour.parse("#123456789"));
}

const std = @import("std");
