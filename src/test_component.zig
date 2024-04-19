const std = @import("std");
const Component = @import("./Component.zig");

const log = std.log.scoped(.test_component);

pub const component = Component{
    .abi_version = 1,
    .name = Component.name("test component"),
    .onComponentsReady = onComponentsReady,
};

fn onComponentsReady(self: *const Component) void {
    log.info("hello from {s}", .{self.name});
}
