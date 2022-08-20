const std = @import("std");

const lua_src = "lua";
const src_path = "src";
const build_path = ".build";

const lua_c_files = [_][]const u8 {
    // Lua interpretor
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

const luax_c_files = [_][]const u8 {
    // LuaX runtime
    "src/run.c",
    "src/tools.c",
    "src/std/std.c",
    "src/fs/fs.c",
    "src/ps/ps.c",
    "src/sys/sys.c",
    "src/crypt/crypt.c",
    "src/rl/rl.c",
    "src/complex/complex.c",
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
    "src/qmath/lqmath-104/lqmath.c",
    "src/qmath/lqmath-104/src/imrat.c",
    "src/complex/lcomplex-100/lcomplex.c",
};

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

    const ARCH = (try std.fmt.allocPrint(page, "{s}", .{target.cpu_arch}))[5..];
    const OS = (try std.fmt.allocPrint(page, "{s}", .{target.os_tag}))[4..];
    const ABI = (try std.fmt.allocPrint(page, "{s}", .{target.abi}))[4..];

    const exe_name = try std.fmt.allocPrint(page, "lrun-{s}-{s}-{s}", .{ARCH, OS, ABI});

    const exe = b.addExecutable(exe_name, null);
    exe.single_threaded = true;
    exe.strip = true;
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.linkLibC();
    exe.install();
    exe.addIncludeDir(src_path);
    exe.addIncludeDir(build_path);
    exe.addIncludeDir(lua_src);
    exe.addCSourceFiles(&lua_c_files, &[_][]const u8 {
        "-std=gnu11",
        "-Os",
        "-Werror",
        "-Wall",
        "-Wextra",
        if (target.os_tag == std.Target.Os.Tag.windows) "" else "-DLUA_USE_POSIX",
    });
    exe.addCSourceFiles(&luax_c_files, &[_][]const u8 {
        "-std=gnu11",
        "-Os",
        "-Werror",
        "-Wall",
        "-Wextra",
        "-Weverything",
        "-Wno-padded",
        "-Wno-reserved-identifier",
        "-Wno-disabled-macro-expansion",
        "-Wno-used-but-marked-unused",
        try std.fmt.allocPrint(page, "-DLUAX_ARCH=\"{s}\"", .{ARCH}),
        try std.fmt.allocPrint(page, "-DLUAX_OS=\"{s}\"", .{OS}),
        try std.fmt.allocPrint(page, "-DLUAX_ABI=\"{s}\"", .{ABI}),
        if (target.os_tag == std.Target.Os.Tag.windows) "" else "-DLUA_USE_POSIX",
    });
    exe.addCSourceFiles(&third_party_c_files, &[_][]const u8 {
        "-std=gnu11",
        "-Os",
        "-Werror",
        if (target.os_tag == std.Target.Os.Tag.windows) "" else "-DLUA_USE_POSIX",
    });
}
