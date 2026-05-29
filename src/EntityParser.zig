pub fn readEntity(data: []const u8) Error!?Entity {
    var token: Token = try .init(data);
    errdefer {
        err("Unexpected token {t} at {d}.{d}", .{ token.tag, token.begins.line, token.begins.column });
    }
    if (token.tag == .eof) return null;
    var entity = readEntityType(&token) catch return error.UnexpectedToken;
    //entity.setup(display);
    readAttributes(&token, &entity) catch return error.UnexpectedToken;
    return entity;
}

pub fn readEntityType(token: *Token) Error!Entity {
    return switch (token.tag) {
        .button => .{ .type = .{ .button = .{} } },
        .checkbox => .{ .type = .{ .checkbox = .{} } },
        .expander => .{ .type = .{ .expander = .{} } },
        .label => .{ .type = .{ .label = .{} } },
        .panel => .{ .type = .{ .panel = .{} } },
        .progress_bar => .{ .type = .{ .progress_bar = .{} } },
        .rectangle => .{ .type = .{ .rectangle = .{} } },
        .sprite => .{ .type = .{ .sprite = .{} } },
        .text_input => .{ .type = .{ .text_input = .{} } },
        else => error.UnexpectedToken,
    };
}

pub fn readAttributes(token: *Token, entity: *Entity) Error!void {
    token.* = try token.next();
    while (true) {
        //err("reading attribute {t}", .{token.tag});
        try switch (token.tag) {
            .panel, .sprite, .rectangle, .text_input, .label, .checkbox, .expander, .progress_bar => return,
            .name => readNameAttribute(token, entity),
            .image => readStringAttribute(token, &entity.texture_name),
            .aria_label => readStringAttribute(token, &entity.aria_label),
            .@"align" => readAlignAttribute(token, entity),
            .rect => readRectAttribute(token, &entity.rect),
            .minimum => readSizeAttribute(token, &entity.minimum),
            .maximum => readSizeAttribute(token, &entity.maximum),
            .pad => readClipAttribute(token, &entity.pad),
            .layout => readClipAttribute(token, &entity.pad),
            .velocity => readClipAttribute(token, &entity.pad),
            .flip => readClipAttribute(token, &entity.pad),
            .text_size => readTextSizeAttribute(token, entity),
            .line_height => readLineHeightAttribute(token, entity),
            .weight => readWeightAttribute(token, entity),
            .progress => readProgressAttribute(token, entity),
            .visible => entity.visible = .visible,
            .hidden => entity.visible = .hidden,
            .style => readStyleAttribute(token, &entity.style),
            .colour => readClipAttribute(token, &entity.pad),
            .max_length => readMaxLengthAttribute(token, entity),
            .checked => readCheckedAttribute(token, entity),
            .on => readOnTextureAttribute(token, entity),
            .off => readOffTextureAttribute(token, entity),
            .checkbox_size => readCheckboxSizeAttribute(token, entity),
            .icon_size => readIconSizeAttribute(token, entity),
            .placeholder_text => readPlaceholderTextAttribute(token, entity),
            .vertical => {
                if (entity.type != .panel)
                    return error.UnexpectedToken;
                entity.type.panel.direction = .top_to_bottom;
                token.* = try token.next();
            },
            .horizontal => {
                if (entity.type != .panel)
                    return error.UnexpectedToken;
                entity.type.panel.direction = .left_to_right;
                token.* = try token.next();
            },
            .eof => return,
            else => {
                if (entity.type == .button) {
                    const button = &entity.type.button;
                    try switch (token.tag) {
                        .icon_default => readStringAttribute(token, &button.icon.default_name),
                        .icon_hover => readStringAttribute(token, &button.icon.hover_name),
                        .icon_pressed => readStringAttribute(token, &button.icon.pressed_name),
                        .icon_disabled => readStringAttribute(token, &button.icon.disabled_name),
                        .button_default => readStringAttribute(token, &button.button.default_name),
                        .button_hover => readStringAttribute(token, &button.button.hover_name),
                        .button_pressed => readStringAttribute(token, &button.button.pressed_name),
                        .button_disabled => readStringAttribute(token, &button.button.disabled_name),
                        else => return error.UnexpectedToken,
                    };
                    continue;
                }
                return error.UnexpectedToken;
            },
        };
    }
}

pub fn readNameAttribute(token: *Token, entity: *Entity) Error!void {
    token.* = try token.next();
    //err("reading attribute vaue {t}='{s}'", .{ token.tag, token.slice() });
    switch (token.tag) {
        .string => {
            entity.name = token.data[token.loc.start + 1 .. token.loc.end - 1];
            token.* = try token.next();
            return;
        },
        else => return error.UnexpectedToken,
    }
}

