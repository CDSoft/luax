/* This file is part of fnv1a.
 *
 * fnv1a is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * fnv1a is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with luax.  If not, see <https://www.gnu.org/licenses/>.
 *
 * For further information about fnv1a you can visit
 * https://codeberg.org/cdsoft/fnv1a
 */

#include "fnv1a_32.h"

#include <string.h>

static const t_fnv1a_32 fnv1a_32_offset_basis = 0x811c9dc5;

static const t_fnv1a_32 fnv1a_32_prime = (t_fnv1a_32)1<<24 | (t_fnv1a_32)1<<8 | 0x93;

void fnv1a_32_init(t_fnv1a_32 *hash)
{
    *hash = fnv1a_32_offset_basis;
}

void fnv1a_32_update(t_fnv1a_32 *hash, const void *data, size_t size)
{
    t_fnv1a_32 h = *hash;
    for (size_t i = 0; i < size; i++) {
        h ^= ((const uint8_t *)data)[i];
        h *= fnv1a_32_prime;
    }
    *hash = h;
}

static inline char digit(uint8_t n)
{
    return n>=10 ? 'a'+(n-10) : '0'+n;
}

void fnv1a_32_digest(const t_fnv1a_32 *hash, t_fnv1a_32_digest digest)
{
    for (size_t i = 0; i < sizeof(t_fnv1a_32); i++) {
        const uint8_t b = (uint8_t)((*hash)>>(8*i));
        digest[2*i+0] = digit(b>>4);
        digest[2*i+1] = digit(b&0xf);
    }
    digest[sizeof(t_fnv1a_32_digest)-1] = '\0';
}

int fnv1a_32_cmp(const t_fnv1a_32 *hash1, const t_fnv1a_32 *hash2)
{
    return memcmp(hash1, hash2, sizeof(t_fnv1a_32));
}
