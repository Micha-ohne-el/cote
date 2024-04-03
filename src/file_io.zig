const std = @import("std");

pub fn readFileCompletely(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    const pwd = std.fs.cwd();
    const file = try pwd.openFile(path, .{});
    defer file.close();

    return file.reader().readAllAlloc(allocator, std.math.maxInt(usize));
}
