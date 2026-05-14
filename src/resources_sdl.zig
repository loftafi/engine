/// Loads a bundle file or folder into a `Resources` manager. Checks standard
/// locations for the existence of the `bundle_filename` or falls back to
/// loading resources from the `dev_repo` folder.
///
/// The reason for existence of this function, is that we need to replace
/// the `Resources` load bundle function with a custom function that attempts
/// to use SDL to load resources.
pub fn initResourcesSdl(
    gpa: Allocator,
    io: std.Io,
    bundle: *Resources,
    config: *const engine.Config,
    bundle_info: *const engine.BundleInfo,
) (Allocator.Error || Resources.Error || engine.Error || std.Io.Dir.StatError ||
    std.Io.File.StatError || std.Io.File.OpenError || error{
    ResourceReadError,
    Utf8ExpectedContinuation,
    Utf8OverlongEncoding,
    Utf8EncodesSurrogateHalf,
    Utf8CodepointTooLarge,
    Utf8InvalidStartByte,
})!void {
    const start = std.Io.Timestamp.now(io, .real).toMilliseconds();

    if (bundle_info.folder) |folder| {
        if (folder.len > 0) {
            if (bundle.loadDirectory(gpa, io, folder, config.resource_filter)) |loaded| {
                if (loaded) {
                    const end = std.Io.Timestamp.now(io, .real).toMilliseconds();
                    info("initResourcesSdl() Dev Resource folder loaded from '{s}' in {d}ms.", .{ folder, end - start });
                    return;
                } else {
                    err("No resources loaded into bundle from {s}", .{folder});
                }
            } else |e| {
                err("initResourcesSdl() error loading repo from '{s}'. {any}", .{ folder, e });
            }
        }
    }

    if (bundle_info.filename) |filename| {
        if (filename.len > 0) {
            // Try to load bundle from current/default path.
            if (loadBundleSdl(bundle, filename)) |loaded| {
                if (loaded) {
                    const end = std.Io.Timestamp.now(io, .real).toMilliseconds();
                    info("initResourcesSdl() Resource list loaded from bundle '{s}' in {d}ms.", .{ filename, end - start });
                    return;
                }
            } else |e| {
                warn("initResourcesSdl() did not load bundle filename '{s}'. {any}", .{ filename, e });
            }

            // Try and find bundle in alternate locations
            if (try find_base_folder(gpa, filename)) |bf| {
                defer gpa.free(bf);
                info("find_base_folder returned: {s}", .{bf});

                if (loadBundleSdl(bundle, bf)) |loaded| {
                    if (loaded) {
                        const end = std.Io.Timestamp.now(io, .real).toMilliseconds();
                        info("Resource list loaded from {s} in {d}ms.", .{ bf, end - start });
                        return;
                    }
                } else |e| {
                    if (e == error.OutOfMemory) {
                        return error.OutOfMemory;
                    } else {
                        warn("loadBundleSdl failed. {any}", .{e});
                        return e;
                    }
                }
            }
            err("initResourcesSdl() could not find bundle '{s}'.", .{filename});
        }
    }
}

