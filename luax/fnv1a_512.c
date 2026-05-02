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

#include "fnv1a_512.h"

#include <string.h>

#ifdef FNV1A_BITINT

static const t_fnv1a_512 fnv1a_512_offset_basis = (t_fnv1a_512)0xb86db0b1171f4416 << (64*7)
                                                | (t_fnv1a_512)0xdca1e50f309990ac << (64*6)
                                                | (t_fnv1a_512)0xac87d059c9000000 << (64*5)
                                                | (t_fnv1a_512)0x0000000000000d21 << (64*4)
                                                | (t_fnv1a_512)0xe948f68a34c192f6 << (64*3)
                                                | (t_fnv1a_512)0x2ea79bc942dbe7ce << (64*2)
                                                | (t_fnv1a_512)0x182036415f56e34b << (64*1)
                                                | (t_fnv1a_512)0xac982aac4afe9fd9 << (64*0);

static const t_fnv1a_512 fnv1a_512_prime = (t_fnv1a_512)1<<344 | (t_fnv1a_512)1<<8 | 0x57;

#else
#ifdef FNV1A_BIT128

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

#else

static const t_fnv1a_512 fnv1a_512_offset_basis  = {
    [15] = 0xb86db0b1, [14] = 0x171f4416,
    [13] = 0xdca1e50f, [12] = 0x309990ac,
    [11] = 0xac87d059, [10] = 0xc9000000,
    [ 9] = 0x00000000, [ 8] = 0x00000d21,
    [ 7] = 0xe948f68a, [ 6] = 0x34c192f6,
    [ 5] = 0x2ea79bc9, [ 4] = 0x42dbe7ce,
    [ 3] = 0x18203641, [ 2] = 0x5f56e34b,
    [ 1] = 0xac982aac, [ 0] = 0x4afe9fd9,
};

static const t_fnv1a_512 fnv1a_512_prime = {
    [10] = 1<<(344 - 10*32),
    [ 0] = 1<<8 | 0x57,
};

#endif
#endif

void fnv1a_512_init(t_fnv1a_512 *hash)
{
    memcpy(hash, &fnv1a_512_offset_basis, sizeof(t_fnv1a_512));
}

#ifdef FNV1A_BITINT

void fnv1a_512_update(t_fnv1a_512 *hash, const void *data, size_t size)
{
    t_fnv1a_512 h = *hash;
    for (size_t i = 0; i < size; i++) {
        h ^= ((const uint8_t *)data)[i];
        h *= fnv1a_512_prime;
    }
    *hash = h;
}

#else

static inline void split(t_fnv1a_512_digit *digit, t_fnv1a_512_digit *carry, t_fnv1a_512_double_digit n) {
    *digit = n & (t_fnv1a_512_digit)~0;
    *carry = n >> 8*sizeof(t_fnv1a_512_digit);
}

#ifdef FNV1A_BIT128

static inline void step(uint8_t data, t_fnv1a_512 *h1, t_fnv1a_512 *h2) {
    t_fnv1a_512_digit carry = 0;
    (*h1)[0] ^= data;
    split(&(*h2)[0], &carry, carry + (t_fnv1a_512_double_digit)(*h1)[0]*fnv1a_512_prime[0]);
    split(&(*h2)[1], &carry, carry + (t_fnv1a_512_double_digit)(*h1)[1]*fnv1a_512_prime[0]);
    split(&(*h2)[2], &carry, carry + (t_fnv1a_512_double_digit)(*h1)[2]*fnv1a_512_prime[0]);
    split(&(*h2)[3], &carry, carry + (t_fnv1a_512_double_digit)(*h1)[3]*fnv1a_512_prime[0]);
    split(&(*h2)[4], &carry, carry + (t_fnv1a_512_double_digit)(*h1)[4]*fnv1a_512_prime[0]);
    split(&(*h2)[5], &carry, carry + (t_fnv1a_512_double_digit)(*h1)[5]*fnv1a_512_prime[0] + (t_fnv1a_512_double_digit)(*h1)[0]*fnv1a_512_prime[5]);
    split(&(*h2)[6], &carry, carry + (t_fnv1a_512_double_digit)(*h1)[6]*fnv1a_512_prime[0] + (t_fnv1a_512_double_digit)(*h1)[1]*fnv1a_512_prime[5]);
    split(&(*h2)[7], &carry, carry + (t_fnv1a_512_double_digit)(*h1)[7]*fnv1a_512_prime[0] + (t_fnv1a_512_double_digit)(*h1)[2]*fnv1a_512_prime[5]);
}

#else

