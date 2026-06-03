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

#pragma once

#include <stdint.h>
#include <stdlib.h>

static inline uint32_t rotl32(uint32_t x, size_t n) { return (x << n) | (x >> (32 - n)); }
static inline uint32_t rotr32(uint32_t x, size_t n) { return (x >> n) | (x << (32 - n)); }

static inline uint32_t load_le32(uint8_t *p)
{
    return (uint32_t)(p[0]) << (8*0)
         | (uint32_t)(p[1]) << (8*1)
         | (uint32_t)(p[2]) << (8*2)
         | (uint32_t)(p[3]) << (8*3)
         ;
}

static inline uint32_t load_be32(const uint8_t *p)
{
    return (uint32_t)(p[0]) << (8*3)
         | (uint32_t)(p[1]) << (8*2)
         | (uint32_t)(p[2]) << (8*1)
         | (uint32_t)(p[3]) << (8*0)
         ;
}

static inline void store_le32(uint8_t *p, uint32_t v)
{
    p[0] = (uint8_t)(v >> (8*0));
    p[1] = (uint8_t)(v >> (8*1));
    p[2] = (uint8_t)(v >> (8*2));
    p[3] = (uint8_t)(v >> (8*3));
}

static inline void store_be32(uint8_t *p, uint32_t v)
{
    p[0] = (uint8_t)(v >> (8*3));
    p[1] = (uint8_t)(v >> (8*2));
    p[2] = (uint8_t)(v >> (8*1));
    p[3] = (uint8_t)(v >> (8*0));
}

static inline void store_be64(uint8_t *p, uint64_t v)
{
    p[0] = (uint8_t)(v >> (8*7));
    p[1] = (uint8_t)(v >> (8*6));
    p[2] = (uint8_t)(v >> (8*5));
    p[3] = (uint8_t)(v >> (8*4));
    p[4] = (uint8_t)(v >> (8*3));
    p[5] = (uint8_t)(v >> (8*2));
    p[6] = (uint8_t)(v >> (8*1));
    p[7] = (uint8_t)(v >> (8*0));
}
