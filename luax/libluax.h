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

#pragma once

#include "lauxlib.h"

/* C module registration function */
LUAMOD_API int luaopen_libluax(lua_State *L);

/* libluax functions to decode and execute a LuaX chunk of Lua code */

/* accessors to the chunks (generated at compile time) */
#define CHUNK_PROTO(kind)               \
    extern size_t kind##_size(void);    \
    extern char *kind##_chunk(void);    \
    extern void kind##_clean(void);     \
    extern void kind##_free(void);

/* run a chunk */
int run_buffer(lua_State *L, const char *name, char *(*chunk)(void), size_t (*size)(void), void (*clean)(void));
