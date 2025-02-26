const std = @import("std");
const builtin = @import("builtin");

const log = std.log.scoped(.io);

pub fn readFileCompletelyFromPath(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    const pwd = std.fs.cwd();

    log.debug("Reading the entirety of file: {s}", .{RealPath.of(pwd, @constCast(path))});

    const file = try pwd.openFile(path, .{});
    defer file.close();

    return readFileCompletely(allocator, file);
}

pub fn readFileCompletely(allocator: std.mem.Allocator, file: std.fs.File) ![]u8 {
    const content = try file.reader().readAllAlloc(allocator, std.math.maxInt(usize));
    log.debug("Read {d} bytes.", .{content.len});
    return content;
}

/// this entire struct literally only exists so we can print fully resolved paths easily.
pub const RealPath = struct {
    dir: std.fs.Dir,
    path: []u8,

    pub fn of(dir: std.fs.Dir, path: []u8) RealPath {
        return RealPath{
            .dir = dir,
            .path = path,
        };
    }

    /// gets automatically called by std.fmt functions.
    pub fn format(this: RealPath, comptime _: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) !void {
        var buf: [256]u8 = undefined;
        try std.fmt.formatBuf(try this.dir.realpath(this.path, &buf), options, writer);
    }
};
