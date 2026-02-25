/// Returns a `Resources` manager with resources preloaded. Checks standard
/// locations for the existence of the `bundle_filename` or falls back to
/// loading resources from the `dev_repo` folder.
///
/// The reason for existence of this function, is that we need to replace
/// the `Resources` load bundle function with a custom function that attempts
/// to use SDL to load resources.
pub fn init_resource_loader(
    allocator: Allocator,
    io: std.Io,
    bundle_filename: ?[]const u8,
    resource_folder: ?[]const u8,
    filename_filter: ?*const fn (name: []const u8, extension: FileType) bool,
) (Allocator.Error || Resources.Error || engine.Error || std.Io.Dir.StatError ||
    std.Io.File.StatError || std.Io.File.OpenError || error{
    ResourceReadError,
    Utf8ExpectedContinuation,
    Utf8OverlongEncoding,
    Utf8EncodesSurrogateHalf,
    Utf8CodepointTooLarge,
    Utf8InvalidStartByte,
})!*Resources {
    const start = std.Io.Timestamp.now(io, .real).toMilliseconds();
    var bundle = try Resources.create(allocator);
    errdefer bundle.destroy();

    var loaded = false;

    if (bundle_filename != null) {
        if (loadBundleSdl(bundle, bundle_filename.?)) |_| {
            const end = std.Io.Timestamp.now(io, .real).toMilliseconds();
            info("Resource list scanned in {d}ms.", .{end - start});
            return bundle;
        } else |e| {
            warn("loadBundleSdl failed. {any}", .{e});
        }

        if (try find_base_folder(allocator, bundle_filename.?)) |base_folder| {
            defer allocator.free(base_folder);
            info("find_base_folder returned: {s}", .{base_folder});

            if (try folder_has_file(base_folder, bundle_filename.?)) {
                loaded = loadBundleSdl(bundle, bundle_filename.?) catch |e| {
                    if (e == error.OutOfMemory) {
                        return error.OutOfMemory;
                    } else {
                        warn("loadBundleSdl failed. {any}", .{e});
                        return e;
                    }
                };
            }
        }
    }

    if (!loaded and resource_folder != null) {
        // Fallback to loading resources from the development resources
        // folder if it is available.
        if (resource_folder.?.len > 0) {
            if (bundle_filename != null and bundle_filename.?.len > 0)
                warn("Fallback to loading repo from folder: {s}", .{resource_folder.?});
            loaded = bundle.loadDirectory(io, resource_folder.?, filename_filter) catch |e| {
                err("error loading repo from {s}. {any}", .{ resource_folder.?, e });
                return e;
            };
        }
    }

    const end = std.Io.Timestamp.now(io, .real).toMilliseconds();
    info("Resource loader setup in {d}ms. loaded={any}", .{ end - start, loaded });
    return bundle;
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
        if (!try folder_has_file(base_path, expected_file)) {
            debug("SDL_GetBasePath(): {s} doesnt contain {s}", .{ base_path, expected_file });
        } else {
            info("Found Base Folder: {s} contains {s}", .{ base_path, expected_file });
            return try allocator.dupe(u8, std.mem.span(sdl_base));
        }
    }

    // First check in the SDL reported current path.
    if (sdl.SDL_GetCurrentDirectory()) |sdl_base| {
        const base_path = std.mem.span(sdl_base);
        if (!try folder_has_file(base_path, expected_file)) {
            debug("SDL_GetCurrentDirectory(): {s} doesnt contain {s}", .{ base_path, expected_file });
        } else {
            info("Found Base Folder: {s} contains {s}", .{ base_path, expected_file });
            return try allocator.dupe(u8, std.mem.span(sdl_base));
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
fn folder_has_file(base_folder: []const u8, expected_file: []const u8) error{ OutOfMemory, ResourceReadError }!bool {
    var path_info: sdl.SDL_PathInfo = undefined;
    var tmp: [1000]u8 = undefined;
    var buffer = std.Io.Writer.fixed(&tmp);
    buffer.writeAll(base_folder) catch return error.ResourceReadError;
    if (!std.mem.endsWith(u8, base_folder, "/") and !std.mem.endsWith(u8, base_folder, "\\")) {
        buffer.writeByte(guess_separator(base_folder)) catch return error.ResourceReadError;
    }
    buffer.writeAll(expected_file) catch return error.ResourceReadError;
    buffer.writeByte(0) catch return error.ResourceReadError;
    if (sdl.SDL_GetPathInfo(buffer.buffer[0..buffer.end].ptr, &path_info)) {
        trace("folder_has_file() check file {s} exists return=true", .{buffer.buffer[0..buffer.end]});
        return true;
    }
    // Either the file doesn't exist or an error occurred
    trace("folder_has_file() check file {s} exists return=false", .{buffer.buffer[0..buffer.end]});
    return false;
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

    const bundle_filename_z = try self.parent_allocator.dupeZ(u8, bundle_filename);
    defer self.parent_allocator.free(bundle_filename_z);

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
            try r.sentences.append(self.arena_allocator, text);
        }
        r.bundle_offset = try read_u64(input);

        try Resources.registerResource(self, r, null);
    }

    self.bundle_file = try self.arena_allocator.dupe(u8, bundle_filename);
    return true;
}

