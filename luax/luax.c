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

#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <libgen.h>

#include "lualib.h"

#include "luax_config.h"

#ifdef _WIN32
#include <windows.h>
#endif

#include "tools.h"

#ifdef __clang__
#pragma clang diagnostic ignored "-Wunsafe-buffer-usage"
#endif

typedef char t_magic[1+sizeof(LUAX_MAGIC_ID)];

typedef struct __attribute__((__packed__))
{
    uint32_t size;
    t_magic magic;
} t_header;

static const t_magic magic = "\0"LUAX_MAGIC_ID;

static inline uint32_t littleendian(uint32_t n)
{
#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
    n = __builtin_bswap32(n);
#endif
    return n;
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

int main(int argc, const char *argv[])
{
    char exe[1024];
    get_exe(argv[0], exe, sizeof(exe));

    lua_State *L = luaL_newstate();
    luaL_openlibs(L);
    createargtable(L, argv, argc, 0);
    luaopen_libluax(L);

    FILE *f = fopen(exe, "rb");
    if (f == NULL) perror(exe);

    t_header header;
    fseek(f, -(long)sizeof(header), SEEK_END);
    if (fread(&header, sizeof(header), 1, f) != 1) perror(arg0(L));
    header.size = littleendian(header.size);
    if (memcmp(header.magic, magic, sizeof(magic)) != 0)
    {
        /* The runtime contains no application */
        error(arg0(L), "LuaX application not found");
    }

    fseek(f, -(long)(header.size + sizeof(header)), SEEK_END);
    char *chunk = safe_malloc(header.size);
    if (fread(chunk, header.size, 1, f) != 1) perror(arg0(L));
    fclose(f);
    char *decoded_chunk = NULL;
    size_t decoded_chunk_len = 0;
    decode_runtime(chunk, header.size, &decoded_chunk, &decoded_chunk_len);
    free(chunk);
    const int status = run_buffer(L, decoded_chunk, decoded_chunk_len, "=");
    free(decoded_chunk);

    lua_close(L);
    exit(status == 0 ? EXIT_SUCCESS : EXIT_FAILURE);
}
