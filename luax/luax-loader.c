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
 * https://codeberg.org/cdsoft/luax
 */

#include "libluax.h"

#include "crypt/fnv1a_32.h"
#include "endianness.h"

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "lauxlib.h"
#include "lualib.h"

static const uint32_t luax_magic = 0x5861754C;

typedef struct __attribute__((__packed__)) {
    uint32_t magic;
    uint32_t size;
    uint32_t hash;
} t_header;

#if defined(_WIN32)

#include <windows.h>

static char *get_exe(void)
{
    char path[PATH_MAX];
    GetModuleFileName(NULL, path, PATH_MAX);
    return strdup(path);
}

#elif defined(__APPLE__) && defined(__MACH__)

#include <mach-o/dyld.h>

static char *get_exe(void)
{
    char path[PATH_MAX];
    uint32_t size = sizeof(path);
    if (_NSGetExecutablePath(path, &size) != 0) {
        fprintf(stderr, "_NSGetExecutablePath: unable to get the executable path\n");
        exit(EXIT_FAILURE);
    }
    return strdup(path);
}

#elif defined(__linux__)

#include <unistd.h>

static char *get_exe(void)
{
    char path[PATH_MAX];
    const ssize_t len = readlink("/proc/self/exe", path, sizeof(path) - 1);
    if (len < 0) {
        perror("readlink");
        exit(EXIT_FAILURE);
    }
    path[len] = '\0';
    return strdup(path);
}

#else
#error "Target not supported"
#endif

static FILE *open_exe(const char *exe)
{
    FILE *f = fopen(exe, "rb");
    if (f == NULL) {
        perror("fopen");
        exit(EXIT_FAILURE);
    }
    return f;
}

static t_header read_header(FILE *f, const char *exe)
{
    t_header header;
    if (fseek(f, -(long)sizeof(t_header), SEEK_END) != 0) {
        perror("fseek");
        exit(EXIT_FAILURE);
    }
    if (fread(&header, sizeof(header), 1, f) != 1) {
        perror("fread");
        exit(EXIT_FAILURE);
    }
    header.magic = le32toh(header.magic);
    header.size  = le32toh(header.size);
    header.hash  = le32toh(header.hash);
    t_fnv1a_32 hash;
    fnv1a_32_init(&hash);
    fnv1a_32_update(&hash, &header, sizeof(header)-sizeof(header.hash));
    if (header.magic != luax_magic || header.hash != hash) {
        fprintf(stderr, "%s: invalid LuaX payload\n", exe);
        exit(EXIT_FAILURE);
    }
    return header;
}

static char *read_payload(FILE *f, t_header header)
{
    char *payload = malloc(header.size);
    if (payload == NULL) {
        perror("malloc");
        exit(EXIT_FAILURE);
    }
    if (fseek(f, -((long)header.size + (long)sizeof(t_header)), SEEK_END) != 0) {
        perror("fseek");
        exit(EXIT_FAILURE);
    }
    if (fread(payload, header.size, 1, f) != 1) {
        perror("fread");
        exit(EXIT_FAILURE);
    }
    return payload;
}

static int traceback(lua_State *L)
{
    const char *msg = lua_tostring(L, 1);
    if (msg == NULL) {
        if (luaL_callmeta(L, 1, "__tostring") && lua_type(L, -1) == LUA_TSTRING) {
            msg = lua_tostring(L, -1);
        } else {
            msg = lua_pushfstring(L, "(error object is a %s value)", luaL_typename(L, 1));
        }
    }
    luaL_traceback(L, L, msg, 1);
    const char *tb = lua_tostring(L, -1);
    fprintf(stderr, "%s\n", tb!=NULL ? tb : msg);
    lua_pop(L, 1);
    return 0;
}

static void createargtable(lua_State *L, const char **argv, int argc)
{
    const int narg = argc - 1;
    lua_createtable(L, narg, 1);
    for (int i = 0; i < argc; i++) {
        lua_pushstring(L, argv[i]);
        lua_rawseti(L, -2, i);
    }
    lua_setglobal(L, "arg");
}

int main(int argc, const char *argv[])
{
    lua_State *L = luaL_newstate();
    luaL_openlibs(L);
    luaopen_libluax(L);

    createargtable(L, argv, argc);

    /* read the payload in the current executable */
    char *exe = get_exe();
    FILE *f = open_exe(exe);
    t_header header = read_header(f, exe);
    char *payload = read_payload(f, header);
    fclose(f);

    /* compile and run the payload */
    if (luaL_loadbuffer(L, payload, header.size, exe) != LUA_OK) {
        fprintf(stderr, "%s\n", lua_tostring(L, -1));
        exit(EXIT_FAILURE);
    }
    free(exe);
    free(payload);
    const int base = lua_gettop(L);
    lua_pushcfunction(L, traceback);
    lua_insert(L, base);
    const int status = lua_pcall(L, 0, 0, base);
    lua_remove(L, base);

    lua_close(L);

    exit(status==LUA_OK ? EXIT_SUCCESS : EXIT_FAILURE);
}
