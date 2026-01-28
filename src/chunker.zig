pub const Chunker = struct {
    data: []const u8 = "",

    pub fn init(data: []const u8) Chunker {
        return .{
            .data = data,
        };
    }

    pub fn next(self: *Chunker, display: *Display) ?TextElement {
        if (self.data.len == 0) {
            return null;
        }

        while (self.data.len > 0) {
            if (is_eol(self.data[0])) {
                if (self.data.len > 1) {
                    const a = self.data[0];
                    const b = self.data[1];
                    if ((a == '\n' and b == '\r') or (a == '\r' and b == '\n')) {
                        self.data.ptr += 1;
                        self.data.len -= 1;
                    }
                }
                self.data.ptr += 1;
                self.data.len -= 1;
                return .{ .text = cr, .width = 0, .font = display.font.default, .texture = undefined };
            }
            if (!is_whitespace(self.data[0])) {
                break;
            }
            self.data.ptr += 1;
            self.data.len -= 1;
        }

        var end: usize = 0;
        while (self.data.len > end) {
            const c = self.data[end];
            if (c == '\\' and self.data.len > end + 1 and self.data[end + 1] == 'n') {
                if (end == 0) {
                    self.data.ptr += 2;
                    self.data.len -= 2;
                    return .{ .text = cr, .width = 0, .font = display.font.default, .texture = undefined };
                }
                break;
            }
            if (is_whitespace_or_eol(c)) break;
            end += 1;
        }

        const token = self.data[0..end];
        self.data.ptr += end;
        self.data.len -= end;

        return .{
            .text = token,
            .font = guess_language(token, display),
            .width = 0,
            .texture = undefined,
        };
    }
};

const cr = "\n";

pub inline fn is_whitespace(c: u8) bool {
    return c == ' ' or c == '\t';
}

pub inline fn is_whitespace_or_eol(c: u8) bool {
    return c == ' ' or c == '\n' or c == '\r' or c == '\t' or c == 0;
}

pub inline fn is_eol(c: u8) bool {
    return c == '\n' or c == '\r' or c == 0;
}

pub fn guess_language(word: []const u8, display: *Display) *Font {
    var lang = Lang.unknown;
    var v = Utf8View.init(word) catch {
        return display.font.default;
    };
    var it = v.iterator();
    while (it.nextCodepoint()) |c| {
        // Grouping characters are not meaningful for detecting language
        if (c == '{' or c == '}' or c == '[' or c == ']') continue;

        var x = Lang.unknown;
        if (is_greek_letter(c)) {
            x = .greek;
        } else if (is_english_letter(c)) {
            x = .english;
        } else if (is_korean_letter(c)) {
            x = .korean;
        } else if (is_chinese_letter(c)) {
            x = .chinese;
        } else if (c == ' ' or c == '\n' or c == '\t' or c == '"' or c == '\'') {
            continue;
        } else if (is_greek_punctuation(c)) {
            continue;
        } else if (is_english_punctuation(c)) {
            if (lang == .greek) return display.font.default;
            continue;
        } else {
            return display.font.default;
        }
        if (lang == .unknown) {
            lang = x;
            continue;
        }
        if (lang != x) {
            warn("Mixed language. Detection failed. {s}", .{word});
            return display.font.default;
        }
    }
    //debug("    chunk {t} {s}", .{ lang, word });
    return switch (lang) {
        .english => display.font.english,
        .greek => display.font.greek,
        .chinese => display.font.chinese,
        .korean => display.font.korean,
        else => display.font.default,
    };
}

pub inline fn is_english_punctuation(c: u21) bool {
    return (c == '.' or c == '?' or c == ',' or c == '"' or c == '\'' or c == '!' or c == '/' or c == '\u{2018}' or c == '\u{2019}' or c == '(' or c == ')' or c == ';' or c == '-');
}

pub inline fn is_greek_punctuation(c: u21) bool {
    return (c == '.' or c == ';' or c == ',' or c == '"' or c == '!' or c == '·' or c == '«' or c == '»');
}

pub inline fn is_english_letter(c: u21) bool {
    return (c >= 'A' and c <= 'Z') or (c >= 'a' and c <= 'z') or (c >= '0' and c <= '9');
}

pub inline fn is_greek_letter(c: u21) bool {
    return (c >= '\u{0370}' and c <= '\u{03FF}') or (c >= '\u{1f00}' and c <= '\u{1ffF}');
}

pub inline fn is_korean_letter(c: u21) bool {
    return (c >= '\u{1100}' and c <= '\u{11ff}') or
        (c >= '\u{ac00}' and c <= '\u{d7af}') or
        (c >= '\u{3130}' and c <= '\u{318f}') or
        (c >= '\u{a960}' and c <= '\u{a97f}') or
        (c >= '\u{d7b0}' and c <= '\u{d7ff}');
}

