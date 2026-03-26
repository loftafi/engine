//! A basic CsvReader for loading the translation data file.
pub const CsvReader = @This();

data: []const u8 = "",
value: []const u8 = "",
row: usize = 0,
column: usize = 0,

/// Next will return a field, an end of line marker, or an end of file marker.
/// When a field is returned, the `value`, `row`, and `column` contain data
/// about the field just read.
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

    var in_quote = false;
    if (end < self.data.len and self.data[end] == '\"') {
        end += 1;
        start += 1;
        end_candidate += 1;
        in_quote = true;
    }
    while (true) {
        if (end >= self.data.len) {
            break;
        }
        switch (self.data[end]) {
            '\"' => {
                end_candidate = end;
                end += 1;
                while (end < self.data.len and self.data[end] == ' ' or self.data[end] == '\t') end += 1;
                if (end < self.data.len and (self.data[end] == ',' or self.data[end] == '\r' or self.data[end] == '\t')) end += 1;
                break;
            },
            ',' => {
                if (in_quote) {
                    end += 1;
                    end_candidate = end;
                    continue;
                }
                end += 1;
                break;
            },
            '\r', '\n' => {
                if (in_quote) {
                    end += 1;
                    end_candidate = end;
                    continue;
                }
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

pub const Token = enum {
    field,
    eol,
    eof,
};

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

    i = CsvReader{ .data = "a1,\"b1\",c1\n" };
    try expectEqual(Token.field, i.next());
    try expectEqualStrings("a1", i.value);
    try expectEqual(Token.field, i.next());
    try expectEqualStrings("b1", i.value);
    try expectEqual(Token.field, i.next());
    try expectEqualStrings("c1", i.value);
    try expectEqual(Token.eol, i.next());
    try expectEqual(Token.eof, i.next());

    i = CsvReader{ .data =
        \\  a1 ,"b
        \\1",c1,  "d,1"
        \\
    };
    try expectEqual(Token.field, i.next());
    try expectEqualStrings("a1", i.value);
    try expectEqual(Token.field, i.next());
    try expectEqualStrings("b\n1", i.value);
    try expectEqual(Token.field, i.next());
    try expectEqualStrings("c1", i.value);
    try expectEqual(Token.field, i.next());
    try expectEqualStrings("d,1", i.value);
    try expectEqual(Token.eol, i.next());
    try expectEqual(Token.eof, i.next());
}

test "reader_with_cr" {
    var i = CsvReader{ .data = "\"a\\nb\",\"c\nd\"\n" };
    try expectEqual(Token.field, i.next());
    try expectEqualStrings("a\\nb", i.value);
    try expectEqual(Token.field, i.next());
    try expectEqualStrings("c\nd", i.value);
    try expectEqual(Token.eol, i.next());
    try expectEqual(Token.eof, i.next());
}

const std = @import("std");
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
