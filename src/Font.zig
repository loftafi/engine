/// A font is held in memory for the entire duration it might be needed.
/// Typically this is the lifetime of the app.
const Font = @This();

/// Render the each font character bitmap with four times the pixel density
/// of the default `text_height`. This ensures text is clear on retina double
/// or triple pixel density screens screens. This enables rendering the bitmap
/// as a larger heading.
const character_pixel_density: f32 = 4.0;

/// Pointer to the font resourcefile in the resource bundle pack.
resource: *Resource,

/// Name of the font as it appeared in the bundle file or resource directory.
name: []const u8,

/// Font is freed when no more references point to the font.
references: usize = 0,

/// Default pixel height to render a character on the screen when `normal`
/// text size is chosen.
pixel_height: u8,

/// Convert the internal TrueType character size, to the `pixel_height` using
/// this scale factor.
scale: f32,

// Raw font data parsed from a TTF file.
font: TrueType,

/// A pointer to the raw font data. This must be kept in memory.
font_buffer: []const u8,

/// The first time a character is needed, it is converted to a bitmap.
cache: std.AutoHashMap(TrueType.GlyphIndex, GlyphBitmap),

/// Temporary working buffer to hold bitmap bytes when an individual character
/// is generated.
glyph_buffer: ArrayListUnmanaged(u8),

/// Temporary working buffer used to convert the greyscale character bitmap
/// bytes into an RGBA image for SDL.
image_buffer: ArrayListUnmanaged(u8),

/// A character bitmap only contains enough width and hight to store the character.
/// Ascent describes how far up from the base "line" the bitmap should be drawn.
ascent: f32,

/// Describes how many pixels below the base "line" a character might fall.
descent: f32,

/// The TTF file may request `line_gap` number of extra pixels in-between
/// each text line.
line_gap: f32,

/// The width of the `space` character, because the `TrueType` module doesnt
/// allow fetching the metrics of a space character.
space_width: f32,

/// Apply a global adjustment to the size and baseline of an entire font file.
config: Config = .{},

pub const Config = struct {
    /// Use to make minor adjustments to the size of characters in this font.
    scale: f32 = 1,
    /// Use to make minor pixel sized adjustments to the baseline of
    /// characters in this font.
    baseline: i8 = 0,
};

pub const GlyphBitmap = struct {
    /// Unicode character
    codepoint: u21,

    /// Width in pixels of the character in the `data` field.
    width: f32,
    /// Height in pixels of the character in the `data` field.
    height: f32,
    /// The width (in pixels) that this character needs. The character may
    /// overflow to the left or right of this width.
    advance: f32,
    /// If a character wants to overflow outside of its bounding box, the
    /// bitmap may be drawn slightly to the left or right of its bounding box.
    left_side_bearing: f32,

    /// Unused. Move a charaacter down slightly if it doesnt start at top.
    y_offset: f32,
    /// Unused. Move a charaacter across slightly if it doesnt start at top.
    x_offset: f32,

    /// Unused. May be removed.
    x_scale: f32,
    // Unused. May be removed.
    y_scale: f32,

    texture: *sdl.SDL_Texture,
};

