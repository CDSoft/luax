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

#include "tools.h"
#include "lua.h"

#include <errno.h>
#include <stdarg.h>
#include <string.h>

int luax_push_result_or_errno(lua_State *L, int res, const char *filename)
{
    if (!res) {
        return luax_push_errno(L, filename);
    }

    lua_pushboolean(L, 1);
    return 1;
}

int luax_push_errno(lua_State *L, const char *filename)
{
    const int en = errno;  /* calls to Lua API may change this value */

    lua_pushnil(L);
    lua_pushfstring(L, "%s: %s", filename, strerror(en));
    lua_pushinteger(L, en);
    return 3;
}

int luax_pusherror(lua_State *L, const char *msg, ...)
{
    va_list args;
    va_start(args, msg);

    lua_pushnil(L);
    lua_pushvfstring(L, msg, args);

    va_end(args);

    return 2;
}
