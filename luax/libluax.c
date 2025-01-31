/* This file is part of luax.
 *
 * luax is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * luax is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with luax.  If not, see <https://www.gnu.org/licenses/>.
 *
 * For further information about luax you can visit
 * https://github.com/cdsoft/luax
 */

#include "libluax.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "lauxlib.h"

#include "version/version.h"

#include "complex/complex.h"
#include "crypt/crypt.h"
#include "fs/fs.h"
#include "imath/imath.h"
#include "linenoise/linenoise.h"
#include "lpeg/lpeg.h"
#ifdef LUAX_USE_LZ4
#include "lz4/lz4.h"
#endif
#include "lzip/lzip.h"
#include "mathx/mathx.h"
#include "ps/ps.h"
#include "qmath/qmath.h"
#ifdef LUAX_USE_SOCKET
#include "socket/luasocket.h"
#endif
#ifdef LUAX_USE_SSL
#include "sec/luasec.h"
#endif
#include "sys/sys.h"
#include "term/term.h"

static const luaL_Reg lrun_libs[] = {
    {"complex",     luaopen_complex},
    {"_crypt",      luaopen_crypt},
    {"_fs",         luaopen_fs},
    {"imath",       luaopen_imath},
    {"linenoise",   luaopen_linenoise},
    {"lpeg",        luaopen_lpeg},
#ifdef LUAX_USE_LZ4
    {"_lz4",        luaopen_lz4},
#endif
    {"_lzip",       luaopen_lzip},
    {"mathx",       luaopen_mathx},
    {"ps",          luaopen_ps},
    {"_qmath",      luaopen_qmath},
#ifdef LUAX_USE_SOCKET
    {"socket",      luaopen_luasocket},
#endif
#ifdef LUAX_USE_SSL
    {"ssl",         luaopen_luasec},
#endif
    {"sys",         luaopen_sys},
    {"_term",       luaopen_term},
    {NULL, NULL},
};

static const char *arg0(lua_State *L)
{
    const int type = lua_getglobal(L, "arg");
    if (type == LUA_TTABLE) {
        lua_rawgeti(L, -1, 0);
    } else {
        lua_pushstring(L, "<LuaX>");
    }
    return luaL_checkstring(L, -1);
}

__attribute__((noreturn))
static void error(const char *what, const char *message)
{
    fprintf(stderr, "%s: %s\n", what, message);
    exit(EXIT_FAILURE);
}

LUAMOD_API int luaopen_libluax(lua_State *L)
{
    set_version(L);
    for (const luaL_Reg *lib = lrun_libs; lib->func != NULL; lib++) {
        luaL_requiref(L, lib->name, lib->func, 0);
        lua_pop(L, 1);
    }

    extern int run_lib(lua_State *);
    if (run_lib(L) != LUA_OK) {
        error(arg0(L), "can not initialize the LuaX runtime\n");
    }

    return 1;
}