/// Load font data into memory and read the basic font metrics. Use `clone()`
/// to retain this Font in memory, and `release()` when no longer needed.
pub fn create(
    allocator: Allocator,
    name: []const u8,
    raw_data: []const u8,
    resource: *Resource,
    pixel_height: u8,
    config: Config,
) (Allocator.Error || engine.Error)!*Font {
    const ttf = TrueType.load(raw_data) catch |f| {
        err("Failed loading font '{s}' size={d} height={d}. {t}", .{ name, raw_data.len, pixel_height, f });
        return engine.Error.FontInitFailed;
    };

    // scale = desired pixel_height / (ascent + descent)
    const scale = ttf.scaleForPixelHeight(pixel_height) * config.scale;

    const metrics = ttf.verticalMetrics();
    debug("Loaded font: '{s}' ascent={d}, descent={d}, line_gap={d}, scale={d}", .{
        name,
        metrics.ascent,
        metrics.descent,
        metrics.line_gap,
        scale,
    });

    const glyph = ttf.codepointGlyphIndex(' ');
    var space_width: f32 = @as(f32, @floatFromInt(pixel_height)) / 3.5;
    if (glyph == .notdef) {
        warn("font has no glyph for space character.", .{});
    } else {
        const info = ttf.glyphHMetrics(glyph);
        const adv = ttf.glyphKernAdvance(glyph, glyph);
        space_width = (info.advance_width - info.left_side_bearing) * scale;
        debug("Font space glyph. {s}  width={d} adv={d}", .{ name, space_width, adv });
    }

    const font_info = try allocator.create(Font);
    font_info.* = .{
        .resource = resource,
        .references = 0,
        .name = try allocator.dupe(u8, name),
        .pixel_height = pixel_height,
        .scale = scale,
        .font = ttf,
        .font_buffer = raw_data,
        .cache = .init(allocator),
        .image_buffer = .empty,
        .glyph_buffer = .empty,
        .ascent = @round(metrics.ascent * scale) + config.baseline,
        .descent = @round(metrics.descent * scale),
        .line_gap = metrics.line_gap * scale,
        .space_width = space_width,
        .config = config,
    };
    return font_info;
}

/// Hold a pointer/reference to this `Font` so that it is not deallocated.
pub fn clone(self: *Font) *Font {
    self.references += 1;
    return self;
}

/// Release a pointer/reference to this `Font` so that it may be deallocated.
pub fn release(self: *Font, allocator: Allocator) bool {
    if (self.references <= 1) {
        self.cleanup(allocator);
        return true;
    }
    self.references -= 1;
    return false;
}

/// Use `clone()` or `release()` to hold or release a handle/reference to this
/// font. Cleanup is automatically called when no more references to this `Font`
/// exist.
pub fn cleanup(self: *Font, allocator: Allocator) void {
    trace("unloaded font: {s}", .{self.name});
    allocator.free(self.font_buffer);
    allocator.free(self.name);
    var vi = self.cache.valueIterator();
    while (vi.next()) |value| {
        if (value.width > 0 or value.height > 0)
            sdl.SDL_DestroyTexture(value.texture);
    }
    self.cache.deinit();
    self.glyph_buffer.deinit(allocator);
    self.image_buffer.deinit(allocator);
    self.* = undefined;
    allocator.destroy(self);
}

/// Measure the width of a text string in pixels at `TextSize.normal`.
/// This is the base pixel hight not including display scale or adjustemnt
/// to a different `TextSize`.
///
/// Measurement must still be multiplied by display scale and text size.
/// Always call `measureText` before `drawText`.
pub fn measureText(
    self: *Font,
    display: *engine.Display,
    size: engine.TextSize,
    string: []const u8,
) (Allocator.Error)!f32 {
    return self.drawString(
        display,
        string,
        .{},
        .WHITE,
        size,
        1,
        .measure,
    );
}

/// Draw a text string at the requested size, colour, and position.
/// `measureText` must be called before `drawText` to ensure any
/// needed character bitmaps may be generated.
pub fn drawText(
    self: *Font,
    display: *engine.Display,
    string: []const u8,
    pos: engine.Vector,
    colour: engine.Colour,
    size: engine.TextSize,
    x_scale: f32,
) Allocator.Error!void {
    _ = try self.drawString(
        display,
        string,
        pos,
        colour,
        size,
        x_scale,
        .draw,
    );
}

