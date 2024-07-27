const std = @import("std");

const ComponentName = @This();

pub const max_len = 62;

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
pub fn from(original_name: []const u8) !ComponentName {
    if (original_name.len > max_len) {
        return error.ComponentNameTooLong;
    }

    var padded: [max_len:0]u8 = undefined;

    @memcpy(padded[0..original_name.len], original_name);
    @memset(padded[original_name.len..], 0);

    return ComponentName{ .data = padded };
}

pub fn slice(this: ComponentName) []const u8 {
    const end = std.mem.indexOfScalar(u8, &this.data, 0) orelse max_len + 1;

    return this.data[0..end];
}

/// gets automatically called by std.fmt functions.
pub fn format(this: ComponentName, comptime _: []const u8, _: std.fmt.FormatOptions, writer: std.io.AnyWriter) !void {
    _ = try writer.write(this.slice());
}
