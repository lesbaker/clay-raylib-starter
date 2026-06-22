const std = @import("std");

const src_files = [_][]const u8{
    "main.c",
};

const ClangdConfig = struct {
    wf_step: *std.Build.Step.WriteFile,
    file: std.Build.LazyPath,
};

const exe_name: []const u8 = "starter";

pub fn create_dot_clangd_config_file_contents(b: *std.Build) []const u8 {
    const config_template =
        \\CompileFlags:
        \\  Add:
        \\    - -I{s}
        \\
    ;
    const cur_path: []const u8 = std.process.currentPathAlloc(b.graph.io, b.allocator) catch @panic("OOM");
    defer b.allocator.free(cur_path);
    const abs_install_path = b.pathResolve(&.{
        cur_path,
        b.install_path,
        "include",
    });
    defer b.allocator.free(abs_install_path);

    return b.fmt(config_template, .{abs_install_path});
}

fn init_exe_mod(exe_mod: *std.Build.Module, b: *std.Build) *std.Build.Module {
    const raylib_dep = b.dependency("raylib", .{});
    const raylib_lib = raylib_dep.artifact("raylib");
    const clay_dep = b.dependency("clay", .{});

    exe_mod.addCSourceFiles(.{
        .root = b.path("src"),
        .files = &src_files,
    });
    exe_mod.addIncludePath(raylib_lib.getEmittedIncludeTree());
    exe_mod.addIncludePath(clay_dep.path(""));
    exe_mod.linkSystemLibrary("raylib", .{});
    exe_mod.linkSystemLibrary("X11", .{});

    return exe_mod;
}

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const c_lang_mod_create_opts: std.Build.Module.CreateOptions = .{
        .link_libc = true,
        .target = target,
        .optimize = optimize,
    };

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
    const wf_step = b.addWriteFiles();
    const clangd_install_step = b.addInstallFile(
        wf_step.add(
            ".clangd",
            create_dot_clangd_config_file_contents(b),
        ),
        ".clangd",
    );

    clangd_config_step.dependOn(&clangd_install_step.step);
    clangd_install_step.step.dependOn(&wf_step.step);

    const the_exe = b.addExecutable(.{
        .name = exe_name,
        .root_module = init_exe_mod(b.createModule(c_lang_mod_create_opts), b),
    });

    b.installArtifact(raylib_lib);
    b.installArtifact(the_exe);

    const clay_h_file = b.addInstallHeaderFile(clay_dep.path("clay.h"), "clay.h");

    b.default_step.dependOn(&clay_h_file.step);
    b.default_step.dependOn(&the_exe.step);
}