/// Measure or send a text string to the renderer. `string` must be _valid_
/// UTF8 text.
fn drawString(
    self: *Font,
    display: *engine.Display,
    string: []const u8,
    pos: engine.Vector,
    colour: engine.Colour,
    size: engine.TextSize,
    x_scale: f32,
    comptime mode: enum { draw, measure },
) Allocator.Error!f32 {
    const scale_factor = size.scale();
    var dest: engine.Rect = .{
        .x = pos.x,
        .y = @round(pos.y),
        .width = 0,
        .height = 0,
    };
    const start_x = dest.x;

    var dbg = if (builtin.mode == .Debug)
        std.Io.Writer.Allocating.init(display.allocator)
    else {};
    defer if (builtin.mode == .Debug) dbg.deinit();

    var previous_glyph: ?TrueType.GlyphIndex = null;
    // Invalid UTF8 should not be possible at this point because
    // all text should be ingested through `Entity.setText()`
    const view = std.unicode.Utf8View.initUnchecked(string);
    var it = view.iterator();
    while (it.nextCodepoint()) |codepoint| {
        if (codepoint == '\r' or codepoint == '\n' or codepoint == '\t')
            continue;

        const glyph = self.font.codepointGlyphIndex(codepoint);
        if (glyph == .notdef) {
            if (codepoint != ' ')
                warn("skip {u} in font {s} ({t})", .{ codepoint, self.name, mode });
            previous_glyph = null;
            dest.x += self.space_width * scale_factor;
            continue;
        }

        const entry = try self.cache.getOrPut(glyph);
        if (!entry.found_existing) {
            self.createGlyphTexture(
                display.allocator,
                codepoint,
                glyph,
                entry.value_ptr,
                display.renderer,
            ) catch |e| {
                warn("failed to generate glyph '{u}'. ({t}) {t}", .{ codepoint, mode, e });
                entry.value_ptr.* = .{
                    .codepoint = codepoint,
                    .width = 0,
                    .height = 0,
                    .left_side_bearing = 0,
                    .advance = self.space_width,
                    .x_offset = 0,
                    .y_offset = 0,
                    .x_scale = 0,
                    .y_scale = 0,
                    .texture = undefined,
                };
            };
            trace("added glyph '{u}' in font {s} ({t})", .{ codepoint, self.name, mode });
        }

        const glyph_info = entry.value_ptr;
        const kern = if (previous_glyph) |previous|
            self.font.glyphKernAdvance(previous, glyph) * self.scale
        else
            0;

        dest.x += kern * scale_factor;
        dest.x += glyph_info.left_side_bearing * scale_factor;
        dest.y = pos.y + (((self.ascent - glyph_info.height - glyph_info.y_offset) * scale_factor) * x_scale);
        dest.height = glyph_info.height * scale_factor;
        dest.width = glyph_info.width * scale_factor;

        if (mode == .draw) {
            if (glyph_info.height > 0 and glyph_info.width > 0) {
                if (x_scale != 1) {
                    const new_height = dest.height * x_scale;
                    //dest.y += (dest.height - new_height) * x_scale;
                    dest.height = new_height;
                }
                _ = sdl.SDL_SetTextureAlphaMod(glyph_info.texture, colour.a);
                _ = sdl.SDL_SetTextureColorMod(glyph_info.texture, colour.r, colour.g, colour.b);
                display.renderTexture(glyph_info.texture, null, &dest);
            } else {
                if (glyph_info.codepoint != ' ')
                    debug("    '{u}' {d} cant draw.", .{ codepoint, codepoint });
            }
        }

        if (mode == .measure and builtin.mode == .Debug) {
            dbg.writer.print("\n  {u} bitmap.width {d} bitmap.height {d} kern {d} lsb={d} char.width {d}", .{
                codepoint,
                glyph_info.width,
                glyph_info.height,
                kern,
                glyph_info.left_side_bearing,
                glyph_info.advance,
            }) catch {};
        }
        dest.x -= glyph_info.left_side_bearing * scale_factor;
        dest.x += glyph_info.advance * scale_factor;

        previous_glyph = glyph;
    }

    if (builtin.mode == .Debug and mode == .measure) {
        trace("draw string='{s}': written={s} width={d}", .{
            string,
            dbg.written(),
            dest.x - start_x,
        });
    }

    return dest.x - start_x;
}

