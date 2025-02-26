const std = @import("std");
const common = @import("common");
const Yaml = @import("yaml").Yaml;
const ComponentConnection = @import("./ComponentConnection.zig");
const io = common.io;
const Component = common.Component;
const RealPath = io.RealPath;
const Version = common.Version;
const ComponentName = common.ComponentName;

const log = std.log.scoped(.component_loader);

/// caller owns the memory returned.
pub fn loadComponents(allocator: std.mem.Allocator, path: []const u8) ![]ComponentConnection {
    log.debug("Loading components...", .{});
    defer log.debug("Loading components finished.", .{});

    const dir = try std.fs.cwd().openDir(path, .{ .iterate = true });

    const index_file = try openIndexFile(dir);
    defer index_file.close();
    var index = try loadIndex(allocator, index_file);
    defer index.deinit();

    var component_map = try loadComponentFiles(allocator, index, dir);
    defer component_map.deinit();
    var component_iter = component_map.iterator();

    var connections = std.ArrayList(ComponentConnection).init(allocator);
    defer connections.deinit();

    while (component_iter.next()) |entry| {
        const meta = entry.key_ptr.*;
        var connection = entry.value_ptr.*;

        if (!connection.component.metadata.version.equals(meta.version)) {
            log.warn("Component '{s}' will be ignored because it is declared to be version {} but presents as version {}.", .{ meta.name, meta.version, connection.component.metadata.version });
            connection.close();
            continue;
        }

        try connections.append(connection);
    }

    return connections.toOwnedSlice();
}

fn openIndexFile(dir: std.fs.Dir) !std.fs.File {
    return dir.openFile("index.yaml", .{}) catch |err| {
        switch (err) {
            std.fs.File.OpenError.FileNotFound => log.warn("No components were loaded because no index.yaml was found in {s}.", .{RealPath.of(dir, @constCast("."))}),
            std.fs.File.OpenError.AccessDenied => log.warn("No components were loaded because '{s}' could not be opened (access denied).", .{RealPath.of(dir, @constCast("index.yaml"))}),
            else => log.warn("No components were loaded because '{s}' could not be opened (not sure why).", .{RealPath.of(dir, @constCast("index.yaml"))}),
        }

        return err;
    };
}

const Index = struct {
    component_metadatas: std.ArrayList(Component.Metadata),

    pub fn deinit(this: *@This()) void {
        this.component_metadatas.deinit();
    }
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

    for (index_config.components) |config_component| {
        log.debug("Sanitizing component: {s}", .{config_component.name});

        const component = Component.Metadata{
            .version = config_component.version,
            .min_cote_version = config_component.min_cote_version,
            .max_cote_version = config_component.max_cote_version,
            .name = try ComponentName.of(config_component.name),
        };

        try component_metadatas.append(component);

        log.debug("Sanitizing component finished: {}", .{component});
    }

    return Index{
        .component_metadatas = component_metadatas,
    };
}

fn loadComponentFiles(allocator: std.mem.Allocator, index: Index, dir: std.fs.Dir) !std.AutoHashMap(Component.Metadata, ComponentConnection) {
    var components = std.AutoHashMap(Component.Metadata, ComponentConnection).init(allocator);

    for (index.component_metadatas.items) |meta| {
        log.debug("Loading component: {any}", .{meta.name});

        const path = try dir.realpathAlloc(allocator, meta.name.data[0..meta.name.length()]);
        defer allocator.free(path);

        log.debug("Loading component at fully resolved path: {s}", .{path});

        var dynlib = try std.DynLib.open(path);

        const component = dynlib.lookup(*Component, "component") orelse return error.InvalidComponent;

        try components.put(meta, ComponentConnection{
            .component = component.*,
            .dynlib = dynlib,
        });

        log.debug("Loading component finished: {any}", .{component});
    }

    return components;
}
