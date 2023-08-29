// This file is part of luax.
//
// luax is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// luax is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with luax.  If not, see <https://www.gnu.org/licenses/>.
//
// For further information about luax you can visit
// http://cdelord.fr/luax

const std = @import("std");
const src = @import("luax-c-sources.zig");

const release = .ReleaseFast;

const lua_src = "lua";
const src_path = "luax-libs";
const build_path = ".build/tmp";

fn tagName(opt: anytype) ?[]const u8 {
    if (opt)|x| { return @tagName(x); }
    return null;
}

pub fn build(b: *std.build.Builder) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    var page = std.heap.page_allocator;

    const runtime_name = std.os.getenv("RUNTIME_NAME");
    const library_name = std.os.getenv("LIB_NAME");
    const runtime = std.os.getenv("RUNTIME");

    const ARCH = (try std.fmt.allocPrint(page, "{?s}", .{tagName(target.cpu_arch)}));
    const OS = (try std.fmt.allocPrint(page, "{?s}", .{tagName(target.os_tag)}));
    const ABI = (try std.fmt.allocPrint(page, "{?s}", .{tagName(target.abi)}));

    const exe_name = try std.fmt.allocPrint(page, "{?s}-{s}-{s}-{s}", .{runtime_name, ARCH, OS, ABI});
    const lib_name = try std.fmt.allocPrint(page, "{?s}-{s}-{s}-{s}", .{library_name, ARCH, OS, ABI});

    const dynamic = if (target.abi)|abi| !std.Target.Abi.isMusl(abi) else true;

    ///////////////////////////////////////////////////////////////////////////
    // LuaX executable
    ///////////////////////////////////////////////////////////////////////////

    const exe = b.addExecutable(.{
        .name = exe_name,
        .target = target,
        .optimize = release,
        .linkage = if (dynamic) .dynamic else .static,
        .link_libc = true,
        .single_threaded = true,
    });
    exe.strip = true;
    exe.rdynamic = dynamic;
    b.installArtifact(exe);
    exe.addIncludePath(.{.cwd_relative = "."});
    exe.addIncludePath(.{.cwd_relative = src_path});
    exe.addIncludePath(.{.cwd_relative = build_path});
    exe.addIncludePath(.{.cwd_relative = lua_src});
    exe.addCSourceFiles(&src.luax_main_c_files, &[_][]const u8 {
        "-std=gnu2x",
        "-O3",
        "-Werror",
        "-Wall",
        "-Wextra",
        "-Weverything",
        "-Wno-padded",
        "-Wno-reserved-identifier",
        "-Wno-disabled-macro-expansion",
        "-Wno-used-but-marked-unused",
        "-Wno-documentation",
        "-Wno-documentation-unknown-command",
        "-Wno-declaration-after-statement",
        try std.fmt.allocPrint(page, "-DRUNTIME={?s}", .{runtime}),
        try std.fmt.allocPrint(page, "-DLUAX_ARCH=\"{s}\"", .{ARCH}),
        try std.fmt.allocPrint(page, "-DLUAX_OS=\"{s}\"", .{OS}),
        try std.fmt.allocPrint(page, "-DLUAX_ABI=\"{s}\"", .{ABI}),
        if (target.os_tag == std.Target.Os.Tag.linux) "-DLUA_USE_LINUX" else "",
        if (target.os_tag == std.Target.Os.Tag.macos) "-DLUA_USE_MACOSX" else "",
        //if (target.os_tag == std.Target.Os.Tag.windows) "-DLUA_BUILD_AS_DLL" else "",
    });
    exe.addCSourceFiles(&src.lua_c_files, &[_][]const u8 {
        "-std=gnu2x",
        "-O3",
        "-Werror",
        "-Wall",
        "-Wextra",
        if (target.os_tag == std.Target.Os.Tag.linux) "-DLUA_USE_LINUX" else "",
        if (target.os_tag == std.Target.Os.Tag.macos) "-DLUA_USE_MACOSX" else "",
    });
    exe.addCSourceFiles(&src.luax_c_files, &[_][]const u8 {
        "-std=gnu2x",
        "-O3",
        "-Werror",
        "-Wall",
        "-Wextra",
        "-Weverything",
        "-Wno-padded",
        "-Wno-reserved-identifier",
        "-Wno-disabled-macro-expansion",
        "-Wno-used-but-marked-unused",
        "-Wno-documentation",
        "-Wno-documentation-unknown-command",
        "-Wno-declaration-after-statement",
        "-Wno-unsafe-buffer-usage",
        try std.fmt.allocPrint(page, "-DRUNTIME={?s}", .{runtime}),
        try std.fmt.allocPrint(page, "-DLUAX_ARCH=\"{s}\"", .{ARCH}),
        try std.fmt.allocPrint(page, "-DLUAX_OS=\"{s}\"", .{OS}),
        try std.fmt.allocPrint(page, "-DLUAX_ABI=\"{s}\"", .{ABI}),
        "-DLUA_LIB",
        if (target.os_tag == std.Target.Os.Tag.linux) "-DLUA_USE_LINUX" else "",
        if (target.os_tag == std.Target.Os.Tag.macos) "-DLUA_USE_MACOSX" else "",
    });
    exe.addCSourceFiles(&src.third_party_c_files, &[_][]const u8 {
        "-std=gnu2x",
        "-O3",
        "-Wno-documentation",
        "-DLUA_LIB",
        if (target.os_tag == std.Target.Os.Tag.linux) "-DLUA_USE_LINUX" else "",
        if (target.os_tag == std.Target.Os.Tag.macos) "-DLUA_USE_MACOSX" else "",
    });
    if (target.os_tag == std.Target.Os.Tag.windows) {
        exe.addCSourceFiles(&src.windows_third_party_c_files, &[_][]const u8 {
            "-std=gnu2x",
            "-O3",
            "-Wno-documentation",
        });
        exe.linkSystemLibraryName("ws2_32");
        exe.linkSystemLibraryName("advapi32");
    } else {
        exe.addCSourceFiles(&src.linux_third_party_c_files, &[_][]const u8 {
            "-std=gnu2x",
            "-O3",
            "-Wno-documentation",
            if (target.os_tag == std.Target.Os.Tag.linux) "-DLUA_USE_LINUX" else "",
            if (target.os_tag == std.Target.Os.Tag.macos) "-DLUA_USE_MACOSX" else "",
        });
    }

    ///////////////////////////////////////////////////////////////////////////
    // Shared library
    ///////////////////////////////////////////////////////////////////////////

    if (dynamic) {
    if (library_name) |_| {

    const lib_shared = b.addSharedLibrary(.{
        .name = lib_name,
        .target = target,
        .optimize = release,
        .link_libc = true,
        .single_threaded = true,
    });
    lib_shared.strip = true;
    b.installArtifact(lib_shared);
    lib_shared.addIncludePath(.{.cwd_relative = "."});
    lib_shared.addIncludePath(.{.cwd_relative = src_path});
    lib_shared.addIncludePath(.{.cwd_relative = build_path});
    lib_shared.addIncludePath(.{.cwd_relative = lua_src});
    if (target.os_tag != std.Target.Os.Tag.linux) {
        lib_shared.addCSourceFiles(&src.lua_c_files, &[_][]const u8 {
            "-std=gnu2x",
            "-O3",
            "-Werror",
            "-Wall",
            "-Wextra",
            if (target.os_tag == std.Target.Os.Tag.linux) "-DLUA_USE_LINUX" else "",
            if (target.os_tag == std.Target.Os.Tag.macos) "-DLUA_USE_MACOSX" else "",
            //if (target.os_tag == std.Target.Os.Tag.windows) "-DLUA_BUILD_AS_DLL" else "",
        });
    }
    lib_shared.addCSourceFiles(&src.luax_c_files, &[_][]const u8 {
        "-std=gnu2x",
        "-O3",
        "-Werror",
        "-Wall",
        "-Wextra",
        "-Weverything",
        "-Wno-padded",
        "-Wno-reserved-identifier",
        "-Wno-disabled-macro-expansion",
        "-Wno-used-but-marked-unused",
        "-Wno-documentation",
        "-Wno-documentation-unknown-command",
        "-Wno-declaration-after-statement",
        "-Wno-unsafe-buffer-usage",
        try std.fmt.allocPrint(page, "-DRUNTIME={?s}", .{runtime}),
        try std.fmt.allocPrint(page, "-DLUAX_ARCH=\"{s}\"", .{ARCH}),
        try std.fmt.allocPrint(page, "-DLUAX_OS=\"{s}\"", .{OS}),
        try std.fmt.allocPrint(page, "-DLUAX_ABI=\"{s}\"", .{ABI}),
        "-DLUA_LIB",
        if (target.os_tag == std.Target.Os.Tag.linux) "-DLUA_USE_LINUX" else "",
        if (target.os_tag == std.Target.Os.Tag.macos) "-DLUA_USE_MACOSX" else "",
        //if (target.os_tag == std.Target.Os.Tag.windows) "-DLUA_BUILD_AS_DLL" else "",
    });
    lib_shared.addCSourceFiles(&src.third_party_c_files, &[_][]const u8 {
        "-std=gnu2x",
        "-O3",
        "-Wno-documentation",
        "-DLUA_LIB",
        if (target.os_tag == std.Target.Os.Tag.linux) "-DLUA_USE_LINUX" else "",
        if (target.os_tag == std.Target.Os.Tag.macos) "-DLUA_USE_MACOSX" else "",
        //if (target.os_tag == std.Target.Os.Tag.windows) "-DLUA_BUILD_AS_DLL" else "",
    });
    if (target.os_tag == std.Target.Os.Tag.windows) {
        lib_shared.addCSourceFiles(&src.windows_third_party_c_files, &[_][]const u8 {
            "-std=gnu2x",
            "-O3",
            "-Wno-documentation",
            //"-DLUA_BUILD_AS_DLL",
        });
        lib_shared.linkSystemLibraryName("ws2_32");
        lib_shared.linkSystemLibraryName("advapi32");
    } else {
        lib_shared.addCSourceFiles(&src.linux_third_party_c_files, &[_][]const u8 {
            "-std=gnu2x",
            "-O3",
            "-Wno-documentation",
            if (target.os_tag == std.Target.Os.Tag.linux) "-DLUA_USE_LINUX" else "",
            if (target.os_tag == std.Target.Os.Tag.macos) "-DLUA_USE_MACOSX" else "",
        });
    }

    }
    }

}
