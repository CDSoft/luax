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

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>

#ifdef _WIN32
#include <windows.h>
#else
#include <unistd.h>
#endif

#include "lauxlib.h"
#include "lualib.h"

#include "tools.h"

#include "std/std.h"
#include "fs/fs.h"
#include "ps/ps.h"
#include "sys/sys.h"
#include "lpeg/lpeg.h"
#include "crypt/crypt.h"
#include "rl/rl.h"
#include "mathx/mathx.h"
#include "imath/imath.h"
#include "qmath/qmath.h"
//#include "complex/complex.h"

typedef struct
{
    uint64_t magic;
    uint64_t size;
} t_header;

const uint64_t magic = (uint64_t)
#include "magic.inc"
;

static const luaL_Reg lrun_libs[] = {
    {"std", luaopen_std},
    {"fs", luaopen_fs},
    {"ps", luaopen_ps},
    {"sys", luaopen_sys},
    {"lpeg", luaopen_lpeg},
    {"crypt", luaopen_crypt},
    {"rl", luaopen_rl},
    {"mathx", luaopen_mathx},
    {"imath", luaopen_imath},
    {"qmath", luaopen_qmath},
    //{"complex", luaopen_complex},
    {NULL, NULL},
};

static const char runtime_chunk[] = {
#include "lua_runtime_bundle.inc"
};

static void createargtable(lua_State *L, const char **argv, int argc, int shift)
{
    int i, narg;
    narg = argc - 1 - shift;  /* number of positive indices */
    lua_createtable(L, narg, 1);
    for (i = 0; i < argc-shift; i++) {
        lua_pushstring(L, argv[i+shift]);
        lua_rawseti(L, -2, i);
    }
    lua_setglobal(L, "arg");
}

static void get_exe(const char *arg0, char *name, size_t name_size)
{
#ifdef _WIN32
    DWORD n = GetModuleFileName(NULL, name, name_size);
    if (n == 0) error(arg0, "Can not be found");
#else
    ssize_t n = readlink("/proc/self/exe", name, name_size);
    if (n < 0) perror(arg0);
#endif
    name[n] = '\0';
}

static int traceback(lua_State *L)
{
    const char *msg = lua_tostring(L, 1);
    luaL_traceback(L, L, msg, 1);
    char *tb = lua_tostring(L, -1);
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
    lua_pop(L, 1);
    return 0;
}

static char *decode(const char *chunk, size_t size)
{
    char *decoded = safe_malloc(size + 1);
    decoded[0] = chunk[0];
    for (size_t i = 1; i < size; i++)
    {
        decoded[i] = decoded[i-1] + chunk[i];
    }
    decoded[size] = '\0';
    return decoded;
}

static uint64_t letoh(uint64_t n)
{
    union {
        uint64_t v;
        uint8_t b[8];
    } w;
    w.b[0] = (n >> (0*8)) & 0xFF;
    w.b[1] = (n >> (1*8)) & 0xFF;
    w.b[2] = (n >> (2*8)) & 0xFF;
    w.b[3] = (n >> (3*8)) & 0xFF;
    w.b[4] = (n >> (4*8)) & 0xFF;
    w.b[5] = (n >> (5*8)) & 0xFF;
    w.b[6] = (n >> (6*8)) & 0xFF;
    w.b[7] = (n >> (7*8)) & 0xFF;
    return w.v;
}

int main(int argc, const char *argv[])
{
    /**************************************************************************
     * Lua state
     **************************************************************************/

    lua_State *L = luaL_newstate();
    luaL_openlibs(L);
    createargtable(L, argv, argc, 0);

    for (const luaL_Reg *lib = lrun_libs; lib->func != NULL; lib++)
    {
        luaL_requiref(L, lib->name, lib->func, 0);
        lua_pop(L, 1);
    }

    char *rt_chunk = decode(runtime_chunk, sizeof(runtime_chunk));

    if (luaL_dostring(L, rt_chunk) != LUA_OK) error(argv[0], "Lua runtime error: can not initialize the Lua runtime");
    lua_pop(L, lua_gettop(L));

    free(rt_chunk);

    /**************************************************************************
     * Lua payload execution
     **************************************************************************/

    char exe[1024];
    get_exe(argv[0], exe, sizeof(exe));
    FILE *f = fopen(exe, "rb");
    if (f == NULL) perror(exe);

    t_header header;
    char *chunk = NULL;
    fseek(f, -(long)sizeof(header), SEEK_END);
    if (fread(&header, sizeof(header), 1, f) != 1) perror(argv[0]);
    header.magic = letoh(header.magic);
    header.size = letoh(header.size);
    if (header.magic != magic)
    {
        /* The runtime contains no application */
        error(argv[0], "Lua application not found");
    }

    fseek(f, -(long)(header.size + sizeof(header)), SEEK_END);
    chunk = safe_malloc(header.size);
    if (fread(chunk, header.size, 1, f) != 1) perror(argv[0]);
    fclose(f);

    char *app_chunk = decode(chunk, header.size);
    if (luaL_loadbuffer(L, app_chunk, header.size, "@?") != LUA_OK) error(argv[0], lua_tostring(L, -1));
    free(app_chunk);
    free(chunk);

    int base = lua_gettop(L);               /* function index */
    lua_pushcfunction(L, traceback);        /* push message handler */
    lua_insert(L, base);                    /* put it under function and args */
    int status = lua_pcall(L, 0, 0, base);
    lua_remove(L, base);                    /* remove message handler from the stack */
    lua_close(L);

    return status;
}
