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

/* rt0: Runtime loader */

#include "rt0.h"

#include "tools.h"

#include "libluax.h"

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

__attribute__((__noreturn__))
static int rt0_run(lua_State *L)
{
    /* Read and execute a chunk in arg[0] */

    /* exe = arg[0] */
    int type = lua_getglobal(L, "arg");
    if (type != LUA_TTABLE)
    {
        error(NULL, "Can not read arg[0]");
    }
    lua_rawgeti(L, -1, 0);
    const char *exe = luaL_checkstring(L, -1);

    luax_run(L, exe); /* no return */
}

static const luaL_Reg blrt0lib[] =
{
    {"run", rt0_run},
    {NULL, NULL}
};

LUAMOD_API int luaopen_rt0 (lua_State *L)
{
    luaL_newlib(L, blrt0lib);
    return 1;
}
