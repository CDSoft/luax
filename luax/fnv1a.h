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

typedef uint64_t t_fnv1a_digit;
typedef __uint128_t t_fnv1a_double_digit;

/******************************************************************************
 * FNV1A - 32 bit
 *****************************************************************************/

typedef uint32_t t_fnv1a_32;
typedef char t_fnv1a_32_digest[sizeof(t_fnv1a_32)*2 + 1];

void fnv1a_32_init(t_fnv1a_32 *hash);
void fnv1a_32_update(t_fnv1a_32 *hash, const void *data, size_t size);
void fnv1a_32_digest(const t_fnv1a_32 *hash, t_fnv1a_32_digest digest);

/******************************************************************************
 * FNV1A - 64 bit
 *****************************************************************************/

typedef uint64_t t_fnv1a_64;
typedef char t_fnv1a_64_digest[sizeof(t_fnv1a_64)*2 + 1];

void fnv1a_64_init(t_fnv1a_64 *hash);
void fnv1a_64_update(t_fnv1a_64 *hash, const void *data, size_t size);
void fnv1a_64_digest(const t_fnv1a_64 *hash, t_fnv1a_64_digest digest);

/******************************************************************************
 * FNV1A - 128 bit
 *****************************************************************************/

typedef __uint128_t t_fnv1a_128;
typedef char t_fnv1a_128_digest[sizeof(t_fnv1a_128)*2 + 1];

void fnv1a_128_init(t_fnv1a_128 *hash);
void fnv1a_128_update(t_fnv1a_128 *hash, const void *data, size_t size);
void fnv1a_128_digest(const t_fnv1a_128 *hash, t_fnv1a_128_digest digest);

/******************************************************************************
 * FNV1A - 256 bit
 *****************************************************************************/

typedef t_fnv1a_digit t_fnv1a_256[256/(8*sizeof(t_fnv1a_digit))];
typedef char t_fnv1a_256_digest[sizeof(t_fnv1a_256)*2 + 1];

void fnv1a_256_init(t_fnv1a_256 *hash);
void fnv1a_256_update(t_fnv1a_256 *hash, const void *data, size_t size);
void fnv1a_256_digest(const t_fnv1a_256 *hash, t_fnv1a_256_digest digest);

/******************************************************************************
 * FNV1A - 512 bit
 *****************************************************************************/

typedef t_fnv1a_digit t_fnv1a_512[512/(8*sizeof(t_fnv1a_digit))];
typedef char t_fnv1a_512_digest[sizeof(t_fnv1a_512)*2 + 1];

void fnv1a_512_init(t_fnv1a_512 *hash);
void fnv1a_512_update(t_fnv1a_512 *hash, const void *data, size_t size);
void fnv1a_512_digest(const t_fnv1a_512 *hash, t_fnv1a_512_digest digest);

/******************************************************************************
 * FNV1A - 1024 bit
 *****************************************************************************/

typedef t_fnv1a_digit t_fnv1a_1024[1024/(8*sizeof(t_fnv1a_digit))];
typedef char t_fnv1a_1024_digest[sizeof(t_fnv1a_1024)*2 + 1];

void fnv1a_1024_init(t_fnv1a_1024 *hash);
void fnv1a_1024_update(t_fnv1a_1024 *hash, const void *data, size_t size);
void fnv1a_1024_digest(const t_fnv1a_1024 *hash, t_fnv1a_1024_digest digest);
