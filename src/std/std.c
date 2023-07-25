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

#include "std.h"

#include "luax_config.h"
#include "tools.h"

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

void set_F_metatable(lua_State *L)
{
    luaL_requiref(L, "F", NULL, 0);         /* push the F package */
    lua_rotate(L, lua_gettop(L), 2);        /* swap the F package and the list to pass to F */
    lua_call(L, 1, 1);                      /* call F(list) and leave list on the stack */
}

LUAMOD_API int luaopen_std(lua_State *L)
{
    lua_pushglobaltable(L);                 /* push _G */
    lua_pushstring(L, LUAX_VERSION);        /* push LUAX_VERSION */
    lua_setfield(L, -2, "_LUAX_VERSION");   /* _G._LUAX_VERSION = LUAX_VERSION */
    lua_remove(L, -2);                      /* remove _G */
    return 0;
}
