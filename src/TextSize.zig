/// Entities that contain text can specify which pre-defined height the
/// text should be rendered at.
pub fn TextSize(text_height: comptime_float) type {
    return enum {
        small,
        normal,
        subheading,
        heading,
        footnote,

        pub const pixels: f32 = text_height;

        pub fn size(self: @This()) f32 {
            return @round(text_height * self.scale());
        }

        /// Return the height of the text relative to the `normal`
        /// text height for this display.
        pub fn scale(self: @This()) f32 {
            return switch (self) {
                .small => 0.8,
                .normal => 1.0,
                .heading => 1.5,
                .subheading => 1.25,
                .footnote => 0.70,
            };
        }

        /// Return one size smaller, or null for the smallest size.
        pub fn decrease(self: @This()) ?@This() {
            return switch (self) {
                .heading => return .subheading,
                .subheading => return .normal,
                .normal => return .small,
                .small => return .footnote,
                .footnote => return null,
            };
        }
    };
}

const Size = @import("Entity.zig").Size;
const engine = @import("engine.zig");
const sdl = engine.sdl;
