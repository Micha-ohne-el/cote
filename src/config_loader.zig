const std = @import("std");
const Yaml = @import("yaml").Yaml;
const Config = @import("./Config.zig");
const file_io = @import("./file_io.zig");

const log = std.log.scoped(.config_loader);

pub fn loadConfig(allocator: std.mem.Allocator, path: []const u8) !Config {
    log.debug("Loading config...", .{});
    defer log.debug("Loading config finshed.", .{});
    log.debug("Config path: {s}", .{path});

    const string = try file_io.readFileCompletelyFromPath(allocator, path);
    defer allocator.free(string);

    return try parse(allocator, string);
}

fn parse(allocator: std.mem.Allocator, config_string: []u8) !Config {
    log.debug("Parsing config...", .{});
    defer log.debug("Parsing config finished.", .{});

    var untyped = try Yaml.load(allocator, config_string);
    defer untyped.deinit();

    return try untyped.parse(Config);
}
