const std = @import("std");
const fs = std.fs;
const Component = @import("./Component.zig");
const test_component = @import("./test_component.zig");
const getRealPath = @import("./file_io.zig").getRealPath;

const log = std.log.scoped(.component_loader);

const paths = [_][]const u8{
    "./components",
};

/// caller owns the memory returned.
pub fn loadComponents(allocator: std.mem.Allocator) ![]Component {
    log.debug("Loading components...", .{});
    defer log.debug("Loading components finished.", .{});

    const files = try findPotentialComponents(allocator);
    defer allocator.free(files);

    // TODO: go through files, try to open them as DynLib.
    // If it fails, log.info("hey dude please only have dynlibs in your component dirs.")
    // If it succeeds, try to get the component out of it.

    log.debug("{any}", .{files});

    return &[0]Component{};
}

/// caller owns the memory returned.
fn findPotentialComponents(allocator: std.mem.Allocator) ![]fs.File {
    var files = std.ArrayList(fs.File).init(allocator);

    for (paths) |path| {
        const components_dir = fs.cwd().openIterableDir(path, .{}) catch |err| switch (err) {
            fs.Dir.OpenError.FileNotFound => {
                log.debug("Skipping path '{s}' because it doesn't exist.", .{path});
                continue;
            },
            fs.Dir.OpenError.NotDir => {
                log.debug("Skipping path '{s}' because it's not a directory.", .{path});
                continue;
            },
            else => return err,
        };

        try findPotentialComponentsInDir(&files, components_dir);
    }

    return files.toOwnedSlice();
}

fn findPotentialComponentsInDir(array_list: *std.ArrayList(fs.File), dir: fs.IterableDir) !void {
    log.debug("Searching for components in '{s}'...", .{try getRealPath(dir.dir, ".")});
    var iterator = dir.iterate();

    while (true) {
        const entry: fs.IterableDir.Entry = try iterator.next() orelse break;

        log.debug("Found file '{s}'.", .{entry.name});

        try array_list.append(try dir.dir.openFile(entry.name, .{}));
    }
}
