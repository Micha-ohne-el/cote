const std = @import("std");
const Version = @import("./Version.zig");

const log = std.log.scoped(.Component);

const name_len = 62;

metadata: Metadata,
onComponentsReady: ?*const fn (self: *const @This()) void = null,

pub const Metadata = struct {
    version: Version,
    min_cote_version: Version,
    max_cote_version: Version,
    name: Name,

    /// gets automatically called by std.fmt functions.
    pub fn format(this: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: std.io.AnyWriter) !void {
        try std.fmt.format(writer, "Component.Metadata \"{s}\" (version {any})", .{ this.name, this.version });
    }
};

pub const Name = [name_len:0]u8;

/// gets automatically called by std.fmt functions.
pub fn format(this: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: std.io.AnyWriter) !void {
    try std.fmt.format(writer, "Component \"{s}\" (version {any})", .{ this.metadata.name, this.metadata.version });
}

/// pads the given name with 0s to `name_len` characters + sentinel.
pub fn nameComptime(comptime original_name: []const u8) Name {
    if (original_name.len > name_len) @compileError(std.fmt.comptimePrint(
        "Names cannot be longer than {} characters + sentinel. This name is {} characters long + sentinel.",
        .{ name_len, original_name.len },
    ));

    comptime var padded: Name = undefined;

    @memcpy(padded[0..original_name.len], original_name);
    @memset(padded[original_name.len..], 0);

    return padded;
}

/// pads the given name with 0s to `name_len` characters + sentinel.
pub fn name(original_name: []const u8) !Name {
    if (original_name.len > name_len) {
        log.err(
            "Names cannot be longer than {} characters + sentinel. This name is {} characters long + sentinel: {s}",
            .{ name_len, original_name.len, original_name },
        );
        return error.NameTooLong;
    }

    var padded: Name = undefined;

    @memcpy(padded[0..original_name.len], original_name);
    @memset(padded[original_name.len..], 0);

    return padded;
}
