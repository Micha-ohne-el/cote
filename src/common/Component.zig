const std = @import("std");
const Version = @import("./Version.zig");
const ComponentName = @import("./ComponentName.zig");

const log = std.log.scoped(.Component);

const name_len = 62;

metadata: Metadata,
onComponentsReady: ?*const fn (self: *const @This()) void = null,

pub const Metadata = struct {
    version: Version,
    min_cote_version: Version,
    max_cote_version: Version,
    name: ComponentName,

    /// gets automatically called by std.fmt functions.
    pub fn format(this: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: std.io.AnyWriter) !void {
        try std.fmt.format(writer, "Component.Metadata \"{any}\" (version {any})", .{ this.name, this.version });
    }
};

/// gets automatically called by std.fmt functions.
pub fn format(this: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: std.io.AnyWriter) !void {
    try std.fmt.format(writer, "Component \"{any}\" (version {any})", .{ this.metadata.name, this.metadata.version });
}
