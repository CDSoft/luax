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

typedef uint8_t t_sha256_digest[32];
typedef char t_sha256_digest_hex[2*sizeof(t_sha256_digest)+1];

typedef struct {
    uint32_t state[8];
    uint64_t count;
    uint8_t buf[64];
    uint32_t buflen;
} t_sha256_ctx;

void sha256_init(t_sha256_ctx *ctx);
void sha256_update(t_sha256_ctx *ctx, const uint8_t *data, size_t len);
void sha256_final(t_sha256_ctx *ctx, t_sha256_digest digest);
void sha256_hex(const char *input, size_t size, t_sha256_digest_hex out);
