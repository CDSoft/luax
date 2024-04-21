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
 * http://cdelord.fr/luax
 */

#include "libluax.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "lauxlib.h"

#include "tools.h"
#include "version/version.h"

#include "fs/fs.h"
#include "ps/ps.h"
#include "sys/sys.h"
#include "lpeg/lpeg.h"
#include "crypt/crypt.h"
#include "mathx/mathx.h"
#include "imath/imath.h"
#include "qmath/qmath.h"
#include "complex/complex.h"
#include "socket/luasocket.h"
#include "lz4/lz4.h"
#include "term/term.h"
#include "linenoise/linenoise.h"

static const luaL_Reg lrun_libs[] = {
    {"_fs", luaopen_fs},
    {"ps", luaopen_ps},
    {"sys", luaopen_sys},
    {"lpeg", luaopen_lpeg},
    {"_crypt", luaopen_crypt},
    {"mathx", luaopen_mathx},
    {"imath", luaopen_imath},
    {"_qmath", luaopen_qmath},
    {"complex", luaopen_complex},
    {"socket", luaopen_luasocket},
    {"_lz4", luaopen_lz4},
    {"_term", luaopen_term},
    {"linenoise", luaopen_linenoise},
    {NULL, NULL},
};

static int traceback(lua_State *L)
{
    const char *msg = lua_tostring(L, 1);
    luaL_traceback(L, L, msg, 1);
    char *tb = safe_strdup(lua_tostring(L, -1));
    size_t nb_nl = 0;
    for (size_t p = strlen(tb)-1; p > 0; p--)
    {
        if (tb[p] == '\n')
        {
            nb_nl++;
            if (nb_nl == 2)     /* Skip the last two lines that do not belong to the chunk */
            {
                tb[p] = '\0';
                break;
            }
        }
    }
    fprintf(stderr, "%s\n", tb);
    free(tb);
    lua_pop(L, 1);
    return 0;
}

static const char *arg0(lua_State *L)
{
    const int type = lua_getglobal(L, "arg");
    if (type == LUA_TTABLE)
    {
        lua_rawgeti(L, -1, 0);
    }
    else
    {
        lua_pushstring(L, "<LuaX>");
    }
    return luaL_checkstring(L, -1);
}

int run_buffer(lua_State *L, const char *name, char *(*chunk)(void), size_t (*size)(void), void (*free_chunk)(void))
{
    if (luaL_loadbuffer(L, chunk(), size(), name) != LUA_OK)
    {
        error(arg0(L), lua_tostring(L, -1));
    }
    free_chunk();
    const int base = lua_gettop(L);         /* function index */
    lua_pushcfunction(L, traceback);        /* push message handler */
    lua_insert(L, base);                    /* put it under function and args */
    const int status = lua_pcall(L, 0, 0, base);
    lua_remove(L, base);                    /* remove message handler from the stack */
    return status;
}

LUAMOD_API int luaopen_libluax(lua_State *L)
{
    set_version(L);
    for (const luaL_Reg *lib = lrun_libs; lib->func != NULL; lib++)
    {
        luaL_requiref(L, lib->name, lib->func, 0);
        lua_pop(L, 1);
    }

    CHUNK_PROTO(lib)
    if (run_buffer(L, "=runtime", lib_chunk, lib_size, lib_free) != LUA_OK)
    {
        error(arg0(L), "can not initialize the LuaX runtime\n");
    }

    return 1;
}
