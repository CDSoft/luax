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

#include "fnv1a_1024.h"

#include <string.h>

#ifdef FNV1A_BITINT

static const t_fnv1a_1024 fnv1a_1024_offset_basis = (t_fnv1a_1024)0x0000000000000000 << (64*15)
                                                  | (t_fnv1a_1024)0x005f7a76758ecc4d << (64*14)
                                                  | (t_fnv1a_1024)0x32e56d5a591028b7 << (64*13)
                                                  | (t_fnv1a_1024)0x4b29fc4223fdada1 << (64*12)
                                                  | (t_fnv1a_1024)0x6c3bf34eda3674da << (64*11)
                                                  | (t_fnv1a_1024)0x9a21d90000000000 << (64*10)
                                                  | (t_fnv1a_1024)0x0000000000000000 << (64* 9)
                                                  | (t_fnv1a_1024)0x0000000000000000 << (64* 8)
                                                  | (t_fnv1a_1024)0x0000000000000000 << (64* 7)
                                                  | (t_fnv1a_1024)0x0000000000000000 << (64* 6)
                                                  | (t_fnv1a_1024)0x0000000000000000 << (64* 5)
                                                  | (t_fnv1a_1024)0x000000000004c6d7 << (64* 4)
                                                  | (t_fnv1a_1024)0xeb6e73802734510a << (64* 3)
                                                  | (t_fnv1a_1024)0x555f256cc005ae55 << (64* 2)
                                                  | (t_fnv1a_1024)0x6bde8cc9c6a93b21 << (64* 1)
                                                  | (t_fnv1a_1024)0xaff4b16c71ee90b3 << (64* 0);

static const t_fnv1a_1024 fnv1a_1024_prime = (t_fnv1a_1024)1<<680 | (t_fnv1a_1024)1<<8 | 0x8d;

#else
#ifdef FNV1A_BIT128

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

#else

static const t_fnv1a_1024 fnv1a_1024_offset_basis  = {
    [31] = 0x00000000, [30] = 0x00000000,
    [29] = 0x005f7a76, [28] = 0x758ecc4d,
    [27] = 0x32e56d5a, [26] = 0x591028b7,
    [25] = 0x4b29fc42, [24] = 0x23fdada1,
    [23] = 0x6c3bf34e, [22] = 0xda3674da,
    [21] = 0x9a21d900, [20] = 0x00000000,
    [19] = 0x00000000, [18] = 0x00000000,
    [17] = 0x00000000, [16] = 0x00000000,
    [15] = 0x00000000, [14] = 0x00000000,
    [13] = 0x00000000, [12] = 0x00000000,
    [11] = 0x00000000, [10] = 0x00000000,
    [ 9] = 0x00000000, [ 8] = 0x0004c6d7,
    [ 7] = 0xeb6e7380, [ 6] = 0x2734510a,
    [ 5] = 0x555f256c, [ 4] = 0xc005ae55,
    [ 3] = 0x6bde8cc9, [ 2] = 0xc6a93b21,
    [ 1] = 0xaff4b16c, [ 0] = 0x71ee90b3,
};

static const t_fnv1a_1024 fnv1a_1024_prime = {
    [21] = 1<<(680 - 21*32),
    [ 0] = 1<<8 | 0x8d,
};

#endif
#endif

void fnv1a_1024_init(t_fnv1a_1024 *hash)
{
    memcpy(hash, &fnv1a_1024_offset_basis, sizeof(t_fnv1a_1024));
}

#ifdef FNV1A_BITINT

void fnv1a_1024_update(t_fnv1a_1024 *hash, const void *data, size_t size)
{
    t_fnv1a_1024 h = *hash;
    for (size_t i = 0; i < size; i++) {
        h ^= ((const uint8_t *)data)[i];
        h *= fnv1a_1024_prime;
    }
    *hash = h;
}

#else

static inline void split(t_fnv1a_1024_digit *digit, t_fnv1a_1024_digit *carry, t_fnv1a_1024_double_digit n) {
    *digit = n & (t_fnv1a_1024_digit)~0;
    *carry = n >> 8*sizeof(t_fnv1a_1024_digit);
}