fn readResourceSdl(
    allocator: Allocator,
    bundle: *Resources,
    resource: *Resource,
) error{ OutOfMemory, ResourceNotFound, ResourceReadError }![]const u8 {
    if (resource.filename) |filename| {
        err("sdl_read_data called on resource that belongs on disk (not in bundle) {s}", .{filename});
        return error.ResourceNotFound;
    }
    if (resource.bundle_offset) |bundle_offset| {
        if (bundle.used_resources) |*manifest| {
            try manifest.put(bundle.arena_allocator, resource.uid, resource);
        }
        return try sdl_load_file_byte_slice(allocator, bundle.bundle_file, bundle_offset, resource.size);
    }
    return error.ResourceNotFound;
}

fn sdl_load_file_byte_slice(
    allocator: Allocator,
    bundle_filename: []const u8,
    offset: usize,
    size: usize,
) error{ OutOfMemory, ResourceNotFound, ResourceReadError }![]u8 {
    const bundle_filename_z = try allocator.dupeZ(u8, bundle_filename);
    defer allocator.free(bundle_filename_z);

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
    const buffer = try allocator.alloc(u8, size);
    errdefer allocator.free(buffer);
    if (sdl.SDL_ReadIO(input, buffer.ptr, buffer.len) == size) {
        return buffer;
    }
    err("SDL ReadIO from bundle file failed: {s}", .{bundle_filename});
    return error.ResourceReadError;
}

inline fn read_u8(i: *sdl.SDL_IOStream) error{ReadRepoFileFailed}!u8 {
    var value: u8 = undefined;
    if (sdl.SDL_ReadU8(i, &value)) {
        return value;
    }
    err("SDL ReadIO from bundle file failed", .{});
    return Resources.Error.ReadRepoFileFailed;
}

inline fn read_u24(i: *sdl.SDL_IOStream) error{ReadRepoFileFailed}!u24 {
    const b1 = try read_u8(i);
    const b2 = try read_u8(i);
    const b3 = try read_u8(i);
    return b1 + (@as(u24, b2) << 8) + (@as(u24, b3) << 16);
}

inline fn read_u32(i: *sdl.SDL_IOStream) error{ReadRepoFileFailed}!u32 {
    var value: u32 = undefined;
    if (sdl.SDL_ReadU32LE(i, &value)) {
        return value;
    }
    err("SDL ReadIO from bundle file failed", .{});
    return Resources.Error.ReadRepoFileFailed;
}

inline fn read_u64(i: *sdl.SDL_IOStream) error{ReadRepoFileFailed}!u64 {
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
) error{ReadRepoFileFailed}!void {
    if (sdl.SDL_ReadIO(i, value.ptr, value.len) == value.len) {
        return;
    }
    err("SDL ReadIO from bundle file failed", .{});
    return Resources.Error.ReadRepoFileFailed;
}

/// Load a preferences data file from the system standard preferences folder.
/// Returns null if the file does not exist. Release the data array after using.
pub fn loadPreferenceData(
    gpa: Allocator,
    config: *const engine.Config,
    filename: []const u8,
) error{ OutOfMemory, ResourceReadError }!?[]const u8 {
    const app_org_z = try gpa.dupeZ(u8, config.app_org orelse default_org_name);
    defer gpa.free(app_org_z);
    const app_name_z = try gpa.dupeZ(u8, config.app_name orelse default_app_name);
    defer gpa.free(app_name_z);

    const path = sdl.SDL_GetPrefPath(app_org_z, app_name_z);
    const zpath = std.mem.sliceTo(path, 0);
    info("Preferences path: {s} for {s}", .{ zpath, filename });

    var file: std.ArrayListUnmanaged(u8) = .empty;
    defer file.deinit(gpa);

    try file.appendSlice(gpa, zpath);
    if (file.items[file.items.len - 1] != '/' and file.items[file.items.len - 1] != '/')
        try file.append(gpa, guess_separator(zpath));
    try file.appendSlice(gpa, filename);
    try file.append(gpa, 0);
    const file_z: [*:0]const u8 = file.items[0 .. file.items.len - 1 :0];
    const data = load_folder_file_bytes(gpa, file_z) catch |e| {
        warn("Read preferences file failed. {s} {any}", .{ path, e });
        return error.ResourceReadError;
    };
    trace("read filename={s} returned bytes={d}", .{ filename, data.len });
    return data;
}

