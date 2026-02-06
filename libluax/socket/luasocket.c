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

#include "luasocket.h"

#include "ext/c/luasocket/luasocket.h"
#include "ext/c/luasocket/mime.h"

#include "lua.h"
#include "lauxlib.h"

#ifndef _WIN32
#include "ext/c/luasocket/unix.h"
extern LUASOCKET_API int luaopen_socket_serial(lua_State *L);
#endif

LUAMOD_API int luaopen_luasocket (lua_State *L)
{
    luaL_requiref(L, "socket.core", luaopen_socket_core, 0);
    luaL_requiref(L, "mime.core", luaopen_mime_core, 0);
#ifndef _WIN32
    luaL_requiref(L, "socket.unix", luaopen_socket_unix, 0);
    luaL_requiref(L, "socket.serial", luaopen_socket_serial, 0);
#endif
    lua_pop(L, 1);
    return 0;
}
