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
    char magic[4];
} t_header;

#if RUNTIME == 1
static const char magic[4] = "LuaX";
#endif

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

static void decode_payload(const char *input, size_t input_len, char **output, size_t *output_len)
{
    char *decrypted_buffer = NULL;
    char *decrypted = NULL;
    size_t decrypted_len = 0;

    const char *err = aes_decrypt_runtime((const uint8_t *)input, input_len, (uint8_t **)&decrypted_buffer, (uint8_t **)&decrypted, &decrypted_len);
    if (err != NULL)
    {
        fprintf(stderr, "Runtime error: %s\n", err);
        exit(EXIT_FAILURE);
    }

    err = lz4_decompress(decrypted, decrypted_len, output, output_len);
    free(decrypted_buffer);
    if (err != NULL)
    {
        fprintf(stderr, "Runtime error: %s\n", err);
        exit(EXIT_FAILURE);
    }
}

static inline uint32_t littleendian(uint32_t n)
{
#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
    n = __builtin_bswap32(n);
#endif
    return n;
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
    char *rt_chunk = NULL;
    size_t rt_chunk_len = 0;
    decode_runtime(runtime_chunk, sizeof(runtime_chunk), &rt_chunk, &rt_chunk_len);
    if (run_buffer(L, rt_chunk, rt_chunk_len, "=runtime", argv[0]) != LUA_OK)
    {
        error(argv[0], "can not initialize LuaX runtime\n");
    }
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
    header.size = littleendian(header.size);
    if (strncmp(header.magic, magic, sizeof(magic)) != 0)
    {
        /* The runtime contains no application */
        error(argv[0], "Lua application not found");
    }

    fseek(f, -(long)(header.size + sizeof(header)), SEEK_END);
    char *chunk = safe_malloc(header.size);
    if (fread(chunk, header.size, 1, f) != 1) perror(argv[0]);
    fclose(f);
    char *decoded_chunk = NULL;
    size_t decoded_chunk_len = 0;
    decode_payload(chunk, header.size, &decoded_chunk, &decoded_chunk_len);
    free(chunk);
    const int status = run_buffer(L, decoded_chunk, decoded_chunk_len, "=", argv[0]);
    free(decoded_chunk);

    lua_close(L);

    return status;

#else

    /**************************************************************************
     * Lua script execution (bootstrap interpretor with no LuaX runtime and payload)
     **************************************************************************/

    if (argc == 3 && strcmp(argv[1], "-e") == 0)
    {
        if (luaL_dostring(L, argv[2]) != LUA_OK)
        {
            error(argv[2], "Can not execute");
        }
    }
    else if (argc > 1)
    {
        luaL_dostring(L, "arg[0] = arg[1]; table.remove(arg, 1)");
        if (luaL_dofile(L, argv[1]) != LUA_OK)
        {
            error(argv[1], "Can not execute");
        }
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
