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

#include "fnv1a_32.h"
#include "endianness.h"

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "lauxlib.h"
#include "lualib.h"

/* A loader can be added 1 payload containing the LuaX runtime and the application.
 * It could contain more in the future
 * (e.g. the loader could contain the LuaX library in the first payload).
 */
#define MAX_PAYLOADS 1

struct t_header {
    uint8_t magic[4];
    uint32_t size;
    uint32_t hash;
};

struct t_payload {
    struct t_header header;
    char *payload;
};

static void check(const char *name, bool condition)
{
    if (!condition) {
        perror(name);
        exit(EXIT_FAILURE);
    }
}

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
    check("readlink", len >= 0);
    path[len] = '\0';
    return strdup(path);
}

#else
#error "Target not supported"
#endif

static bool read_header(FILE *f, size_t offset, struct t_header *header)
{
    check("fseek", fseek(f, -(long)(offset + sizeof(struct t_header)), SEEK_END) == 0);
    check("fread", fread(header, sizeof(struct t_header), 1, f) == 1);
    t_fnv1a_32 hash;
    fnv1a_32_init(&hash);
    fnv1a_32_update(&hash, header, sizeof(struct t_header)-sizeof(header->hash));
    header->size = le32toh(header->size);
    header->hash = le32toh(header->hash);
    return fnv1a_32_cmp(&hash, &header->hash) == 0;
}

static char *read_payload(FILE *f, size_t offset, struct t_header *header)
{
    char *payload = (char*)malloc(header->size);
    check("malloc", payload != NULL);
    check("fseek", fseek(f, -(long)(offset + header->size + sizeof(struct t_header)), SEEK_END) == 0);
    check("fread", fread(payload, header->size, 1, f) == 1);
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
    lua_warning(L, "@off", 0);  /* by default, Lua stand-alone has warnings off */
    luaopen_libluax(L);

    createargtable(L, argv, argc);

    struct t_payload payloads[MAX_PAYLOADS] = {0};
    size_t offset = 0;
    size_t nb_payloads = 0;

    /* search for the payloads at the end of the executable */
    char *exe = get_exe();
    FILE *f = fopen(exe, "rb");
    check("fopen", f != NULL);
    while (nb_payloads < MAX_PAYLOADS) {
        if (!read_header(f, offset, &payloads[nb_payloads].header)) { break; }
        payloads[nb_payloads].payload = read_payload(f, offset, &payloads[nb_payloads].header);
        offset += payloads[nb_payloads].header.size;
        nb_payloads++;
    }
    fclose(f);

    /* compile and run the payloads */
    if (nb_payloads == 0) {
        fprintf(stderr, "%s: no LuaX payload found\n", exe);
        exit(EXIT_FAILURE);
    }
    while (nb_payloads > 0) {
        nb_payloads--;
        if (luaL_loadbuffer(L, payloads[nb_payloads].payload, payloads[nb_payloads].header.size, exe) != LUA_OK) {
            fprintf(stderr, "%s\n", lua_tostring(L, -1));
            exit(EXIT_FAILURE);
        }
        free(payloads[nb_payloads].payload);
        const int base = lua_gettop(L);
        lua_pushcfunction(L, traceback);
        lua_insert(L, base);
        const int status = lua_pcall(L, 0, 0, base);
        lua_remove(L, base);
        if (status != LUA_OK) {
            exit(EXIT_FAILURE);
        }
    }

    free(exe);

    lua_close(L);

    exit(EXIT_SUCCESS);
}
