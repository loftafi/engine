/// Read quiz tokens from a byte array.
pub const Token = @This();

/// Token type.
tag: Tag,

/// The cursor position of the start of this token.
begins: Cursor,
/// The cursor position of the end of this token.
ends: Cursor,

/// Beginning and ending of byte slice.
loc: Loc,

/// Read elements (lines) from a quiz data file. Lines may
/// contain a heading, a comment, or a question entry.
data: []const u8,

pub const Loc = struct {
    start: u32,
    end: u32,
};

// Human readable description of where a token starts inside the data file.
pub const Cursor = struct {
    line: u32,
    column: u32,
};

pub const empty = Token{
    .tag = .eof,
    .begins = .{ .line = 0, .column = 0 },
    .ends = .{ .line = 0, .column = 0 },
    .loc = .{ .start = 0, .end = 0 },
    .data = "",
};

pub const Tag = enum(u8) {
    unexpected,
    panel,
    button,
    checkbox,
    text_input,
    expander,
    label,
    sprite,
    rectangle,
    progress_bar,
    name,
    @"align",
    eof,
    string,
    number,
    colour,
    text,
    line_height,
    text_size,
    placeholder_text,
    max_length,
    on_change,
    on_submit,
    on_update,
    on_resized,
    on_visiblity,
    pad,
    start,
    centre,
    end,
    vertical,
    horizontal,
    stretch,
    fit,
    fill,
    visible,
    hidden,
    aria_label,
    rect,
    x,
    y,
    width,
    height,
    minimum,
    maximum,
    layout,
    fixed,
    grows,
    shrinks,
    flip,
    true,
    false,
    image,
    background,
    corner_radius,
    image_corner_radius,
    border,
    icon_size,
    icon_default,
    icon_pressed,
    icon_hover,
    icon_disabled,
    button_default,
    button_hover,
    button_pressed,
    button_disabled,
    state,
    disabled,
    no_toggle,
    on,
    off,
    correct,
    incorrect,
    style,
    emphasised,
    success,
    failed,
    tinted,
    faded,
    normal,
    custom,
    checked,
    checkbox_size,
    open_bracket,
    close_bracket,
    @"struct",
    colon,
    equals,
    comma,
    velocity,
    @"inline",
    float,
    heading,
    small,
    subheading,
    footnote,
    weight,
    progress,
};

/// Wrap a string of bytes with a parser. This wrapper does
/// not need `deinit()`. Use `next_element()` to fetch items.
pub fn init(text: []const u8) Error!Token {
    const token = Token{
        .tag = .eof,
        .begins = .{ .line = 0, .column = 0 },
        .ends = .{ .line = 0, .column = 0 },
        .loc = .{
            .start = 0,
            .end = if (std.mem.startsWith(u8, text, "\xEF\xBB\xBF")) 3 else 0,
        },
        .data = text,
    };
    return token.next();
}

//pub var count: usize = 0;

