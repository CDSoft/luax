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

#include "F.h"

#include "lua.h"
#include "lauxlib.h"

void set_F_metatable(lua_State *L)
{
    luaL_requiref(L, "F", NULL, 0);         /* push the F package */
    lua_rotate(L, lua_gettop(L), 2);        /* swap the F package and the list to pass to F */
    lua_call(L, 1, 1);                      /* call F(list) and leave list on the stack */
}
