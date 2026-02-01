/// Elements that contain text can specify which pre-defined height the
/// text should be rendered at.
pub fn TextSize(text_height: comptime_float) type {
    return enum {
        small,
        normal,
        subheading,
        heading,
        footnote,

        /// Return the height of the text relative to the `normal`
        /// text height for this display.
        pub fn height(self: @This()) f32 {
            return switch (self) {
                .small => 0.75,
                .normal => 1.0,
                .heading => 1.5,
                .subheading => 1.25,
                .footnote => 0.75,
            };
        }

        /// Return the on screen height of a word in pixels.
        pub fn pixel_height(self: @This(), scale: f32) f32 {
            return @round(text_height * scale * self.height());
        }

        /// Return the on screen size of a text texture. `scale` expects the
        /// display scale. That is, the user_scale and the screen
        /// scale (pixel density)
        pub fn pixel_size(self: @This(), scale: f32, texture: *const sdl.SDL_Texture) Size {

            // How tall the text should actually appear on the screen
            const height_adjusted = text_height * scale * self.height();

            return .{
                .height = height_adjusted,
                .width = height_adjusted * @as(f32, @floatFromInt(texture.*.w)) / @as(f32, @floatFromInt(texture.*.h)),
            };
        }

        /// How many pixels between each word, depending on the selected
        /// font size.
        pub fn word_spacing(self: @This(), scale: f32) f32 {
            return text_height * self.height() * scale / 3.5;
        }
    };
}

const Size = @import("engine.zig").Size;
const sdl = @import("sdl");
