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

typedef uint64_t t_fnv1a_64;

/* Hexadecimal digest type */

typedef char t_fnv1a_64_digest[sizeof(t_fnv1a_64)*2 + 1];

/* Hash initialisation
 * Initializes `hash` with the hash initial value.
 */

void fnv1a_64_init(t_fnv1a_64 *hash);

/* Hash update
 * Update `hash` with `size` bytes stored at `data`.
 */

void fnv1a_64_update(t_fnv1a_64 *hash, const void *data, size_t size);

/* Hexadecimal digest
 * Stores the hexadecimal digest of `hash` to `digest`.
 */

void fnv1a_64_digest(const t_fnv1a_64 *hash, t_fnv1a_64_digest digest);

/* Hash comparison
 * Compares `hash1` and `hash2` with `memcmp` and returns `0`, `1` or `-1`.
 */

int fnv1a_64_cmp(const t_fnv1a_64 *hash1, const t_fnv1a_64 *hash2);
