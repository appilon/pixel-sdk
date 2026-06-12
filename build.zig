const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const module_abi = b.addModule("module_abi", .{
        .root_source_file = b.path("src/module_abi.zig"),
        .target = target,
        .optimize = optimize,
    });
    _ = b.addModule("snapshot_exchange", .{
        .root_source_file = b.path("src/snapshot_exchange.zig"),
        .target = target,
        .optimize = optimize,
    });
    const time = b.addModule("time", .{
        .root_source_file = b.path("src/time.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const module_log = b.addModule("module_log", .{
        .root_source_file = b.path("src/module_log.zig"),
        .target = target,
        .optimize = optimize,
    });
    module_log.addImport("module_abi", module_abi);
    module_log.addImport("time", time);

    const abi_tests = b.addTest(.{
        .root_module = module_abi,
    });
    const snapshot_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/snapshot_exchange.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const time_tests = b.addTest(.{ .root_module = time });
    const module_log_tests = b.addTest(.{ .root_module = module_log });

    const test_step = b.step("test", "Run ABI tests");
    test_step.dependOn(&b.addRunArtifact(abi_tests).step);
    test_step.dependOn(&b.addRunArtifact(snapshot_tests).step);
    test_step.dependOn(&b.addRunArtifact(time_tests).step);
    test_step.dependOn(&b.addRunArtifact(module_log_tests).step);
}
