const std = @import("std");

pub fn build(b: *std.Build) void {
    // const target = b.standardTargetOptions(.{});
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .riscv64,
        .cpu_model = .{
            .explicit = &std.Target.riscv.cpu.generic,
        },
        .cpu_features_add = std.Target.riscv.featureSet(&.{
            .@"64bit",
            .i,
            .m,
            .f,
            .d,
        }),
    });
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addLibrary(.{
        .linkage = .dynamic,
        .name = "tst",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .strip = true,
            // .pic = true,
        }),
    });
    // const exe = b.addExecutable(.{
    //     .name = "tst",
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("src/main.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //     }),
    // });

    // exe.rdynamic = true;
    exe.want_lto = true;
    // exe.pie = true;
    // exe.entry = .disabled;

    b.installArtifact(exe);

    b.getInstallStep().dependOn(&b.addInstallFile(exe.getEmittedAsm(), "test.asm").step);
}
