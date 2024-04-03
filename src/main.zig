const std = @import("std");
const file_io = @import("./file_io.zig");
const Config = @import("./Config.zig");
const Yaml = @import("yaml").Yaml;

pub fn main() !void {
    var config = try loadConfig();

    std.debug.print("{d}", .{config.test_prop});
}

fn loadConfig() !Config {
    const path = "./test-config.yaml";
    const allocator = std.heap.page_allocator;

    const string = try file_io.readFileCompletely(allocator, path);
    defer allocator.free(string);

    return try parseConfig(allocator, string);
}

fn parseConfig(allocator: std.mem.Allocator, config_string: []u8) !Config {
    var untyped = try Yaml.load(allocator, config_string);
    defer untyped.deinit();

    return try untyped.parse(Config);
}
