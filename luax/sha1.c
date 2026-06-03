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

#include "sha1.h"

#include "bits.h"
#include "hex.h"

#include <string.h>

static const uint32_t K[4] = {
    0x5A827999,
    0x6ED9EBA1,
    0x8F1BBCDC,
    0xCA62C1D6,
};

static const uint32_t H0[5] = {
    0x67452301,
    0xEFCDAB89,
    0x98BADCFE,
    0x10325476,
    0xC3D2E1F0,
};

static void sha1_transform(t_sha1_ctx *ctx)
{
    uint32_t w[80];
    uint32_t a, b, c, d, e, temp;

    for (int i = 0; i < 16; i++) {
        w[i] = load_be32(&ctx->block[4*i]);
    }
    for (int i = 16; i < 80; i++) {
        w[i] = rotl32(w[i-3] ^ w[i-8] ^ w[i-14] ^ w[i-16], 1);
    }

    a = ctx->h[0];
    b = ctx->h[1];
    c = ctx->h[2];
    d = ctx->h[3];
    e = ctx->h[4];

    #define ROUND(f, k)                                 \
        temp = rotl32(a, 5) + (f) + e + (k) + w[i];     \
        e = d;                                          \
        d = c;                                          \
        c = rotl32(b, 30);                              \
        b = a;                                          \
        a = temp;

    for (int i =  0; i < 20; i++) { ROUND((b & c) | (~b & d),          K[0]) }
    for (int i = 20; i < 40; i++) { ROUND(b ^ c ^ d,                   K[1]) }
    for (int i = 40; i < 60; i++) { ROUND((b & c) | (b & d) | (c & d), K[2]) }
    for (int i = 60; i < 80; i++) { ROUND(b ^ c ^ d,                   K[3]) }

    ctx->h[0] += a;
    ctx->h[1] += b;
    ctx->h[2] += c;
    ctx->h[3] += d;
    ctx->h[4] += e;
}

void sha1_init(t_sha1_ctx *ctx)
{
    memcpy(ctx->h, H0, sizeof H0);
    ctx->bitlen = 0;
    ctx->blocklen = 0;
}

void sha1_update(t_sha1_ctx *ctx, const uint8_t *data, size_t len)
{
    for (size_t i = 0; i < len; i++) {
        ctx->block[ctx->blocklen++] = data[i];
        if (ctx->blocklen == 64) {
            sha1_transform(ctx);
            ctx->bitlen += 512;
            ctx->blocklen = 0;
        }
    }
}

void sha1_final(t_sha1_ctx *ctx, t_sha1_digest digest)
{
    uint32_t i = ctx->blocklen;

    ctx->block[i++] = 0x80;
    if (i > 56) {
        while (i < 64) { ctx->block[i++] = 0x00; }
        sha1_transform(ctx);
        i = 0;
    }
    while (i < 56) { ctx->block[i++] = 0x00; }

    ctx->bitlen += (uint64_t)ctx->blocklen * 8;
    store_be64(&ctx->block[56], ctx->bitlen);
    sha1_transform(ctx);

    for (int j = 0; j < 5; j++) {
        store_be32(&digest[4*j], ctx->h[j]);
    }
}

void sha1_hex(const char *input, size_t size, t_sha1_digest_hex out)
{
    t_sha1_ctx ctx;
    t_sha1_digest digest;
    sha1_init(&ctx);
    sha1_update(&ctx, (const uint8_t *)input, size);
    sha1_final(&ctx, digest);
    raw_to_hex((const char *)digest, sizeof(t_sha1_digest), out);
    out[2*sizeof(t_sha1_digest)] = '\0';
}