/// Return the location of the read only applicaion base folder as long as
/// it contains the expected file resource.
fn find_base_folder(
    allocator: Allocator,
    expected_file: []const u8,
) error{ OutOfMemory, ResourceReadError }!?[]const u8 {

    // First check in the SDL reported base path.
    if (sdl.SDL_GetBasePath()) |sdl_base| {
        const base_path = std.mem.span(sdl_base);
        if (try make_sdl_file_path(allocator, base_path, expected_file)) |p| {
            info("Found Base Folder: {s} contains {s}", .{ p, expected_file });
            return p;
        } else {
            debug("SDL_GetBasePath(): {s} doesnt contain {s}", .{ base_path, expected_file });
        }
    }

    // Fall back to check in the SDL reported current path.
    if (sdl.SDL_GetCurrentDirectory()) |sdl_base| {
        const base_path = std.mem.span(sdl_base);
        if (try make_sdl_file_path(allocator, base_path, expected_file)) |p| {
            info("Found Base Folder: {s} contains {s}", .{ base_path, expected_file });
            return p;
        } else {
            debug("SDL_GetCurrentDirectory(): {s} doesnt contain {s}", .{ base_path, expected_file });
        }
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
fn make_sdl_file_path(allocator: Allocator, base_folder: []const u8, expected_file: []const u8) error{ OutOfMemory, ResourceReadError }!?[]const u8 {
    // Make the folder/file path
    var buffer: std.ArrayListUnmanaged(u8) = .empty;
    buffer.appendSlice(allocator, base_folder) catch return error.ResourceReadError;
    if (!std.mem.endsWith(u8, base_folder, "/") and !std.mem.endsWith(u8, base_folder, "\\")) {
        buffer.append(allocator, guess_separator(base_folder)) catch return error.ResourceReadError;
    }
    buffer.appendSlice(allocator, expected_file) catch return error.ResourceReadError;
    buffer.append(allocator, 0) catch return error.ResourceReadError;

    // Check if it exists
    var path_info: sdl.SDL_PathInfo = undefined;
    if (sdl.SDL_GetPathInfo(buffer.items[0..buffer.items.len].ptr, &path_info)) {
        trace("make_sdl_file_path() check file {s} exists return=true", .{buffer.items[0..buffer.items.len]});
        return try buffer.toOwnedSlice(allocator);
    }
    // Either the file doesn't exist or an error occurred
    trace("make_sdl_file_path() check file {s} exists return=false", .{buffer.items[0..buffer.items.len]});
    return null;
}
/// Try and load using SDL first, otherwise, use the normal resource loader.
pub inline fn loadResourceSdl(
    allocator: Allocator,
    io: std.Io,
    bundle: *Resources,
    resource: *Resource,
) error{ OutOfMemory, ResourceNotFound, ResourceReadError }![]const u8 {
    if (resource.bundle_offset != null) {
        // load resource using sdl
        return readResourceSdl(allocator, bundle, resource);
    } else {
        // load resource using file system
        const data = bundle.loadResource(allocator, io, resource) catch |e| {
            if (e == error.OutOfMemory) return error.OutOfMemory;
            if (e == error.FileNotFound) return error.ResourceNotFound;
            return error.ResourceReadError;
        };
        return data;
    }
}

/// Returns an error if bundle was not loaded for any reason.
pub fn loadBundleSdl(
    self: *Resources,
    bundle_filename: []const u8,
) (Allocator.Error || Resources.Error || error{
    Utf8OverlongEncoding,
    Utf8EncodesSurrogateHalf,
    Utf8CodepointTooLarge,
    Utf8InvalidStartByte,
    Utf8ExpectedContinuation,
})!bool {
    var buffer: [300:0]u8 = undefined;

    const bundle_filename_z: [:0]u8 = try self.arena.allocator().dupeZ(u8, bundle_filename);
    errdefer self.arena.allocator().free(bundle_filename_z);

    const in = sdl.SDL_IOFromFile(bundle_filename_z.ptr, "rb");
    if (in == null) {
        err("Open bundle file via sdl failed: {s}", .{bundle_filename});
        return Resources.Error.ReadRepoFileFailed;
    }
    const input = in.?;
    defer _ = sdl.SDL_CloseIO(input);

    const b1 = try read_u8(input);
    const b2 = try read_u8(input);
    const b3 = try read_u8(input);
    if (b1 + 9 != b2) {
        err("Invalid bundle file: {s}", .{bundle_filename});
        return Resources.Error.ReadRepoFileFailed;
    }
    if (b1 + 1 != b3) {
        err("Invalid bundle file: {s}", .{bundle_filename});
        return Resources.Error.ReadRepoFileFailed;
    }
    const entries = try read_u24(input);
    for (0..entries) |_| {
        var r = try Resource.create(self.arena.allocator());
        errdefer r.destroy(self.arena.allocator());
        const resource_type = try read_u8(input);
        r.resource = @enumFromInt(resource_type);
        r.uid = try read_u64(input);
        r.size = try read_u32(input);
        r.filename = bundle_filename_z;
        const sentence_count = try read_u8(input);
        for (0..sentence_count) |_| {
            const name_len: u8 = try read_u8(input);
            try read_slice(input, buffer[0..name_len]);
            const text = try self.arena.allocator().dupe(u8, buffer[0..name_len]);
            try r.sentences.append(self.arena.allocator(), text);
        }
        r.bundle_offset = try read_u64(input);

        try Resources.registerResource(self, r, null);
    }

    try self.bundle_files.append(self.arena.allocator(), bundle_filename_z);
    return true;
}

fn readResourceSdl(
    gpa: Allocator,
    bundle: *Resources,
    resource: *Resource,
) error{ OutOfMemory, ResourceNotFound, ResourceReadError }![]const u8 {
    if (resource.bundle_offset == null) {
        err("sdl_read_data called on resource that belongs on disk (not in bundle) {s}", .{resource.filename.?});
        return error.ResourceNotFound;
    }
    if (resource.bundle_offset) |bundle_offset| {
        if (bundle.used_resources) |*manifest| {
            try manifest.put(bundle.arena.allocator(), resource.uid, resource);
        }
        return try sdl_load_file_byte_slice(gpa, resource.filename.?, bundle_offset, resource.size);
    }
    return error.ResourceNotFound;
}

fn sdl_load_file_byte_slice(
    gpa: Allocator,
    bundle_filename: []const u8,
    offset: usize,
    size: usize,
) error{ OutOfMemory, ResourceNotFound, ResourceReadError }![]u8 {
    const bundle_filename_z = try gpa.dupeZ(u8, bundle_filename);
    defer gpa.free(bundle_filename_z);

    const in = sdl.SDL_IOFromFile(bundle_filename_z.ptr, "rb");
    if (in == null) {
        err("Open bundle (to read from {d}) failed: {s}", .{ offset, bundle_filename });
        return error.ResourceReadError;
    }
    const input = in.?;
    defer _ = sdl.SDL_CloseIO(input);

    if (sdl.SDL_SeekIO(input, @intCast(offset), sdl.SDL_IO_SEEK_SET) == -1) {
        err("Seek file failed: {s} {d} {d}", .{ bundle_filename, offset, size });
        return error.ResourceReadError;
    }
    const buffer = try gpa.alloc(u8, size);
    errdefer gpa.free(buffer);
    if (sdl.SDL_ReadIO(input, buffer.ptr, buffer.len) == size) {
        return buffer;
    }
    err("SDL ReadIO from bundle file failed: {s}", .{bundle_filename});
    return error.ResourceReadError;
}

inline fn read_u8(i: *sdl.SDL_IOStream) (Resources.Error)!u8 {
    var value: u8 = undefined;
    if (sdl.SDL_ReadU8(i, &value)) {
        return value;
    }
    err("SDL ReadIO from bundle file failed", .{});
    return Resources.Error.ReadRepoFileFailed;
}

inline fn read_u24(i: *sdl.SDL_IOStream) (Resources.Error)!u24 {
    const b1 = try read_u8(i);
    const b2 = try read_u8(i);
    const b3 = try read_u8(i);
    return b1 + (@as(u24, b2) << 8) + (@as(u24, b3) << 16);
}

inline fn read_u32(i: *sdl.SDL_IOStream) (Resources.Error)!u32 {
    var value: u32 = undefined;
    if (sdl.SDL_ReadU32LE(i, &value)) {
        return value;
    }
    err("SDL ReadIO from bundle file failed", .{});
    return Resources.Error.ReadRepoFileFailed;
}

inline fn read_u64(i: *sdl.SDL_IOStream) (Resources.Error)!u64 {
    var value: u64 = undefined;
    if (sdl.SDL_ReadU64LE(i, &value)) {
        return value;
    }
    err("SDL ReadIO from bundle file failed", .{});
    return Resources.Error.ReadRepoFileFailed;
}

inline fn read_slice(
    i: *sdl.SDL_IOStream,
    value: []u8,
) (Resources.Error)!void {
    if (sdl.SDL_ReadIO(i, value.ptr, value.len) == value.len) {
        return;
    }
    err("SDL ReadIO from bundle file failed", .{});
    return Resources.Error.ReadRepoFileFailed;
}

/// Load a preferences data file from the system standard preferences folder.
/// Returns null if the file does not exist. Release the data array after using.
pub fn deletePreferenceData(
    gpa: Allocator,
    config: *const engine.Config,
    filename: []const u8,
) error{OutOfMemory}!void {
    const preference_file = try make_preference_file_path(gpa, config, filename);
    defer gpa.free(preference_file);
    if (!sdl.SDL_GetPathInfo(preference_file.ptr, null)) return;
    _ = sdl.SDL_RemovePath(preference_file.ptr);
}

/// Load a preferences data file from the system standard preferences folder.
/// `filename` is the name of the file without any path information.
/// Returns null if the file does not exist. Release the data array after using.
pub fn loadPreferenceData(
    gpa: Allocator,
    config: *const engine.Config,
    filename: []const u8,
) error{ OutOfMemory, ResourceReadError }!?[]const u8 {
    const name = try make_preference_file_path(gpa, config, filename);
    defer gpa.free(name);

    debug("Loading file: {s}", .{name});
    const data = load_folder_file_bytes(gpa, name) catch |e| {
        if (!sdl.SDL_GetPathInfo(name.ptr, null)) return null;
        warn("Read file failed. {s} {any}", .{ name, e });
        return error.ResourceReadError;
    };
    return data;
}

fn make_preference_file_path(
    gpa: Allocator,
    config: *const engine.Config,
    filename: []const u8,
) error{OutOfMemory}![:0]const u8 {
    const app_org_z = try gpa.dupeZ(u8, config.app_org orelse default_org_name);
    defer gpa.free(app_org_z);
    const app_name_z = try gpa.dupeZ(u8, config.app_name orelse default_app_name);
    defer gpa.free(app_name_z);

    const path = sdl.SDL_GetPrefPath(app_org_z, app_name_z);
    const zpath = std.mem.sliceTo(path, 0);
    //debug("Preferences path: {s} for {s}", .{ zpath, filename });

    var file: std.ArrayListUnmanaged(u8) = .empty;
    defer file.deinit(gpa);

    try file.appendSlice(gpa, zpath);
    if (file.items[file.items.len - 1] != '/' and file.items[file.items.len - 1] != '/')
        try file.append(gpa, guess_separator(zpath));
    try file.appendSlice(gpa, filename);
    return gpa.dupeSentinel(u8, file.items, 0);
}

// `filename` must end with a 0
fn load_folder_file_bytes(
    gpa: Allocator,
    filename: []const u8,
) error{ OutOfMemory, ResourceReadError }!?[]const u8 {
    _ = sdl.SDL_ClearError();
    const in = sdl.SDL_IOFromFile(filename.ptr, "rb");
    if (in == null) {
        if (!sdl.SDL_GetPathInfo(filename.ptr, null)) return null;
        const sdl_error = sdl.SDL_GetError();
        if (sdl_error != null)
            err("Open file '{s}' failed. {s}", .{ filename, sdl_error })
        else
            err("Open file '{s}' failed", .{filename});
        return error.ResourceReadError;
    }
    const input = in.?;
    defer _ = sdl.SDL_CloseIO(input);

    var buffer = std.ArrayListUnmanaged(u8).empty;
    errdefer buffer.deinit(gpa);
    var block: [1024 * 5]u8 = undefined;
    _ = sdl.SDL_ClearError();
    while (true) {
        const l = sdl.SDL_ReadIO(input, &block, block.len);
        if (l > 0) {
            try buffer.appendSlice(gpa, block[0..l]);
            continue;
        }
        const f = sdl.SDL_GetError();
        if (f != null and f[0] != 0) {
            err("SDL ReadIO from file '{s}' failed: {s}", .{ filename, f });
            _ = sdl.SDL_ClearError();
            return error.ResourceReadError;
        }
        break;
    }

    const data = try buffer.toOwnedSlice(gpa);
    return data;
}

/// Output preference data to a file inside the OS's preferenence data folder.
/// First writes data to a temporary file to ensure the data can be completely
/// written, then replaces the data file with the temporary file.
pub fn savePreferenceData(
    gpa: Allocator,
    io: std.Io,
    config: *const engine.Config,
    filename: []const u8,
    data: []const u8,
) error{ ResourceWriteError, OutOfMemory }!void {
    const app_org_z = try gpa.dupeZ(u8, config.app_org orelse default_org_name);
    defer gpa.free(app_org_z);
    const app_name_z = try gpa.dupeZ(u8, config.app_name orelse default_app_name);
    defer gpa.free(app_name_z);

    // SDL auto creates the preferences path if it does not yet exist.
    const path = sdl.SDL_GetPrefPath(app_org_z, app_name_z);
    const zpath = std.mem.sliceTo(path, 0);

    var folder = std.Io.Dir.openDirAbsolute(io, zpath, .{}) catch |e| {
        err("Open preferences folder failed. {t} {s}", .{ e, path });
        return error.ResourceWriteError;
    };

    var temp_filename: [30]u8 = undefined;
    random_string(&temp_filename);

    var file = folder.createFile(io, &temp_filename, .{}) catch |e| {
        err("Create temporary file failed. {t} {s}", .{ e, path });
        return error.ResourceWriteError;
    };
    defer file.close(io);
    file.writeStreamingAll(io, data) catch |e| {
        err("Write temporary failed. {t} {s}", .{ e, path });
        return error.ResourceWriteError;
    };
    trace("Created temporary file: {s}", .{temp_filename});

    folder.rename(&temp_filename, folder, filename, io) catch |f| {
        if (f == error.RenameError) {
            err("Update file failed. {t} (Failed: {s} -> {s})", .{ f, temp_filename, filename });
        }
        return error.ResourceWriteError;
    };
    info("Saved preferences data. (Moved {s} -> {s}{s}", .{
        temp_filename,
        zpath,
        filename,
    });
}

// Fill an array with random alphanumeric characters, A-Z, a-z, 0-9.
pub fn random_string(data: []u8) void {
    for (0..data.len) |i| {
        const x = random(26 + 26 + 10);
        data[i] = switch (x) {
            0...25 => 'a' + @as(u8, @intCast(x)),
            26...51 => 'A' + @as(u8, @intCast(x - 26)),
            else => '0' + @as(u8, @intCast(x - 26 - 26)),
        };
    }
}

test "load_save_preferences" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    seed(io);

    var app_name: [20]u8 = undefined;
    random_string(&app_name);

    const filename = "test_settings.cfg";
    const data = "file\ndata\nWould you like a cup of tea?";

    try deletePreferenceData(gpa, &test_config, filename);
    const none = try loadPreferenceData(gpa, &test_config, filename);
    try expectEqual(null, none);

    try savePreferenceData(gpa, io, &test_config, filename, data);
    const read = try loadPreferenceData(gpa, &test_config, filename);
    try expect(read != null);
    defer gpa.free(read.?);
    try expectEqualStrings(data, read.?);

    const data2 = "file\ndata2";
    try savePreferenceData(gpa, io, &test_config, filename, data2);
    const read2 = try loadPreferenceData(gpa, &test_config, filename);
    try expect(read2 != null);
    defer gpa.free(read2.?);
    try expectEqualStrings(data2, read2.?);

    try deletePreferenceData(gpa, &test_config, filename);
}

const builtin = @import("builtin");

const std = @import("std");
const Allocator = std.mem.Allocator;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

const praxis = @import("praxis");
const BoundedArray = praxis.BoundedArray;
const random = praxis.random.random;
const seed = praxis.random.seed;

const engine = @import("engine.zig");
const sdl = engine.sdl;
const Display = engine.Display;
const log = @import("log.zig");
const err = log.err;
const warn = log.warn;
const info = log.info;
const debug = log.debug;
const trace = log.trace;
const default_app_name = engine.default_app_name;
const default_org_name = engine.default_org_name;

const resources = @import("resources");
const Resources = resources.Resources;
const Resource = resources.Resource;
const Type = resources.Type;

const test_config = @import("test.zig").test_config;
