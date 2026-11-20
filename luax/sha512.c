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
 * Software freedom is inseparable from freedom of thought. Fascism -
 * in all its forms - is incompatible with the values this project stands
 * on, even though the GPL itself cannot and does not restrict who may
 * use this software. See FREEDOM.md.
 *
 * You should have received a copy of the GNU General Public License
 * along with luax.  If not, see <https://www.gnu.org/licenses/>.
 *
 * For further information about luax you can visit
 * https://codeberg.org/cdsoft/luax
 */

#include "sha512.h"

#include "bits.h"
#include "hex.h"

#include <string.h>

static const uint64_t K[80] = {
    0x428a2f98d728ae22ULL, 0x7137449123ef65cdULL, 0xb5c0fbcfec4d3b2fULL, 0xe9b5dba58189dbbcULL, 
    0x3956c25bf348b538ULL, 0x59f111f1b605d019ULL, 0x923f82a4af194f9bULL, 0xab1c5ed5da6d8118ULL, 
    0xd807aa98a3030242ULL, 0x12835b0145706fbeULL, 0x243185be4ee4b28cULL, 0x550c7dc3d5ffb4e2ULL,
    0x72be5d74f27b896fULL, 0x80deb1fe3b1696b1ULL, 0x9bdc06a725c71235ULL, 0xc19bf174cf692694ULL, 
    0xe49b69c19ef14ad2ULL, 0xefbe4786384f25e3ULL, 0x0fc19dc68b8cd5b5ULL, 0x240ca1cc77ac9c65ULL, 
    0x2de92c6f592b0275ULL, 0x4a7484aa6ea6e483ULL, 0x5cb0a9dcbd41fbd4ULL, 0x76f988da831153b5ULL,
    0x983e5152ee66dfabULL, 0xa831c66d2db43210ULL, 0xb00327c898fb213fULL, 0xbf597fc7beef0ee4ULL, 
    0xc6e00bf33da88fc2ULL, 0xd5a79147930aa725ULL, 0x06ca6351e003826fULL, 0x142929670a0e6e70ULL, 
    0x27b70a8546d22ffcULL, 0x2e1b21385c26c926ULL, 0x4d2c6dfc5ac42aedULL, 0x53380d139d95b3dfULL,
    0x650a73548baf63deULL, 0x766a0abb3c77b2a8ULL, 0x81c2c92e47edaee6ULL, 0x92722c851482353bULL,
    0xa2bfe8a14cf10364ULL, 0xa81a664bbc423001ULL, 0xc24b8b70d0f89791ULL, 0xc76c51a30654be30ULL,
    0xd192e819d6ef5218ULL, 0xd69906245565a910ULL, 0xf40e35855771202aULL, 0x106aa07032bbd1b8ULL,
    0x19a4c116b8d2d0c8ULL, 0x1e376c085141ab53ULL, 0x2748774cdf8eeb99ULL, 0x34b0bcb5e19b48a8ULL,
    0x391c0cb3c5c95a63ULL, 0x4ed8aa4ae3418acbULL, 0x5b9cca4f7763e373ULL, 0x682e6ff3d6b2b8a3ULL,
    0x748f82ee5defb2fcULL, 0x78a5636f43172f60ULL, 0x84c87814a1f0ab72ULL, 0x8cc702081a6439ecULL,
    0x90befffa23631e28ULL, 0xa4506cebde82bde9ULL, 0xbef9a3f7b2c67915ULL, 0xc67178f2e372532bULL,
    0xca273eceea26619cULL, 0xd186b8c721c0c207ULL, 0xeada7dd6cde0eb1eULL, 0xf57d4f7fee6ed178ULL,
    0x06f067aa72176fbaULL, 0x0a637dc5a2c898a6ULL, 0x113f9804bef90daeULL, 0x1b710b35131c471bULL,
    0x28db77f523047d84ULL, 0x32caab7b40c72493ULL, 0x3c9ebe0a15c9bebcULL, 0x431d67c49c100d4cULL,
    0x4cc5d4becb3e42b6ULL, 0x597f299cfc657e2aULL, 0x5fcb6fab3ad6faecULL, 0x6c44198c4a475817ULL,
};