#ifdef FNV1A_BIT128

static inline void step(uint8_t data, t_fnv1a_1024 *h1, t_fnv1a_1024 *h2) {
    t_fnv1a_1024_digit carry = 0;
    (*h1)[0] ^= data;
    split(&(*h2)[ 0], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[ 0]*fnv1a_1024_prime[0]);
    split(&(*h2)[ 1], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[ 1]*fnv1a_1024_prime[0]);
    split(&(*h2)[ 2], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[ 2]*fnv1a_1024_prime[0]);
    split(&(*h2)[ 3], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[ 3]*fnv1a_1024_prime[0]);
    split(&(*h2)[ 4], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[ 4]*fnv1a_1024_prime[0]);
    split(&(*h2)[ 5], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[ 5]*fnv1a_1024_prime[0]);
    split(&(*h2)[ 6], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[ 6]*fnv1a_1024_prime[0]);
    split(&(*h2)[ 7], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[ 7]*fnv1a_1024_prime[0]);
    split(&(*h2)[ 8], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[ 8]*fnv1a_1024_prime[0]);
    split(&(*h2)[ 9], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[ 9]*fnv1a_1024_prime[0]);
    split(&(*h2)[10], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[10]*fnv1a_1024_prime[0] + (t_fnv1a_1024_double_digit)(*h1)[ 0]*fnv1a_1024_prime[10]);
    split(&(*h2)[11], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[11]*fnv1a_1024_prime[0] + (t_fnv1a_1024_double_digit)(*h1)[ 1]*fnv1a_1024_prime[10]);
    split(&(*h2)[12], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[12]*fnv1a_1024_prime[0] + (t_fnv1a_1024_double_digit)(*h1)[ 2]*fnv1a_1024_prime[10]);
    split(&(*h2)[13], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[13]*fnv1a_1024_prime[0] + (t_fnv1a_1024_double_digit)(*h1)[ 3]*fnv1a_1024_prime[10]);
    split(&(*h2)[14], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[14]*fnv1a_1024_prime[0] + (t_fnv1a_1024_double_digit)(*h1)[ 4]*fnv1a_1024_prime[10]);
    split(&(*h2)[15], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[15]*fnv1a_1024_prime[0] + (t_fnv1a_1024_double_digit)(*h1)[ 5]*fnv1a_1024_prime[10]);
}

#else

