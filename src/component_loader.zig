const std = @import("std");
const fs = std.fs;
const Yaml = @import("yaml").Yaml;
const file_io = @import("./file_io.zig");
const Component = @import("./Component.zig");
const test_component = @import("./test_component.zig");
const getRealPath = @import("./file_io.zig").getRealPath;

const log = std.log.scoped(.component_loader);

/// caller owns the memory returned.
pub fn loadComponents(allocator: std.mem.Allocator, path: []const u8) ![]Component.Metadata { // TODO: This should return actual Components (populate them by loading the lib file).
    log.debug("Loading components...", .{});
    defer log.debug("Loading components finished.", .{});

    const dir = try fs.cwd().openDir(path, .{ .iterate = true });

    const index_file = try openIndexFile(dir);
    defer index_file.close();
    const index = try loadIndex(allocator, index_file);

    return index.components;
}

fn openIndexFile(dir: fs.Dir) !fs.File {
    return dir.openFile("index.yaml", .{}) catch |err| {
        switch (err) {
            fs.File.OpenError.FileNotFound => log.warn("No components were loaded because no index.yaml was found in {s}.", .{try file_io.getRealPath(dir, ".")}),
            fs.File.OpenError.AccessDenied => log.warn("No components were loaded because '{s}' could not be opened (access denied).", .{try file_io.getRealPath(dir, "index.yaml")}),
            else => log.warn("No components were loaded because '{s}' could not be opened (not sure why).", .{try file_io.getRealPath(dir, "index.yaml")}),
        }

        return err;
    };
}

const Index = struct {
    components: []Component.Metadata,
};

const UnsafeIndex = struct {
    components: []struct {
        abi_version: u8,
        name: []const u8,
    },
};

fn loadIndex(allocator: std.mem.Allocator, file: fs.File) !Index {
    log.debug("Loading index file...", .{});
    defer log.debug("Loading index finished.", .{});

    const string = try file_io.readFileCompletely(allocator, file);
    defer allocator.free(string);

    return try parseIndex(allocator, string);
}

fn parseIndex(allocator: std.mem.Allocator, index_string: []u8) !Index {
    log.debug("Parsing index...", .{});
    defer log.debug("Parsing index finished.", .{});

    var untyped = try Yaml.load(allocator, index_string);
    defer untyped.deinit();

    return try sanitizeIndex(allocator, try untyped.parse(UnsafeIndex));
}

fn sanitizeIndex(allocator: std.mem.Allocator, unsafe_index: UnsafeIndex) !Index {
    log.debug("Sanitizing index...", .{});
    defer log.debug("Sanitizing index finished.", .{});

    var components = std.ArrayList(Component.Metadata).init(allocator);
    defer components.deinit();

    for (unsafe_index.components) |unsafe_component| {
        log.debug("Sanitizing component: {s}", .{unsafe_component.name});

        const component = Component.Metadata{
            .abi_version = unsafe_component.abi_version,
            .name = try Component.name(unsafe_component.name),
        };

        try components.append(component);
    }

    return Index{
        .components = try components.toOwnedSlice(),
    };
}
