const std = @import("std");

const name_len = 62;

abi_version: u8,
name: [name_len:0]u8,
onComponentsReady: ?*const fn (self: *const @This()) void = null,

/// pads the given name with 0s to `name_len` characters + sentinel.
pub fn name(comptime original_name: [:0]const u8) [name_len:0]u8 {
    if (original_name.len > name_len) @compileError(std.fmt.comptimePrint(
        "Names cannot be longer than {} characters + sentinel. This name is {} characters long + sentinel.",
        .{ name_len, original_name.len },
    ));

    comptime var padded: [name_len:0]u8 = undefined;

    @memcpy(padded[0..original_name.len], original_name);
    @memset(padded[original_name.len..], 0);

    return padded;
}
