/// Next will return a field, an end of line marker, or an end of file marker.
/// When a field is returned, the `value`, `row`, and `column` contain data
/// about the field just read.
pub const CsvReader = struct {
    data: []const u8 = "",
    value: []const u8 = "",
    row: usize = 0,
    column: usize = 0,

    pub fn next(self: *CsvReader) Token {
        var start: usize = 0;
        while (true) {
            if (start >= self.data.len) {
                return .eof;
            }
            switch (self.data[start]) {
                ' ', '\t' => {
                    start += 1;
                },
                '\r', '\n' => {
                    if (start + 1 < self.data.len) {
                        const x = self.data[start];
                        const y = self.data[start + 1];
                        if (x == '\n' and y == '\r') {
                            self.data = self.data[start + 2 ..];
                            self.row += 1;
                            self.column = 0;
                            return .eol;
                        }
                        if (x == '\r' and y == '\n') {
                            self.data = self.data[start + 2 ..];
                            self.row += 1;
                            self.column = 0;
                            return .eol;
                        }
                    }
                    self.data = self.data[start + 1 ..];
                    return .eol;
                },
                else => {
                    break;
                },
            }
        }
        var end = start;
        var end_candidate = start;
        while (true) {
            if (end >= self.data.len) {
                break;
            }
            switch (self.data[end]) {
                ',' => {
                    end += 1;
                    break;
                },
                '\r', '\n' => {
                    break;
                },
                ' ', '\t' => end += 1,
                else => {
                    end += 1;
                    end_candidate = end;
                    continue;
                },
            }
        }
        self.value = self.data[start..end_candidate];
        self.data = self.data[end..];
        self.column += 1;
        return .field;
    }
};

pub const Token = enum {
    field,
    eol,
    eof,
};

const std = @import("std");
const log = std.log;
const praxis = @import("praxis");
const Lang = praxis.Lang;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;

test "reader" {
    var i = CsvReader{ .data = "a,b\n" };
    try expectEqual(Token.field, i.next());
    try expectEqualStrings("a", i.value);
    try expectEqual(Token.field, i.next());
    try expectEqualStrings("b", i.value);
    try expectEqual(Token.eol, i.next());
    try expectEqual(Token.eof, i.next());

    i = CsvReader{ .data = " a, b \r\n  d   \t , e " };
    try expectEqual(Token.field, i.next());
    try expectEqualStrings("a", i.value);
    try expectEqual(0, i.row);
    try expectEqual(Token.field, i.next());
    try expectEqualStrings("b", i.value);
    try expectEqual(0, i.row);
    try expectEqual(Token.eol, i.next());
    try expectEqual(Token.field, i.next());
    try expectEqualStrings("d", i.value);
    try expectEqual(1, i.row);
    try expectEqual(Token.field, i.next());
    try expectEqualStrings("e", i.value);
    try expectEqual(1, i.row);
    try expectEqual(Token.eof, i.next());

    i = CsvReader{ .data = ",a,,b" };
    try expectEqual(Token.field, i.next());
    try expectEqualStrings("", i.value);
    try expectEqual(Token.field, i.next());
    try expectEqualStrings("a", i.value);
    try expectEqual(Token.field, i.next());
    try expectEqualStrings("", i.value);
    try expectEqual(Token.field, i.next());
    try expectEqualStrings("b", i.value);
    try expectEqual(Token.eof, i.next());
}
