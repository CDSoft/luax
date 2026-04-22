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

typedef uint8_t t_sha1_digest[20];
typedef char t_sha1_digest_hex[2*sizeof(t_sha1_digest)+1];

typedef struct {
    uint32_t h[5];
    uint8_t  block[64];
    uint64_t bitlen;
    uint32_t blocklen;
} t_sha1_ctx;

void sha1_init(t_sha1_ctx *ctx);
void sha1_update(t_sha1_ctx *ctx, const uint8_t *data, size_t len);
void sha1_final(t_sha1_ctx *ctx, t_sha1_digest digest);
void sha1_hex(const char *input, size_t size, t_sha1_digest_hex out);
