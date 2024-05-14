const std = @import("std");
const builtin = @import("builtin");

const log = std.log.scoped(.file_io);

pub fn readFileCompletelyFromPath(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    const pwd = std.fs.cwd();

    log.debug("Reading the entirety of file: {s}", .{try getRealPath(pwd, path)});

    const file = try pwd.openFile(path, .{});
    defer file.close();

    return readFileCompletely(allocator, file);
}

pub fn readFileCompletely(allocator: std.mem.Allocator, file: std.fs.File) ![]u8 {
    const content = try file.reader().readAllAlloc(allocator, std.math.maxInt(usize));
    log.debug("Read {d} bytes.", .{content.len});
    return content;
}

pub fn getRealPath(dir: std.fs.Dir, path: []const u8) ![]u8 {
    var buf: [std.fs.MAX_PATH_BYTES]u8 = undefined;

    return try dir.realpath(path, &buf);
}
