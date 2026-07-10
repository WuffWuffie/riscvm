const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_target = b.resolveTargetQuery(.{
        .cpu_arch = .riscv64,
        .os_tag = .linux,
        .cpu_model = .{ .explicit = &std.Target.riscv.cpu.generic_rv64 },
        .cpu_features_add = std.Target.riscv.featureSet(&.{ .unaligned_scalar_mem, .d, .m }),
        .abi = .musl,
    });
    const lib_optimize: std.builtin.OptimizeMode = .ReleaseSmall;

    const lib = b.addLibrary(.{
        .linkage = .dynamic,
        .name = "tst",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/tst.zig"),
            .target = lib_target,
            .optimize = lib_optimize,
            .strip = true,
            .single_threaded = true,
            .omit_frame_pointer = true,
        }),
    });

    // lib.lto = .full;

    // lib.bundle_ubsan_rt = false;
    // lib.bundle_compiler_rt = true;

    b.installArtifact(lib);

    const exe = b.addExecutable(.{
        .name = "riscvm2",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // exe.lto = .full;

    // exe.root_module.addAnonymousImport("program", .{ .root_source_file = test_lib });

    // b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.addPassthruArgs();

    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());
}
