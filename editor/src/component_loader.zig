const std = @import("std");
const common = @import("common");
const Yaml = @import("yaml").Yaml;
const io = common.io;
const Component = common.Component;
const getRealPath = io.getRealPath;
const Version = common.Version;
const ComponentName = common.ComponentName;

const log = std.log.scoped(.component_loader);

/// caller owns the memory returned.
pub fn loadComponents(allocator: std.mem.Allocator, path: []const u8) ![]Component {
    log.debug("Loading components...", .{});
    defer log.debug("Loading components finished.", .{});

    const dir = try std.fs.cwd().openDir(path, .{ .iterate = true });

    const index_file = try openIndexFile(dir);
    defer index_file.close();
    const index = try loadIndex(allocator, index_file);

    const components = try loadComponentFiles(allocator, index, dir);

    return components;
}

fn openIndexFile(dir: std.fs.Dir) !std.fs.File {
    return dir.openFile("index.yaml", .{}) catch |err| {
        switch (err) {
            std.fs.File.OpenError.FileNotFound => log.warn("No components were loaded because no index.yaml was found in {s}.", .{try io.getRealPath(dir, ".")}),
            std.fs.File.OpenError.AccessDenied => log.warn("No components were loaded because '{s}' could not be opened (access denied).", .{try io.getRealPath(dir, "index.yaml")}),
            else => log.warn("No components were loaded because '{s}' could not be opened (not sure why).", .{try io.getRealPath(dir, "index.yaml")}),
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

fn loadIndex(allocator: std.mem.Allocator, file: std.fs.File) !Index {
    log.debug("Loading index file...", .{});
    defer log.debug("Loading index finished.", .{});

    const string = try io.readFileCompletely(allocator, file);
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
            .name = try ComponentName.from(config_component.name),
        };

        try component_metadatas.append(component);
    }

    return Index{
        .component_metadata = try component_metadatas.toOwnedSlice(),
    };
}

fn loadComponentFiles(allocator: std.mem.Allocator, index: Index, dir: std.fs.Dir) ![]Component {
    var components = std.ArrayList(Component).init(allocator);
    defer components.deinit();

    for (index.component_metadata) |meta| {
        const path = try dir.realpathAlloc(allocator, meta.name.slice());
        defer allocator.free(path);

        var dynlib = try std.DynLib.open(path);

        const component = dynlib.lookup(*Component, "component") orelse return error.InvalidComponent;

        if (!component.metadata.version.equals(meta.version)) return error.ComponentDiffersFromIndex;

        try components.append(component.*);
    }

    return components.toOwnedSlice();
}
