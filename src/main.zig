const std = @import("std");
const file_io = @import("./file_io.zig");
const Config = @import("./Config.zig");
const config_loader = @import("./config_loader.zig");
const Component = @import("./Component.zig");
const component_loader = @import("./component_loader.zig");

const log = std.log;

pub const std_options = std.Options{
    .fmt_max_depth = 20,
    .log_scope_levels = &[_]std.log.ScopeLevel{
        .{ .scope = .parse, .level = .info },
        .{ .scope = .tokenizer, .level = .info },
    },
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const config_path = "./test-config.yaml";
    const config = try config_loader.loadConfig(allocator, config_path);

    const components_path = "./components";
    const components = try component_loader.loadComponents(allocator, components_path);
    defer allocator.free(components);

    log.debug("test prop: {d}", .{config.test_prop});

    for (components) |component| {
        log.info("Loaded component: {any}", .{component});

        //if (component.onComponentsReady) |onComponentsReady| {
        //    onComponentsReady(&component);
        //}
    }
}
