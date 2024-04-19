const std = @import("std");

abi_version: u8,
name: *const [63:0]u8,
onComponentsReady: ?*const fn (self: *const @This()) void = null,

/// pads the given name to 63 characters + sentinel.
pub fn name(comptime original_name: [:0]const u8) *const [63:0]u8 {
    if (original_name.len > 63) @compileError(std.fmt.comptimePrint(
        "Names cannot be longer than 63 characters + sentinel. This name is {} characters long + sentinel.",
        .{original_name.len},
    ));

    return original_name ++ [_]u8{0} ** (63 - original_name.len);
}
