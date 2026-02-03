pub fn TextInput(comptime T: type) type {
    return struct {
        pub const Self = @This();
        font: *Font = undefined,
        font_name: ?[]const u8 = null,
        texture: ?*sdl.SDL_Texture = null,
        initial_text: ?[]const u8 = "",
        icon_texture_name: ?[]const u8 = "",
        text: ArrayListUnmanaged(u8) = .empty,
        runes: ArrayListUnmanaged(u21) = .empty,
        max_runes: usize = 0,
        cursor_character: usize = 0,
        cursor_pixels: f32 = 0,
        on_change: Element(T).Callback = .empty,
        on_submit: Element(T).Callback = .empty,
        placeholder_texture: ?*sdl.SDL_Texture = null,
        placeholder_text: ?[]const u8 = "",
        placeholder_translate: []const u8 = "",
    };
}

const std = @import("std");
const ArrayListUnmanaged = std.ArrayListUnmanaged;

const sdl = @import("sdl");

const engine = @import("engine.zig");
const err = engine.err;
const warn = engine.warn;
const info = engine.info;
const debug = engine.debug;
const trace = engine.trace;
const Display = engine.Display;
const Element = engine.Element;
const Error = engine.Error;
const LayoutDirection = engine.LayoutDirection;
const Font = engine.Font;
const Size = engine.Size;
const Scroller = engine.Scroller;
const Texture = engine.Texture;
const ToggleState = engine.ToggleState;
const Vector = engine.Vector;
const Callback = engine.Callback;
const BoolCallback = engine.BoolCallback;
const UpdateCallback = engine.UpdateCallback;
