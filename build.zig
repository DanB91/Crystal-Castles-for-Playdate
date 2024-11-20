const std = @import("std");

const os_tag = @import("builtin").os.tag;

const name = "Crystal Castles";
pub fn build(b: *std.Build) !void {
    const pdx_file_name = name ++ ".pdx";

    const toolbox_module = b.addModule("toolbox", .{
        .root_source_file = b.path("src/toolbox/src/toolbox.zig"),
    });
    const build_number = try get_and_increment_build_number(b);

    const build_info_options = b.addOptions();
    build_info_options.addOption(isize, "BUILD_NUMBER", build_number);
    const build_info_module = build_info_options.createModule();

    const optimize = b.standardOptimizeOption(.{});

    const writer = b.addWriteFiles();
    const source_dir = writer.getDirectory();
    writer.step.name = "write source directory";

    const levels_data_module = b.addModule("levels.bin", .{
        .root_source_file = b.path("assets/levels.bin"),
    });

    const lib = b.addSharedLibrary(.{
        .name = "pdex",
        .root_source_file = b.path("src/main.zig"),
        .optimize = optimize,
        .target = b.host,
    });
    lib.root_module.addImport("toolbox", toolbox_module);
    lib.root_module.addImport("build_info", build_info_module);
    lib.root_module.addImport("levels.bin", levels_data_module);
    _ = writer.addCopyFile(lib.getEmittedBin(), "pdex" ++ switch (os_tag) {
        .windows => ".dll",
        .macos => ".dylib",
        .linux => ".so",
        else => @panic("Unsupported OS"),
    });

    const playdate_target = b.resolveTargetQuery(try std.Target.Query.parse(.{
        .arch_os_abi = "thumb-freestanding-eabihf",
        .cpu_features = "cortex_m7+vfp4d16sp",
    }));
    const elf = b.addExecutable(.{
        .name = "pdex.elf",
        .root_source_file = b.path("src/main.zig"),
        .target = playdate_target,
        .optimize = optimize,
        .pic = true,
    });
    elf.link_emit_relocs = true;
    elf.entry = .{ .symbol_name = "eventHandler" };

    elf.setLinkerScriptPath(b.path("link_map.ld"));
    if (optimize == .ReleaseFast) {
        elf.root_module.omit_frame_pointer = true;
    }
    elf.root_module.addImport("toolbox", toolbox_module);
    elf.root_module.addImport("build_info", build_info_module);
    elf.root_module.addImport("levels.bin", levels_data_module);
    elf.root_module.single_threaded = true;

    _ = writer.addCopyFile(elf.getEmittedBin(), "pdex.elf");

    try addCopyDirectory(writer, "assets", "./assets");

    const playdate_sdk_path = try std.process.getEnvVarOwned(b.allocator, "PLAYDATE_SDK_PATH");
    const pdc_path = b.pathJoin(&.{ playdate_sdk_path, "bin", if (os_tag == .windows) "pdc.exe" else "pdc" });
    const pd_simulator_path = switch (os_tag) {
        .linux => b.pathJoin(&.{ playdate_sdk_path, "bin", "PlaydateSimulator" }),
        .macos => "open", // `open` focuses the window, while running the simulator directry doesn't.
        .windows => b.pathJoin(&.{ playdate_sdk_path, "bin", "PlaydateSimulator.exe" }),
        else => @panic("Unsupported OS"),
    };

    const pdc = b.addSystemCommand(&.{pdc_path});
    pdc.addDirectorySourceArg(source_dir);
    pdc.setName("pdc");
    const pdx = pdc.addOutputFileArg(pdx_file_name);

    b.installDirectory(.{
        .source_dir = pdx,
        .install_dir = .prefix,
        .install_subdir = pdx_file_name,
    });
    b.installDirectory(.{
        .source_dir = source_dir,
        .install_dir = .prefix,
        .install_subdir = "pdx_source_dir",
    });

    const run_cmd = b.addSystemCommand(&.{pd_simulator_path});
    run_cmd.addDirectorySourceArg(pdx);
    run_cmd.setName("PlaydateSimulator");
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
    run_step.dependOn(b.getInstallStep());

    const clean_step = b.step("clean", "Clean all artifacts");
    clean_step.dependOn(b.getUninstallStep());
    clean_step.dependOn(&b.addRemoveDirTree(b.path("zig-cache")).step);
    clean_step.dependOn(&b.addRemoveDirTree(b.path(".zig-cache")).step);
    clean_step.dependOn(&b.addRemoveDirTree(b.path("zig-out")).step);
}

pub fn addCopyDirectory(
    wf: *std.Build.Step.WriteFile,
    src_path: []const u8,
    dest_path: []const u8,
) !void {
    const b = wf.step.owner;
    var dir = try b.build_root.handle.openDir(
        src_path,
        .{ .iterate = true },
    );
    defer dir.close();
    var it = dir.iterate();
    while (try it.next()) |entry| {
        const new_src_path = b.pathJoin(&.{ src_path, entry.name });
        const new_dest_path = b.pathJoin(&.{ dest_path, entry.name });
        const new_src = b.path(new_src_path);
        switch (entry.kind) {
            .file => {
                _ = wf.addCopyFile(new_src, new_dest_path);
            },
            .directory => {
                try addCopyDirectory(
                    wf,
                    new_src_path,
                    new_dest_path,
                );
            },
            //TODO: possible support for sym links?
            else => {},
        }
    }
}

const BUILD_INFO_FILE_NAME = "build_info.txt";
fn get_and_increment_build_number(b: *std.Build) !isize {
    const contents = std.fs.cwd().readFileAlloc(b.allocator, BUILD_INFO_FILE_NAME, 512 * 1024) catch |e| {
        switch (e) {
            error.FileNotFound => {
                try write_build_number(1, b);
                return 1;
            },
            else => {
                return e;
            },
        }
    };
    const build_number = try std.fmt.parseInt(isize, contents, 10);
    try write_build_number(build_number + 1, b);
    return build_number;
}

fn write_build_number(build_number: isize, b: *std.Build) !void {
    const data = try std.fmt.allocPrint(b.allocator, "{}", .{build_number});
    try std.fs.cwd().writeFile(.{
        .sub_path = BUILD_INFO_FILE_NAME,
        .data = data,
    });
}
