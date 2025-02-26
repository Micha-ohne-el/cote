pub const Component = @import("./component.zig").Component;
pub const ComponentName = @import("./component_name.zig").ComponentName;
pub const Config = @import("./Config.zig");
pub const io = @import("io.zig");
pub const Version = @import("./version.zig").Version;

test {
    _ = Component;
    _ = ComponentName;
    _ = Config;
    _ = io;
    _ = Version;
}
