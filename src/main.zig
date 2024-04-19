const std = @import("std");
const file_io = @import("./file_io.zig");
const Config = @import("./Config.zig");
const Component = @import("./Component.zig");
const test_component = @import("./test_component.zig");
const Yaml = @import("yaml").Yaml;

const log = std.log;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var config = try loadConfig();
    var components = try loadComponents(allocator);
    defer allocator.free(components);

    log.debug("test prop: {d}", .{config.test_prop});

    for (components) |component| {
        if (component.onComponentsReady) |onComponentsReady| {
            onComponentsReady(&component);
        }
    }
}

fn loadConfig() !Config {
    log.debug("Loading config.", .{});

    const path = "./test-config.yaml";
    log.debug("Config path: {s}", .{path});

    const allocator = std.heap.page_allocator;

    const string = try file_io.readFileCompletely(allocator, path);
    defer allocator.free(string);
    log.debug("Read {d} bytes.", .{string.len});

    return try parseConfig(allocator, string);
}

fn parseConfig(allocator: std.mem.Allocator, config_string: []u8) !Config {
    log.debug("Parsing config.", .{});

    var untyped = try Yaml.load(allocator, config_string);
    defer untyped.deinit();

    return try untyped.parse(Config);
}

/// caller owns the memory returned.
fn loadComponents(allocator: std.mem.Allocator) ![]Component {
    log.debug("Loading components.", .{});

    var components = std.ArrayList(Component).init(allocator);

    try components.append(test_component.component);

    return components.toOwnedSlice();
}
