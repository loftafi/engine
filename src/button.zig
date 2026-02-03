pub fn Button(comptime T: type) type {
    return struct {
        pub const Self = @This();
        font: *Font = undefined,
        font_name: ?[]const u8 = null,
        text_size: T = .normal,
        text: []const u8 = "",
        translated: []const u8 = "",
        text_texture: ?*sdl.SDL_Texture = null,
        icon_size: Size = .{ .width = 0, .height = 0 },
        spacing: f32 = 0,
        icon_default_name: ?[]const u8 = null,
        icon_hover: ?*Texture = null,
        icon_hover_name: ?[]const u8 = null,
        icon_pressed: ?*Texture = null,
        icon_pressed_name: ?[]const u8 = null,
        icon_disabled: ?*Texture = null,
        icon_disabled_name: ?[]const u8 = null,
        background_default_name: ?[]const u8 = null,
        background_hover: ?*Texture = null,
        background_hover_name: ?[]const u8 = null,
        background_pressed: ?*Texture = null,
        background_pressed_name: ?[]const u8 = null,
        background_disabled: ?*Texture = null,
        background_disabled_name: ?[]const u8 = null,
        on_click: Element(T).Callback = .empty,
        toggle: ToggleState = .no_toggle,
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
const Scroller = engine.Scroller;
const Vector = engine.Vector;
const Callback = engine.Callback;
const BoolCallback = engine.BoolCallback;
const UpdateCallback = engine.UpdateCallback;
const LayoutDirection = engine.LayoutDirection;
const Error = engine.Error;
const Font = engine.Font;
const Size = engine.Size;
const Texture = engine.Texture;
const ToggleState = engine.ToggleState;
