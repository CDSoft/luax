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

#include "lauxlib.h"
#include "lualib.h"

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

    extern int run_app(lua_State *);
    const int status = run_app(L);

    lua_close(L);

    exit(status==LUA_OK ? EXIT_SUCCESS : EXIT_FAILURE);
}
