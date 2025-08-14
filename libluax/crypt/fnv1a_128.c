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
 * along with luax.  If not, see <https://www.gnu.org/licenses/>.
 *
 * For further information about fnv1a you can visit
 * https://codeberg.org/cdsoft/fnv1a
 */

#include "fnv1a_128.h"

#include <string.h>

#if defined(FNV1A_BITINT) || defined(FNV1A_BIT128)

static const t_fnv1a_128 fnv1a_128_offset_basis = (t_fnv1a_128)0x6c62272e07bb0142 << (64*1)
                                                | (t_fnv1a_128)0x62b821756295c58d << (64*0);

static const t_fnv1a_128 fnv1a_128_prime = (t_fnv1a_128)1<<88 | (t_fnv1a_128)1<<8 | 0x3b;

#else

static const t_fnv1a_128 fnv1a_128_offset_basis  = {
    [3] = 0x6c62272e, [2] = 0x07bb0142,
    [1] = 0x62b82175, [0] = 0x6295c58d,
};

static const t_fnv1a_128 fnv1a_128_prime = {
    [2] = 1<<(88-2*32),
    [0] = 1<<8 | 0x3b,
};

#endif

void fnv1a_128_init(t_fnv1a_128 *hash)
{
    memcpy(hash, &fnv1a_128_offset_basis, sizeof(fnv1a_128_offset_basis));
}

#if defined(FNV1A_BITINT) || defined(FNV1A_BIT128)

void fnv1a_128_update(t_fnv1a_128 *hash, const void *data, size_t size)
{
    t_fnv1a_128 h = *hash;
    for (size_t i = 0; i < size; i++) {
        h ^= ((const uint8_t *)data)[i];
        h *= fnv1a_128_prime;
    }
    *hash = h;
}

#else

static inline void split(t_fnv1a_128_digit *digit, t_fnv1a_128_digit *carry, t_fnv1a_128_double_digit n) {
    *digit = n & (t_fnv1a_128_digit)~0;
    *carry = n >> 8*sizeof(t_fnv1a_128_digit);
}

static inline void step(uint8_t data, t_fnv1a_128 *h1, t_fnv1a_128 *h2) {
    t_fnv1a_128_digit carry = 0;
    (*h1)[0] ^= data;
    split(&(*h2)[0], &carry, carry + (t_fnv1a_128_double_digit)(*h1)[0]*fnv1a_128_prime[0]);
    split(&(*h2)[1], &carry, carry + (t_fnv1a_128_double_digit)(*h1)[1]*fnv1a_128_prime[0]);
    split(&(*h2)[2], &carry, carry + (t_fnv1a_128_double_digit)(*h1)[2]*fnv1a_128_prime[0] + (t_fnv1a_128_double_digit)(*h1)[0]*fnv1a_128_prime[2]);
    split(&(*h2)[3], &carry, carry + (t_fnv1a_128_double_digit)(*h1)[3]*fnv1a_128_prime[0] + (t_fnv1a_128_double_digit)(*h1)[1]*fnv1a_128_prime[2]);
}

void fnv1a_128_update(t_fnv1a_128 *hash, const void *data, size_t size)
{
    t_fnv1a_128 hash2;
    size_t i;
    if (size == 0) { return; }
    for (i = 0; i < size-1; i += 2) {
        step(((const uint8_t *)data)[i], hash, &hash2);
        step(((const uint8_t *)data)[i+1], &hash2, hash);
    }
    if (i < size) {
        step(((const uint8_t *)data)[i], hash, &hash2);
        memcpy(hash, &hash2, sizeof(t_fnv1a_128));
    }
}

#endif

static inline char digit(uint8_t n)
{
    return n>=10 ? 'a'+(n-10) : '0'+n;
}

void fnv1a_128_digest(const t_fnv1a_128 *hash, t_fnv1a_128_digest digest)
{
    for (size_t i = 0; i < sizeof(t_fnv1a_128); i++) {
        const uint8_t b = ((const uint8_t*)(hash))[i];
        digest[2*i+0] = digit(b>>4);
        digest[2*i+1] = digit(b&0xf);
    }
    digest[sizeof(t_fnv1a_128_digest)-1] = '\0';
}

int fnv1a_128_cmp(const t_fnv1a_128 *hash1, const t_fnv1a_128 *hash2)
{
    return memcmp(hash1, hash2, sizeof(t_fnv1a_128));
}
