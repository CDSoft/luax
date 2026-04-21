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

#define ROTL32(x, n) (((x) << (n)) | ((x) >> (32 - (n))))

#define K0 0x5A827999
#define K1 0x6ED9EBA1
#define K2 0x8F1BBCDC
#define K3 0xCA62C1D6

static void sha1_transform(SHA1_CTX *ctx)
{
    uint32_t w[80];
    uint32_t a, b, c, d, e, temp;

    for (int i = 0; i < 16; i++) {
        w[i] = ((uint32_t)ctx->block[4*i + 0] << (8*3))
             | ((uint32_t)ctx->block[4*i + 1] << (8*2))
             | ((uint32_t)ctx->block[4*i + 2] << (8*1))
             | ((uint32_t)ctx->block[4*i + 3] << (8*0));
    }
    for (int i = 16; i < 80; i++)
        w[i] = ROTL32(w[i-3] ^ w[i-8] ^ w[i-14] ^ w[i-16], 1);

    a = ctx->h[0];
    b = ctx->h[1];
    c = ctx->h[2];
    d = ctx->h[3];
    e = ctx->h[4];

    #define ROUND(f, k)                                 \
        temp = ROTL32(a, 5) + (f) + e + (k) + w[i];     \
        e = d;                                          \
        d = c;                                          \
        c = ROTL32(b, 30);                              \
        b = a;                                          \
        a = temp;

    for (int i =  0; i < 20; i++) { ROUND((b & c) | (~b & d),          K0) }
    for (int i = 20; i < 40; i++) { ROUND(b ^ c ^ d,                   K1) }
    for (int i = 40; i < 60; i++) { ROUND((b & c) | (b & d) | (c & d), K2) }
    for (int i = 60; i < 80; i++) { ROUND(b ^ c ^ d,                   K3) }

    ctx->h[0] += a;
    ctx->h[1] += b;
    ctx->h[2] += c;
    ctx->h[3] += d;
    ctx->h[4] += e;
}

void sha1_init(SHA1_CTX *ctx)
{
    ctx->h[0] = 0x67452301;
    ctx->h[1] = 0xEFCDAB89;
    ctx->h[2] = 0x98BADCFE;
    ctx->h[3] = 0x10325476;
    ctx->h[4] = 0xC3D2E1F0;
    ctx->bitlen = 0;
    ctx->blocklen = 0;
}

void sha1_update(SHA1_CTX *ctx, const uint8_t *data, size_t len)
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

void sha1_final(SHA1_CTX *ctx, uint8_t digest[20])
{
    uint32_t i = ctx->blocklen;

    ctx->block[i++] = 0x80;
    if (i > 56) {
        while (i < 64) ctx->block[i++] = 0x00;
        sha1_transform(ctx);
        i = 0;
    }
    while (i < 56) ctx->block[i++] = 0x00;

    ctx->bitlen += (uint64_t)ctx->blocklen * 8;
    ctx->block[56] = (ctx->bitlen >> (8*7)) & 0xFF;
    ctx->block[57] = (ctx->bitlen >> (8*6)) & 0xFF;
    ctx->block[58] = (ctx->bitlen >> (8*5)) & 0xFF;
    ctx->block[59] = (ctx->bitlen >> (8*4)) & 0xFF;
    ctx->block[60] = (ctx->bitlen >> (8*3)) & 0xFF;
    ctx->block[61] = (ctx->bitlen >> (8*2)) & 0xFF;
    ctx->block[62] = (ctx->bitlen >> (8*1)) & 0xFF;
    ctx->block[63] = (ctx->bitlen >> (8*0)) & 0xFF;
    sha1_transform(ctx);

    for (int j = 0; j < 5; j++) {
        digest[4*j + 0] = (ctx->h[j] >> (8*3)) & 0xFF;
        digest[4*j + 1] = (ctx->h[j] >> (8*2)) & 0xFF;
        digest[4*j + 2] = (ctx->h[j] >> (8*1)) & 0xFF;
        digest[4*j + 3] = (ctx->h[j] >> (8*0)) & 0xFF;
    }
}

static inline char digit(uint8_t n)
{
    return n>=10 ? 'a'+(n-10) : '0'+n;
}

void sha1_hex(const char *input, size_t size, char out[41])
{
    SHA1_CTX ctx;
    uint8_t digest[20];
    sha1_init(&ctx);
    sha1_update(&ctx, (const uint8_t *)input, size);
    sha1_final(&ctx, digest);
    for (int i = 0; i < 20; i++) {
        out[2*i+0] = digit(digest[i]>>4);
        out[2*i+1] = digit(digest[i]&0xf);
    }
    out[40] = '\0';
}
