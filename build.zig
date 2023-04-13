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

const lua_src = "lua";
const tinycrypt_src = "src/crypt/tinycrypt";
const lz4_src = "src/lz4/lz4";
const src_path = "src";
const build_path = ".build/tmp";

const lua_c_files = [_][]const u8 {
    // Lua interpreter
    "lua/lapi.c",
    "lua/lauxlib.c",
    "lua/lbaselib.c",
    "lua/lcode.c",
    "lua/lcorolib.c",
    "lua/lctype.c",
    "lua/ldblib.c",
    "lua/ldebug.c",
    "lua/ldo.c",
    "lua/ldump.c",
    "lua/lfunc.c",
    "lua/lgc.c",
    "lua/linit.c",
    "lua/liolib.c",
    "lua/llex.c",
    "lua/lmathlib.c",
    "lua/lmem.c",
    "lua/loadlib.c",
    "lua/lobject.c",
    "lua/lopcodes.c",
    "lua/loslib.c",
    "lua/lparser.c",
    "lua/lstate.c",
    "lua/lstring.c",
    "lua/lstrlib.c",
    "lua/ltable.c",
    "lua/ltablib.c",
    "lua/ltm.c",
    //"lua/lua.c",
    //"lua/luac.c",
    "lua/lundump.c",
    "lua/lutf8lib.c",
    "lua/lvm.c",
    "lua/lzio.c",
};

const luax_main_c_files = [_][]const u8 {
    // LuaX runtime
    "src/main.c",
};

const luax_c_files = [_][]const u8 {
    // LuaX library (static and dynamic)
    "src/rt0/rt0.c",
    "src/libluax.c",
    "src/tools.c",
    "src/std/std.c",
    "src/fs/fs.c",
    "src/ps/ps.c",
    "src/sys/sys.c",
    "src/crypt/crypt.c",
    "src/complex/complex.c",
    "src/linenoise/linenoise.c",
    "src/socket/luasocket.c",
    "src/lz4/lz4.c",
    "src/term/term.c",
};

const third_party_c_files = [_][]const u8 {
    // LuaX runtime
    "src/lpeg/lpeg-1.0.2/lpcap.c",
    "src/lpeg/lpeg-1.0.2/lpcode.c",
    "src/lpeg/lpeg-1.0.2/lpprint.c",
    "src/lpeg/lpeg-1.0.2/lptree.c",
    "src/lpeg/lpeg-1.0.2/lpvm.c",
    "src/mathx/mathx/lmathx.c",
    "src/imath/limath-104/limath.c",
    "src/imath/limath-104/src/imath.c",
    "src/qmath/lqmath-105/lqmath.c",
    "src/qmath/lqmath-105/src/imrat.c",
    "src/complex/lcomplex-100/lcomplex.c",
    "src/socket/luasocket/auxiliar.c",
    "src/socket/luasocket/buffer.c",
    "src/socket/luasocket/compat.c",
    "src/socket/luasocket/except.c",
    "src/socket/luasocket/inet.c",
    "src/socket/luasocket/io.c",
    "src/socket/luasocket/luasocket.c",
    "src/socket/luasocket/mime.c",
    "src/socket/luasocket/options.c",
    "src/socket/luasocket/select.c",
    "src/socket/luasocket/tcp.c",
    "src/socket/luasocket/timeout.c",
    "src/socket/luasocket/udp.c",
    "src/crypt/tinycrypt/aes_decrypt.c",
    "src/crypt/tinycrypt/aes_encrypt.c",
    "src/crypt/tinycrypt/cbc_mode.c",
    "src/crypt/tinycrypt/ccm_mode.c",
    "src/crypt/tinycrypt/cmac_mode.c",
    "src/crypt/tinycrypt/ctr_mode.c",
    "src/crypt/tinycrypt/ctr_prng.c",
    "src/crypt/tinycrypt/ecc.c",
    "src/crypt/tinycrypt/ecc_dh.c",
    "src/crypt/tinycrypt/ecc_dsa.c",
    "src/crypt/tinycrypt/ecc_platform_specific.c",
    "src/crypt/tinycrypt/hmac.c",
    "src/crypt/tinycrypt/hmac_prng.c",
    "src/crypt/tinycrypt/sha256.c",
    "src/crypt/tinycrypt/utils.c",
    "src/lz4/lz4/lz4.c",
    "src/lz4/lz4/lz4file.c",
    "src/lz4/lz4/lz4frame.c",
    "src/lz4/lz4/lz4hc.c",
    "src/lz4/lz4/xxhash.c",
};

