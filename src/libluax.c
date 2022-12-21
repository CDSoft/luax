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

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include <unistd.h>
#include <libgen.h>

#include "lauxlib.h"
#include "lualib.h"

#include "luax_config.h"

#include "tools.h"

#include "std/std.h"
#include "fs/fs.h"
#include "ps/ps.h"
#include "sys/sys.h"
#include "lpeg/lpeg.h"
#include "crypt/crypt.h"
#include "mathx/mathx.h"
#include "imath/imath.h"
#include "qmath/qmath.h"
#include "complex/complex.h"
#include "linenoise/linenoise.h"
#include "socket/luasocket.h"
#include "lz4/lz4.h"

static const luaL_Reg lrun_libs[] = {
    {"std", luaopen_std},
    {"fs", luaopen_fs},
    {"ps", luaopen_ps},
    {"sys", luaopen_sys},
    {"lpeg", luaopen_lpeg},
    {"crypt", luaopen_crypt},
    {"linenoise", luaopen_linenoise},
    {"mathx", luaopen_mathx},
    {"imath", luaopen_imath},
    {"qmath", luaopen_qmath},
    {"complex", luaopen_complex},
    {"socket", luaopen_luasocket},
    {"lz4", luaopen_lz4},
    {NULL, NULL},
};

#if RUNTIME == 1

static const char runtime_chunk[] = {
#include "lua_runtime_bundle.dat"
};

static const char *arg0(lua_State *L)
{
    int type = lua_getglobal(L, "arg");
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

static void decode_runtime(const char *input, size_t input_len, char **output, size_t *output_len)
{
    char *rc4_buffer = NULL;
    size_t rc4_buffer_len = 0;
    rc4_runtime(input, input_len, &rc4_buffer, &rc4_buffer_len);
    const char *err = lz4_decompress(rc4_buffer, rc4_buffer_len, output, output_len);
    free(rc4_buffer);
    if (err != NULL)
    {
        fprintf(stderr, "Runtime error: %s\n", err);
        exit(EXIT_FAILURE);
    }
}

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

int run_buffer(lua_State *L, char *buffer, size_t size, const char *name)
{
    if (luaL_loadbuffer(L, buffer, size, name) != LUA_OK)
    {
        error(arg0(L), lua_tostring(L, -1));
    }
    memset(buffer, 0, size);
    const int base = lua_gettop(L);         /* function index */
    lua_pushcfunction(L, traceback);        /* push message handler */
    lua_insert(L, base);                    /* put it under function and args */
    const int status = lua_pcall(L, 0, 0, base);
    lua_remove(L, base);                    /* remove message handler from the stack */
    return status;
}

#endif

LUAMOD_API int luaopen_luax(lua_State *L)
{
    for (const luaL_Reg *lib = lrun_libs; lib->func != NULL; lib++)
    {
        luaL_requiref(L, lib->name, lib->func, 0);
        lua_pop(L, 1);
    }

#if RUNTIME == 1
    char *rt_chunk = NULL;
    size_t rt_chunk_len = 0;
    decode_runtime(runtime_chunk, sizeof(runtime_chunk), &rt_chunk, &rt_chunk_len);
    if (run_buffer(L, rt_chunk, rt_chunk_len, "=runtime") != LUA_OK)
    {
        error(arg0(L), "can not initialize LuaX runtime\n");
    }
    free(rt_chunk);
#endif

    return 1;
}
