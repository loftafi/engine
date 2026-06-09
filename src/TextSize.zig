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

        /// How many pixels between each word, depending on the selected
        /// font size.
        pub fn word_spacing(self: @This()) f32 {
            return @round(text_height * self.scale() / 3.5);
        }
    };
}

const Size = @import("Entity.zig").Size;
const engine = @import("engine.zig");
const sdl = engine.sdl;
