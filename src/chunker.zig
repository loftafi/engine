pub const Chunker = struct {
    data: []const u8 = "",

    pub fn init(data: []const u8) Chunker {
        return .{
            .data = data,
        };
    }

    pub fn next(self: *Chunker) ?[]const u8 {
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
                const token = "\n";
                self.data.ptr += 1;
                self.data.len -= 1;
                return token;
            }
            if (!is_whitespace(self.data[0])) {
                break;
            }
            self.data.ptr += 1;
            self.data.len -= 1;
        }

        var end: usize = 0;
        while (self.data.len > end) {
            if (is_whitespace_or_eol(self.data[end])) {
                break;
            }
            end += 1;
        }

        const token = self.data[0..end];
        self.data.ptr += end;
        self.data.len -= end;
        return token;
    }
};

pub inline fn is_whitespace(c: u8) bool {
    return c == ' ' or c == '\t';
}

pub inline fn is_whitespace_or_eol(c: u8) bool {
    return c == ' ' or c == '\n' or c == '\r' or c == '\t' or c == 0;
}

pub inline fn is_eol(c: u8) bool {
    return c == '\n' or c == '\r' or c == 0;
}

const eql = @import("std").mem.eql;
const std = @import("std");
const unicode = @import("std").unicode;
const expect = std.testing.expect;
const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;

test "read_chunks" {
    var data = Chunker.init("the fish");
    try expectEqualStrings("the", data.next().?);
    try expectEqualStrings("fish", data.next().?);
    try expectEqual(null, data.next());

    data = Chunker.init("");
    try expectEqual(null, data.next());

    data = Chunker.init("τίς βλέπει");
    try expectEqualStrings("τίς", data.next().?);
    try expectEqualStrings("βλέπει", data.next().?);
    try expectEqual(null, data.next());

    data = Chunker.init("God, god.");
    try expectEqualStrings("God,", data.next().?);
    try expectEqualStrings("god.", data.next().?);
    try expectEqual(null, data.next());

    data = Chunker.init("fish\ncat\n");
    try expectEqualStrings("fish", data.next().?);
    try expectEqualStrings("\n", data.next().?);
    try expectEqualStrings("cat", data.next().?);
    try expectEqualStrings("\n", data.next().?);
    try expectEqual(null, data.next());

    data = Chunker.init("  'fish'   \n     [cat]      \n");
    try expectEqualStrings("'fish'", data.next().?);
    try expectEqualStrings("\n", data.next().?);
    try expectEqualStrings("[cat]", data.next().?);
    try expectEqualStrings("\n", data.next().?);
    try expectEqual(null, data.next());

    data = Chunker.init("fish\n\ncat");
    try expectEqualStrings("fish", data.next().?);
    try expectEqualStrings("\n", data.next().?);
    try expectEqualStrings("\n", data.next().?);
    try expectEqualStrings("cat", data.next().?);
    try expectEqual(null, data.next());

    data = Chunker.init("fish\r\n\n\rcat");
    try expectEqualStrings("fish", data.next().?);
    try expectEqualStrings("\n", data.next().?);
    try expectEqualStrings("\n", data.next().?);
    try expectEqualStrings("cat", data.next().?);
    try expectEqual(null, data.next());
}
