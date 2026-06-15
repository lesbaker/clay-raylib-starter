const std = @import("std");

const src_files = [_][]const u8{
    "main.c",
};

const ClangdConfig = struct {
    wf_step: *std.Build.Step.WriteFile,
    file: std.Build.LazyPath,
};

const config_template =
    \\CompileFlags:
    \\  Add:
    \\    - -I{s}
    \\
;

const exe_name: []const u8 = "starter";

pub fn create_dot_clangd_config_step(b: *std.Build) *const ClangdConfig {
    const wf_step = b.addWriteFiles();
    const cur_path: []const u8 = std.process.currentPathAlloc(b.graph.io, b.allocator) catch @panic("OOM");
    defer b.allocator.free(cur_path);
    const abs_install_path = b.pathResolve(&.{
        cur_path,
        b.install_path,
    });
    defer b.allocator.free(abs_install_path);

    const clangd_config = b.fmt(config_template, .{abs_install_path});
    const clangd_file = wf_step.add(".clangd", clangd_config);

    return &.{ .wf_step = wf_step, .file = clangd_file };
}

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const raylib_dep = b.dependency("raylib", .{});
    const raylib_lib = raylib_dep.artifact("raylib");
    const clay_dep = b.dependency("clay", .{});

    const copy_h_step = b.step("copy-headers", "Only copy clay and raylib headers to include dir");

    for (raylib_lib.installed_headers.items) |installation| {
        switch (installation) {
            .file => |file| {
                copy_h_step.dependOn(&b.addInstallHeaderFile(file.source, file.dest_rel_path).step);
            },
            .directory => {
                continue;
            },
        }
    }
    copy_h_step.dependOn(&b.addInstallHeaderFile(clay_dep.path("clay.h"), "clay.h").step);

    const clangd_config_step = b.step(
        "create-clangd-dotfile",
        "Generate clangd dotfile to assist compatible code editors",
    );
    // const clangd_file = create_dot_clangd_config_step(b);
    const wf_step = b.addWriteFiles();
    const cur_path: []const u8 = std.process.currentPathAlloc(b.graph.io, b.allocator) catch @panic("OOM");
    defer b.allocator.free(cur_path);
    const abs_install_path = b.pathResolve(&.{
        cur_path,
        b.install_path,
        "include",
    });
    defer b.allocator.free(abs_install_path);

    const clangd_config = b.fmt(config_template, .{abs_install_path});
    const clangd_file = wf_step.add(".clangd", clangd_config);
    const clangd_install_step = b.addInstallFile(clangd_file, ".clangd");

    clangd_config_step.dependOn(&clangd_install_step.step);
    clangd_install_step.step.dependOn(&wf_step.step);

    const hello_mod = b.createModule(.{
        .link_libc = true,
        .target = target,
        .optimize = optimize,
    });

    hello_mod.addCSourceFiles(.{
        .root = b.path("src"),
        .files = &src_files,
    });
    hello_mod.addIncludePath(raylib_lib.getEmittedIncludeTree());
    hello_mod.addIncludePath(clay_dep.path(""));
    hello_mod.linkSystemLibrary("raylib", .{});
    hello_mod.linkSystemLibrary("X11", .{});

    const the_exe = b.addExecutable(.{
        .name = exe_name,
        .root_module = hello_mod,
    });

    b.installArtifact(raylib_lib);
    b.installArtifact(the_exe);
    // const raylib_h_file = b.addInstallFile(raylib_dep.path("src/raylib.h"), "raylib.h");
    // const raymath_h_file = b.addInstallFile(raylib_dep.path("src/raymath.h"), "raymath.h");
    // const rcamera_h_file = b.addInstallFile(raylib_dep.path("src/rcamera.h"), "rcamera.h");
    // const rgestures_h_file = b.addInstallFile(raylib_dep.path("src/rgestures.h"), "rgestures.h");
    // const rlgl_h_file = b.addInstallFile(raylib_dep.path("src/rlgl.h"), "rlgl.h");

    const clay_h_file = b.addInstallHeaderFile(clay_dep.path("clay.h"), "clay.h");

    // b.default_step.dependOn(&raylib_h_file.step);
    // b.default_step.dependOn(&raymath_h_file.step);
    // b.default_step.dependOn(&rcamera_h_file.step);
    // b.default_step.dependOn(&rgestures_h_file.step);
    // b.default_step.dependOn(&rlgl_h_file.step);

    b.default_step.dependOn(&clay_h_file.step);
    b.default_step.dependOn(&the_exe.step);
}