static void step(uint8_t data, t_fnv1a_1024 *h1, t_fnv1a_1024 *h2) {
    t_fnv1a_1024_digit carry = 0;
    (*h1)[0] ^= data;
    split(&(*h2)[ 0], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[ 0]*fnv1a_1024_prime[0]);
    split(&(*h2)[ 1], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[ 1]*fnv1a_1024_prime[0]);
    split(&(*h2)[ 2], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[ 2]*fnv1a_1024_prime[0]);
    split(&(*h2)[ 3], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[ 3]*fnv1a_1024_prime[0]);
    split(&(*h2)[ 4], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[ 4]*fnv1a_1024_prime[0]);
    split(&(*h2)[ 5], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[ 5]*fnv1a_1024_prime[0]);
    split(&(*h2)[ 6], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[ 6]*fnv1a_1024_prime[0]);
    split(&(*h2)[ 7], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[ 7]*fnv1a_1024_prime[0]);
    split(&(*h2)[ 8], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[ 8]*fnv1a_1024_prime[0]);
    split(&(*h2)[ 9], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[ 9]*fnv1a_1024_prime[0]);
    split(&(*h2)[10], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[10]*fnv1a_1024_prime[0]);
    split(&(*h2)[11], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[11]*fnv1a_1024_prime[0]);
    split(&(*h2)[12], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[12]*fnv1a_1024_prime[0]);
    split(&(*h2)[13], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[13]*fnv1a_1024_prime[0]);
    split(&(*h2)[14], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[14]*fnv1a_1024_prime[0]);
    split(&(*h2)[15], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[15]*fnv1a_1024_prime[0]);
    split(&(*h2)[16], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[16]*fnv1a_1024_prime[0]);
    split(&(*h2)[17], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[17]*fnv1a_1024_prime[0]);
    split(&(*h2)[18], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[18]*fnv1a_1024_prime[0]);
    split(&(*h2)[19], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[19]*fnv1a_1024_prime[0]);
    split(&(*h2)[20], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[20]*fnv1a_1024_prime[0]);
    split(&(*h2)[21], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[21]*fnv1a_1024_prime[0] + (t_fnv1a_1024_double_digit)(*h1)[ 0]*fnv1a_1024_prime[21]);
    split(&(*h2)[22], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[22]*fnv1a_1024_prime[0] + (t_fnv1a_1024_double_digit)(*h1)[ 1]*fnv1a_1024_prime[21]);
    split(&(*h2)[23], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[23]*fnv1a_1024_prime[0] + (t_fnv1a_1024_double_digit)(*h1)[ 2]*fnv1a_1024_prime[21]);
    split(&(*h2)[24], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[24]*fnv1a_1024_prime[0] + (t_fnv1a_1024_double_digit)(*h1)[ 3]*fnv1a_1024_prime[21]);
    split(&(*h2)[25], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[25]*fnv1a_1024_prime[0] + (t_fnv1a_1024_double_digit)(*h1)[ 4]*fnv1a_1024_prime[21]);
    split(&(*h2)[26], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[26]*fnv1a_1024_prime[0] + (t_fnv1a_1024_double_digit)(*h1)[ 5]*fnv1a_1024_prime[21]);
    split(&(*h2)[27], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[27]*fnv1a_1024_prime[0] + (t_fnv1a_1024_double_digit)(*h1)[ 6]*fnv1a_1024_prime[21]);
    split(&(*h2)[28], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[28]*fnv1a_1024_prime[0] + (t_fnv1a_1024_double_digit)(*h1)[ 7]*fnv1a_1024_prime[21]);
    split(&(*h2)[29], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[29]*fnv1a_1024_prime[0] + (t_fnv1a_1024_double_digit)(*h1)[ 8]*fnv1a_1024_prime[21]);
    split(&(*h2)[30], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[30]*fnv1a_1024_prime[0] + (t_fnv1a_1024_double_digit)(*h1)[ 9]*fnv1a_1024_prime[21]);
    split(&(*h2)[31], &carry, carry + (t_fnv1a_1024_double_digit)(*h1)[31]*fnv1a_1024_prime[0] + (t_fnv1a_1024_double_digit)(*h1)[10]*fnv1a_1024_prime[21]);
}

#endif

void fnv1a_1024_update(t_fnv1a_1024 *hash, const void *data, size_t size)
{
    t_fnv1a_1024 hash2;
    size_t i;
    if (size == 0) { return; }
    for (i = 0; i < size-1; i += 2) {
        step(((const uint8_t *)data)[i], hash, &hash2);
        step(((const uint8_t *)data)[i+1], &hash2, hash);
    }
    if (i < size) {
        step(((const uint8_t *)data)[i], hash, &hash2);
        memcpy(hash, &hash2, sizeof(t_fnv1a_1024));
    }
}

#endif

static inline char digit(uint8_t n)
{
    return n>=10 ? 'a'+(n-10) : '0'+n;
}

void fnv1a_1024_digest(const t_fnv1a_1024 *hash, t_fnv1a_1024_digest digest)
{
    for (size_t i = 0; i < (sizeof(t_fnv1a_1024)); i++) {
        const uint8_t b = ((const uint8_t*)(hash))[i];
        digest[2*i+0] = digit(b>>4);
        digest[2*i+1] = digit(b&0xf);
    }
    digest[sizeof(t_fnv1a_1024_digest)-1] = '\0';
}

int fnv1a_1024_cmp(const t_fnv1a_1024 *hash1, const t_fnv1a_1024 *hash2)
{
    return memcmp(hash1, hash2, sizeof(t_fnv1a_1024));
}
