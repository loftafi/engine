/// Calculate the height and width a series of rects would consume
pub const BoxLayout = @This();

/// Space between each item on a line.
spacing: f32 = 0,

/// Space between each line.
line_spacing: f32 = 0,

/// Internal variable tracking where to place the next item.
needed: Size = .{ .width = 0, .height = 0 },

/// Call `finalise()` then read the final width and height.
final: Size = .{ .width = 0, .height = 0 },

/// Maximum number of pixels allowed before a line must wrap.
max_width: f32 = 0,

/// After moving to a new line, trailing_space reports how much
/// white space was left at the end of the previous line.
trailing_space: f32 = 0,

pub const empty = BoxLayout{
    .needed = .{ .width = 0, .height = 0 },
    .final = .{ .width = 0, .height = 0 },
    .max_width = 0,
    .spacing = 0,
    .line_spacing = 0,
};

pub fn init(max_width: f32, spacing: f32, line_spacing: f32) BoxLayout {
    return .{
        .needed = .{ .width = 0, .height = 0 },
        .final = .{ .width = 0, .height = 0 },
        .max_width = max_width,
        .spacing = spacing,
        .line_spacing = line_spacing,
    };
}

/// Place the next entity in the box and update the internal
/// metrics to account for this new box
pub fn place(self: *BoxLayout, width: f32, height: f32) Vector {
    // If adding this block would overflow, wrap to next line.
    if (self.needed.width > 0 and self.needed.width + width > self.max_width) {
        self.finalise();
    }
    if (self.needed.width > 0) {
        self.needed.width += self.spacing;
    } else if (self.needed.width == 0 and self.final.height > 0) {
        self.final.height += self.line_spacing;
    }
    const x = self.needed.width;
    const y = self.final.height;
    self.needed.width += width;
    self.needed.height = @max(self.needed.height, height);
    if (self.needed.width > self.max_width) {
        self.finalise();
    }
    return .{ .x = x, .y = y };
}

/// Set the `final.width` and `final.height` so that these
/// variables may be read.
pub fn finalise(self: *BoxLayout) void {
    if (self.needed.width == 0 and self.needed.height == 0) return;
    self.trailing_space = self.max_width - self.needed.width;
    self.final.width = @max(self.final.width, self.needed.width);
    self.final.height += self.needed.height;
    self.needed.width = 0;
    self.needed.height = 0;
}

pub fn clear(self: *BoxLayout) void {
    self.* = .empty;
}

test "box_layout" {
    var shape: BoxLayout = .init(200, 5, 2);

    const l1 = shape.place(50, 10);
    const l2 = shape.place(50, 5);
    const l3 = shape.place(50, 10);
    shape.finalise();
    try eq(160, shape.final.width);
    try eq(10, shape.final.height);
    try eq(40, shape.trailing_space);

    try eq(l1.x, 0);
    try eq(l1.y, 0);
    try eq(l2.x, 55);
    try eq(l2.y, 0);
    try eq(l3.x, 110);
    try eq(l3.y, 0);

    const l4 = shape.place(50, 10);
    shape.finalise();
    try eq(160, shape.final.width);
    try eq(22, shape.final.height);
    try eq(l4.x, 0);
    try eq(l4.y, 12);
    try eq(150, shape.trailing_space);
}

test "box_word_overflow" {
    var shape: BoxLayout = .init(200, 5, 2);

    const l1 = shape.place(100, 10);
    const l2 = shape.place(220, 5);
    try eq(-20, shape.trailing_space);

    const l3 = shape.place(50, 10);
    shape.finalise();
    try eq(220, shape.final.width);
    try eq(10 + 2 + 5 + 2 + 10, shape.final.height);
    try eq(150, shape.trailing_space);

    try eq(l1.x, 0);
    try eq(l1.y, 0);
    try eq(l2.x, 0);
    try eq(l2.y, 12);
    try eq(l3.x, 0);
    try eq(l3.y, 19);
}

const std = @import("std");
const eq = std.testing.expectEqual;

const Vector = @import("Entity.zig").Vector;
const Size = @import("Entity.zig").Size;
