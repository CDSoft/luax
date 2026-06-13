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

#include "fnv1a.h"

#include <string.h>
#include <sys/types.h>

/******************************************************************************
 * Big endian hexadecimal digests
 *****************************************************************************/

static const char hex[] = "0123456789abcdef";

static inline void to_hex_32(const t_fnv1a_32 w, char *d)
{
    size_t k = 0;
    for (ssize_t j = 2*sizeof(w)-1; j >= 0; j--) {
        d[k++] = hex[(w >> (4*j)) & 0xF];
    }
    d[k] = '\0';
}

static inline void to_hex_64(const t_fnv1a_64 w, char *d)
{
    size_t k = 0;
    for (ssize_t j = 2*sizeof(w)-1; j >= 0; j--) {
        d[k++] = hex[(w >> (4*j)) & 0xF];
    }
    d[k] = '\0';
}

static inline void to_hex_128(const t_fnv1a_128 w, char *d)
{
    size_t k = 0;
    for (ssize_t j = 2*sizeof(w)-1; j >= 0; j--) {
        d[k++] = hex[(w >> (4*j)) & 0xF];
    }
    d[k] = '\0';
}

static inline void to_hex_big(const t_fnv1a_digit *ws, size_t n, char *d)
{
    size_t k = 0;
    for (ssize_t i = (ssize_t)(n/sizeof(ws[0]))-1; i >= 0; i--) {
        const t_fnv1a_digit w = ws[i];
        for (ssize_t j = 2*sizeof(w)-1; j >= 0; j--) {
            d[k++] = hex[(w >> (4*j)) & 0xF];
        }
    }
    d[k] = '\0';
}

/******************************************************************************
 * FNV1A - 32 bit
 *****************************************************************************/

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

void fnv1a_32_digest(const t_fnv1a_32 *hash, t_fnv1a_32_digest digest)
{
    to_hex_32(*hash, digest);
}

/******************************************************************************
 * FNV1A - 64 bit
 *****************************************************************************/

static const t_fnv1a_64 fnv1a_64_offset_basis = 0xcbf29ce484222325;
static const t_fnv1a_64 fnv1a_64_prime = (t_fnv1a_64)1<<40 | (t_fnv1a_64)1<<8 | 0xb3;

void fnv1a_64_init(t_fnv1a_64 *hash)
{
    *hash = fnv1a_64_offset_basis;
}
void fnv1a_64_update(t_fnv1a_64 *hash, const void *data, size_t size)
{
    t_fnv1a_64 h = *hash;
    for (size_t i = 0; i < size; i++) {
        h ^= ((const uint8_t *)data)[i];
        h *= fnv1a_64_prime;
    }
    *hash = h;
}

void fnv1a_64_digest(const t_fnv1a_64 *hash, t_fnv1a_64_digest digest)
{
    to_hex_64(*hash, digest);
}

/******************************************************************************
 * FNV1A - 128 bit
 *****************************************************************************/

static const t_fnv1a_128 fnv1a_128_offset_basis = (t_fnv1a_128)0x6c62272e07bb0142 << (64*1)
                                                | (t_fnv1a_128)0x62b821756295c58d << (64*0);

static const t_fnv1a_128 fnv1a_128_prime = (t_fnv1a_128)1<<88 | (t_fnv1a_128)1<<8 | 0x3b;

void fnv1a_128_init(t_fnv1a_128 *hash)
{
    memcpy(hash, &fnv1a_128_offset_basis, sizeof(fnv1a_128_offset_basis));
}

void fnv1a_128_update(t_fnv1a_128 *hash, const void *data, size_t size)
{
    t_fnv1a_128 h = *hash;
    for (size_t i = 0; i < size; i++) {
        h ^= ((const uint8_t *)data)[i];
        h *= fnv1a_128_prime;
    }
    *hash = h;
}

void fnv1a_128_digest(const t_fnv1a_128 *hash, t_fnv1a_128_digest digest)
{
    to_hex_128(*hash, digest);
}

/******************************************************************************
 * FNV1A - 256 bit
 *****************************************************************************/

static const t_fnv1a_256 fnv1a_256_offset_basis  = {
    [3] = 0xdd268dbcaac55036,
    [2] = 0x2d98c384c4e576cc,
    [1] = 0xc8b1536847b6bbb3,
    [0] = 0x1023b4c8caee0535,
};

static const t_fnv1a_256 fnv1a_256_prime = {
    [2] = 1ULL<<(168 - 2*64),
    [0] = 1<<8 | 0x63,
};

void fnv1a_256_init(t_fnv1a_256 *hash)
{
    memcpy(hash, &fnv1a_256_offset_basis, sizeof(t_fnv1a_256));
}

static inline void split(t_fnv1a_digit *digit, t_fnv1a_digit *carry, t_fnv1a_double_digit n)
{
    *digit = n & (t_fnv1a_digit)~0;
    *carry = n >> 8*sizeof(t_fnv1a_digit);
}

