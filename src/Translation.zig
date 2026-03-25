/// Serves translations from a default language or key into a user
/// requested/preferred language.
pub const Translation = @This();

maps: std.AutoHashMapUnmanaged(Lang, std.StringHashMapUnmanaged([]const u8)) = .empty,
current: ?std.StringHashMapUnmanaged([]const u8) = .empty,
data: std.ArrayListUnmanaged([]const u8) = .empty,

pub const empty: @This() = .{
    .maps = .empty,
    .data = .empty,
    .current = .empty,
};

pub fn deinit(self: *Translation, allocator: Allocator) void {
    var i = self.maps.iterator();
    while (i.next()) |map| {
        map.value_ptr.deinit(allocator);
    }
    self.maps.deinit(allocator);
    for (self.data.items) |*item| {
        allocator.free(item.*);
    }
    self.data.deinit(allocator);
}

/// Each colum represents a langauge in the `lang.Lang` enum. The header row
/// contans the language code (defined by the enum), and every subsequent row
/// should have the same number of columns as the header row.
pub fn load_translation_data(
    self: *Translation,
    allocator: Allocator,
    tdata: []const u8,
) Allocator.Error!void {
    const data = try allocator.dupe(u8, tdata);
    try self.data.append(allocator, data);
    var headers: std.ArrayListUnmanaged(*std.StringHashMapUnmanaged([]const u8)) = .empty;
    defer headers.deinit(allocator);
    var i = CsvReader{ .data = data };

    var col: usize = 0;
    var line: usize = 0;
    while (true) {
        // Read header
        switch (i.next()) {
            .eol => {
                line += 1;
                break;
            },
            .eof => {
                err("load_translation_data has no row data. Line: {d}", .{line});
                return;
            },
            .field => {
                col += 1;
                if (col == 1) continue; // Skip unused first cell
                const lr: Lang = Lang.parse_code(i.value);
                if (lr == .unknown) {
                    err("load_translation_data has invalid languge code: '{s}'", .{i.value});
                    return;
                }
                try self.maps.put(allocator, lr, .empty);
                try headers.append(allocator, self.maps.getPtr(lr).?);
            },
        }
    }
    if (headers.items.len == 0) {
        err("load_translation_data found no language data. Line: {d}", .{line});
        return;
    }

    while (true) {
        // Read rows
        switch (i.next()) {
            .eof => {
                return;
            },
            .eol => {
                line += 1;
                continue;
            },
            .field => {
                const key = i.value;
                col = 0;
                var n: Token = .eof;
                while (col < headers.items.len) : (col += 1) {
                    n = i.next();
                    if (n == .field) {
                        try headers.items[col].*.put(allocator, key, i.value);
                    } else if (n == .eol or n == .eof) {
                        // Handle case where last column(s) are empty
                        break;
                    } else {
                        err("load_translation_data has unexpected token {s} on row {d}.", .{ @tagName(n), i.row });
                        return;
                    }
                }
                if (n == .eof) return;
                if (n == .eol) continue;
                // Next should be eol or eof
                if (i.next() == .field) {
                    err("load_translation_data has too many entries on row {d} line {d}.", .{ i.row, line });
                    return;
                }
            },
        }
    }
}

pub fn set_language(self: *Translation, language: Lang) void {
    if (self.maps.contains(language)) {
        self.current = self.maps.get(language).?;
        return;
    }
    self.current = null;
}

/// Return the localised version of a key in the currently selected language.
pub fn translate(self: *Translation, key: []const u8) []const u8 {
    if (self.current) |current| {
        if (current.get(key)) |value| {
            return value;
        }
    }
    return key;
}

test "translator" {
    const allocator = std.testing.allocator;
    {
        var translator: Translation = .empty;
        defer translator.deinit(allocator);
        try translator.load_translation_data(allocator, "keys,en,el\nBREAD,bread,ἄρτος\n");

        try expect(translator.maps.contains(Lang.english));
        try expect(!translator.maps.contains(Lang.hebrew));
        try expect(translator.maps.contains(Lang.greek));

        translator.set_language(.english);
        try expectEqualStrings("bread", translator.translate("BREAD"));
        translator.set_language(.greek);
        try expectEqualStrings("ἄρτος", translator.translate("BREAD"));
    }
    {
        var translator: Translation = .empty;
        defer translator.deinit(allocator);
        try translator.load_translation_data(allocator,
            \\keys,en,el
            \\VERB,Verb,ῥῆμα
            \\NOUN,Noun,ὄνομα
            \\ADJECTIVE,Adjective,ἐπὶθετον
            \\ADVERB,Adverb,ἐπίρρημα
        );
        translator.set_language(.english);
        try expectEqualStrings("Noun", translator.translate("NOUN"));
        translator.set_language(.greek);
        try expectEqualStrings("ὄνομα", translator.translate("NOUN"));
    }
    {
        var translator: Translation = .empty;
        defer translator.deinit(allocator);
        try translator.load_translation_data(allocator,
            \\keys,en,es,zh_TW,ko,Uk
            \\NONE,,,,,
            \\APPLE,a,a,a,a,a
            \\PEAR,a,a,a
            \\COFFEE,a,a,a,a,a
        );
        try expectEqual(5, translator.maps.count());
    }
}

const std = @import("std");
const Allocator = std.mem.Allocator;
const praxis = @import("praxis");
const engine = @import("engine.zig");
const err = engine.err;
const Lang = praxis.Lang;
const CsvReader = @import("csv_reader.zig").CsvReader;
const Token = @import("csv_reader.zig").Token;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
