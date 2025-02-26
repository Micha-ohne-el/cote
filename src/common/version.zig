const std = @import("std");

pub const Version = extern struct {
    major: u8,
    minor: u8,
    patch: u8,

    /// comptime version of `parse`.
    /// Always returns a `Version` so that catching is not necessary.
    /// Throws a compile error on failure.
    pub fn of(comptime version_string: []const u8) Version {
        return parse(version_string) catch @compileError("Invalid version string");
    }

    pub fn parse(version_string: []const u8) !Version {
        var it = std.mem.splitScalar(u8, version_string, '.');
        const result = Version{
            .major = parsePart(it.first()) catch return error.MajorVersionInvalid,
            .minor = parsePart(it.next() orelse return error.MinorVersionMissing) catch return error.MinorVersionInvalid,
            .patch = parsePart(it.next() orelse return error.PatchVersionMissing) catch return error.PatchVersionInvalid,
        };

        if (it.next() != null) return error.TooManyVersionParts;

        return result;
    }

    /// gets automatically called by std.fmt functions.
    pub fn format(this: Version, comptime _: []const u8, _: std.fmt.FormatOptions, writer: std.io.AnyWriter) !void {
        try std.fmt.format(writer, "{d}.{d}.{d}", .{ this.major, this.minor, this.patch });
    }

    pub fn equals(this: Version, other: Version) bool {
        return this.major == other.major and this.minor == other.minor and this.patch == other.patch;
    }

    pub fn isGreater(this: Version, other: Version) bool {
        if (this.major > other.major) return true;
        if (this.major < other.major) return false;

        if (this.minor > other.minor) return true;
        if (this.minor < other.minor) return false;

        if (this.patch > other.patch) return true;
        if (this.patch < other.patch) return false;

        return false;
    }

    pub fn isLess(this: Version, other: Version) bool {
        if (this.major < other.major) return true;
        if (this.major > other.major) return false;

        if (this.minor < other.minor) return true;
        if (this.minor > other.minor) return false;

        if (this.patch < other.patch) return true;
        if (this.patch > other.patch) return false;

        return false;
    }

    pub fn isGreaterOrEqual(this: Version, other: Version) bool {
        return this.isGreater(other) or this.equals(other);
    }

    pub fn isLessOrEqual(this: Version, other: Version) bool {
        return this.isLess(other) or this.equals(other);
    }

    pub fn isIn(this: Version, min: Version, max: Version) bool {
        return this.isGreaterOrEqual(min) and this.isLessOrEqual(max);
    }
};

fn parsePart(part: []const u8) !u8 {
    return std.fmt.parseUnsigned(u8, part, 10) catch |err| switch (err) {
        error.InvalidCharacter => return error.InvalidVersion,
        error.Overflow => return error.InvalidVersion,
        else => return err,
    };
}

test "parse" {
    const v1 = try Version.parse("0.0.0");
    try std.testing.expectEqual(0, v1.major);
    try std.testing.expectEqual(0, v1.minor);
    try std.testing.expectEqual(0, v1.patch);

    const v2 = try Version.parse("1.2.3");
    try std.testing.expectEqual(1, v2.major);
    try std.testing.expectEqual(2, v2.minor);
    try std.testing.expectEqual(3, v2.patch);

    const v3 = try Version.parse("012.123.234");
    try std.testing.expectEqual(12, v3.major);
    try std.testing.expectEqual(123, v3.minor);
    try std.testing.expectEqual(234, v3.patch);

    try std.testing.expectEqual(error.MinorVersionMissing, Version.parse("1"));
    try std.testing.expectEqual(error.PatchVersionMissing, Version.parse("1.2"));
    try std.testing.expectEqual(error.TooManyVersionParts, Version.parse("1.2.3.4"));
    try std.testing.expectEqual(error.MajorVersionInvalid, Version.parse(".2.3"));
    try std.testing.expectEqual(error.MinorVersionInvalid, Version.parse("1..3"));
    try std.testing.expectEqual(error.PatchVersionInvalid, Version.parse("1.2."));
    try std.testing.expectEqual(error.TooManyVersionParts, Version.parse("1.2.3."));
    try std.testing.expectEqual(error.MajorVersionInvalid, Version.parse("v1.2.3"));
    try std.testing.expectEqual(error.PatchVersionInvalid, Version.parse("1.2.3-alpha"));
    try std.testing.expectEqual(error.PatchVersionInvalid, Version.parse("1.2.999"));
    try std.testing.expectEqual(error.PatchVersionInvalid, Version.parse("1.2.-3"));
    try std.testing.expectEqual(error.PatchVersionInvalid, Version.parse("1.2.+3"));
    try std.testing.expectEqual(error.MajorVersionInvalid, Version.parse(" 1.2.3"));
    try std.testing.expectEqual(error.PatchVersionInvalid, Version.parse("1.2.3 "));
}

