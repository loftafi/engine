//! A font is held in memory for the entire duration it might be needed.
//! Typically this is the lifetime of the app.
const Font = @This();

/// The name of the font as it appeared in the bundle file or resource directory.
name: []const u8,

/// The SDL handle to access the font.
font: *sdl.TTF_Font,

/// A pointer to the raw font data. This must be kept in memory.
font_buffer: []const u8,

references: usize = 0,

pub fn create(
    allocator: Allocator,
    name: []const u8,
    font: *sdl.TTF_Font,
    raw_data: []const u8,
) !*Font {
    const font_info = try allocator.create(Font);
    font_info.* = .{
        .name = try allocator.dupe(u8, name),
        .font = font,
        .font_buffer = raw_data,
        .references = 0,
    };
    debug("loaded font: {s}", .{sdl.TTF_GetFontFamilyName(font_info.font)});
    return font_info;
}

pub fn clone(self: *Font) *Font {
    self.references += 1;
    return self;
}

pub fn release(self: *Font, allocator: Allocator) bool {
    if (self.references <= 1) {
        self.cleanup(allocator);
        return true;
    }
    self.references -= 1;
    return false;
}

pub fn cleanup(self: *Font, allocator: Allocator) void {
    sdl.TTF_CloseFont(self.font);
    trace("unloaded font: {s}", .{self.name});
    allocator.free(self.font_buffer);
    allocator.free(self.name);
    self.* = undefined;
    allocator.destroy(self);
}

const std = @import("std");
const ArrayListUnmanaged = std.ArrayListUnmanaged;
const Allocator = std.mem.Allocator;
const sdl = @import("sdl");
const builtin = @import("builtin");
const engine = @import("engine.zig");
const debug = engine.log.debug;
const trace = engine.log.trace;