pub fn readPlaceholderTextAttribute(token: *Token, entity: *Entity) Error!void {
    if (entity.type != .text_input) return error.UnexpectedToken;
    token.* = try token.next();
    //err("reading attribute vaue {t}='{s}'", .{ token.tag, token.slice() });
    switch (token.tag) {
        .string => {
            entity.type.text_input.placeholder_text = token.data[token.loc.start + 1 .. token.loc.end - 1];
            token.* = try token.next();
            return;
        },
        else => return error.UnexpectedToken,
    }
}

pub fn readOnTextureAttribute(token: *Token, entity: *Entity) Error!void {
    if (entity.type != .checkbox) return error.UnexpectedToken;
    token.* = try token.next();
    //err("reading attribute vaue {t}='{s}'", .{ token.tag, token.slice() });
    switch (token.tag) {
        .string => {
            entity.type.checkbox.on = token.data[token.loc.start + 1 .. token.loc.end - 1];
            token.* = try token.next();
            return;
        },
        else => return error.UnexpectedToken,
    }
}

pub fn readOffTextureAttribute(token: *Token, entity: *Entity) Error!void {
    if (entity.type != .checkbox) return error.UnexpectedToken;
    token.* = try token.next();
    //err("reading attribute vaue {t}='{s}'", .{ token.tag, token.slice() });
    switch (token.tag) {
        .string => {
            entity.type.checkbox.off = token.data[token.loc.start + 1 .. token.loc.end - 1];
            token.* = try token.next();
            return;
        },
        else => return error.UnexpectedToken,
    }
}

pub fn readLineHeightAttribute(token: *Token, entity: *Entity) Error!void {
    const line_height = switch (entity.type) {
        .label => &entity.type.label.line_height,
        .checkbox => &entity.type.checkbox.line_height,
        else => return error.UnexpectedToken,
    };
    token.* = try token.next();
    //err("reading attribute vaue {t}='{s}'", .{ token.tag, token.slice() });
    switch (token.tag) {
        .number => {
            line_height.* = std.fmt.parseFloat(f32, token.slice()) catch return error.UnexpectedToken;
            token.* = try token.next();
            return;
        },
        else => return error.UnexpectedToken,
    }
}

pub fn readWeightAttribute(token: *Token, entity: *Entity) Error!void {
    if (entity.type != .expander) return error.UnexpectedToken;
    token.* = try token.next();
    //err("reading attribute vaue {t}='{s}'", .{ token.tag, token.slice() });
    switch (token.tag) {
        .number => {
            entity.type.expander.weight = std.fmt.parseFloat(f32, token.slice()) catch return error.UnexpectedToken;
            token.* = try token.next();
            return;
        },
        else => return error.UnexpectedToken,
    }
}

pub fn readProgressAttribute(token: *Token, entity: *Entity) Error!void {
    if (entity.type != .progress_bar) return error.UnexpectedToken;
    token.* = try token.next();
    //err("reading attribute vaue {t}='{s}'", .{ token.tag, token.slice() });
    switch (token.tag) {
        .number => {
            entity.type.progress_bar.progress = std.fmt.parseFloat(f32, token.slice()) catch return error.UnexpectedToken;
            token.* = try token.next();
            return;
        },
        else => return error.UnexpectedToken,
    }
}

pub fn readMaxLengthAttribute(token: *Token, entity: *Entity) Error!void {
    if (entity.type != .text_input) return error.UnexpectedToken;
    token.* = try token.next();
    //err("reading attribute vaue {t}='{s}'", .{ token.tag, token.slice() });
    switch (token.tag) {
        .number => {
            const f = std.fmt.parseFloat(f32, token.slice()) catch return error.UnexpectedToken;
            if (f != @ceil(f)) return error.UnexpectedToken;
            if (f > engine.Entity.TextInput.default_max_length) return error.UnexpectedToken;
            entity.type.text_input.max_length = @intFromFloat(f);
            token.* = try token.next();
            return;
        },
        else => return error.UnexpectedToken,
    }
}

pub fn readStyleAttribute(token: *Token, style: *engine.Theme.Style) Error!void {
    token.* = try token.next();
    //err("reading attribute vaue {t}='{s}'", .{ token.tag, token.slice() });
    if (token.tag == .equals)
        token.* = try token.next();
    switch (token.tag) {
        .normal => style.* = .normal,
        .faded => style.* = .faded,
        .tinted => style.* = .tinted,
        .emphasised => style.* = .emphasised,
        .success => style.* = .success,
        .failed => style.* = .failed,
        .background => style.* = .background,
        .custom => style.* = .custom,
        else => return error.UnexpectedToken,
    }
    token.* = try token.next();
    return;
}

