const std = @import("std");

const lua_src = "lua";
const c_files = [_][]const u8 {

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

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("lua", "lua/lua.c");
    exe.single_threaded = true;
    exe.strip = true;
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.linkLibC();
    exe.install();
    exe.addIncludeDir(lua_src);
    exe.addCSourceFiles(&c_files, &[_][]const u8 {
        "-std=gnu11",
        "-Os",
        "-Werror",
        "-Wall",
        "-Wextra",
        if (target.os_tag == std.Target.Os.Tag.windows) "" else "-DLUA_USE_POSIX",
    });
}
