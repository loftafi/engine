//! Describes the colour and style of on screen entities.
pub const Theme = @This();

/// A zig enum formmatted tag. i.e. midnight_glow
tag: []const u8,

/// Default text colour
text_colour: Colour,

/// Default panel colour
panel_colour: Colour,

/// Default background colour
background_colour: Colour,

/// Default button colour
button_colour: Colour,

/// Colour of the placeholder text in the text input entity.
input_background_colour: Colour,
input_placeholder_colour: Colour,
input_text_colour: Colour,
input_icon_colour: Colour,

/// Colour of the cursor in the text input entity
input_cursor_colour: Colour,

tinted_text_colour: Colour,
tinted_panel_colour: Colour,
tinted_button_colour: Colour,

/// A bold panel where the colours are intended to be inverted versions of the
/// regular panel. i.e. If the normal background is white, this would be black.
emphasised_panel_colour: Colour,
emphasised_text_colour: Colour,
emphasised_button_colour: Colour,

/// Switch from default panel style to a faded/de-emphasised version of
/// the normal panel style.
faded_panel_colour: Colour,
faded_text_colour: Colour,
faded_button_colour: Colour,

/// Use for success dialogue boxes and panels.
success_panel_colour: Colour,
success_text_colour: Colour,
success_button_colour: Colour,

/// Use for error dialogue boxes and panels.
failed_panel_colour: Colour,
failed_text_colour: Colour,
failed_button_colour: Colour,

/// Default background of a button when toggle is enabled.
toggle_button_off: Colour,

/// Background of a button when a toggle button is marked picked.
toggle_button_on: Colour,

/// Background of a button in toggle mode that has been marked correct.
toggle_button_correct: Colour,

/// Background of a button in toggle mode that has been marked incorrect.
toggle_button_incorrect: Colour,

/// A toggle button that is non-tappable.
toggle_button_disabled: Colour,
toggle_button_disabled_text: Colour,

/// The colour of the progress bar itself. Not the colour of
/// the entity background.
progress_bar_background: Colour,

/// The colour of the progress indicator that is overlaid onto the progress bar.
progress_bar_foreground: Colour,

pub const Style = enum {
    normal,
    faded,
    tinted,
    emphasised,
    success,
    failed,
    background,
    custom,

    pub fn text(self: Style, theme: *Theme, custom: Colour) Colour {
        return switch (self) {
            .normal => theme.text_colour,
            .faded => theme.faded_text_colour,
            .tinted => theme.tinted_text_colour,
            .emphasised => theme.emphasised_text_colour,
            .success => theme.success_text_colour,
            .failed => theme.failed_text_colour,
            .background => theme.background_colour,
            .custom => custom,
        };
    }

    pub fn panel(self: Style, theme: *Theme, custom: Colour) Colour {
        return switch (self) {
            .normal => theme.text_colour,
            .background => theme.background_colour,
            .tinted => theme.tinted_text_colour,
            .faded => theme.faded_panel_colour,
            .emphasised => theme.emphasised_panel_colour,
            .success => theme.success_panel_colour,
            .failed => theme.failed_panel_colour,
            .custom => custom,
        };
    }
};

