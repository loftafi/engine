/// a `Resources` manager. If a resource bundle is not available
/// check if there is a developer resource folder.
pub fn init_resource_loader(
    allocator: Allocator,
    bundle_filename: [:0]const u8,
    dev_repo: []const u8,
) error{
    OutOfMemory,
    ResourceReadError,
    NoResources,
    ReadMetadataFailed,
    ReadRepoFileFailed,
    InvalidResourceUID,
    MetadataMissing,
    Utf8ExpectedContinuation,
    Utf8OverlongEncoding,
    Utf8EncodesSurrogateHalf,
    Utf8CodepointTooLarge,
    Utf8InvalidStartByte,
}!*Resources {
    const start = std.time.milliTimestamp();

    var resources = try Resources.create(allocator);
    if (sdl_load_bundle(resources, bundle_filename)) |_| {
        const end = std.time.milliTimestamp();
        info("Resource list scanned in {d}ms.", .{end - start});
        return resources;
    } else |e| {
        warn("sdl_load_bundle failed. {any}", .{e});
    }

    var loaded: bool = false;
    if (try find_base_folder(allocator, bundle_filename)) |base_folder| {
        defer allocator.free(base_folder);
        info("find_base_folder returned: {s}", .{base_folder});

        if (try folder_has_file(base_folder, bundle_filename)) {
            loaded = sdl_load_bundle(resources, bundle_filename) catch |e| {
                if (e == error.OutOfMemory) {
                    return error.OutOfMemory;
                } else {
                    warn("sdl_load_bundle failed. {any}", .{e});
                    return e;
                }
            };
        }
    }

    if (!loaded) {
        // Fallback to loading resources from the development resources
        // folder if it is available.
        if (dev_repo.len > 0) {
            loaded = resources.load_directory(dev_repo) catch |e| {
                err("error loading repo from {s}. {any}", .{ dev_repo, e });
                return e;
            };
        }
    }

    const end = std.time.milliTimestamp();
    info("Resource loader setup in {d}ms. loaded={any}", .{ end - start, loaded });
    return resources;
}

/// Check of a specific file exists in any of the expected location. Return
/// a non empty string containing the path if the location is found.
fn find_base_folder(allocator: Allocator, expected_file: [:0]const u8) error{ OutOfMemory, ResourceReadError }!?[]const u8 {

    // First check in the SDL reported base path.
    if (sdl.SDL_GetBasePath()) |sdl_base| {
        if (!try folder_has_file(std.mem.span(sdl_base), expected_file)) {
            debug("SDL_GetBasePath(): {s} doesnt contain {s}", .{ sdl_base, expected_file });
        } else {
            info("Found Base Folder: {s} contains {s}", .{ sdl_base, expected_file });
            return try allocator.dupe(u8, std.mem.span(sdl_base));
        }
    }

    // Check the current folder for the expected file.
    var buffer: [1000]u8 = undefined;
    const p = std.fs.cwd().realpathZ(".", &buffer) catch |e| {
        info("Error reading current working path: {any}", .{e});
        return error.ResourceReadError;
    };
    if (!try folder_has_file(p, expected_file)) {
        debug("cwd {s} doesnt contain {s}", .{ p, expected_file });
    } else {
        info("Found Base Folder: {s} contains {s}", .{ p, expected_file });
        if (p.len + 1 < buffer.len) {
            buffer[p.len] = guess_separator(p);
        } else {
            return error.ResourceReadError;
        }
        return try allocator.dupe(u8, buffer[0 .. p.len + 1]);
    }

    return null;
}

fn guess_separator(base_folder: []const u8) u8 {
    if (std.mem.startsWith(u8, base_folder, "/")) {
        return '/';
    } else if (std.mem.startsWith(u8, base_folder, "\\")) {
        return '\\';
    } else if (std.mem.endsWith(u8, base_folder, "/")) {
        return '/';
    } else if (std.mem.endsWith(u8, base_folder, "\\")) {
        return '\\';
    }
    return '/';
}

