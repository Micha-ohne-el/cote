const std = @import("std");
const Component = @import("./Component.zig");
const test_component = @import("./test_component.zig");

const log = std.log.scoped(.component_loader);

/// caller owns the memory returned.
pub fn loadComponents(allocator: std.mem.Allocator) ![]Component {
    log.debug("Loading components...", .{});
    defer log.debug("Loading components finished.", .{});

    var components = std.ArrayList(Component).init(allocator);

    try components.append(test_component.component);

    return components.toOwnedSlice();
}
