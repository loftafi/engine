//! An animator is provided to the main run loop to move an engine
//! `Element` along a requested movement path for a specific `duration`.
//!
//! Visual examples of each movement path: https://easings.net

pub const Mode = enum {
    move,
    fade_in,
    fade_out,
    pause,
    appear,
    hide,
};

pub const Ease = enum {
    /// Move from one place to another place with a small
    /// smooth acceleration at the start and end.
    ease,
    /// Move from one place to another with no acceleration.
    linear,
    /// Move from one place to another but bounce on the end point.
    bounce,
    /// Enlarge to the destination then shrink back to the starting position.
    stretch,
};

mode: Mode = .move,
movement: Ease = .ease,
start: Rect = undefined,
end: Rect = undefined,
duration: i64 = 0, // number of nanoseconds to animate over

setup: bool = false,
start_time: i64 = 0,
end_time: i64 = 0,
target: *Element = undefined,

/// Reposition/adjust an element based on the current_time in nanoseconds.
/// When an animation starts, an `Ease` formula calculates the current
/// position/adjustment of an `Element` based on the `start_time` and expected
/// `end_time` of the animation.
pub fn animate(self: *Self, display: *Display, current_time: i64) bool {
    _ = display;

    if (!self.setup) {
        self.setup = true;
        self.start_time = current_time;
        self.end_time = current_time + self.duration;
        trace("animate {s} {s} from {d}ns to {d}ns (duration={d})", .{ self.target.name, @tagName(self.mode), self.start_time, self.end_time, self.duration });
        if (self.mode != .pause) {
            //self.target.visible = .hidden;
        }
    }

    // An item moves along its parth from the start time to the end time.
    // `step` indicates how close (in time) we are to the end point.
    const step: i64 = self.end_time - current_time;

    switch (self.mode) {
        .pause => {
            // no action needed
        },
        .move => {
            switch (self.movement) {
                .ease => {
                    self.target.rect.x = ease(self.start.x, self.end.x, step, self.duration);
                    self.target.rect.y = ease(self.start.y, self.end.y, step, self.duration);
                    self.target.rect.width = ease(self.start.width, self.end.width, step, self.duration);
                    self.target.rect.height = ease(self.start.height, self.end.height, step, self.duration);
                },
                .bounce => {
                    self.target.rect.x = bounce(self.start.x, self.end.x, step, self.duration);
                    self.target.rect.y = bounce(self.start.y, self.end.y, step, self.duration);
                    self.target.rect.width = bounce(self.start.width, self.end.width, step, self.duration);
                    self.target.rect.height = bounce(self.start.height, self.end.height, step, self.duration);
                },
                .linear => {
                    self.target.rect.x = lerp(self.start.x, self.end.x, step, self.duration);
                    self.target.rect.y = lerp(self.start.y, self.end.y, step, self.duration);
                    self.target.rect.width = lerp(self.start.width, self.end.width, step, self.duration);
                    self.target.rect.height = lerp(self.start.height, self.end.height, step, self.duration);
                },
                .stretch => {
                    self.target.rect.x = stretch(self.start.x, -self.end.x, step, self.duration);
                    self.target.rect.y = stretch(self.start.y, -self.end.y, step, self.duration);
                    self.target.rect.width = stretch(self.start.width, self.end.width * 2, step, self.duration);
                    self.target.rect.height = stretch(self.start.height, self.end.height * 2, step, self.duration);
                },
            }
        },
        .appear => {
            self.target.visible = .visible;
        },
        .hide => {
            self.target.visible = .hidden;
        },
        .fade_in => {
            switch (self.movement) {
                .ease => {
                    self.target.colour.a = @as(u8, @intFromFloat(ease(0, 255, step, 255)));
                },
                .bounce => {
                    self.target.colour.a = @as(u8, @intFromFloat(bounce(0, 255, step, 255)));
                },
                .stretch => {
                    self.target.colour.a = @as(u8, @intFromFloat(stretch(0, 255, step, 255)));
                },
                .linear => {
                    self.target.colour.a = @as(u8, @intFromFloat(lerp(0, 255, step, 255)));
                },
            }
        },
        .fade_out => {
            switch (self.movement) {
                .ease => {
                    self.target.colour.a = @as(u8, @intFromFloat(ease(255, 0, step, 255)));
                },
                .bounce => {
                    self.target.colour.a = @as(u8, @intFromFloat(bounce(255, 0, step, 255)));
                },
                .stretch => {
                    self.target.colour.a = @as(u8, @intFromFloat(stretch(255, 0, step, 255)));
                },
                .linear => {
                    self.target.colour.a = @as(u8, @intFromFloat(lerp(255, 0, step, 255)));
                },
            }
        },
    }

    if (current_time > self.end_time) {
        if (self.mode == .fade_out) {
            self.target.visible = .hidden;
        }
        if (self.mode == .move) {
            if (self.movement == .stretch) {
                self.target.rect.x = self.start.x;
                self.target.rect.y = self.start.y;
                self.target.rect.width = self.start.width;
                self.target.rect.height = self.start.height;
            } else {
                self.target.rect.x = self.end.x;
                self.target.rect.y = self.end.y;
            }
        }
        return true;
    }

    return false;
}