pub fn readStringAttribute(token: *Token, string: *?[]const u8) Error!void {
    //err("token={t} {s}", .{ token.tag, token.slice() });
    token.* = try token.next();
    //err("token={t} {s}", .{ token.tag, token.slice() });
    switch (token.tag) {
        .string => {
            string.* = token.data[token.loc.start + 1 .. token.loc.end - 1];
            token.* = try token.next();
            return;
        },
        else => return error.UnexpectedToken,
    }
}

pub fn readFloatValue(token: *Token) Error!f32 {
    //err("token={t} {s}", .{ token.tag, token.slice() });
    token.* = try token.next();
    //err("token={t} {s}", .{ token.tag, token.slice() });
    if (token.tag == .equals)
        token.* = try token.next();
    switch (token.tag) {
        .number => {
            const f = std.fmt.parseFloat(f32, token.slice()) catch return error.UnexpectedToken;
            token.* = try token.next();
            return f;
        },
        else => return error.UnexpectedToken,
    }
}

pub fn readAlignAttribute(token: *Token, entity: *Entity) Error!void {
    token.* = try token.next();
    switch (token.tag) {
        .string => {
            entity.layout.x = .fixed;
            return;
        },
        else => return error.UnexpectedToken,
    }
}

pub fn readCheckedAttribute(token: *Token, entity: *Entity) Error!void {
    token.* = try token.next();
    entity.type.checkbox.checked = true;
}

pub fn readRectAttribute(token: *Token, rect: *engine.Rect) Error!void {
    token.* = try token.next();
    switch (token.tag) {
        .string => {
            rect.x = 0;
            return;
        },
        else => return error.UnexpectedToken,
    }
}

pub fn readSizeAttribute(token: *Token, size: *engine.Size) Error!void {
    token.* = try token.next();
    var value_count: u8 = 0;
    var read_width = false;
    var read_height = false;
    while (true) {
        switch (token.tag) {
            .width => {
                if (read_width == true) return error.UnexpectedToken;
                token.* = try token.next();
                size.width = try readFloatValue(token);
                read_width = true;
            },
            .height => {
                if (read_height == true) return error.UnexpectedToken;
                token.* = try token.next();
                size.height = try readFloatValue(token);
                read_height = true;
            },
            .number => {
                if (value_count == 2) return error.UnexpectedToken;
                if (value_count == 0) size.width = std.fmt.parseFloat(f32, token.slice()) catch unreachable;
                if (value_count == 1) size.height = std.fmt.parseFloat(f32, token.slice()) catch unreachable;
                value_count += 1;
                token.* = try token.next();
            },
            else => {
                if (read_width == true or read_height == true or value_count > 0) return;
                return error.UnexpectedToken;
            },
        }
    }
}

pub fn readCheckboxSizeAttribute(token: *Token, entity: *engine.Entity) Error!void {
    if (entity.type != .checkbox) return error.UnexpectedToken;
    const size = &entity.type.checkbox.checkbox_size;
    token.* = try token.next();
    var value_count: u8 = 0;
    var read_width = false;
    var read_height = false;
    while (true) {
        switch (token.tag) {
            .width => {
                if (read_width == true) return error.UnexpectedToken;
                token.* = try token.next();
                size.width = try readFloatValue(token);
                read_width = true;
            },
            .height => {
                if (read_height == true) return error.UnexpectedToken;
                token.* = try token.next();
                size.height = try readFloatValue(token);
                read_height = true;
            },
            .number => {
                if (value_count == 2) return error.UnexpectedToken;
                if (value_count == 0) size.width = std.fmt.parseFloat(f32, token.slice()) catch unreachable;
                if (value_count == 1) size.height = std.fmt.parseFloat(f32, token.slice()) catch unreachable;
                value_count += 1;
                token.* = try token.next();
            },
            else => {
                if (read_width == true or read_height == true or value_count > 0) return;
                return error.UnexpectedToken;
            },
        }
    }
}