const linux_third_party_c_files = [_][]const u8 {
    "src/linenoise/linenoise/linenoise.c",
    "src/socket/luasocket/serial.c",
    "src/socket/luasocket/unixdgram.c",
    "src/socket/luasocket/unixstream.c",
    "src/socket/luasocket/usocket.c",
    "src/socket/luasocket/unix.c",
};

const windows_third_party_c_files = [_][]const u8 {
    "src/socket/luasocket/wsocket.c",
};

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

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    var page = std.heap.page_allocator;

    const runtime_name = std.os.getenv("RUNTIME_NAME");
    const library_name = std.os.getenv("LIB_NAME");
    const runtime = std.os.getenv("RUNTIME");

    const ARCH = (try std.fmt.allocPrint(page, "{s}", .{tagName(target.cpu_arch)}));
    const OS = (try std.fmt.allocPrint(page, "{s}", .{tagName(target.os_tag)}));
    const ABI = (try std.fmt.allocPrint(page, "{s}", .{tagName(target.abi)}));

    const exe_name = try std.fmt.allocPrint(page, "{s}-{s}-{s}-{s}", .{runtime_name, ARCH, OS, ABI});
    const lib_name = try std.fmt.allocPrint(page, "{s}-{s}-{s}-{s}", .{library_name, ARCH, OS, ABI});

    ///////////////////////////////////////////////////////////////////////////
    // LuaX executable
    ///////////////////////////////////////////////////////////////////////////

    const exe = b.addExecutable(exe_name, null);
    exe.single_threaded = true;
    exe.strip = true;
    exe.rdynamic = true;
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.linkLibC();
    exe.install();
    exe.addIncludeDir(src_path);
    exe.addIncludeDir(tinycrypt_src);
    exe.addIncludeDir(lz4_src);
    exe.addIncludeDir(build_path);
    exe.addIncludeDir(lua_src);
    exe.addCSourceFiles(&luax_main_c_files, &[_][]const u8 {
        "-std=gnu11",
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
        try std.fmt.allocPrint(page, "-DRUNTIME={s}", .{runtime}),
        try std.fmt.allocPrint(page, "-DLUAX_ARCH=\"{s}\"", .{ARCH}),
        try std.fmt.allocPrint(page, "-DLUAX_OS=\"{s}\"", .{OS}),
        try std.fmt.allocPrint(page, "-DLUAX_ABI=\"{s}\"", .{ABI}),
        if (target.os_tag == std.Target.Os.Tag.linux) "-DLUA_USE_LINUX" else "",
        if (target.os_tag == std.Target.Os.Tag.macos) "-DLUA_USE_MACOSX" else "",
        //if (target.os_tag == std.Target.Os.Tag.windows) "-DLUA_BUILD_AS_DLL" else "",
    });
    exe.addCSourceFiles(&lua_c_files, &[_][]const u8 {
        "-std=gnu11",
        "-O3",
        "-Werror",
        "-Wall",
        "-Wextra",
        if (target.os_tag == std.Target.Os.Tag.linux) "-DLUA_USE_LINUX" else "",
        if (target.os_tag == std.Target.Os.Tag.macos) "-DLUA_USE_MACOSX" else "",
    });
    exe.addCSourceFiles(&luax_c_files, &[_][]const u8 {
        "-std=gnu11",
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
        try std.fmt.allocPrint(page, "-DRUNTIME={s}", .{runtime}),
        try std.fmt.allocPrint(page, "-DLUAX_ARCH=\"{s}\"", .{ARCH}),
        try std.fmt.allocPrint(page, "-DLUAX_OS=\"{s}\"", .{OS}),
        try std.fmt.allocPrint(page, "-DLUAX_ABI=\"{s}\"", .{ABI}),
        "-DLUA_LIB",
        if (target.os_tag == std.Target.Os.Tag.linux) "-DLUA_USE_LINUX" else "",
        if (target.os_tag == std.Target.Os.Tag.macos) "-DLUA_USE_MACOSX" else "",
    });
    exe.addCSourceFiles(&third_party_c_files, &[_][]const u8 {
        "-std=gnu11",
        "-O3",
        "-Wno-documentation",
        "-DLUA_LIB",
        if (target.os_tag == std.Target.Os.Tag.linux) "-DLUA_USE_LINUX" else "",
        if (target.os_tag == std.Target.Os.Tag.macos) "-DLUA_USE_MACOSX" else "",
    });
    if (target.os_tag == std.Target.Os.Tag.windows) {
        exe.addCSourceFiles(&windows_third_party_c_files, &[_][]const u8 {
            "-std=gnu11",
            "-O3",
            "-Wno-documentation",
        });
        exe.linkSystemLibraryName("ws2_32");
        exe.linkSystemLibraryName("advapi32");
    } else {
        exe.addCSourceFiles(&linux_third_party_c_files, &[_][]const u8 {
            "-std=gnu11",
            "-O3",
            "-Wno-documentation",
            if (target.os_tag == std.Target.Os.Tag.linux) "-DLUA_USE_LINUX" else "",
            if (target.os_tag == std.Target.Os.Tag.macos) "-DLUA_USE_MACOSX" else "",
        });
    }

    ///////////////////////////////////////////////////////////////////////////
    // Shared library
    ///////////////////////////////////////////////////////////////////////////

    if (library_name) |_| {

    const lib_shared = b.addSharedLibrary(lib_name, null, .{.unversioned=.{}});
    lib_shared.single_threaded = true;
    lib_shared.strip = true;
    lib_shared.setTarget(target);
    lib_shared.setBuildMode(mode);
    lib_shared.linkLibC();
    lib_shared.install();
    lib_shared.addIncludeDir(src_path);
    lib_shared.addIncludeDir(build_path);
    lib_shared.addIncludeDir(lua_src);
    lib_shared.addIncludeDir(tinycrypt_src);
    lib_shared.addIncludeDir(lz4_src);
    if (target.os_tag != std.Target.Os.Tag.linux) {
        lib_shared.addCSourceFiles(&lua_c_files, &[_][]const u8 {
            "-std=gnu11",
            "-O3",
            "-Werror",
            "-Wall",
            "-Wextra",
            if (target.os_tag == std.Target.Os.Tag.linux) "-DLUA_USE_LINUX" else "",
            if (target.os_tag == std.Target.Os.Tag.macos) "-DLUA_USE_MACOSX" else "",
            //if (target.os_tag == std.Target.Os.Tag.windows) "-DLUA_BUILD_AS_DLL" else "",
        });
    }
    lib_shared.addCSourceFiles(&luax_c_files, &[_][]const u8 {
        "-std=gnu11",
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
        try std.fmt.allocPrint(page, "-DRUNTIME={s}", .{runtime}),
        try std.fmt.allocPrint(page, "-DLUAX_ARCH=\"{s}\"", .{ARCH}),
        try std.fmt.allocPrint(page, "-DLUAX_OS=\"{s}\"", .{OS}),
        try std.fmt.allocPrint(page, "-DLUAX_ABI=\"{s}\"", .{ABI}),
        "-DLUA_LIB",
        if (target.os_tag == std.Target.Os.Tag.linux) "-DLUA_USE_LINUX" else "",
        if (target.os_tag == std.Target.Os.Tag.macos) "-DLUA_USE_MACOSX" else "",
        //if (target.os_tag == std.Target.Os.Tag.windows) "-DLUA_BUILD_AS_DLL" else "",
    });
    lib_shared.addCSourceFiles(&third_party_c_files, &[_][]const u8 {
        "-std=gnu11",
        "-O3",
        "-Wno-documentation",
        "-DLUA_LIB",
        if (target.os_tag == std.Target.Os.Tag.linux) "-DLUA_USE_LINUX" else "",
        if (target.os_tag == std.Target.Os.Tag.macos) "-DLUA_USE_MACOSX" else "",
        //if (target.os_tag == std.Target.Os.Tag.windows) "-DLUA_BUILD_AS_DLL" else "",
    });
    if (target.os_tag == std.Target.Os.Tag.windows) {
        lib_shared.addCSourceFiles(&windows_third_party_c_files, &[_][]const u8 {
            "-std=gnu11",
            "-O3",
            "-Wno-documentation",
            //"-DLUA_BUILD_AS_DLL",
        });
        lib_shared.linkSystemLibraryName("ws2_32");
        lib_shared.linkSystemLibraryName("advapi32");
    } else {
        lib_shared.addCSourceFiles(&linux_third_party_c_files, &[_][]const u8 {
            "-std=gnu11",
            "-O3",
            "-Wno-documentation",
            if (target.os_tag == std.Target.Os.Tag.linux) "-DLUA_USE_LINUX" else "",
            if (target.os_tag == std.Target.Os.Tag.macos) "-DLUA_USE_MACOSX" else "",
        });
    }

    }

}