inline fn lerp(start: f32, end: f32, step: i64, total_steps: i64) f32 {
    return end - ((end - start) * (@as(f32, @floatFromInt(step)) / @as(f32, @floatFromInt(total_steps))));
}

inline fn stretch(start: f32, middle: f32, step: i64, total_steps: i64) f32 {
    const pos: f32 = @min(@as(f32, @floatFromInt(step)) / @as(f32, @floatFromInt(total_steps)), 1.0);
    return start + (1 - @abs(1 - (2 * pos))) * middle;
    //return start + @sin(@as(f32, @floatFromInt(step)) * (PI / @as(f32, @floatFromInt(total_steps)))) * middle;
}

const FLOAT_EPSILON: f32 = 0.00001;
const PI: f32 = std.math.pi;

inline fn bounce(start: f32, _end: f32, step: i64, total_steps: i64) f32 {
    var value = @as(f32, @floatFromInt(total_steps - step)) / @as(f32, @floatFromInt(total_steps));
    const end = _end - start;
    const d: f32 = 1;
    const p: f32 = d * 0.3;
    var s: f32 = 0;
    var a: f32 = 0;

    if (@abs(value) < FLOAT_EPSILON) {
        return start;
    }

    value /= d;
    if (@abs(value - 1) < FLOAT_EPSILON) {
        return start + end;
    }

    if (@abs(a) < FLOAT_EPSILON or a < @abs(end)) {
        a = end;
        s = p * 0.25;
    } else {
        s = p / (2 * PI) * std.math.asin(end / a);
    }
    return (a * std.math.pow(f32, 2, -10 * value) * @sin((value * d - s) * (2 * PI) / p) + end + start);
}

inline fn ease(start: f32, end: f32, step: i64, total_steps: i64) f32 {
    var value = @as(f32, @floatFromInt(total_steps - step)) / @as(f32, @floatFromInt(total_steps));
    value = value * 2;
    const p = end - start;

    if (value < 1) {
        return p * 0.5 * value * value + start;
    } else {
        value -= 1;
        return p * -0.5 * (value * (value - 2) - 1) + start;
    }
}

const std = @import("std");
const engine = @import("engine.zig");
const Rect = engine.Rect;
const Element = engine.Element;
const Display = engine.Display;
const Self = @This();
const err = engine.err;
const warn = engine.warn;
const info = engine.info;
const trace = engine.trace;
const debug = engine.debug;
const eq = std.testing.expectEqual;

test "stretch formula" {

    // Button top left
    try eq(100, stretch(100, -10, 0, 10));
    try eq(100, stretch(100, -10, 10, 10));
    try eq(90, stretch(100, -10, 5, 10));
    // Button size
    try eq(200, stretch(200, 20, 0, 10));
    try eq(200, stretch(200, 20, 10, 10));
    try eq(220, stretch(200, 20, 5, 10));
}
