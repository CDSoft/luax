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

#include "rl.h"

#include "tools.h"

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

static int rl_read(lua_State* L)
{
    const char *prompt = lua_tostring(L, 1);
    /* io.write(prompt) */
    lua_getglobal(L, "io");         /* push io */
    lua_getfield(L, -1, "write");   /* push io.write */
    lua_remove(L, -2);              /* remove io */
    lua_pushstring(L, prompt);      /* push prompt */
    lua_call(L, 1, 0);              /* call io.write(prompt) */
    /* io.flush() */
    lua_getglobal(L, "io");         /* push io */
    lua_getfield(L, -1, "flush");   /* push io.write */
    lua_remove(L, -2);              /* remove io */
    lua_call(L, 0, 0);              /* call io.write(prompt) */
    /* return io.read "*l" */
    lua_getglobal(L, "io");         /* push io */
    lua_getfield(L, -1, "read");    /* push io.read */
    lua_remove(L, -2);              /* remove io */
    lua_pushstring(L, "*l");        /* push "*l" */
    lua_call(L, 1, 1);              /* call io.read("*l") */
    return 1;
}

static const struct luaL_Reg rl[] = {
    {"read", rl_read},
    {NULL, NULL},
};

LUAMOD_API int luaopen_rl(lua_State *L)
{
    luaL_newlib(L, rl);
    return 1;
}
