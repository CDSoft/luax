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

#include "lua.h"

#include <stdint.h>
#include <stdlib.h>

/* C module registration function */
LUAMOD_API int luaopen_lz4(lua_State *L);

/* LZ4 functions to be used by libluax.c to decrypt the payload */
const char *lz4_compress(const char *src, const size_t src_len, char **dst, size_t *dst_len);
const char *lz4_decompress(const char *src, const size_t src_len, char **dst, size_t *dst_len);
