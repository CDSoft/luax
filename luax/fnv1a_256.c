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

#include "fnv1a_256.h"

#include <string.h>

#ifdef FNV1A_BITINT

static const t_fnv1a_256 fnv1a_256_offset_basis = (t_fnv1a_256)0xdd268dbcaac55036 << (64*3)
                                                | (t_fnv1a_256)0x2d98c384c4e576cc << (64*2)
                                                | (t_fnv1a_256)0xc8b1536847b6bbb3 << (64*1)
                                                | (t_fnv1a_256)0x1023b4c8caee0535 << (64*0);

static const t_fnv1a_256 fnv1a_256_prime = (t_fnv1a_256)1<<168 | (t_fnv1a_256)1<<8 | 0x63;

#else
#ifdef FNV1A_BIT128

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

#else

static const t_fnv1a_256 fnv1a_256_offset_basis  = {
    [7] = 0xdd268dbc, [6] = 0xaac55036,
    [5] = 0x2d98c384, [4] = 0xc4e576cc,
    [3] = 0xc8b15368, [2] = 0x47b6bbb3,
    [1] = 0x1023b4c8, [0] = 0xcaee0535,
};

static const t_fnv1a_256 fnv1a_256_prime = {
    [5] = 1<<(168 - 5*32),
    [0] = 1<<8 | 0x63,
};

#endif
#endif

void fnv1a_256_init(t_fnv1a_256 *hash)
{
    memcpy(hash, &fnv1a_256_offset_basis, sizeof(t_fnv1a_256));
}

#ifdef FNV1A_BITINT

void fnv1a_256_update(t_fnv1a_256 *hash, const void *data, size_t size)
{
    t_fnv1a_256 h = *hash;
    for (size_t i = 0; i < size; i++) {
        h ^= ((const uint8_t *)data)[i];
        h *= fnv1a_256_prime;
    }
    *hash = h;
}

#else

static inline void split(t_fnv1a_256_digit *digit, t_fnv1a_256_digit *carry, t_fnv1a_256_double_digit n) {
    *digit = n & (t_fnv1a_256_digit)~0;
    *carry = n >> 8*sizeof(t_fnv1a_256_digit);
}

#ifdef FNV1A_BIT128

static inline void step(uint8_t data, t_fnv1a_256 *h1, t_fnv1a_256 *h2) {
    t_fnv1a_256_digit carry = 0;
    (*h1)[0] ^= data;
    split(&(*h2)[0], &carry, carry + (t_fnv1a_256_double_digit)(*h1)[0]*fnv1a_256_prime[0]);
    split(&(*h2)[1], &carry, carry + (t_fnv1a_256_double_digit)(*h1)[1]*fnv1a_256_prime[0]);
    split(&(*h2)[2], &carry, carry + (t_fnv1a_256_double_digit)(*h1)[2]*fnv1a_256_prime[0] + (t_fnv1a_256_double_digit)(*h1)[0]*fnv1a_256_prime[2]);
    split(&(*h2)[3], &carry, carry + (t_fnv1a_256_double_digit)(*h1)[3]*fnv1a_256_prime[0] + (t_fnv1a_256_double_digit)(*h1)[1]*fnv1a_256_prime[2]);
}

#else

static inline void step(uint8_t data, t_fnv1a_256 *h1, t_fnv1a_256 *h2) {
    t_fnv1a_256_digit carry = 0;
    (*h1)[0] ^= data;
    split(&(*h2)[0], &carry, carry + (t_fnv1a_256_double_digit)(*h1)[0]*fnv1a_256_prime[0]);
    split(&(*h2)[1], &carry, carry + (t_fnv1a_256_double_digit)(*h1)[1]*fnv1a_256_prime[0]);
    split(&(*h2)[2], &carry, carry + (t_fnv1a_256_double_digit)(*h1)[2]*fnv1a_256_prime[0]);
    split(&(*h2)[3], &carry, carry + (t_fnv1a_256_double_digit)(*h1)[3]*fnv1a_256_prime[0]);
    split(&(*h2)[4], &carry, carry + (t_fnv1a_256_double_digit)(*h1)[4]*fnv1a_256_prime[0]);
    split(&(*h2)[5], &carry, carry + (t_fnv1a_256_double_digit)(*h1)[5]*fnv1a_256_prime[0] + (t_fnv1a_256_double_digit)(*h1)[0]*fnv1a_256_prime[5]);
    split(&(*h2)[6], &carry, carry + (t_fnv1a_256_double_digit)(*h1)[6]*fnv1a_256_prime[0] + (t_fnv1a_256_double_digit)(*h1)[1]*fnv1a_256_prime[5]);
    split(&(*h2)[7], &carry, carry + (t_fnv1a_256_double_digit)(*h1)[7]*fnv1a_256_prime[0] + (t_fnv1a_256_double_digit)(*h1)[2]*fnv1a_256_prime[5]);
}

#endif

void fnv1a_256_update(t_fnv1a_256 *hash, const void *data, size_t size)
{
    t_fnv1a_256 hash2;
    size_t i;
    if (size == 0) { return; }
    for (i = 0; i < size-1; i += 2) {
        step(((const uint8_t *)data)[i], hash, &hash2);
        step(((const uint8_t *)data)[i+1], &hash2, hash);
    }
    if (i < size) {
        step(((const uint8_t *)data)[i], hash, &hash2);
        memcpy(hash, &hash2, sizeof(t_fnv1a_256));
    }
}

#endif

static inline char digit(uint8_t n)
{
    return n>=10 ? 'a'+(n-10) : '0'+n;
}

void fnv1a_256_digest(const t_fnv1a_256 *hash, t_fnv1a_256_digest digest)
{
    for (size_t i = 0; i < (sizeof(t_fnv1a_256)); i++) {
        const uint8_t b = ((const uint8_t*)(hash))[i];
        digest[2*i+0] = digit(b>>4);
        digest[2*i+1] = digit(b&0xf);
    }
    digest[sizeof(t_fnv1a_256_digest)-1] = '\0';
}

int fnv1a_256_cmp(const t_fnv1a_256 *hash1, const t_fnv1a_256 *hash2)
{
    return memcmp(hash1, hash2, sizeof(t_fnv1a_256));
}
