//! An animator is provided to the main run loop to move an engine
//! `Entity` along a requested movement path for a specific `duration`.
//!
//! Visual examples of each movement path: https://easings.net
pub fn Animator(comptime T: type) type {
    return struct {
        pub const Mode = enum {
            move,
            colour,
            background_colour,

            /// Change the visibility of an entity at the start and/or end
            /// of the animation.
            visibility,

            /// Take no action for the duration of the animation, except
            /// call the `on_end` function when the animation completes.
            pause,

            /// Slide the value of a progress bar
            progress_bar,
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

        mode: union(Mode) {
            move: struct {
                start: Rect = undefined,
                end: Rect = undefined,
            },
            colour: struct {
                start: Colour = undefined,
                end: Colour = undefined,
            },
            background_colour: struct {
                start: Colour = undefined,
                end: Colour = undefined,
            },
            visibility: struct {
                start: Visibility = undefined,
                end: Visibility = undefined,
            },
            pause: struct {},
            progress_bar: struct {
                start: f32 = 0,
                end: f32 = 0,
            },
        },

        movement: Ease = .ease,

        /// Total number of milliseconds to animate over
        duration: i64 = 0,

        target: *Entity(T),

        on_end: Entity(T).Callback = .{ .func = null },

        internal: struct {
            /// An animator is not initially setup. It becomes setup when the
            /// animation starts.
            setup: bool = false,

            /// Start time of animation in milliseconds.
            start_time: i64 = 0,

            /// End time of animation in milliseconds.
            end_time: i64 = 0,
        } = .{ .setup = false },

        /// Create an Animator struct.
        pub fn create(allocator: Allocator, animator: *const Animator(T)) Allocator.Error!*Animator(T) {
            var new_animator = try allocator.create(Animator(T));
            new_animator.* = animator.*;
            new_animator.internal.setup = false;
            if (new_animator.duration == 0) {
                warn("add_animator called with duration of 0", .{});
                new_animator.duration = 10;
            }
            return new_animator;
        }

        /// Destroy a previously `create`d Animator.
        pub fn destroy(self: *Animator(T), allocator: Allocator) void {
            allocator.destroy(self);
        }

        /// Reposition/adjust an entity based on the current_time in milliseconds.
        /// When an animation starts, an `Ease` formula calculates the current
        /// position/adjustment of an `Entity` based on the `start_time` and expected
        /// `end_time` of the animation.
        ///
        /// Animators may change visibility of an entity, so the animate event may
        /// return errors associated with a visibility change.
        pub fn animate(self: *@This(), current_time: i64) Allocator.Error!bool {
            if (!self.internal.setup) {
                self.internal.setup = true;
                self.internal.start_time = current_time;
                self.internal.end_time = current_time + self.duration;
                trace("animate {s} {s} from {d}ns to {d}ns (duration={d})", .{
                    self.target.name,
                    @tagName(self.mode),
                    self.internal.start_time,
                    self.internal.end_time,
                    self.duration,
                });
                if (self.mode != .pause) {
                    //self.target.visible = .hidden;
                }
            }

            // An item moves along its parth from the start time to the end time.
            // `step` indicates how close (in time) we are to the end point.
            var step: i64 = self.internal.end_time - current_time;
            if (current_time > self.internal.end_time) step = 0;

            switch (self.mode) {
                .pause => {
                    // no action needed
                },
                .move => |m| {
                    switch (self.movement) {
                        .ease => {
                            self.target.rect.x = ease_float(f32, m.start.x, m.end.x, step, self.duration);
                            self.target.rect.y = ease_float(f32, m.start.y, m.end.y, step, self.duration);
                            self.target.rect.width = ease_float(f32, m.start.width, m.end.width, step, self.duration);
                            self.target.rect.height = ease_float(f32, m.start.height, m.end.height, step, self.duration);
                        },
                        .bounce => {
                            self.target.rect.x = bounce_float(f32, m.start.x, m.end.x, step, self.duration);
                            self.target.rect.y = bounce_float(f32, m.start.y, m.end.y, step, self.duration);
                            self.target.rect.width = bounce_float(f32, m.start.width, m.end.width, step, self.duration);
                            self.target.rect.height = bounce_float(f32, m.start.height, m.end.height, step, self.duration);
                        },
                        .linear => {
                            self.target.rect.x = lerp_float(f32, m.start.x, m.end.x, step, self.duration);
                            self.target.rect.y = lerp_float(f32, m.start.y, m.end.y, step, self.duration);
                            self.target.rect.width = lerp_float(f32, m.start.width, m.end.width, step, self.duration);
                            self.target.rect.height = lerp_float(f32, m.start.height, m.end.height, step, self.duration);
                        },
                        .stretch => {
                            self.target.rect.x = stretch_float(f32, m.start.x, -m.end.x, step, self.duration);
                            self.target.rect.y = stretch_float(f32, m.start.y, -m.end.y, step, self.duration);
                            self.target.rect.width = stretch_float(f32, m.start.width, m.end.width * 2, step, self.duration);
                            self.target.rect.height = stretch_float(f32, m.start.height, m.end.height * 2, step, self.duration);
                        },
                    }
                },
                .visibility => {
                    self.target.visible = self.mode.visibility.start;
                },
                .progress_bar => |m| {
                    switch (self.movement) {
                        .ease => self.target.type.progress_bar.progress = ease_float(f32, m.start, m.end, step, self.duration),
                        .bounce => self.target.type.progress_bar.progress = bounce_float(f32, m.start, m.end, step, self.duration),
                        .stretch => self.target.type.progress_bar.progress = stretch_float(f32, m.start, m.end, step, self.duration),
                        .linear => self.target.type.progress_bar.progress = lerp_float(f32, m.start, m.end, step, self.duration),
                    }
                },
                .colour => |m| {
                    switch (self.movement) {
                        .ease => self.target.colour.a = ease_int(u8, m.start.a, m.end.a, step, self.duration),
                        .bounce => self.target.colour.a = bounce_int(u8, m.start.a, m.end.a, step, self.duration),
                        .stretch => self.target.colour.a = stretch_int(u8, m.start.a, m.end.a, step, self.duration),
                        .linear => self.target.colour.a = lerp_int(u8, m.start.a, m.end.a, step, self.duration),
                    }
                },
                .background_colour => |m| {
                    switch (self.movement) {
                        .ease => self.target.background.colour.a = ease_int(u8, m.start.a, m.end.a, step, self.duration),
                        .bounce => self.target.background.colour.a = bounce_int(u8, m.start.a, m.end.a, step, self.duration),
                        .stretch => self.target.background.colour.a = stretch_int(u8, m.start.a, m.end.a, step, self.duration),
                        .linear => self.target.background.colour.a = lerp_int(u8, m.start.a, m.end.a, step, self.duration),
                    }
                },
            }

            if (current_time > self.internal.end_time) {
                // At end of animation, clamp to end value
                switch (self.mode) {
                    .move => |m| {
                        if (self.movement == .stretch) {
                            self.target.rect.x = m.start.x;
                            self.target.rect.y = m.start.y;
                            self.target.rect.width = m.start.width;
                            self.target.rect.height = m.start.height;
                        } else {
                            self.target.rect.x = m.end.x;
                            self.target.rect.y = m.end.y;
                        }
                    },
                    .visibility => {},
                    .progress_bar => |m| self.target.type.progress_bar.progress = m.end,
                    .colour => |m| self.target.colour.a = m.end.a,
                    .background_colour => |m| self.target.colour.a = m.end.a,
                    .pause => {},
                }
                return true;
            }

            return false;
        }
    };
}

pub const seconds = 1000;

fn lerp_float(comptime T: type, start: T, end: T, step: i64, total_steps: i64) T {
    return end - (((end - start) * (@as(T, @floatFromInt(step))) / @as(T, @floatFromInt(total_steps))));
}

fn lerp_int(comptime T: type, start: T, end: T, step: i64, total_steps: i64) T {
    return end - @as(T, @intCast(@divFloor(@as(i64, (end - start)) * step, total_steps)));
}

inline fn stretch_float(comptime T: type, start: T, middle: T, step: i64, total_steps: i64) T {
    const pos: f32 = @min(@as(T, @floatFromInt(step)) / @as(T, @floatFromInt(total_steps)), 1.0);
    return start + (1 - @abs(1 - (2 * pos))) * middle;
    //return start + @sin(@as(f32, @floatFromInt(step)) * (PI / @as(f32, @floatFromInt(total_steps)))) * middle;
}

inline fn stretch_int(comptime T: type, start: T, end: T, step: i64, total_steps: i64) T {
    return @as(T, @intFromFloat(stretch_float(f32, @floatFromInt(start), @floatFromInt(end), step, total_steps)));
}

const FLOAT_EPSILON: f32 = 0.00001;
const PI: f32 = std.math.pi;

inline fn bounce_float(comptime T: type, start: T, _end: T, step: i64, total_steps: i64) T {
    var value = @as(T, @floatFromInt(total_steps - step)) / @as(T, @floatFromInt(total_steps));
    const end = _end - start;
    const d: T = 1;
    const p: T = d * 0.3;
    var s: T = 0;
    var a: T = 0;

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
    const result = (a * std.math.pow(f32, 2, -10 * value) * @sin((value * d - s) * (2 * PI) / p) + end + start);
    return result;
}

inline fn bounce_int(comptime T: type, start: T, end: T, step: i64, total_steps: i64) T {
    return @as(T, @intFromFloat(bounce_float(f32, @floatFromInt(start), @floatFromInt(end), step, total_steps)));
}

inline fn ease_float(comptime T: type, start: T, end: T, step: i64, total_steps: i64) T {
    // `step` ranges between 0 to `total_steps`, `value` ranges from 2 to 0
    var value = @as(T, @floatFromInt(total_steps - step)) / @as(T, @floatFromInt(total_steps));
    value = value * 2;

    if (value < 1) {
        const offset = (end - start) * value * value / 2;
        return start + offset;
    } else {
        value -= 1;
        const offset = (end - start) * (value * (value - 2) - 1) / -2;
        return start + offset;
    }
}

inline fn ease_int(comptime T: type, start: T, end: T, step: i64, total_steps: i64) T {
    // `step` ranges between 0 to `total_steps`, `value` ranges from 256 to 0
    return @as(T, @intFromFloat(ease_float(f32, @floatFromInt(start), @floatFromInt(end), step, total_steps)));
}

const std = @import("std");
const Allocator = std.mem.Allocator;

const entity = @import("entity.zig");
const Entity = entity.Entity;
const Visibility = entity.Visibility;
const Rect = entity.Rect;

const Colour = @import("theme.zig").Colour;

const engine = @import("engine.zig");
const Display = engine.Display;
const TextSize = engine.TextSize;
const err = engine.err;
const warn = engine.warn;
const info = engine.info;
const trace = engine.trace;
const debug = engine.debug;
const eq = std.testing.expectEqual;
const headless_display = @import("test.zig").headless_display;

test "stretch formula" {

    // Button top left
    try eq(100, stretch_float(f32, 100, -10, 0, 10));
    try eq(100, stretch_float(f32, 100, -10, 10, 10));
    try eq(90, stretch_float(f32, 100, -10, 5, 10));
    // Button size
    try eq(200, stretch_int(u8, 200, 20, 0, 10));
    try eq(200, stretch_int(u8, 200, 20, 10, 10));
    try eq(220, stretch_int(u8, 200, 20, 5, 10));
}

test "animator_init" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    var display = try headless_display(gpa, io, TextSize(10), 300, 300, 2);
    defer display.destroy(gpa);

    const animator = try Animator(TextSize(10)).create(gpa, &.{
        .mode = .{ .move = .{} },
        .target = &display.root,
        .duration = 10 * seconds,
    });
    defer animator.destroy(gpa);
}
