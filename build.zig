const std = @import("std");

pub fn build(b: *std.Build) void {
    const options = BuildOptions{
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
    };

    const deps = addDependencies(b, options);

    const common = addCommon(b, options);
    const editor = addEditor(b, options);

    editor.root_module.addImport("common", common);
    editor.root_module.addImport("yaml", deps.yaml.module("yaml"));

    const all_tests = b.step("test-all", "Test all modules");
    all_tests.dependencies.appendSlice(&[2]*std.Build.Step{
        addTestStep(b, "common", common),
        addTestStep(b, "editor", &editor.root_module),
    }) catch @panic("OOM");

    _ = addRunStep(b, "editor", editor);
}

const BuildOptions = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
};

const Dependencies = struct {
    yaml: *std.Build.Dependency,
};

fn addDependencies(b: *std.Build, options: BuildOptions) Dependencies {
    return Dependencies{
        .yaml = b.dependency("yaml", options),
    };
}

fn addCommon(b: *std.Build, options: BuildOptions) *std.Build.Module {
    return b.addModule("common", .{
        .root_source_file = b.path("src/common/root.zig"),
        .target = options.target,
        .optimize = options.optimize,
    });
}

fn addEditor(b: *std.Build, options: BuildOptions) *std.Build.Step.Compile {
    const compile = b.addExecutable(.{
        .name = "cote",
        .root_source_file = b.path("src/editor/main.zig"),
        .target = options.target,
        .optimize = options.optimize,
    });

    b.installArtifact(compile);

    return compile;
}

fn addTestStep(b: *std.Build, comptime name: []const u8, module: *std.Build.Module) *std.Build.Step {
    const compile = b.addTest(.{
        .name = "test-" ++ name,
        .root_source_file = module.root_source_file.?,
        .target = module.resolved_target,
        .optimize = module.optimize.?,
    });

    b.installArtifact(compile);

    const run = b.addRunArtifact(compile);

    const step = b.step("test-" ++ name, "Run tests for module " ++ name);

    step.dependOn(&run.step);

    return step;
}

fn addRunStep(b: *std.Build, comptime name: []const u8, compile: *std.Build.Step.Compile) *std.Build.Step {
    const run = b.addRunArtifact(compile);
    run.step.dependOn(b.getInstallStep());

    if (b.args) |args| run.addArgs(args);

    const step = b.step("run-" ++ name, "Run module " ++ name);
    step.dependOn(&run.step);

    return step;
}