/// Assumes base_folder has a trailing / provided by `SDL_GetBasePath()`
fn folder_has_file(base_folder: []const u8, expected_file: []const u8) error{ OutOfMemory, ResourceReadError }!bool {
    var path_info: sdl.SDL_PathInfo = undefined;
    var buffer = std.BoundedArray(u8, 1000){};
    buffer.appendSlice(base_folder) catch return error.ResourceReadError;
    if (!std.mem.endsWith(u8, base_folder, "/") and !std.mem.endsWith(u8, base_folder, "\\")) {
        buffer.append(guess_separator(base_folder)) catch return error.ResourceReadError;
    }
    buffer.appendSlice(expected_file) catch return error.ResourceReadError;
    buffer.append(0) catch return error.ResourceReadError;
    if (sdl.SDL_GetPathInfo(buffer.slice().ptr, &path_info)) {
        return true;
    }
    // Either the file doesn't exist or an error occurred
    debug("File not found {s}", .{buffer.slice()});
    return false;
}
/// Try and load using SDL first, otherwise, use the normal resource loader.
pub inline fn sdl_load_resource(
    resources: *Resources,
    resource: *Resource,
    allocator: Allocator,
) error{ OutOfMemory, ResourceNotFound, ResourceReadError }![]const u8 {
    if (resource.bundle_offset != null) {
        //debug("load resource using sdl", .{});
        return sdl_read_data(resources, resource, allocator);
    } else {
        //debug("load resource using praxis", .{});
        const data = resources.read_data(resource, allocator) catch |e| {
            if (e == error.OutOfMemory) return error.OutOfMemory;
            if (e == error.FileNotFound) return error.ResourceNotFound;
            return error.ResourceReadError;
        };
        return data;
    }
}

/// Returns an error if bundle was not loaded for any reason.
pub fn sdl_load_bundle(
    self: *Resources,
    bundle_filename: [:0]const u8,
) error{
    OutOfMemory,
    ResourceReadError,
    Utf8OverlongEncoding,
    Utf8EncodesSurrogateHalf,
    Utf8CodepointTooLarge,
    Utf8InvalidStartByte,
    Utf8ExpectedContinuation,
}!bool {
    var buffer: [300:0]u8 = undefined;

    const in = sdl.SDL_IOFromFile(bundle_filename, "rb");
    if (in == null) {
        if (builtin.is_test) {
            debug("Open bundle file failed: {s}", .{bundle_filename});
        } else {
            err("Open bundle file failed: {s}", .{bundle_filename});
        }
        return error.ResourceReadError;
    }
    const input = in.?;
    defer _ = sdl.SDL_CloseIO(input);

    const b1 = try read_u8(input);
    const b2 = try read_u8(input);
    const b3 = try read_u8(input);
    if (b1 + 9 != b2) {
        err("Invalid bundle file: {s}", .{bundle_filename});
        return error.ResourceReadError;
    }
    if (b1 + 1 != b3) {
        err("Invalid bundle file: {s}", .{bundle_filename});
        return error.ResourceReadError;
    }
    const entries = try read_u24(input);
    for (0..entries) |_| {
        var r = try Resource.create(self.arena_allocator);
        errdefer r.destroy(self.arena_allocator);
        const resource_type = try read_u8(input);
        r.resource = @enumFromInt(resource_type);
        r.uid = try read_u64(input);
        r.size = try read_u32(input);
        const sentence_count = try read_u8(input);
        for (0..sentence_count) |_| {
            const name_len: u8 = try read_u8(input);
            try read_slice(input, buffer[0..name_len]);
            const text = try self.arena_allocator.dupe(u8, buffer[0..name_len]);
            try r.sentences.append(text);
        }
        r.bundle_offset = try read_u64(input);

        try self.by_uid.put(r.uid, r);
        for (r.sentences.items) |sentence| {
            self.by_filename.add(sentence, r) catch |e| {
                err("Bundle contains invalid filename: {s} -> {s}. {any}", .{ bundle_filename, sentence, e });
                return error.ResourceReadError;
            };
        }

        var unique = UniqueWords.init(self.arena_allocator);
        defer unique.deinit();
        try unique.addArray(&r.sentences.items);
        var it = unique.words.iterator();
        while (it.next()) |word| {
            if (word.key_ptr.*.len > 0) {
                self.by_word.add(word.key_ptr.*, r) catch |e| {
                    err("Bundle contains invalid filename word size: {s} -> {s} {any}", .{ bundle_filename, word.key_ptr.*, e });
                    return error.ResourceReadError;
                };
            } else {
                const file_uid = encode_uid(u64, r.uid, buffer[0..40 :0]);
                std.debug.print("empty sentence keyword in {s}\n", .{file_uid});
            }
        }
    }

    self.bundle_file = try self.arena_allocator.dupe(u8, bundle_filename);
    return true;
}

