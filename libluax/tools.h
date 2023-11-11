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

#include <lstate.h>

#include <stdlib.h>
#include <stdbool.h>

struct lrun_Reg
{
    const char *name;
    const unsigned char *chunk;
    const unsigned int *size;
    bool autoload;
};

typedef const struct lrun_Reg *luax_Lib;

void error(const char *what, const char *message);

void *safe_malloc(size_t size);
void *safe_realloc(void *ptr, size_t size);
char *safe_strdup(const char *s);

const char *ext(const char *name);
void strip_ext(char *name);

int luax_pushresult(lua_State *L, int i, const char *filename);
int luax_pusherror(lua_State *L, const char *msg);
int luax_pusherror1(lua_State *L, const char *msg, const char *arg1);
int luax_pusherror2(lua_State *L, const char *msg, const char *arg1, int arg2);