/// Read the next token from the data stream.
pub fn next(self: *const Token) Error!Token {
    //count += 1;
    //if (count == 999) @panic("tokenizer stuck");
    //err("previous: {t} {s}", .{ self.tag, self.slice() });

    if (self.loc.end >= self.data.len) {
        return .{
            .tag = .eof,
            .begins = self.ends,
            .ends = self.ends,
            .loc = self.loc,
            .data = self.data,
        };
    }

    var loc = self.loc;
    var begins = self.ends; // Remember the line/column of token start
    var current = self.ends;
    loc.start = loc.end;
    const whitespace_start = self.ends; // File ends at _last_ whitespace.
    const whitespace_byte = self.loc.start;

    // Pass over whitespace
    var c: u21 = try self.char(&loc.end, &current);
    while (c <= 32) {
        loc.start = loc.end; // Advance start since it was whitespace
        if (c == 0 or self.loc.end >= self.data.len) return .{
            .tag = .eof,
            .ends = current,
            .begins = whitespace_start,
            .loc = .{ .start = whitespace_byte, .end = loc.end },
            .data = self.data,
        };
        begins = current;
        c = try self.char(&loc.end, &current);
    }

    switch (c) {
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' => {
            while (true) : (_ = try self.char(&loc.end, &current)) {
                const p = try self.peek(loc.end);
                if (p >= '0' and p <= '9') continue;
                break;
            }
            if (try self.peek(loc.end) == '.') {
                _ = try self.char(&loc.end, &current);
            }
            while (true) : (_ = try self.char(&loc.end, &current)) {
                const p = try self.peek(loc.end);
                if (p >= '0' and p <= '9') continue;
                break;
            }
            return .{
                .tag = .number,
                .begins = begins,
                .ends = current,
                .loc = loc,
                .data = self.data,
            };
        },
        '"' => {
            while (true) {
                c = try self.char(&loc.end, &current);
                if (c == '"' or c == 0) break;
            }
            return .{
                .tag = .string,
                .begins = begins,
                .ends = current,
                .loc = loc,
                .data = self.data,
            };
        },

        '=' => {
            return .{
                .tag = .equals,
                .begins = begins,
                .ends = current,
                .loc = loc,
                .data = self.data,
            };
        },

        ',' => {
            return .{
                .tag = .comma,
                .begins = begins,
                .ends = current,
                .loc = loc,
                .data = self.data,
            };
        },

        '\\', '$', '/', '-', '+' => {
            return .{
                .tag = .unexpected,
                .begins = begins,
                .ends = current,
                .loc = loc,
                .data = self.data,
            };
        },
        '{' => {
            return .{
                .tag = .open_bracket,
                .begins = begins,
                .ends = current,
                .loc = loc,
                .data = self.data,
            };
        },
        '}' => {
            return .{
                .tag = .close_bracket,
                .begins = begins,
                .ends = current,
                .loc = loc,
                .data = self.data,
            };
        },
        ':' => {
            return .{
                .tag = .colon,
                .begins = begins,
                .ends = current,
                .loc = loc,
                .data = self.data,
            };
        },
        else => {
            while (true) {
                // Consume all word characers until a word
                // ending character appears.
                const p = try self.peek(loc.end);
                if (p == ' ' or p == '\n' or p == '\t' or p == '\r' or
                    p == '{' or p == '}' or p == ':' or p == '=' or p == 0) break;
                _ = try self.char(&loc.end, &current);
            }
            const value = self.data[loc.start..loc.end];
            for (std.enums.values(Tag)) |tag| {
                if (std.ascii.eqlIgnoreCase(value, @tagName(tag))) {
                    return .{
                        .tag = tag,
                        .begins = begins,
                        .ends = current,
                        .loc = loc,
                        .data = self.data,
                    };
                }
            }
            return .{
                .tag = .unexpected,
                .begins = begins,
                .ends = current,
                .loc = loc,
                .data = self.data,
            };
        },
    }
}

/// Read the next character from the data stream.
inline fn char(self: *const Token, index: *u32, pos: *Cursor) Error!u21 {
    if (index.* >= self.data.len) return 0;
    const x: u8 = self.data[index.*];
    const l = @as(u32, std.unicode.utf8ByteSequenceLength(x) catch {
        std.log.err("invalid utf8 at byte {any} in {any}\n", .{ index.*, self.data });
        return Error.InvalidUtf8;
    });
    const c: u21 = std.unicode.utf8Decode(self.data[index.*..(index.* + l)]) catch {
        std.log.err("invalid utf8 at byte {any} in {any}\n", .{ index.*, self.data });
        return Error.InvalidUtf8;
    };
    if (c == '\n') {
        if (self.ends.line == 0xffffffff) return Error.MaxLineCountExceeded;
        pos.*.line += 1;
        pos.*.column = 0;
    } else {
        pos.*.column += 1;
    }
    index.* += l;
    return c;
}

/// Peek into the next character in the data stream.
inline fn peek(self: *const Token, index: u32) Error!u21 {
    if (index >= self.data.len) return 0;
    const x: u8 = self.data[index];
    const l = @as(u32, std.unicode.utf8ByteSequenceLength(x) catch {
        std.log.err("invalid utf8 at byte {any} in {any}\n", .{ index, self.data });
        return Error.InvalidUtf8;
    });
    const c: u21 = std.unicode.utf8Decode(self.data[index..(index + l)]) catch {
        std.log.err("invalid utf8 at byte {any} in {any}\n", .{ index, self.data });
        return Error.InvalidUtf8;
    };
    return c;
}

/// Return the slice of data backing a token.
pub inline fn slice(self: *const Token) []const u8 {
    return self.data[self.loc.start..self.loc.end];
}

pub const Error = error{
    MaxLineCountExceeded,
    InvalidUtf8,
};

test "tokenise_nothing" {
    const token = try Token.init("");
    try expectEqual(0, token.ends.line);
    try expectEqual(0, token.ends.column);
    try expectEqual(.eof, token.tag);
}

test "eof_cursor" {
    var token = try Token.init("a");
    token = try token.next();
    try expectEqual(0, token.begins.line);
    try expectEqual(1, token.begins.column);
    try expectEqual(0, token.ends.line);
    try expectEqual(1, token.ends.column);
    try expectEqual(.eof, token.tag);
}

