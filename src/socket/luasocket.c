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

#include "luasocket.h"

#include "ext/luasocket/luasocket.h"
#include "ext/luasocket/mime.h"

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#ifndef _WIN32
#include "ext/luasocket/unix.h"
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

#ifdef _WIN32

/* https://github.com/mirror/mingw-w64/blob/master/mingw-w64-crt/libsrc/ws2tcpip/gai_strerrorA.c */
/* https://github.com/mirror/mingw-w64/blob/master/mingw-w64-crt/libsrc/ws2tcpip/gai_strerrorW.c */

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#undef  __CRT__NO_INLINE
#define __CRT__NO_INLINE
#include <stdlib.h>
#include <winsock2.h>
#include <ws2tcpip.h>

char *gai_strerrorA(int ecode)
{
    static char buff[GAI_STRERROR_BUFFER_SIZE + 1];
    wcstombs(buff, gai_strerrorW(ecode), GAI_STRERROR_BUFFER_SIZE + 1);
    return buff;
}

WCHAR *gai_strerrorW(int ecode)
{
    DWORD dwMsgLen __attribute__((unused));
    static WCHAR buff[GAI_STRERROR_BUFFER_SIZE + 1];
    dwMsgLen = FormatMessageW(FORMAT_MESSAGE_FROM_SYSTEM|FORMAT_MESSAGE_IGNORE_INSERTS|FORMAT_MESSAGE_MAX_WIDTH_MASK,
                    NULL, (DWORD)ecode, MAKELANGID(LANG_NEUTRAL,SUBLANG_DEFAULT), (LPWSTR)buff,
                    GAI_STRERROR_BUFFER_SIZE, NULL);
    return buff;
}

#endif
