const std = @import("std");

pub const max_len = 62;

pub const ComponentName = extern struct {
    data: [max_len:0]u8,

    /// pads the given name with 0s to `max_len` characters + sentinel.
    pub fn of(comptime original_name: []const u8) ComponentName {
        if (original_name.len > max_len) @compileError(std.fmt.comptimePrint(
            "ComponentNames cannot be longer than {d} characters + sentinel. This name is {d} characters long + sentinel.",
            .{ max_len, original_name.len },
        ));

        comptime var padded: [max_len:0]u8 = undefined;

        @memcpy(padded[0..original_name.len], original_name);
        @memset(padded[original_name.len..], 0);

        return ComponentName{ .data = padded };
    }

    /// pads the given name with 0s to `max_len` characters + sentinel.
    pub fn from(allocator: std.mem.Allocator, original_name: []const u8) !ComponentName {
        if (original_name.len > max_len) {
            return error.ComponentNameTooLong;
        }

        var name = try allocator.create(ComponentName);

        @memcpy(name.data[0..original_name.len], original_name);
        @memset(name.data[original_name.len..], 0);

        return name.*;
    }

    /// returns the index of the sentinel.
    pub fn length(this: ComponentName) usize {
        return std.mem.indexOfScalar(u8, &this.data, 0) orelse max_len + 1;
    }

    /// gets automatically called by std.fmt functions.
    pub fn format(this: ComponentName, comptime _: []const u8, _: std.fmt.FormatOptions, writer: std.io.AnyWriter) !void {
        try std.fmt.format(writer, "{s}", .{this.data[0..this.length()]});
    }
};
