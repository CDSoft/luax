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

#include "luasec.h"

#include "ext/opt/luasec/context.h"
#include "ext/opt/luasec/x509.h"
#include "ext/opt/luasec/ssl.h"

#include "lua.h"
#include "lauxlib.h"

/* Defined in config.c */
LSEC_API int luaopen_ssl_config(lua_State *L);

LUAMOD_API int luaopen_luasec (lua_State *L)
{
    luaL_requiref(L, "ssl.context", luaopen_ssl_context, 0);
    luaL_requiref(L, "ssl.config", luaopen_ssl_config, 0);
    luaL_requiref(L, "ssl.core", luaopen_ssl_core, 0);
    luaL_requiref(L, "ssl.x509", luaopen_ssl_x509, 0);
    lua_pop(L, 1);
    return 0;
}
