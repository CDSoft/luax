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

pub fn build(b: *std.build.Builder) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    const exe_name = "lua";

    const exe = b.addExecutable(.{
        .name = exe_name,
        .target = target,
        .optimize = release,
        .linkage = .dynamic,
        .link_libc = true,
        .single_threaded = true,
    });
    exe.strip = true;
    exe.rdynamic = true;
    b.installArtifact(exe);
    exe.addIncludePath(.{.cwd_relative = lua_src});
    exe.addCSourceFiles(&src.lua_main_c_files, &[_][]const u8 {
        "-std=gnu2x",
        "-O3",
        "-Werror",
        "-Wall",
        "-Wextra",
        if (target.os_tag == std.Target.Os.Tag.linux) "-DLUA_USE_LINUX" else "",
        if (target.os_tag == std.Target.Os.Tag.macos) "-DLUA_USE_MACOSX" else "",
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
}