pub fn sdl_read_data(
    self: *Resources,
    resource: *Resource,
    allocator: Allocator,
) error{ OutOfMemory, ResourceNotFound, ResourceReadError }![]const u8 {
    if (resource.filename) |filename| {
        err("sdl_read_data called on resource that belongs on disk (not in bundle) {s}", .{filename});
        return error.ResourceNotFound;
    }
    if (resource.bundle_offset) |bundle_offset| {
        if (self.used_resource_list) |*manifest| {
            try manifest.append(resource);
        }
        return try sdl_load_file_byte_slice(allocator, self.bundle_file, bundle_offset, resource.size);
    }
    return error.ResourceNotFound;
}

fn sdl_load_file_byte_slice(
    allocator: Allocator,
    bundle_filename: []const u8,
    offset: usize,
    size: usize,
) error{ OutOfMemory, ResourceNotFound, ResourceReadError }![]u8 {
    const in = sdl.SDL_IOFromFile(bundle_filename.ptr, "rb");
    if (in == null) {
        //return error.CantOpenBundle;
        err("Open bundle file failed: {s}", .{bundle_filename});
        return error.ResourceReadError;
    }
    const input = in.?;
    defer _ = sdl.SDL_CloseIO(input);

    if (sdl.SDL_SeekIO(input, @intCast(offset), sdl.SDL_IO_SEEK_SET) == -1) {
        err("Seek file failed: {s} {d} {d}", .{ bundle_filename, offset, size });
        return error.ResourceReadError;
    }
    const buffer = try allocator.alloc(u8, size);
    errdefer allocator.free(buffer);
    if (sdl.SDL_ReadIO(input, buffer.ptr, buffer.len) == size) {
        return buffer;
    }
    err("SDL ReadIO from bundle file failed: {s}", .{bundle_filename});
    return error.ResourceReadError;
}

inline fn read_u8(i: *sdl.SDL_IOStream) !u8 {
    var value: u8 = undefined;
    if (sdl.SDL_ReadU8(i, &value)) {
        return value;
    }
    err("SDL ReadIO from bundle file failed", .{});
    return error.ResourceReadError;
}

inline fn read_u24(i: *sdl.SDL_IOStream) error{ResourceReadError}!u24 {
    const b1 = try read_u8(i);
    const b2 = try read_u8(i);
    const b3 = try read_u8(i);
    return b1 + (@as(u24, b2) << 8) + (@as(u24, b3) << 16);
}

inline fn read_u32(i: *sdl.SDL_IOStream) error{ResourceReadError}!u32 {
    var value: u32 = undefined;
    if (sdl.SDL_ReadU32LE(i, &value)) {
        return value;
    }
    err("SDL ReadIO from bundle file failed", .{});
    return error.ResourceReadError;
}

inline fn read_u64(i: *sdl.SDL_IOStream) error{ResourceReadError}!u64 {
    var value: u64 = undefined;
    if (sdl.SDL_ReadU64LE(i, &value)) {
        return value;
    }
    err("SDL ReadIO from bundle file failed", .{});
    return error.ResourceReadError;
}

inline fn read_slice(
    i: *sdl.SDL_IOStream,
    value: []u8,
) error{ResourceReadError}!void {
    if (sdl.SDL_ReadIO(i, value.ptr, value.len) == value.len) {
        return;
    }
    err("SDL ReadIO from bundle file failed", .{});
    return error.ResourceReadError;
}

const builtin = @import("builtin");
const sdl = @import("sdl");
const std = @import("std");
const Allocator = std.mem.Allocator;
const praxis = @import("praxis");
const Resources = @import("resources").Resources;
const encode_uid = @import("resources").encode_uid;
const UniqueWords = @import("resources").UniqueWords;
const Resource = @import("resources").Resource;
const ResourceType = @import("resources").ResourceType;
const engine = @import("engine.zig");
const err = engine.err;
const warn = engine.warn;
const info = engine.info;
const debug = engine.debug;