static inline void step(uint8_t data, t_fnv1a_512 *h1, t_fnv1a_512 *h2) {
    t_fnv1a_512_digit carry = 0;
    (*h1)[0] ^= data;
    split(&(*h2)[ 0], &carry, carry + (t_fnv1a_512_double_digit)(*h1)[ 0]*fnv1a_512_prime[0]);
    split(&(*h2)[ 1], &carry, carry + (t_fnv1a_512_double_digit)(*h1)[ 1]*fnv1a_512_prime[0]);
    split(&(*h2)[ 2], &carry, carry + (t_fnv1a_512_double_digit)(*h1)[ 2]*fnv1a_512_prime[0]);
    split(&(*h2)[ 3], &carry, carry + (t_fnv1a_512_double_digit)(*h1)[ 3]*fnv1a_512_prime[0]);
    split(&(*h2)[ 4], &carry, carry + (t_fnv1a_512_double_digit)(*h1)[ 4]*fnv1a_512_prime[0]);
    split(&(*h2)[ 5], &carry, carry + (t_fnv1a_512_double_digit)(*h1)[ 5]*fnv1a_512_prime[0]);
    split(&(*h2)[ 6], &carry, carry + (t_fnv1a_512_double_digit)(*h1)[ 6]*fnv1a_512_prime[0]);
    split(&(*h2)[ 7], &carry, carry + (t_fnv1a_512_double_digit)(*h1)[ 7]*fnv1a_512_prime[0]);
    split(&(*h2)[ 8], &carry, carry + (t_fnv1a_512_double_digit)(*h1)[ 8]*fnv1a_512_prime[0]);
    split(&(*h2)[ 9], &carry, carry + (t_fnv1a_512_double_digit)(*h1)[ 9]*fnv1a_512_prime[0]);
    split(&(*h2)[10], &carry, carry + (t_fnv1a_512_double_digit)(*h1)[10]*fnv1a_512_prime[0] + (t_fnv1a_512_double_digit)(*h1)[0]*fnv1a_512_prime[10]);
    split(&(*h2)[11], &carry, carry + (t_fnv1a_512_double_digit)(*h1)[11]*fnv1a_512_prime[0] + (t_fnv1a_512_double_digit)(*h1)[1]*fnv1a_512_prime[10]);
    split(&(*h2)[12], &carry, carry + (t_fnv1a_512_double_digit)(*h1)[12]*fnv1a_512_prime[0] + (t_fnv1a_512_double_digit)(*h1)[2]*fnv1a_512_prime[10]);
    split(&(*h2)[13], &carry, carry + (t_fnv1a_512_double_digit)(*h1)[13]*fnv1a_512_prime[0] + (t_fnv1a_512_double_digit)(*h1)[3]*fnv1a_512_prime[10]);
    split(&(*h2)[14], &carry, carry + (t_fnv1a_512_double_digit)(*h1)[14]*fnv1a_512_prime[0] + (t_fnv1a_512_double_digit)(*h1)[4]*fnv1a_512_prime[10]);
    split(&(*h2)[15], &carry, carry + (t_fnv1a_512_double_digit)(*h1)[15]*fnv1a_512_prime[0] + (t_fnv1a_512_double_digit)(*h1)[5]*fnv1a_512_prime[10]);
}

#endif

void fnv1a_512_update(t_fnv1a_512 *hash, const void *data, size_t size)
{
    t_fnv1a_512 hash2;
    size_t i;
    if (size == 0) { return; }
    for (i = 0; i < size-1; i += 2) {
        step(((const uint8_t *)data)[i], hash, &hash2);
        step(((const uint8_t *)data)[i+1], &hash2, hash);
    }
    if (i < size) {
        step(((const uint8_t *)data)[i], hash, &hash2);
        memcpy(hash, &hash2, sizeof(t_fnv1a_512));
    }
}

#endif

static inline char digit(uint8_t n)
{
    return n>=10 ? 'a'+(n-10) : '0'+n;
}

void fnv1a_512_digest(const t_fnv1a_512 *hash, t_fnv1a_512_digest digest)
{
    for (size_t i = 0; i < (sizeof(t_fnv1a_512)); i++) {
        const uint8_t b = ((const uint8_t*)(hash))[i];
        digest[2*i+0] = digit(b>>4);
        digest[2*i+1] = digit(b&0xf);
    }
    digest[sizeof(t_fnv1a_512_digest)-1] = '\0';
}

int fnv1a_512_cmp(const t_fnv1a_512 *hash1, const t_fnv1a_512 *hash2)
{
    return memcmp(hash1, hash2, sizeof(t_fnv1a_512));
}
