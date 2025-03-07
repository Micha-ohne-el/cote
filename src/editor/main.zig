const std = @import("std");
const builtin = @import("builtin");
const common = @import("common");
const io = common.io;
const Config = common.Config;
const Component = common.Component;
const config_loader = @import("./config_loader.zig");
const component_loader = @import("./component_loader.zig");

const log = std.log;

pub const std_options = std.Options{
    .fmt_max_depth = 20,
    .log_level = switch (builtin.mode) {
        .Debug => .debug,
        .ReleaseSafe => .info,
        .ReleaseFast, .ReleaseSmall => .warn,
    },
    .log_scope_levels = &[_]std.log.ScopeLevel{
        // zig-yaml logs:
        .{ .scope = .parse, .level = .info },
        .{ .scope = .tokenizer, .level = .info },
    },
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer log.debug("gpa.deinit() => {s}", .{@tagName(gpa.deinit())});
    const allocator = gpa.allocator();

    const config_path = ".test/test-config.yaml";
    const config = try config_loader.loadConfig(allocator, config_path);

    const components_path = ".test/components";
    const components = try component_loader.loadComponents(allocator, components_path);
    defer allocator.free(components);

    log.info("Cote is running with {d} component(s) loaded.", .{components.len});

    log.debug("test prop: {d}", .{config.test_prop});

    for (components) |component| {
        log.info("Loaded component: {any}", .{component.component});

        //if (component.onComponentsReady) |onComponentsReady| {
        //    onComponentsReady(&component);
        //}
    }
}
