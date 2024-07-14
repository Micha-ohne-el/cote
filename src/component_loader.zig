const std = @import("std");
const fs = std.fs;
const Yaml = @import("yaml").Yaml;
const file_io = @import("./file_io.zig");
const Component = @import("./Component.zig");
const test_component = @import("./test_component.zig");
const getRealPath = @import("./file_io.zig").getRealPath;
const Version = @import("./Version.zig");

const log = std.log.scoped(.component_loader);

/// caller owns the memory returned.
pub fn loadComponents(allocator: std.mem.Allocator, path: []const u8) ![]Component.Metadata { // TODO: This should return actual Components (populate them by loading the lib file).
    log.debug("Loading components...", .{});
    defer log.debug("Loading components finished.", .{});

    const dir = try fs.cwd().openDir(path, .{ .iterate = true });

    const index_file = try openIndexFile(dir);
    defer index_file.close();
    const index = try loadIndex(allocator, index_file);

    return index.component_metadata;
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
    component_metadata: []Component.Metadata,
};

const IndexConfig = struct {
    components: []struct {
        version: Version,
        min_cote_version: Version,
        max_cote_version: Version,
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

    return try sanitizeIndex(allocator, try untyped.parse(IndexConfig));
}

fn sanitizeIndex(allocator: std.mem.Allocator, index_config: IndexConfig) !Index {
    log.debug("Sanitizing index...", .{});
    defer log.debug("Sanitizing index finished.", .{});

    var component_metadatas = std.ArrayList(Component.Metadata).init(allocator);
    defer component_metadatas.deinit();

    for (index_config.components) |config_component| {
        log.debug("Sanitizing component: {s}", .{config_component.name});

        const component = Component.Metadata{
            .version = config_component.version,
            .min_cote_version = config_component.min_cote_version,
            .max_cote_version = config_component.max_cote_version,
            .name = try Component.name(config_component.name),
        };

        try component_metadatas.append(component);
    }

    return Index{
        .component_metadata = try component_metadatas.toOwnedSlice(),
    };
}