test "one_token" {
    var token = try Token.init("button\n");
    try expectEqual(.button, token.tag);
    try expectEqual(0, token.begins.line);
    try expectEqual(0, token.begins.column);
    try expectEqual(0, token.ends.line);
    try expectEqual(6, token.ends.column);
    token = try token.next();
    try expectEqual(0, token.begins.line);
    try expectEqual(6, token.begins.column);
    try expectEqual(1, token.ends.line);
    try expectEqual(0, token.ends.column);
    try expectEqual(.eof, token.tag);
}

test "tokenise_whitespace" {
    const token = try Token.init(" \n  \n ");
    try expectEqual(.eof, token.tag);
}

test "tokenise_word" {
    var token = try Token.init("cloth");
    try expectEqual(.unexpected, token.tag);
    try expectEqualStrings("cloth", token.slice());
    try expectEqual(Cursor{ .line = 0, .column = 0 }, token.begins);
    try expectEqual(Cursor{ .line = 0, .column = 5 }, token.ends);
    try expectEqual(Loc{ .start = 0, .end = 5 }, token.loc);
    token = try token.next();
    try expectEqual(.eof, token.tag);
}

test "tokenise_word_boundary" {
    var token = try Token.init("cloth=");
    try expectEqual(.unexpected, token.tag);
    try expectEqualStrings("cloth", token.slice());
    try expectEqual(Cursor{ .line = 0, .column = 0 }, token.begins);
    try expectEqual(Cursor{ .line = 0, .column = 5 }, token.ends);
    try expectEqual(Loc{ .start = 0, .end = 5 }, token.loc);
    token = try token.next();
    try expectEqual(.equals, token.tag);
    try expectEqualStrings("=", token.slice());
    try expectEqual(Cursor{ .line = 0, .column = 5 }, token.begins);
    try expectEqual(Cursor{ .line = 0, .column = 6 }, token.ends);
    try expectEqual(Loc{ .start = 5, .end = 6 }, token.loc);
    token = try token.next();
    try expectEqual(.eof, token.tag);
}

test "tokenise_position" {
    var token = try Token.init("style\n  normal");
    try expectEqualStrings("style", token.slice());
    try expectEqual(.style, token.tag);
    try expectEqual(Cursor{ .line = 0, .column = 0 }, token.begins);
    try expectEqual(Cursor{ .line = 0, .column = 5 }, token.ends);
    try expectEqual(Loc{ .start = 0, .end = 5 }, token.loc);
    token = try token.next();
    try expectEqual(.normal, token.tag);
    token = try token.next();
    try expectEqual(.eof, token.tag);
}

test "empty_string" {
    var token = try Token.init("\"\"");
    try expectEqual(Token.Tag.string, token.tag);
    token = try token.next();
    try expectEqual(.eof, token.tag);
    token = try token.next();
    try expectEqual(.eof, token.tag);
}

test "number" {
    var token = try Token.init("width 1.0 1. 1 height");
    try expectEqual(Token.Tag.width, token.tag);
    token = try token.next();
    try expectEqual(.number, token.tag);
    try expectEqualStrings("1.0", token.slice());
    token = try token.next();
    try expectEqual(.number, token.tag);
    try expectEqualStrings("1.", token.slice());
    token = try token.next();
    try expectEqual(.number, token.tag);
    try expectEqualStrings("1", token.slice());
    token = try token.next();
    try expectEqual(.height, token.tag);
    token = try token.next();
    try expectEqual(.eof, token.tag);
}

test "sentence" {
    var token = try Token.init("label name \"green book\" layout grows");
    try expectEqual(.label, token.tag);
    try expectEqualStrings("label", token.slice());
    try expectEqual(0, token.ends.line);
    try expectEqual(5, token.ends.column);

    token = try token.next();
    try expectEqual(.name, token.tag);
    try expectEqualStrings("name", token.slice());
    try expectEqual(0, token.ends.line);
    try expectEqual(10, token.ends.column);

    token = try token.next();
    try expectEqual(.string, token.tag);
    try expectEqualStrings("\"green book\"", token.slice());
    try expectEqual(0, token.ends.line);
    try expectEqual(23, token.ends.column);

    token = try token.next();
    try expectEqual(.layout, token.tag);
    try expectEqualStrings("layout", token.slice());
    try expectEqual(0, token.ends.line);
    try expectEqual(30, token.ends.column);

    token = try token.next();
    try expectEqual(.grows, token.tag);
    try expectEqualStrings("grows", token.slice());
    try expectEqual(0, token.ends.line);
    try expectEqual(36, token.ends.column);

    token = try token.next();
    try expectEqual(.eof, token.tag);
}

const std = @import("std");
const err = std.log.err;
const eql = std.mem.eql;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
