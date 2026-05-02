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
 * along with fnv1a.  If not, see <https://www.gnu.org/licenses/>.
 *
 * For further information about fnv1a you can visit
 * https://codeberg.org/cdsoft/fnv1a
 */

#pragma once

#include <stdint.h>
#include <stdlib.h>

/* Hash type */

#ifdef FNV1A_BITINT
typedef unsigned _BitInt(512) t_fnv1a_512;
#else
#ifdef FNV1A_BIT128
typedef uint64_t t_fnv1a_512_digit;
typedef __uint128_t t_fnv1a_512_double_digit;
typedef t_fnv1a_512_digit t_fnv1a_512[512/(8*sizeof(t_fnv1a_512_digit))];
#else
typedef uint32_t t_fnv1a_512_digit;
typedef uint64_t t_fnv1a_512_double_digit;
typedef t_fnv1a_512_digit t_fnv1a_512[512/(8*sizeof(t_fnv1a_512_digit))];
#endif
#endif

/* Hexadecimal digest type */

typedef char t_fnv1a_512_digest[sizeof(t_fnv1a_512)*2 + 1];

/* Hash initialisation
 * Initializes `hash` with the hash initial value.
 */

void fnv1a_512_init(t_fnv1a_512 *hash);

/* Hash update
 * Update `hash` with `size` bytes stored at `data`.
 */

void fnv1a_512_update(t_fnv1a_512 *hash, const void *data, size_t size);

/* Hexadecimal digest
 * Stores the hexadecimal digest of `hash` to `digest`.
 */

void fnv1a_512_digest(const t_fnv1a_512 *hash, t_fnv1a_512_digest digest);

/* Hash comparison
 * Compares `hash1` and `hash2` with `memcmp` and returns `0`, `1` or `-1`.
 */

int fnv1a_512_cmp(const t_fnv1a_512 *hash1, const t_fnv1a_512 *hash2);
