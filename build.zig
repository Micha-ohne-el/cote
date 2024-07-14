const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const flags = addFlags(b);

    const exe = b.addExecutable(.{
        .name = "cote",
        .root_source_file = b.path("src/main.zig"),
        .target = flags.target,
        .optimize = flags.optimize,
    });

    addDependencies(b, exe, flags);

    b.installArtifact(exe);

    addRunStep(b, exe);

    addTestStep(b, flags);
}

const Flags = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.Mode,
};

fn addFlags(b: *std.Build) Flags {
    return Flags{
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
    };
}

fn addDependencies(b: *std.Build, c: *std.Build.Step.Compile, args: anytype) void {
    const yaml = b.dependency("yaml", args);
    c.root_module.addImport("yaml", yaml.module("yaml"));
}

fn addRunStep(b: *std.Build, c: *std.Build.Step.Compile) void {
    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(c);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

fn addTestStep(b: *std.Build, flags: Flags) void {
    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = flags.target,
        .optimize = flags.optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