/// Create a bitmap for an individual codepoint. The `GlyphBitmap` represents
/// standard `normal` sized character width and height. The `texture` contains
/// a higher density version of the character.
pub fn createGlyphTexture(
    self: *Font,
    gpa: Allocator,
    codepoint: u21,
    glyph: TrueType.GlyphIndex,
    entry: *GlyphBitmap,
    renderer: *sdl.SDL_Renderer,
) error{ GlyphNotFound, GlyphBitmapFailed, OutOfMemory }!void {
    self.glyph_buffer.clearRetainingCapacity();
    self.image_buffer.clearRetainingCapacity();

    const horizontal = self.font.glyphHMetrics(glyph);
    const vertical = self.font.glyphBox(glyph) orelse return error.GlyphNotFound;

    // `scale` to the desired physical width and height
    // but multiply the bitmap to the desired `character_pixel_density`
    const dims = self.font.glyphBitmap(
        gpa,
        &self.glyph_buffer,
        glyph,
        self.scale * character_pixel_density,
        self.scale * character_pixel_density,
    ) catch {
        return error.GlyphBitmapFailed;
    };

    // Convert from 1 byte per pixel to RGBA
    try self.image_buffer.ensureTotalCapacity(gpa, dims.width * dims.height * 4);
    for (0..dims.height) |y| {
        for (0..dims.width) |x| {
            self.image_buffer.appendAssumeCapacity(self.glyph_buffer.items[y * dims.width + x]);
            self.image_buffer.appendSliceAssumeCapacity(&.{ 255, 255, 255 });
        }
    }

    // Register the bitmap to an SDL Surface
    const tmp = sdl.SDL_CreateSurfaceFrom(
        dims.width,
        dims.height,
        sdl.SDL_PIXELFORMAT_RGBA8888,
        self.image_buffer.items.ptr,
        dims.width * 4, // 4 bytes per pixel per row.
    );
    defer sdl.SDL_DestroySurface(tmp);

    // Load the SDL Surface into a GPU Texture
    const texture = sdl.SDL_CreateTextureFromSurface(renderer, tmp) orelse {
        engine.log.err("character {u} to texture failed. {s}", .{
            codepoint,
            sdl.SDL_GetError(),
        });
        return error.GlyphBitmapFailed;
    };

    entry.* = .{
        .codepoint = codepoint,
        .width = dims.width / character_pixel_density,
        .height = dims.height / character_pixel_density,
        .left_side_bearing = @as(f32, @floatFromInt(horizontal.left_side_bearing)) * self.scale,
        .advance = @as(f32, @floatFromInt(horizontal.advance_width)) * self.scale,
        .x_offset = @as(f32, @floatFromInt(vertical.x0)) * self.scale,
        .y_offset = @round(@as(f32, @floatFromInt(vertical.y0)) * self.scale),
        .x_scale = @as(f32, @floatFromInt(vertical.x1)) * self.scale,
        .y_scale = @round(@as(f32, @floatFromInt(vertical.y1)) * self.scale),
        .texture = texture,
    };
}

/// Holdes references to the currently loaded fonts in use for each
/// language. By default, every language uses the first loaded font.
pub const Language = struct {
    default: *Font,
    english: *Font,
    greek: *Font,
    korean: *Font,
    chinese: *Font,
};

const std = @import("std");
const ArrayListUnmanaged = std.ArrayListUnmanaged;
const Allocator = std.mem.Allocator;
const builtin = @import("builtin");

const engine = @import("engine.zig");
const err = engine.log.err;
const warn = engine.log.warn;
const notice = engine.log.notice;
const debug = engine.log.debug;
const trace = engine.log.trace;
const sdl = engine.sdl;
const Colour = engine.Colour;

const Resource = @import("resources").Resource;

const TrueType = @import("TrueType");