pub inline fn is_chinese_letter(c: u21) bool {
    //https://stackoverflow.com/questions/1366068/whats-the-complete-range-for-chinese-characters-in-unicode
    return (c >= '\u{4e00}' and c <= '\u{9fff}') or
        (c >= '\u{3400}' and c <= '\u{4dbf}') or
        (c >= '\u{20000}' and c <= '\u{2a6df}') or
        (c >= '\u{2b740}' and c <= '\u{2ebef}') or
        (c >= '\u{30000}' and c <= '\u{323af}') or
        (c >= '\u{f900}' and c <= '\u{faff}') or
        (c >= '\u{2e80}' and c <= '\u{2fdf}');
}

test "read_chunks" {
    const allocator = std.testing.allocator;
    var display = try Display.create(allocator, test_config);
    defer display.destroy(allocator);
    _ = try display.load_font(allocator, "Roboto-Light");
    try expectEqual(1, display.fonts.items.len);
    display.font.greek = try display.load_font(allocator, "Roboto-Black");
    display.font.chinese = try display.load_font(allocator, "Roboto-Bold");
    display.font.korean = try display.load_font(allocator, "Roboto-Thin");
    try expectEqual(4, display.fonts.items.len);

    var data = Chunker.init("the fish");
    try expectEqualStrings("the", data.next(display).?.text);
    try expectEqualStrings("fish", data.next(display).?.text);
    try expectEqual(null, data.next(display));

    data = Chunker.init("");
    try expectEqual(null, data.next(display));

    data = Chunker.init("τίς βλέπει");
    try expectEqualStrings("τίς", data.next(display).?.text);
    try expectEqualStrings("βλέπει", data.next(display).?.text);
    try expectEqual(null, data.next(display));

    data = Chunker.init("God, god.");
    try expectEqualStrings("God,", data.next(display).?.text);
    try expectEqualStrings("god.", data.next(display).?.text);
    try expectEqual(null, data.next(display));

    data = Chunker.init("fish\ncat\n");
    try expectEqualStrings("fish", data.next(display).?.text);
    try expectEqualStrings("\n", data.next(display).?.text);
    try expectEqualStrings("cat", data.next(display).?.text);
    try expectEqualStrings("\n", data.next(display).?.text);
    try expectEqual(null, data.next(display));

    data = Chunker.init("  'fish'   \n     [cat]      \n");
    try expectEqualStrings("'fish'", data.next(display).?.text);
    try expectEqualStrings("\n", data.next(display).?.text);
    try expectEqualStrings("[cat]", data.next(display).?.text);
    try expectEqualStrings("\n", data.next(display).?.text);
    try expectEqual(null, data.next(display));

    data = Chunker.init("fish\n\ncat");
    try expectEqualStrings("fish", data.next(display).?.text);
    try expectEqualStrings("\n", data.next(display).?.text);
    try expectEqualStrings("\n", data.next(display).?.text);
    try expectEqualStrings("cat", data.next(display).?.text);
    try expectEqual(null, data.next(display));

    data = Chunker.init("fish\r\n\n\rcat");
    try expectEqualStrings("fish", data.next(display).?.text);
    try expectEqualStrings("\n", data.next(display).?.text);
    try expectEqualStrings("\n", data.next(display).?.text);
    try expectEqualStrings("cat", data.next(display).?.text);
    try expectEqual(null, data.next(display));

    data = Chunker.init("\\ncat");
    try expectEqualStrings("\n", data.next(display).?.text);
    try expectEqualStrings("cat", data.next(display).?.text);
    try expectEqual(null, data.next(display));

    data = Chunker.init("fish\\cat");
    try expectEqualStrings("fish\\cat", data.next(display).?.text);
    try expectEqual(null, data.next(display));

    data = Chunker.init("fish\\ncat");
    try expectEqualStrings("fish", data.next(display).?.text);
    try expectEqualStrings("\n", data.next(display).?.text);
    try expectEqualStrings("cat", data.next(display).?.text);
    try expectEqual(null, data.next(display));

    data = Chunker.init("fish 你好 한국어 ἄρτος");
    try expectEqual(display.font.english, data.next(display).?.font);
    try expectEqual(display.font.chinese, data.next(display).?.font);
    try expectEqual(display.font.korean, data.next(display).?.font);
    try expectEqual(display.font.greek, data.next(display).?.font);
    try expectEqual(null, data.next(display));

    data = Chunker.init("fish, 你好, 한국어, ἄρτος,");
    try expectEqual(display.font.english, data.next(display).?.font);
    try expectEqual(display.font.chinese, data.next(display).?.font);
    try expectEqual(display.font.korean, data.next(display).?.font);
    try expectEqual(display.font.greek, data.next(display).?.font);
    try expectEqual(null, data.next(display));
}

const eql = @import("std").mem.eql;
const std = @import("std");
const unicode = @import("std").unicode;
const Utf8View = std.unicode.Utf8View;

const praxis = @import("praxis");
const Lang = praxis.Lang;

const TextElement = @import("element.zig").TextElement;
const test_config = @import("test.zig").test_config;

const engine = @import("engine.zig");
const Display = engine.Display;
const Font = engine.Font;
const debug = engine.debug;
const warn = engine.warn;

const expect = std.testing.expect;
const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