static inline void step_256(uint8_t data, t_fnv1a_256 *h1, t_fnv1a_256 *h2)
{
    t_fnv1a_digit carry = 0;
    (*h1)[0] ^= data;
    split(&(*h2)[0], &carry, carry + (t_fnv1a_double_digit)(*h1)[0]*fnv1a_256_prime[0]);
    split(&(*h2)[1], &carry, carry + (t_fnv1a_double_digit)(*h1)[1]*fnv1a_256_prime[0]);
    split(&(*h2)[2], &carry, carry + (t_fnv1a_double_digit)(*h1)[2]*fnv1a_256_prime[0] + (t_fnv1a_double_digit)(*h1)[0]*fnv1a_256_prime[2]);
    split(&(*h2)[3], &carry, carry + (t_fnv1a_double_digit)(*h1)[3]*fnv1a_256_prime[0] + (t_fnv1a_double_digit)(*h1)[1]*fnv1a_256_prime[2]);
}

void fnv1a_256_update(t_fnv1a_256 *hash, const void *data, size_t size)
{
    t_fnv1a_256 hash2;
    size_t i;
    if (size == 0) { return; }
    for (i = 0; i < size-1; i += 2) {
        step_256(((const uint8_t *)data)[i], hash, &hash2);
        step_256(((const uint8_t *)data)[i+1], &hash2, hash);
    }
    if (i < size) {
        step_256(((const uint8_t *)data)[i], hash, &hash2);
        memcpy(hash, &hash2, sizeof(t_fnv1a_256));
    }
}

void fnv1a_256_digest(const t_fnv1a_256 *hash, t_fnv1a_256_digest digest)
{
    to_hex_big(*hash, sizeof(*hash), digest);
}

/******************************************************************************
 * FNV1A - 512 bit
 *****************************************************************************/

static const t_fnv1a_512 fnv1a_512_offset_basis  = {
    [7] = 0xb86db0b1171f4416,
    [6] = 0xdca1e50f309990ac,
    [5] = 0xac87d059c9000000,
    [4] = 0x0000000000000d21,
    [3] = 0xe948f68a34c192f6,
    [2] = 0x2ea79bc942dbe7ce,
    [1] = 0x182036415f56e34b,
    [0] = 0xac982aac4afe9fd9,
};

static const t_fnv1a_512 fnv1a_512_prime = {
    [5] = 1<<(344 - 5*64),
    [0] = 1<<8 | 0x57,
};

void fnv1a_512_init(t_fnv1a_512 *hash)
{
    memcpy(hash, &fnv1a_512_offset_basis, sizeof(t_fnv1a_512));
}

static inline void step_512(uint8_t data, t_fnv1a_512 *h1, t_fnv1a_512 *h2)
{
    t_fnv1a_digit carry = 0;
    (*h1)[0] ^= data;
    split(&(*h2)[0], &carry, carry + (t_fnv1a_double_digit)(*h1)[0]*fnv1a_512_prime[0]);
    split(&(*h2)[1], &carry, carry + (t_fnv1a_double_digit)(*h1)[1]*fnv1a_512_prime[0]);
    split(&(*h2)[2], &carry, carry + (t_fnv1a_double_digit)(*h1)[2]*fnv1a_512_prime[0]);
    split(&(*h2)[3], &carry, carry + (t_fnv1a_double_digit)(*h1)[3]*fnv1a_512_prime[0]);
    split(&(*h2)[4], &carry, carry + (t_fnv1a_double_digit)(*h1)[4]*fnv1a_512_prime[0]);
    split(&(*h2)[5], &carry, carry + (t_fnv1a_double_digit)(*h1)[5]*fnv1a_512_prime[0] + (t_fnv1a_double_digit)(*h1)[0]*fnv1a_512_prime[5]);
    split(&(*h2)[6], &carry, carry + (t_fnv1a_double_digit)(*h1)[6]*fnv1a_512_prime[0] + (t_fnv1a_double_digit)(*h1)[1]*fnv1a_512_prime[5]);
    split(&(*h2)[7], &carry, carry + (t_fnv1a_double_digit)(*h1)[7]*fnv1a_512_prime[0] + (t_fnv1a_double_digit)(*h1)[2]*fnv1a_512_prime[5]);
}

void fnv1a_512_update(t_fnv1a_512 *hash, const void *data, size_t size)
{
    t_fnv1a_512 hash2;
    size_t i;
    if (size == 0) { return; }
    for (i = 0; i < size-1; i += 2) {
        step_512(((const uint8_t *)data)[i], hash, &hash2);
        step_512(((const uint8_t *)data)[i+1], &hash2, hash);
    }
    if (i < size) {
        step_512(((const uint8_t *)data)[i], hash, &hash2);
        memcpy(hash, &hash2, sizeof(t_fnv1a_512));
    }
}

void fnv1a_512_digest(const t_fnv1a_512 *hash, t_fnv1a_512_digest digest)
{
    to_hex_big(*hash, sizeof(*hash), digest);
}

/******************************************************************************
 * FNV1A - 1024 bit
 *****************************************************************************/