pub fn readIconSizeAttribute(token: *Token, entity: *engine.Entity) Error!void {
    if (entity.type != .button) return error.UnexpectedToken;
    const size = &entity.type.checkbox.checkbox_size;
    token.* = try token.next();
    var value_count: u8 = 0;
    var read_width = false;
    var read_height = false;
    while (true) {
        switch (token.tag) {
            .width => {
                if (read_width == true) return error.UnexpectedToken;
                token.* = try token.next();
                size.width = try readFloatValue(token);
                read_width = true;
            },
            .height => {
                if (read_height == true) return error.UnexpectedToken;
                token.* = try token.next();
                size.height = try readFloatValue(token);
                read_height = true;
            },
            .number => {
                if (value_count == 2) return error.UnexpectedToken;
                if (value_count == 0) size.width = std.fmt.parseFloat(f32, token.slice()) catch unreachable;
                if (value_count == 1) size.height = std.fmt.parseFloat(f32, token.slice()) catch unreachable;
                value_count += 1;
                token.* = try token.next();
            },
            else => {
                if (read_width == true or read_height == true or value_count > 0) return;
                return error.UnexpectedToken;
            },
        }
    }
}

pub fn readTextSizeAttribute(token: *Token, entity: *engine.Entity) Error!void {
    const size = switch (entity.type) {
        .label => &entity.type.label.text_size,
        .checkbox => &entity.type.checkbox.text_size,
        else => return error.UnexpectedToken,
    };
    token.* = try token.next();
    switch (token.tag) {
        .small => size.* = .small,
        .normal => size.* = .normal,
        .subheading => size.* = .subheading,
        .heading => size.* = .heading,
        .footnote => size.* = .footnote,
        else => return error.UnexpectedToken,
    }
    token.* = try token.next();
}

pub fn readClipAttribute(token: *Token, clip: *engine.Clip) Error!void {
    token.* = try token.next();
    switch (token.tag) {
        .string => {
            clip.left = 0;
            return;
        },
        else => return error.UnexpectedToken,
    }
}

pub const Error = error{
    MaxLineCountExceeded,
    InvalidUtf8,
    UnexpectedToken,
};

test "panel" {
    const entity = try readEntity(
        \\panel name "coffee" image "cat"
        \\minimum width=33 height=120
        \\maximum height=99 width=88
        \\horizontal
        \\style tinted
    ) orelse unreachable;
    try expectEqual(33, entity.minimum.width);
    try expectEqual(120, entity.minimum.height);
    try expectEqual(88, entity.maximum.width);
    try expectEqual(99, entity.maximum.height);
    try expectEqualStrings("coffee", entity.name);
    try expectEqualStrings("cat", entity.texture_name.?);
    try expectEqual(.left_to_right, entity.type.panel.direction);
    try expectEqual(.tinted, entity.style);
}

test "label" {
    const entity = try readEntity(
        \\label name "coffee" line_height 1.2
        \\minimum 33 44
        \\style emphasised text_size heading
    ) orelse unreachable;
    try expectEqual(33, entity.minimum.width);
    try expectEqual(44, entity.minimum.height);
    try expectEqual(1.2, entity.type.label.line_height);
    try expectEqualStrings("coffee", entity.name);
    try expectEqual(.heading, entity.type.label.text_size);
    try expectEqual(.emphasised, entity.style);
}

test "checkbox" {
    const entity = try readEntity(
        \\checkbox name "coffee"
        \\minimum width=12.34 height=120
        \\style tinted text_size heading
        \\line_height 1.2 on "on" off "off"
        \\checkbox_size 25 26
    ) orelse unreachable;
    try expectEqual(1.2, entity.type.checkbox.line_height);
    try expectEqual(12.34, entity.minimum.width);
    try expectEqual(120, entity.minimum.height);
    try expectEqualStrings("coffee", entity.name);
    try expectEqualStrings("on", entity.type.checkbox.on.?);
    try expectEqualStrings("off", entity.type.checkbox.off.?);
    try expectEqual(.heading, entity.type.checkbox.text_size);
    try expectEqual(.tinted, entity.style);
    try expectEqual(25, entity.type.checkbox.checkbox_size.width);
    try expectEqual(26, entity.type.checkbox.checkbox_size.height);
}

test "text_input" {
    const entity = try readEntity(
        \\text_input name "coffee"
        \\minimum 100 40
        \\style normal placeholder_text "Enter your food"
        \\max_length 123
    ) orelse unreachable;
    try expectEqual(100, entity.minimum.width);
    try expectEqual(40, entity.minimum.height);
    try expectEqualStrings("Enter your food", entity.type.text_input.placeholder_text.?);
    try expectEqual(.normal, entity.style);
    try expectEqual(123, entity.type.text_input.max_length);
}

test "expander" {
    const entity = try readEntity(
        \\expander name "expander 1" weight 0.4
    ) orelse unreachable;
    try expectEqual(0.4, entity.type.expander.weight);
    try expectEqualStrings("expander 1", entity.name);
}

const std = @import("std");
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;

const engine = @import("engine.zig");
const err = engine.log.err;

const Token = @import("Token.zig");
const Entity = @import("Entity.zig");