static const uint64_t H0[8] = {
    0x6a09e667f3bcc908ULL, 0xbb67ae8584caa73bULL,
    0x3c6ef372fe94f82bULL, 0xa54ff53a5f1d36f1ULL,
    0x510e527fade682d1ULL, 0x9b05688c2b3e6c1fULL,
    0x1f83d9abfb41bd6bULL, 0x5be0cd19137e2179ULL,
};

static inline uint64_t ch(uint64_t x, uint64_t y, uint64_t z)  { return (x & y) ^ (~x & z); }
static inline uint64_t maj(uint64_t x, uint64_t y, uint64_t z) { return (x & y) ^ (x & z) ^ (y & z); }
static inline uint64_t bsig0(uint64_t x) { return rotr64(x, 28) ^ rotr64(x, 34) ^ rotr64(x, 39); }
static inline uint64_t bsig1(uint64_t x) { return rotr64(x, 14) ^ rotr64(x, 18) ^ rotr64(x, 41); }
static inline uint64_t ssig0(uint64_t x) { return rotr64(x, 1) ^ rotr64(x, 8) ^ (x >> 7); }
static inline uint64_t ssig1(uint64_t x) { return rotr64(x, 19) ^ rotr64(x, 61) ^ (x >> 6); }

static void sha512_block(uint64_t state[8], const uint8_t *p)
{
    uint64_t w[80];
    for (size_t i = 0; i < 16; i++) {
        w[i] = load_be64(&p[i*8]);
    }
    for (size_t i = 16; i < 80; i++) {
        w[i] = ssig1(w[i-2]) + w[i-7] + ssig0(w[i-15]) + w[i-16];
    }
    uint64_t a, b, c, d, e, f, g, h;
    a = state[0]; b = state[1]; c = state[2]; d = state[3];
    e = state[4]; f = state[5]; g = state[6]; h = state[7];
    for (size_t i = 0; i < 80; i++) {
        const uint64_t t1 = h + bsig1(e) + ch(e, f, g) + K[i] + w[i];
        const uint64_t t2 = bsig0(a) + maj(a, b, c);
        h = g; g = f; f = e; e = d + t1;
        d = c; c = b; b = a; a = t1 + t2;
    }
    state[0] += a; state[1] += b; state[2] += c; state[3] += d;
    state[4] += e; state[5] += f; state[6] += g;  state[7] += h;
}

void sha512_init(t_sha512_ctx *ctx)
{
    memcpy(ctx->state, H0, sizeof H0);
    ctx->len = 0;
    ctx->buflen = 0;
}

void sha512_update(t_sha512_ctx *ctx, const uint8_t *data, size_t len)
{
    const uint8_t *p = data;
    ctx->len += len;
    if (ctx->buflen > 0) {
        size_t take = 128 - ctx->buflen;
        if (take > len) { take = len; }
        memcpy(ctx->buf + ctx->buflen, p, take);
        ctx->buflen += take;
        p += take;
        len -= take;
        if (ctx->buflen == 128) {
            sha512_block(ctx->state, ctx->buf);
            ctx->buflen = 0;
        }
    }
    while (len >= 128) {
        sha512_block(ctx->state, p);
        p += 128;
        len -= 128;
    }
    if (len) {
        memcpy(ctx->buf, p, len);
        ctx->buflen = len;
    }
}

void sha512_final(t_sha512_ctx *ctx, t_sha512_digest digest)
{
    uint64_t bits = ctx->len * 8;
    uint8_t pad[256];
    size_t padlen = (ctx->buflen < 112) ? 128 - ctx->buflen : 256 - ctx->buflen;
    memset(pad, 0, sizeof pad);
    pad[0] = 0x80;
    for (size_t i = 0; i < 8; i++) {
        pad[padlen - 16 + i] = 0;
        pad[padlen - 8 + i] = (uint8_t)(bits >> (56 - 8 * i));
    }
    sha512_update(ctx, pad, padlen);
    for (size_t i = 0; i < 8; i++) {
        store_be64(&digest[i*8], ctx->state[i]);
    }
}

void sha512_hex(const char *input, size_t size, t_sha512_digest_hex out)
{
    t_sha512_ctx ctx;
    t_sha512_digest digest;
    sha512_init(&ctx);
    sha512_update(&ctx, (const uint8_t *)input, size);
    sha512_final(&ctx, digest);
    raw_to_hex((const char *)digest, sizeof(t_sha512_digest), out);
    out[2*sizeof(t_sha512_digest)] = '\0';
}
