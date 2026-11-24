/// Describe a bounding box, clipping area, or inner padding depths.
pub const Clip = @This();

top: f32 = 0,
bottom: f32 = 0,
left: f32 = 0,
right: f32 = 0,

pub fn isClipped(self: Clip, rect: Rect) bool {
    if (rect.x + rect.width < self.left) return true;
    if (rect.y + rect.height < self.top) return true;
    if (rect.x > self.right) return true;
    if (rect.y > self.bottom) return true;
    return false;
}

/// Shrink a bounding `rect` if it crosses this `clip` boundary.
pub fn applyEdgeClipping(clip: Clip, rect: *engine.Rect) void {
    // Is text crossing over scroll box boundary?
    if (rect.y + rect.height > clip.bottom) {
        rect.height = @max(0, clip.bottom - rect.y);
    } else if (rect.y < clip.top) {
        const cut_amount = clip.top - rect.y;
        rect.height = @max(0, rect.height - cut_amount);
        rect.y += cut_amount;
    }
}

/// Shrink any edge of this `clip` if it falls out of `bounds`.
pub fn intersect(clip: Clip, bounds: Clip) Clip {
    return .{
        .top = if (clip.top < bounds.top) bounds.top else clip.top,
        .left = if (clip.left < bounds.left) bounds.left else clip.left,
        .bottom = if (clip.bottom > bounds.bottom) bounds.bottom else clip.bottom,
        .right = if (clip.right > bounds.right) bounds.right else clip.right,
    };
}

test intersect {
    const a: Clip = .{ .top = 10, .bottom = 20, .left = 10, .right = 20 };
    const b: Clip = .{ .top = 10, .bottom = 20, .left = 10, .right = 20 };
    try expectEqualDeep(a, b);
    try expectEqualDeep(a, a.intersect(b));
    try expectEqualDeep(a, b.intersect(a));
    const c: Clip = .{ .top = 12, .bottom = 18, .left = 12, .right = 18 };
    try expectEqualDeep(c, a.intersect(c));
    try expectEqualDeep(c, c.intersect(a));
    const d: Clip = .{ .top = 0, .bottom = 30, .left = 10, .right = 20 };
    try expectEqualDeep(a, d.intersect(a));
    try expectEqualDeep(a, a.intersect(d));
    const e: Clip = .{ .top = 10, .bottom = 20, .left = 0, .right = 30 };
    try expectEqualDeep(a, e.intersect(a));
    try expectEqualDeep(a, a.intersect(e));
}

pub const std = @import("std");
pub const expectEqualDeep = std.testing.expectEqualDeep;

pub const engine = @import("engine.zig");
pub const Rect = engine.Rect;