test "of" {
    comptime {
        const v1 = Version.of("0.0.0");
        try std.testing.expectEqual(0, v1.major);
        try std.testing.expectEqual(0, v1.minor);
        try std.testing.expectEqual(0, v1.patch);

        const v2 = Version.of("1.2.3");
        try std.testing.expectEqual(1, v2.major);
        try std.testing.expectEqual(2, v2.minor);
        try std.testing.expectEqual(3, v2.patch);

        const v3 = Version.of("012.123.234");
        try std.testing.expectEqual(12, v3.major);
        try std.testing.expectEqual(123, v3.minor);
        try std.testing.expectEqual(234, v3.patch);
    }
}

test "equals" {
    const v1 = try Version.parse("0.0.0");
    const v2 = try Version.parse("255.255.255");
    const v3 = try Version.parse("1.2.3");
    const v4 = try Version.parse("1.2.4");
    const v5 = try Version.parse("1.3.3");
    const v6 = try Version.parse("2.2.3");

    try std.testing.expect(v1.equals(Version{ .major = 0, .minor = 0, .patch = 0 }));
    try std.testing.expect(v2.equals(Version{ .major = 255, .minor = 255, .patch = 255 }));
    try std.testing.expect(v3.equals(Version{ .major = 1, .minor = 2, .patch = 3 }));
    try std.testing.expect(v4.equals(Version{ .major = 1, .minor = 2, .patch = 4 }));
    try std.testing.expect(v5.equals(Version{ .major = 1, .minor = 3, .patch = 3 }));
    try std.testing.expect(v6.equals(Version{ .major = 2, .minor = 2, .patch = 3 }));

    // cross-testing all six versions against each other:
    const vs = [_]*const Version{ &v1, &v2, &v3, &v4, &v5, &v6 };
    for (vs) |va| {
        for (vs) |vb| {
            if (va == vb) {
                try std.testing.expect(va.equals(vb.*));
                try std.testing.expect(vb.equals(va.*));
            } else {
                try std.testing.expect(!va.equals(vb.*));
                try std.testing.expect(!vb.equals(va.*));
            }
        }
    }
}

test "isGreater" {
    const v = try Version.parse("5.5.5");

    try std.testing.expect(v.isGreater(try Version.parse("5.5.4")));
    try std.testing.expect(v.isGreater(try Version.parse("5.4.6")));
    try std.testing.expect(v.isGreater(try Version.parse("4.6.6")));

    try std.testing.expect(!v.isGreater(try Version.parse("5.5.5")));
}

test "isLess" {
    const v = try Version.parse("5.5.5");

    try std.testing.expect(v.isLess(try Version.parse("5.5.6")));
    try std.testing.expect(v.isLess(try Version.parse("5.6.4")));
    try std.testing.expect(v.isLess(try Version.parse("6.4.4")));

    try std.testing.expect(!v.isLess(try Version.parse("5.5.5")));
}

test "isGreaterOrEqual" {
    const v = try Version.parse("5.5.5");

    try std.testing.expect(v.isGreaterOrEqual(try Version.parse("5.5.4")));
    try std.testing.expect(v.isGreaterOrEqual(try Version.parse("5.4.6")));
    try std.testing.expect(v.isGreaterOrEqual(try Version.parse("4.6.6")));

    try std.testing.expect(v.isGreaterOrEqual(try Version.parse("5.5.5")));
}

test "isLessOrEqual" {
    const v = try Version.parse("5.5.5");

    try std.testing.expect(v.isLessOrEqual(try Version.parse("5.5.6")));
    try std.testing.expect(v.isLessOrEqual(try Version.parse("5.6.4")));
    try std.testing.expect(v.isLessOrEqual(try Version.parse("6.4.4")));

    try std.testing.expect(v.isLessOrEqual(try Version.parse("5.5.5")));
}
