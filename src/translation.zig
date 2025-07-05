//! Serves translations from a default language or key into a user
//! requested/preferred language.

pub const Translation = struct {
    maps: std.AutoHashMap(Lang, std.StringHashMap([]const u8)) = undefined,
    current: ?std.StringHashMap([]const u8) = null,
    data: std.ArrayList([]const u8) = undefined,

    pub fn init(self: *Translation, allocator: std.mem.Allocator) void {
        self.maps = std.AutoHashMap(Lang, std.StringHashMap([]const u8)).init(allocator);
        errdefer self.maps.deinit();
        self.data = std.ArrayList([]const u8).init(allocator);
        errdefer self.data.deinit();
        self.current = null;
    }

    pub fn deinit(self: *Translation) void {
        var i = self.maps.iterator();
        while (i.next()) |map| {
            map.value_ptr.deinit();
        }
        self.maps.deinit();
        for (self.data.items) |*item| {
            self.data.allocator.free(item.*);
        }
        self.data.deinit();
    }

    /// Each colum represents a langauge in the `lang.Lang` enum. The header row
    /// contans the language code (defined by the enum), and every subsequent row
    /// should have the same number of columns as the header row.
    pub fn load_translation_data(self: *Translation, tdata: []const u8) !void {
        const data = try self.data.allocator.dupe(u8, tdata);
        try self.data.append(data);
        var headers = std.ArrayList(*std.StringHashMap([]const u8)).init(self.data.allocator);
        defer headers.deinit();
        var i = CsvReader{ .data = data };

        while (true) {
            // Read header
            switch (i.next()) {
                .eol => break,
                .eof => {
                    log.err("load_translation_data has no row data", .{});
                    return;
                },
                .field => {
                    const lr = Lang.parse_code(i.value);
                    if (lr == .unknown) {
                        log.err("load_translation_data has invalid languge code: '{s}'", .{i.value});
                        return;
                    }
                    try self.maps.put(lr, std.StringHashMap([]const u8).init(self.data.allocator));
                    try headers.append(self.maps.getPtr(lr).?);
                },
            }
        }
        if (headers.items.len == 0) {
            log.err("load_translation_data found no language data.", .{});
            return;
        }

        while (true) {
            // Read rows
            switch (i.next()) {
                .eof => {
                    return;
                },
                .eol => {
                    continue;
                },
                .field => {
                    const en = i.value;
                    try headers.items[0].*.put(en, en);
                    var col: usize = 1;
                    while (col < headers.items.len) : (col += 1) {
                        const n = i.next();
                        if (n == .field) {
                            try headers.items[col].*.put(en, i.value);
                        } else {
                            log.err("load_translation_data has unexpected eol/eof on row {d}.", .{i.row});
                            return;
                        }
                    }
                    if (i.next() == .field) {
                        log.err("load_translation_data has too many entries on row {d}.", .{i.row});
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
};

const std = @import("std");
const log = std.log;
const praxis = @import("praxis");
const Lang = praxis.Lang;
const CsvReader = @import("csv_reader.zig").CsvReader;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;

test "translator" {
    {
        var translator = Translation{};
        translator.init(std.testing.allocator);
        defer translator.deinit();
        try translator.load_translation_data("en,el\nbread,ἄρτος\n");
        translator.set_language(.english);
        try expectEqualStrings("fish", translator.translate("fish"));
        try expectEqualStrings("bread", translator.translate("bread"));
        translator.set_language(.greek);
        try expectEqualStrings("ἄρτος", translator.translate("bread"));
    }
    {
        var translator = Translation{};
        translator.init(std.testing.allocator);
        defer translator.deinit();
        try translator.load_translation_data(
            \\en,el
            \\Verb,ῥῆμα
            \\Noun,ὄνομα
            \\Adjective,ἐπὶθετον
            \\Adverb,ἐπίρρημα
        );
        translator.set_language(.english);
        try expectEqualStrings("Noun", translator.translate("Noun"));
        translator.set_language(.greek);
        try expectEqualStrings("ὄνομα", translator.translate("Noun"));
    }
}