/// The `Display` is prefilled with this usable set of default themes on
/// initialisation.
pub const default_themes = [5]Theme{
    .{
        .tag = "black",
        .text_colour = .{ .r = 255, .g = 255, .b = 255, .a = 255 },
        .background_colour = .{ .r = 0, .g = 0, .b = 0, .a = 255 },
        .button_colour = .{ .r = 20, .g = 20, .b = 20, .a = 255 },
        .input_background_colour = .{ .r = 255, .g = 255, .b = 255, .a = 255 },
        .input_placeholder_colour = .{ .r = 132, .g = 142, .b = 172, .a = 255 },
        .input_icon_colour = .{ .r = 132, .g = 142, .b = 172, .a = 255 },
        .input_text_colour = .{ .r = 0, .g = 0, .b = 0, .a = 255 },
        .input_cursor_colour = .{ .r = 255, .g = 255, .b = 255, .a = 128 },
        .panel_colour = .{ .r = 31, .g = 34, .b = 48, .a = 255 },
        .tinted_text_colour = .{ .r = 185, .g = 185, .b = 245, .a = 255 },
        .tinted_panel_colour = .{ .r = 255, .g = 205, .b = 205, .a = 128 },
        .tinted_button_colour = .{ .r = 255, .g = 205, .b = 205, .a = 128 },
        .emphasised_text_colour = .{ .r = 0, .g = 0, .b = 0, .a = 255 },
        .emphasised_panel_colour = .{ .r = 255, .g = 255, .b = 255, .a = 255 },
        .emphasised_button_colour = .{ .r = 230, .g = 235, .b = 255, .a = 255 },
        .success_text_colour = .{ .r = 255, .g = 255, .b = 255, .a = 255 },
        .success_button_colour = .{ .r = 35, .g = 129, .b = 43, .a = 255 },
        .success_panel_colour = .{ .r = 83, .g = 172, .b = 75, .a = 128 },
        .failed_text_colour = .{ .r = 255, .g = 255, .b = 255, .a = 255 },
        .failed_button_colour = .{ .r = 145, .g = 59, .b = 59, .a = 255 },
        .failed_panel_colour = .{ .r = 150, .g = 80, .b = 65, .a = 255 },
        .faded_text_colour = .{ .r = 204, .g = 204, .b = 204, .a = 255 },
        .faded_panel_colour = .{ .r = 15, .g = 17, .b = 25, .a = 255 },
        .faded_button_colour = .{ .r = 35, .g = 37, .b = 45, .a = 255 },
        .toggle_button_off = .{ .r = 42, .g = 52, .b = 62, .a = 255 },
        .toggle_button_on = .{ .r = 80, .g = 99, .b = 119, .a = 255 },
        .toggle_button_disabled = .{ .r = 22, .g = 32, .b = 42, .a = 215 },
        .toggle_button_disabled_text = .{ .r = 140, .g = 140, .b = 140, .a = 200 },
        .toggle_button_correct = .{ .r = 80, .g = 119, .b = 81, .a = 255 },
        .toggle_button_incorrect = .{ .r = 119, .g = 80, .b = 80, .a = 255 },
        .progress_bar_background = .{ .r = 31, .g = 34, .b = 48, .a = 255 },
        .progress_bar_foreground = .{ .r = 132, .g = 142, .b = 172, .a = 255 },
    },

    .{
        .tag = "midnight",
        .text_colour = .{ .r = 195, .g = 195, .b = 220, .a = 255 },
        .background_colour = .{ .r = 31, .g = 41, .b = 51, .a = 255 },
        .button_colour = .{ .r = 51, .g = 61, .b = 71, .a = 255 },
        .input_background_colour = .{ .r = 249, .g = 249, .b = 255, .a = 255 },
        .input_placeholder_colour = .{ .r = 146, .g = 146, .b = 175, .a = 255 },
        .input_icon_colour = .{ .r = 146, .g = 146, .b = 175, .a = 255 },
        .input_text_colour = .{ .r = 60, .g = 60, .b = 95, .a = 255 },
        .input_cursor_colour = .{ .r = 195, .g = 195, .b = 220, .a = 128 },
        .panel_colour = .{ .r = 47, .g = 58, .b = 69, .a = 255 },
        .tinted_text_colour = .{ .r = 150, .g = 150, .b = 142, .a = 128 },
        .tinted_panel_colour = .{ .r = 185, .g = 166, .b = 194, .a = 255 },
        .tinted_button_colour = .{ .r = 185, .g = 166, .b = 194, .a = 255 },
        .emphasised_text_colour = .{ .r = 60, .g = 60, .b = 95, .a = 255 },
        .emphasised_panel_colour = .{ .r = 235, .g = 245, .b = 255, .a = 255 },
        .emphasised_button_colour = .{ .r = 205, .g = 215, .b = 225, .a = 255 },
        .success_text_colour = .{ .r = 255, .g = 255, .b = 255, .a = 255 },
        .success_button_colour = .{ .r = 35, .g = 129, .b = 43, .a = 255 },
        .success_panel_colour = .{ .r = 83, .g = 172, .b = 75, .a = 128 },
        .failed_text_colour = .{ .r = 255, .g = 255, .b = 255, .a = 255 },
        .failed_button_colour = .{ .r = 145, .g = 59, .b = 59, .a = 255 },
        .failed_panel_colour = .{ .r = 150, .g = 80, .b = 65, .a = 255 },
        .faded_text_colour = .{ .r = 156, .g = 156, .b = 156, .a = 255 },
        .faded_panel_colour = .{ .r = 36, .g = 46, .b = 56, .a = 255 },
        .faded_button_colour = .{ .r = 56, .g = 66, .b = 76, .a = 255 },
        .toggle_button_off = .{ .r = 58, .g = 72, .b = 86, .a = 255 },
        .toggle_button_on = .{ .r = 80, .g = 99, .b = 119, .a = 255 },
        .toggle_button_disabled = .{ .r = 38, .g = 52, .b = 66, .a = 215 },
        .toggle_button_correct = .{ .r = 80, .g = 119, .b = 81, .a = 255 },
        .toggle_button_incorrect = .{ .r = 119, .g = 80, .b = 80, .a = 255 },
        .toggle_button_disabled_text = .{ .r = 125, .g = 125, .b = 165, .a = 200 },
        .progress_bar_background = .{ .r = 47, .g = 58, .b = 69, .a = 255 },
        .progress_bar_foreground = .{ .r = 146, .g = 146, .b = 175, .a = 255 },
    },

    .{
        .tag = "sand",
        .text_colour = .{ .r = 60, .g = 60, .b = 35, .a = 255 },
        .background_colour = .{ .r = 224, .g = 214, .b = 204, .a = 255 },
        .button_colour = .{ .r = 204, .g = 194, .b = 184, .a = 255 },
        .input_background_colour = .{ .r = 255, .g = 250, .b = 245, .a = 255 },
        .input_placeholder_colour = .{ .r = 128, .g = 128, .b = 85, .a = 255 },
        .input_icon_colour = .{ .r = 128, .g = 128, .b = 85, .a = 255 },
        .input_text_colour = .{ .r = 60, .g = 60, .b = 35, .a = 198 },
        .input_cursor_colour = .{ .r = 120, .g = 80, .b = 55, .a = 128 },
        .panel_colour = .{ .r = 210, .g = 200, .b = 190, .a = 255 },
        .tinted_text_colour = .{ .r = 90, .g = 90, .b = 65, .a = 255 },
        .tinted_panel_colour = .{ .r = 100, .g = 60, .b = 35, .a = 128 },
        .tinted_button_colour = .{ .r = 100, .g = 60, .b = 35, .a = 128 },
        .emphasised_text_colour = .{ .r = 100, .g = 60, .b = 35, .a = 128 },
        .emphasised_panel_colour = .{ .r = 100, .g = 60, .b = 35, .a = 128 },
        .emphasised_button_colour = .{ .r = 80, .g = 40, .b = 15, .a = 128 },
        .success_text_colour = .{ .r = 255, .g = 255, .b = 255, .a = 255 },
        .success_button_colour = .{ .r = 35, .g = 129, .b = 43, .a = 255 },
        .success_panel_colour = .{ .r = 83, .g = 172, .b = 75, .a = 128 },
        .failed_text_colour = .{ .r = 255, .g = 255, .b = 255, .a = 255 },
        .failed_button_colour = .{ .r = 145, .g = 59, .b = 59, .a = 255 },
        .failed_panel_colour = .{ .r = 150, .g = 80, .b = 65, .a = 255 },
        .faded_text_colour = .{ .r = 40, .g = 50, .b = 15, .a = 235 },
        .faded_panel_colour = .{ .r = 217, .g = 207, .b = 197, .a = 255 },
        .faded_button_colour = .{ .r = 237, .g = 227, .b = 217, .a = 255 },
        .toggle_button_off = .{ .r = 196, .g = 184, .b = 170, .a = 255 },
        .toggle_button_on = .{ .r = 157, .g = 138, .b = 118, .a = 255 },
        .toggle_button_disabled = .{ .r = 176, .g = 164, .b = 150, .a = 215 },
        .toggle_button_disabled_text = .{ .r = 130, .g = 120, .b = 105, .a = 200 },
        .toggle_button_correct = .{ .r = 132, .g = 160, .b = 100, .a = 255 },
        .toggle_button_incorrect = .{ .r = 159, .g = 111, .b = 98, .a = 255 },
        .progress_bar_background = .{ .r = 210, .g = 200, .b = 190, .a = 255 },
        .progress_bar_foreground = .{ .r = 128, .g = 128, .b = 85, .a = 255 },
    },

    .{
        .tag = "white",
        .text_colour = .{ .r = 0, .g = 0, .b = 0, .a = 255 },
        .background_colour = .{ .r = 255, .g = 255, .b = 255, .a = 255 },
        .button_colour = .{ .r = 235, .g = 235, .b = 255, .a = 255 },
        .input_background_colour = .{ .r = 235, .g = 245, .b = 255, .a = 255 },
        .input_placeholder_colour = .{ .r = 154, .g = 154, .b = 184, .a = 255 },
        .input_icon_colour = .{ .r = 154, .g = 154, .b = 184, .a = 255 },
        .input_text_colour = .{ .r = 0, .g = 10, .b = 30, .a = 255 },
        .input_cursor_colour = .{ .r = 110, .g = 120, .b = 140, .a = 128 },
        .panel_colour = .{ .r = 217, .g = 230, .b = 242, .a = 255 },
        .tinted_text_colour = .{ .r = 99, .g = 138, .b = 171, .a = 128 },
        .tinted_panel_colour = .{ .r = 40, .g = 0, .b = 0, .a = 128 },
        .tinted_button_colour = .{ .r = 40, .g = 0, .b = 0, .a = 128 },
        .emphasised_text_colour = .{ .r = 235, .g = 235, .b = 255, .a = 255 },
        .emphasised_panel_colour = .{ .r = 0, .g = 0, .b = 20, .a = 225 },
        .emphasised_button_colour = .{ .r = 20, .g = 20, .b = 40, .a = 188 },
        .success_text_colour = .{ .r = 255, .g = 255, .b = 255, .a = 255 },
        .success_button_colour = .{ .r = 35, .g = 129, .b = 43, .a = 255 },
        .success_panel_colour = .{ .r = 83, .g = 172, .b = 75, .a = 128 },
        .failed_text_colour = .{ .r = 255, .g = 255, .b = 255, .a = 255 },
        .failed_button_colour = .{ .r = 145, .g = 59, .b = 59, .a = 255 },
        .failed_panel_colour = .{ .r = 150, .g = 80, .b = 65, .a = 255 },
        .faded_text_colour = .{ .r = 40, .g = 40, .b = 40, .a = 255 },
        .faded_panel_colour = .{ .r = 240, .g = 247, .b = 255, .a = 255 },
        .faded_button_colour = .{ .r = 220, .g = 227, .b = 245, .a = 255 },
        .toggle_button_off = .{ .r = 193, .g = 203, .b = 213, .a = 255 },
        .toggle_button_on = .{ .r = 131, .g = 142, .b = 149, .a = 255 },
        .toggle_button_disabled = .{ .r = 173, .g = 183, .b = 193, .a = 215 },
        .toggle_button_disabled_text = .{ .r = 110, .g = 110, .b = 125, .a = 200 },
        .toggle_button_correct = .{ .r = 132, .g = 160, .b = 100, .a = 255 },
        .toggle_button_incorrect = .{ .r = 159, .g = 111, .b = 98, .a = 255 },
        .progress_bar_background = .{ .r = 217, .g = 230, .b = 242, .a = 255 },
        .progress_bar_foreground = .{ .r = 104, .g = 104, .b = 114, .a = 255 },
    },
    .{
        .tag = "garden",
        .text_colour = .{ .r = 255, .g = 255, .b = 255, .a = 255 },
        .background_colour = .{ .r = 59, .g = 123, .b = 86, .a = 255 },
        .button_colour = .{ .r = 79, .g = 143, .b = 106, .a = 255 },
        .input_background_colour = .{ .r = 245, .g = 255, .b = 250, .a = 255 },
        .input_placeholder_colour = .{ .r = 176, .g = 214, .b = 176, .a = 255 },
        .input_icon_colour = .{ .r = 136, .g = 194, .b = 136, .a = 255 },
        .input_text_colour = .{ .r = 60, .g = 90, .b = 30, .a = 255 },
        .input_cursor_colour = .{ .r = 60, .g = 100, .b = 0, .a = 128 },
        .panel_colour = .{ .r = 86, .g = 150, .b = 114, .a = 255 },
        .tinted_text_colour = .{ .r = 250, .g = 250, .b = 170, .a = 255 },
        .tinted_panel_colour = .{ .r = 14, .g = 57, .b = 14, .a = 255 },
        .tinted_button_colour = .{ .r = 14, .g = 57, .b = 14, .a = 255 },
        .emphasised_text_colour = .{ .r = 255, .g = 255, .b = 170, .a = 255 },
        .emphasised_panel_colour = .{ .r = 14, .g = 57, .b = 14, .a = 255 },
        .emphasised_button_colour = .{ .r = 14, .g = 57, .b = 14, .a = 255 },
        .success_text_colour = .{ .r = 255, .g = 255, .b = 255, .a = 255 },
        .success_button_colour = .{ .r = 35, .g = 129, .b = 43, .a = 255 },
        .success_panel_colour = .{ .r = 83, .g = 172, .b = 75, .a = 128 },
        .failed_text_colour = .{ .r = 255, .g = 255, .b = 255, .a = 255 },
        .failed_button_colour = .{ .r = 145, .g = 59, .b = 59, .a = 255 },
        .failed_panel_colour = .{ .r = 150, .g = 80, .b = 65, .a = 255 },
        .faded_text_colour = .{ .r = 204, .g = 204, .b = 204, .a = 255 },
        .faded_panel_colour = .{ .r = 65, .g = 130, .b = 92, .a = 255 },
        .faded_button_colour = .{ .r = 85, .g = 150, .b = 112, .a = 255 },
        .toggle_button_off = .{ .r = 20, .g = 70, .b = 20, .a = 255 },
        .toggle_button_on = .{ .r = 80, .g = 99, .b = 119, .a = 255 },
        .toggle_button_disabled = .{ .r = 0, .g = 50, .b = 0, .a = 215 },
        .toggle_button_disabled_text = .{ .r = 105, .g = 155, .b = 105, .a = 200 },
        .toggle_button_correct = .{ .r = 80, .g = 119, .b = 81, .a = 255 },
        .toggle_button_incorrect = .{ .r = 119, .g = 80, .b = 80, .a = 255 },
        .progress_bar_background = .{ .r = 86, .g = 150, .b = 114, .a = 255 },
        .progress_bar_foreground = .{ .r = 136, .g = 194, .b = 136, .a = 255 },
    },
};

const Colour = @import("Colour.zig");
