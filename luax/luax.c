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

#include "lualib.h"

#ifdef _WIN32
#include <windows.h>
#endif

#include "tools.h"

#ifdef __clang__
#pragma clang diagnostic ignored "-Wunsafe-buffer-usage"
#endif

static const uint8_t app_chunk[] = {
#include "lua_app_bundle.dat"
};

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
    lua_State *L = luaL_newstate();
    luaL_openlibs(L);
    createargtable(L, argv, argc, 0);
    luaopen_libluax(L);

    char *chunk = NULL;
    size_t chunk_len = 0;
    decode_runtime((const char *)app_chunk, sizeof(app_chunk), &chunk, &chunk_len);
    (void)run_buffer(L, chunk, chunk_len, "=luax");
    free(chunk);

    lua_close(L);
    exit(EXIT_SUCCESS);
}
