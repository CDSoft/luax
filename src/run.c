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
#include <unistd.h>
#include <libgen.h>

#ifdef _WIN32
#include <windows.h>
#endif

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

typedef struct
{
    uint32_t size;
    uint32_t magic;
} t_header;

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

#if RUNTIME==1
static const char runtime_chunk[] = {
#include "lua_runtime_bundle.dat"
};
#endif

static void createargtable(lua_State *L, const char **argv, int argc, int shift)
{
    const int narg = argc - 1 - shift;  /* number of positive indices */
    lua_createtable(L, narg, 1);
    for (int i = 0; i < argc-shift; i++) {
        lua_pushstring(L, argv[i+shift]);
        lua_rawseti(L, -2, i);
    }
    lua_setglobal(L, "arg");
}

static void get_exe(const char *arg0, char *name, size_t name_size)
{
#ifdef _WIN32
    const DWORD n = GetModuleFileName(NULL, name, name_size);
    if (n == 0) error(arg0, "Can not be found");
#else
    const ssize_t n = readlink("/proc/self/exe", name, name_size);
    if (n < 0) perror(arg0);
#endif
    name[n] = '\0';
}

#if RUNTIME == 1

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

static void decode(const char *input, size_t size, char *output)
{
    /* Important: decode shall be able to decode the input in place.
     * I.e. output == input when decoding the playload.
     */
    switch (input[size-1])
    {
        case '-':
            output[0] = input[0];
            for (size_t i = 1; i < size-1; i++)
            {
                output[i] = output[i-1] + input[i];
            }
            break;
        case '#':
            rc4_runtime(input, size-1, output);
            break;
        default:
            /* unknown encoding, let it fail */
            break;
    }
}

static uint32_t letoh(uint8_t *bs)
{
    return (uint32_t)( (bs[0] << (0*8))
                     | (bs[1] << (1*8))
                     | (bs[2] << (2*8))
                     | (bs[3] << (3*8))
                     );
}

static int run_buffer(lua_State *L, char *buffer, size_t size, const char *name, const char *argv0)
{
    if (luaL_loadbuffer(L, buffer, size, name) != LUA_OK) error(argv0, lua_tostring(L, -1));
    memset(buffer, 0, size);
    const int base = lua_gettop(L);         /* function index */
    lua_pushcfunction(L, traceback);        /* push message handler */
    lua_insert(L, base);                    /* put it under function and args */
    const int status = lua_pcall(L, 0, 0, base);
    lua_remove(L, base);                    /* remove message handler from the stack */
    return status;
}

#endif

int main(int argc, const char *argv[])
{
    char exe[1024];
    get_exe(argv[0], exe, sizeof(exe));

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

#if RUNTIME == 1
    char *rt_chunk = safe_malloc(sizeof(runtime_chunk));
    decode(runtime_chunk, sizeof(runtime_chunk), rt_chunk);
    run_buffer(L, rt_chunk, sizeof(runtime_chunk)-1, "=runtime", argv[0]);
    free(rt_chunk);
#endif

#if RUNTIME == 1

    /**************************************************************************
     * Lua payload execution
     **************************************************************************/

    FILE *f = fopen(exe, "rb");
    if (f == NULL) perror(exe);

    t_header header;
    fseek(f, -(long)sizeof(header), SEEK_END);
    if (fread(&header, sizeof(header), 1, f) != 1) perror(argv[0]);
    header.magic = letoh((uint8_t*)&header.magic);
    header.size = letoh((uint8_t*)&header.size);
    if (header.magic != MAGIC)
    {
        /* The runtime contains no application */
        error(argv[0], "Lua application not found");
    }

    fseek(f, -(long)(header.size + sizeof(header)), SEEK_END);
    char *chunk = safe_malloc(header.size);
    if (fread(chunk, header.size, 1, f) != 1) perror(argv[0]);
    fclose(f);
    decode(chunk, header.size, chunk); /* decode chunk in place */
    const int status = run_buffer(L, chunk, header.size-1, "=", argv[0]);
    free(chunk);

    lua_close(L);

    return status;

#else

    /**************************************************************************
     * Lua script execution (bootstrap interpretor with no LuaX runtime and payload)
     **************************************************************************/

    if (argc == 3 && strcmp(argv[1], "-e") == 0)
    {
        luaL_dostring(L, argv[2]);
    }
    else if (argc > 1)
    {
        luaL_dostring(L, "arg[0] = arg[1]; table.remove(arg, 1)");
        luaL_dofile(L, argv[1]);
    }
    else
    {
        const char *name = basename(exe);
        fprintf(stderr, "usage:\n"
                        "\t%s -e 'Lua expression'\n"
                        "\t%s script.lua\n",
                        name, name);
        exit(EXIT_FAILURE);
    }

    return EXIT_SUCCESS;

#endif

}
