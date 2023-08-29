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

#include <errno.h>
#include <stdio.h>
#include <string.h>

__attribute__((noreturn))
void error(const char *what, const char *message)
{
    if (what != NULL)
    {
        fprintf(stderr, "%s: %s\n", what, message);
    }
    else
    {
        fprintf(stderr, "%s\n", message);
    }
    exit(EXIT_FAILURE);
}

static inline void *check_ptr(void *ptr)
{
    if (ptr == NULL)
    {
        error(NULL, "Memory allocation error\n");
    }
    return ptr;
}

void *safe_malloc(size_t size)
{
    return check_ptr(malloc(size));
}

void *safe_realloc(void *ptr, size_t size)
{
    return check_ptr(realloc(ptr, size));
}

char *safe_strdup(const char *s)
{
    return check_ptr(strdup(s));
}

static size_t last_index(const char *s, char c)
{
    size_t idx = MAX_SIZET;
    size_t i;
    for (i = 0; s[i] != '\0'; i++)
    {
        if (s[i] == c) idx = i;
    }
    if (idx == MAX_SIZET) idx = i;
    return idx;
}

const char *ext(const char *name)
{
    return &name[last_index(name, '.')];
}

void strip_ext(char *name)
{
    name[last_index(name, '.')] = '\0';
}

int bl_pushresult(lua_State *L, int i, const char *filename)
{
    const int en = errno;  /* calls to Lua API may change this value */
    if (i)
    {
        lua_pushboolean(L, 1);
        return 1;
    }
    else
    {
        lua_pushnil(L);
        lua_pushfstring(L, "%s: %s", filename, strerror(en));
        lua_pushinteger(L, en);
        return 3;
    }
}

int bl_pusherror(lua_State *L, const char *msg)
{
    lua_pushnil(L);
    lua_pushstring(L, msg);
    return 2;
}

int bl_pusherror1(lua_State *L, const char *msg, const char *arg1)
{
    lua_pushnil(L);
    lua_pushfstring(L, msg, arg1);
    return 2;
}

int bl_pusherror2(lua_State *L, const char *msg, const char *arg1, int arg2)
{
    lua_pushnil(L);
    lua_pushfstring(L, msg, arg1, arg2);
    return 2;
}