// `filename` must end with a 0
fn load_folder_file_bytes(
    gpa: Allocator,
    filename: [*:0]const u8,
) error{ OutOfMemory, ResourceReadError }![]const u8 {
    const in = sdl.SDL_IOFromFile(filename, "rb");
    if (in == null) {
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

    return buffer.toOwnedSlice(gpa);
}

/// Output preference data to a file inside the OS's preferenence data folder.
/// First writes data to a temporary file to ensure the data can be completely
/// written, then replaces the data file with the temporary file.
pub fn save_preference_data(
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
        err("Open preferences path failed. {s} {any}", .{ path, e });
        return error.ResourceWriteError;
    };

    var temp_filename: [30]u8 = undefined;
    random_string(&temp_filename);

    var file = folder.createFile(io, &temp_filename, .{}) catch |e| {
        err("Create temporary preferences file failed. {s} {any}", .{ path, e });
        return error.ResourceWriteError;
    };
    defer file.close(io);
    file.writeStreamingAll(io, data) catch |e| {
        err("Write preferences data failed. {s} {any}", .{ path, e });
        return error.ResourceWriteError;
    };
    debug("Created temporary preferences file: {s}", .{temp_filename});

    folder.rename(&temp_filename, folder, filename, io) catch |f| {
        if (f == error.RenameError) {
            err("Update preferences file '{s}' failed. {any} ({s} -> {s})", .{ filename, f, temp_filename, filename });
        }
        return error.ResourceWriteError;
    };
    info("Saved preferences data. Moved contents from={s} to={s}", .{ temp_filename, filename });
}

/// Remove a preference data file from the standard system preference
/// file location.
pub fn remove_preference_data(
    gpa: Allocator,
    io: std.Io,
    config: *const engine.Config,
    filename: []const u8,
) error{ ResourceDeleteError, OutOfMemory }!void {
    const app_org_z = try gpa.dupeZ(u8, config.app_org orelse default_org_name);
    defer gpa.free(app_org_z);
    const app_name_z = try gpa.dupeZ(u8, config.app_name orelse default_app_name);
    defer gpa.free(app_name_z);

    const path = sdl.SDL_GetPrefPath(app_org_z, app_name_z);
    const zpath = std.mem.sliceTo(path, 0);

    // Check the folder exists
    std.Io.Dir.cwd().access(io, zpath, .{}) catch |f| {
        if (f == error.FileNotFound) return;
        return error.ResourceDeleteError;
    };

    var folder = std.Io.Dir.openDirAbsolute(io, zpath, .{}) catch |e| {
        warn("Open preferences path failed. {s} {any}", .{ path, e });
        return error.ResourceDeleteError;
    };

    // Check the file exists
    folder.access(io, filename, .{}) catch |f| {
        if (f == error.FileNotFound) return;
        return error.ResourceDeleteError;
    };
    folder.deleteFile(io, filename) catch |e| {
        warn("Delete preferences file '{s}' failed. {s} {any}", .{ filename, path, e });
        return error.ResourceDeleteError;
    };
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

    const filename = "settings.cfg";
    const data = "file\ndata";

    try save_preference_data(gpa, io, &test_config, filename, data);
    const read = try loadPreferenceData(gpa, &test_config, filename);
    try expect(read != null);
    defer gpa.free(read.?);
    try expectEqualStrings(data, read.?);

    const data2 = "file\ndata2";
    try save_preference_data(gpa, io, &test_config, filename, data2);
    const read2 = try loadPreferenceData(gpa, &test_config, filename);
    try expect(read2 != null);
    defer gpa.free(read2.?);
    try expectEqualStrings(data2, read2.?);

    try remove_preference_data(gpa, io, &test_config, filename);
}

const std = @import("std");
const expectEqualStrings = std.testing.expectEqualStrings;
const expect = std.testing.expect;

const builtin = @import("builtin");
const sdl = @import("sdl");
const Allocator = std.mem.Allocator;

const praxis = @import("praxis");
const BoundedArray = praxis.BoundedArray;
const random = praxis.random.random;
const seed = praxis.random.seed;

const engine = @import("engine.zig");
const Display = engine.Display;
const err = engine.err;
const warn = engine.warn;
const info = engine.info;
const debug = engine.debug;
const trace = engine.debug;
const default_app_name = engine.default_app_name;
const default_org_name = engine.default_org_name;

const resources = @import("resources");
const encode_uid = resources.encode_uid;
const FileType = resources.FileType;
const Resources = resources.Resources;
const Resource = resources.Resource;
const UniqueWords = resources.UniqueWords;

const test_config = @import("test.zig").test_config;
