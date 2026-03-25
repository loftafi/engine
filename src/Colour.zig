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
