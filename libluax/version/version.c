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
 * https://github.com/cdsoft/luax
 */

#include "version.h"

#include "luax_config.h"

#include "lua.h"

void set_version(lua_State *L)
{
    lua_pushglobaltable(L);                 /* push _G */
    lua_pushstring(L, LUAX_VERSION);        /* push LUAX_VERSION */
    lua_setfield(L, -2, "_LUAX_VERSION");   /* _G._LUAX_VERSION = LUAX_VERSION */
    lua_pushstring(L, LUAX_DATE);           /* push LUAX_DATE */
    lua_setfield(L, -2, "_LUAX_DATE");      /* _G._LUAX_DATE = LUAX_DATE */
    lua_pushstring(L, LUAX_COPYRIGHT);      /* push LUAX_COPYRIGHT */
    lua_setfield(L, -2, "_LUAX_COPYRIGHT"); /* _G._LUAX_COPYRIGHT = LUAX_COPYRIGHT */
    lua_remove(L, -1);                      /* remove _G */
}
