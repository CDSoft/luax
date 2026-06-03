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

#include "sha256.h"

#include "bits.h"
#include "hex.h"

#include <string.h>

static const uint32_t K[64] = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
    0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
    0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
};

static const uint32_t H0[8] = {
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
    0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
};

static inline uint32_t ch(uint32_t e, uint32_t f, uint32_t g) { return (e & f) ^ (~e & g); }
static inline uint32_t maj(uint32_t a, uint32_t b, uint32_t c) { return (a & b) ^ (a & c) ^ (b & c); }

static inline uint32_t Sigma0(uint32_t a) { return rotr32(a,  2) ^ rotr32(a, 13) ^ rotr32(a, 22); }
static inline uint32_t Sigma1(uint32_t e) { return rotr32(e,  6) ^ rotr32(e, 11) ^ rotr32(e, 25); }
static inline uint32_t sigma0(uint32_t x) { return rotr32(x,  7) ^ rotr32(x, 18) ^ (x >>  3); }
static inline uint32_t sigma1(uint32_t x) { return rotr32(x, 17) ^ rotr32(x, 19) ^ (x >> 10); }

static void sha256_compress(uint32_t state[8], const uint8_t block[64])
{
    uint32_t W[64];
    for (size_t i = 0; i < 16; i++) {
        W[i] = load_be32(&block[i*4]);
    }
    for (size_t i = 16; i < 64; i++) {
        W[i] = sigma1(W[i-2]) + W[i-7] + sigma0(W[i-15]) + W[i-16];
    }
    uint32_t a, b, c, d, e, f, g, h;
    a = state[0]; b = state[1]; c = state[2]; d = state[3];
    e = state[4]; f = state[5]; g = state[6]; h = state[7];
    for (size_t i = 0; i < 64; i++) {
        const uint32_t T1 = h + Sigma1(e) + ch(e, f, g) + K[i] + W[i];
        const uint32_t T2 = Sigma0(a) + maj(a, b, c);
        h = g; g = f; f = e; e = d + T1;
        d = c; c = b; b = a; a = T1 + T2;
    }
    state[0] += a; state[1] += b; state[2] += c; state[3] += d;
    state[4] += e; state[5] += f; state[6] += g; state[7] += h;
}

void sha256_init(t_sha256_ctx *ctx)
{
    memcpy(ctx->state, H0, sizeof H0);
    ctx->count = 0;
    ctx->buflen = 0;
}

void sha256_update(t_sha256_ctx *ctx, const uint8_t *data, size_t len)
{
    const uint8_t *p = data;
    ctx->count += (uint64_t)len * 8;
    if (ctx->buflen > 0) {
        const uint32_t need = 64 - ctx->buflen;
        if (len < need) {
            memcpy(ctx->buf + ctx->buflen, p, len);
            ctx->buflen += (uint32_t)len;
            return;
        }
        memcpy(ctx->buf + ctx->buflen, p, need);
        sha256_compress(ctx->state, ctx->buf);
        p += need;
        len -= need;
        ctx->buflen = 0;
    }
    while (len >= 64) {
        sha256_compress(ctx->state, p);
        p += 64;
        len -= 64;
    }
    if (len > 0) {
        memcpy(ctx->buf, p, len);
        ctx->buflen = (uint32_t)len;
    }
}

void sha256_final(t_sha256_ctx *ctx, t_sha256_digest digest)
{
    ctx->buf[ctx->buflen] = 0x80;
    if (ctx->buflen < 56) {
        const uint32_t padlen = 56 - ctx->buflen - 1;
        memset(&ctx->buf[ctx->buflen + 1], 0, padlen);
        store_be64(&ctx->buf[56], ctx->count);
        sha256_compress(ctx->state, ctx->buf);
    } else {
        const uint32_t padlen = 64 - ctx->buflen - 1;
        memset(&ctx->buf[ctx->buflen + 1], 0, padlen);
        sha256_compress(ctx->state, ctx->buf);
        uint8_t pad[64];
        memset(pad, 0, 56);
        store_be64(&pad[56], ctx->count);
        sha256_compress(ctx->state, pad);
    }
    for (size_t i = 0; i < 8; i++) {
        store_be32(&digest[i*4], ctx->state[i]);
    }
    memset(ctx, 0, sizeof *ctx);
}

void sha256_hex(const char *input, size_t size, t_sha256_digest_hex out)
{
    t_sha256_ctx ctx;
    t_sha256_digest digest;
    sha256_init(&ctx);
    sha256_update(&ctx, (const uint8_t *)input, size);
    sha256_final(&ctx, digest);
    raw_to_hex((const char *)digest, sizeof(t_sha256_digest), out);
    out[2*sizeof(t_sha256_digest)] = '\0';
}
