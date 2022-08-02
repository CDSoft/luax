const std = @import("std");

const src_path = "src";
const build_path = ".build";

const lua_src = "lua";
const lua_c_files = [_][]const u8 {
    "lapi.c",
    "lauxlib.c",
    "lbaselib.c",
    "lcode.c",
    "lcorolib.c",
    "lctype.c",
    "ldblib.c",
    "ldebug.c",
    "ldo.c",
    "ldump.c",
    "lfunc.c",
    "lgc.c",
    "linit.c",
    "liolib.c",
    "llex.c",
    "lmathlib.c",
    "lmem.c",
    "loadlib.c",
    "lobject.c",
    "lopcodes.c",
    "loslib.c",
    "lparser.c",
    "lstate.c",
    "lstring.c",
    "lstrlib.c",
    "ltable.c",
    "ltablib.c",
    "ltm.c",
    //"lua.c",
    //"luac.c",
    "lundump.c",
    "lutf8lib.c",
    "lvm.c",
    "lzio.c",
};

const runtime_c_files = [_][]const u8 {
    "tools.c",
    "std/std.c",
    "fs/fs.c",
    "ps/ps.c",
    "sys/sys.c",
    "lpeg/lpeg-1.0.2/lpcap.c",
    "lpeg/lpeg-1.0.2/lpcode.c",
    "lpeg/lpeg-1.0.2/lpprint.c",
    "lpeg/lpeg-1.0.2/lptree.c",
    "lpeg/lpeg-1.0.2/lpvm.c",
    "crypt/crypt.c",
    "rl/rl.c",
    "mathx/mathx/lmathx.c",
    "imath/limath-104/limath.c",
    "imath/limath-104/src/imath.c",
    "qmath/lqmath-104/lqmath.c",
    "qmath/lqmath-104/src/imrat.c",
    //"complex/lcomplex-100/lcomplex.c",
};

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("lrun", "src/run.c");
    exe.single_threaded = true;
    exe.strip = true;
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.linkLibC();
    exe.install();
    exe.addIncludeDir(src_path);
    exe.addIncludeDir(build_path);
    exe.addIncludeDir(lua_src);
    if (target.os_tag == std.Target.Os.Tag.windows) {
        const c_flags = [_][]const u8{
            "-std=gnu99",
            "-Os",
            "-DLUA_USE_WINDOWS",
        };
        inline for (lua_c_files) |c_file| {
            exe.addCSourceFile(lua_src ++ "/" ++ c_file, &c_flags);
        }
        //exe.add("ws2_32");
    } else {
        const c_flags = [_][]const u8{
            "-std=gnu99",
            "-Os",
            "-DLUA_USE_POSIX",
        };
        inline for (lua_c_files) |c_file| {
            exe.addCSourceFile(lua_src ++ "/" ++ c_file, &c_flags);
        }
    }
    const c_flags = [_][]const u8{
        "-std=gnu99",
        "-Os",
    };
    inline for (runtime_c_files) |c_file| {
        exe.addCSourceFile("src/" ++ c_file, &c_flags);
    }
}