static const t_fnv1a_1024 fnv1a_1024_offset_basis  = {
    [15] = 0x0000000000000000,
    [14] = 0x005f7a76758ecc4d,
    [13] = 0x32e56d5a591028b7,
    [12] = 0x4b29fc4223fdada1,
    [11] = 0x6c3bf34eda3674da,
    [10] = 0x9a21d90000000000,
    [ 9] = 0x0000000000000000,
    [ 8] = 0x0000000000000000,
    [ 7] = 0x0000000000000000,
    [ 6] = 0x0000000000000000,
    [ 5] = 0x0000000000000000,
    [ 4] = 0x000000000004c6d7,
    [ 3] = 0xeb6e73802734510a,
    [ 2] = 0x555f256cc005ae55,
    [ 1] = 0x6bde8cc9c6a93b21,
    [ 0] = 0xaff4b16c71ee90b3,
};

static const t_fnv1a_1024 fnv1a_1024_prime = {
    [10] = 1ULL<<(680 - 10*64),
    [ 0] = 1<<8 | 0x8d,
};

void fnv1a_1024_init(t_fnv1a_1024 *hash)
{
    memcpy(hash, &fnv1a_1024_offset_basis, sizeof(t_fnv1a_1024));
}

static inline void step_1024(uint8_t data, t_fnv1a_1024 *h1, t_fnv1a_1024 *h2)
{
    t_fnv1a_digit carry = 0;
    (*h1)[0] ^= data;
    split(&(*h2)[ 0], &carry, carry + (t_fnv1a_double_digit)(*h1)[ 0]*fnv1a_1024_prime[0]);
    split(&(*h2)[ 1], &carry, carry + (t_fnv1a_double_digit)(*h1)[ 1]*fnv1a_1024_prime[0]);
    split(&(*h2)[ 2], &carry, carry + (t_fnv1a_double_digit)(*h1)[ 2]*fnv1a_1024_prime[0]);
    split(&(*h2)[ 3], &carry, carry + (t_fnv1a_double_digit)(*h1)[ 3]*fnv1a_1024_prime[0]);
    split(&(*h2)[ 4], &carry, carry + (t_fnv1a_double_digit)(*h1)[ 4]*fnv1a_1024_prime[0]);
    split(&(*h2)[ 5], &carry, carry + (t_fnv1a_double_digit)(*h1)[ 5]*fnv1a_1024_prime[0]);
    split(&(*h2)[ 6], &carry, carry + (t_fnv1a_double_digit)(*h1)[ 6]*fnv1a_1024_prime[0]);
    split(&(*h2)[ 7], &carry, carry + (t_fnv1a_double_digit)(*h1)[ 7]*fnv1a_1024_prime[0]);
    split(&(*h2)[ 8], &carry, carry + (t_fnv1a_double_digit)(*h1)[ 8]*fnv1a_1024_prime[0]);
    split(&(*h2)[ 9], &carry, carry + (t_fnv1a_double_digit)(*h1)[ 9]*fnv1a_1024_prime[0]);
    split(&(*h2)[10], &carry, carry + (t_fnv1a_double_digit)(*h1)[10]*fnv1a_1024_prime[0] + (t_fnv1a_double_digit)(*h1)[ 0]*fnv1a_1024_prime[10]);
    split(&(*h2)[11], &carry, carry + (t_fnv1a_double_digit)(*h1)[11]*fnv1a_1024_prime[0] + (t_fnv1a_double_digit)(*h1)[ 1]*fnv1a_1024_prime[10]);
    split(&(*h2)[12], &carry, carry + (t_fnv1a_double_digit)(*h1)[12]*fnv1a_1024_prime[0] + (t_fnv1a_double_digit)(*h1)[ 2]*fnv1a_1024_prime[10]);
    split(&(*h2)[13], &carry, carry + (t_fnv1a_double_digit)(*h1)[13]*fnv1a_1024_prime[0] + (t_fnv1a_double_digit)(*h1)[ 3]*fnv1a_1024_prime[10]);
    split(&(*h2)[14], &carry, carry + (t_fnv1a_double_digit)(*h1)[14]*fnv1a_1024_prime[0] + (t_fnv1a_double_digit)(*h1)[ 4]*fnv1a_1024_prime[10]);
    split(&(*h2)[15], &carry, carry + (t_fnv1a_double_digit)(*h1)[15]*fnv1a_1024_prime[0] + (t_fnv1a_double_digit)(*h1)[ 5]*fnv1a_1024_prime[10]);
}

void fnv1a_1024_update(t_fnv1a_1024 *hash, const void *data, size_t size)
{
    t_fnv1a_1024 hash2;
    size_t i;
    if (size == 0) { return; }
    for (i = 0; i < size-1; i += 2) {
        step_1024(((const uint8_t *)data)[i], hash, &hash2);
        step_1024(((const uint8_t *)data)[i+1], &hash2, hash);
    }
    if (i < size) {
        step_1024(((const uint8_t *)data)[i], hash, &hash2);
        memcpy(hash, &hash2, sizeof(t_fnv1a_1024));
    }
}

void fnv1a_1024_digest(const t_fnv1a_1024 *hash, t_fnv1a_1024_digest digest)
{
    to_hex_big(*hash, sizeof(*hash), digest);
}
