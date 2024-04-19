const std = @import("std");
const file_io = @import("./file_io.zig");
const Config = @import("./Config.zig");
const config_loader = @import("./config_loader.zig");
const Component = @import("./Component.zig");
const test_component = @import("./test_component.zig");

const log = std.log;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const config_path = "./test-config.yaml";
    var config = try config_loader.loadConfig(config_path);

    var components = try loadComponents(allocator);
    defer allocator.free(components);

    log.debug("test prop: {d}", .{config.test_prop});

    for (components) |component| {
        if (component.onComponentsReady) |onComponentsReady| {
            onComponentsReady(&component);
        }
    }
}

/// caller owns the memory returned.
fn loadComponents(allocator: std.mem.Allocator) ![]Component {
    log.debug("Loading components.", .{});

    var components = std.ArrayList(Component).init(allocator);

    try components.append(test_component.component);

    return components.toOwnedSlice();
}
