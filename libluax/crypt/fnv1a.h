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

/* FNV-1a hash for various sizes
 * http://www.isthe.com/chongo/tech/comp/fnv/index.html
 * https://en.wikipedia.org/wiki/Fowler%E2%80%93Noll%E2%80%93Vo_hash_function
 */

#include <stdint.h>
#include <stdlib.h>

#if defined(__clang__) && __clang_major__ >= 16 || defined(__GNUC__) && __GNUC__ >= 13
#define HAS_BITINT 1
#endif

/* 32-bit FNV-1a */

typedef uint32_t t_fnv1a_32;

static const t_fnv1a_32 fnv1a_32_init  = 0x811c9dc5;
static const t_fnv1a_32 fnv1a_32_prime = (t_fnv1a_32)1<<24 | (t_fnv1a_32)1<<8 | 0x93;

static inline void fnv1a_32_u8(t_fnv1a_32 *hash, uint8_t b) {
    *hash = (*hash ^ b) * fnv1a_32_prime;
}

static inline void fnv1a_32_u16(t_fnv1a_32 *hash, uint16_t n) {
    for (size_t i = 0; i < sizeof(uint16_t); i++) {
        fnv1a_32_u8(hash, (uint8_t)(n>>(8*i)));
    }
}

static inline void fnv1a_32_u32(t_fnv1a_32 *hash, uint32_t n) {
    for (size_t i = 0; i < sizeof(uint32_t); i++) {
        fnv1a_32_u8(hash, (uint8_t)(n>>(8*i)));
    }
}

static inline void fnv1a_32_u64(t_fnv1a_32 *hash, uint64_t n) {
    for (size_t i = 0; i < sizeof(uint64_t); i++) {
        fnv1a_32_u8(hash, (uint8_t)(n>>(8*i)));
    }
}

static inline void fnv1a_32(t_fnv1a_32 *hash, const uint8_t bs[], size_t len) {
    for (size_t i = 0; i < len; i++) {
        fnv1a_32_u8(hash, bs[i]);
    }
}

/* 64-bit FNV-1a */

typedef uint64_t t_fnv1a_64;

static const t_fnv1a_64 fnv1a_64_init  = 0xcbf29ce484222325;
static const t_fnv1a_64 fnv1a_64_prime = (t_fnv1a_64)1<<40 | (t_fnv1a_64)1<<8 | 0xb3;

static inline void fnv1a_64_u8(t_fnv1a_64 *hash, uint8_t b) {
    *hash = (*hash ^ b) * fnv1a_64_prime;
}

static inline void fnv1a_64_u16(t_fnv1a_64 *hash, uint16_t n) {
    for (size_t i = 0; i < sizeof(uint16_t); i++) {
        fnv1a_64_u8(hash, (uint8_t)(n>>(8*i)));
    }
}

static inline void fnv1a_64_u32(t_fnv1a_64 *hash, uint32_t n) {
    for (size_t i = 0; i < sizeof(uint32_t); i++) {
        fnv1a_64_u8(hash, (uint8_t)(n>>(8*i)));
    }
}

static inline void fnv1a_64_u64(t_fnv1a_64 *hash, uint64_t n) {
    for (size_t i = 0; i < sizeof(uint64_t); i++) {
        fnv1a_64_u8(hash, (uint8_t)(n>>(8*i)));
    }
}

static inline void fnv1a_64(t_fnv1a_64 *hash, const uint8_t bs[], size_t len) {
    for (size_t i = 0; i < len; i++) {
        fnv1a_64_u8(hash, bs[i]);
    }
}

/* 128-bit FNV-1a */

#ifdef HAS_BITINT

typedef unsigned _BitInt(128) t_fnv1a_128;

static const t_fnv1a_128 fnv1a_128_init  = (t_fnv1a_128)0x6c62272e07bb0142<<64 | 0x62b821756295c58d;
static const t_fnv1a_128 fnv1a_128_prime = (t_fnv1a_128)1<<88 | (t_fnv1a_128)1<<8 | 0x3b;

#else

typedef struct { uint32_t d, c, b, a; } t_fnv1a_128;

static const t_fnv1a_128 fnv1a_128_init  = { .a = 0x6c62272e, .b = 0x07bb0142, .c = 0x62b82175, .d = 0x6295c58d };
static const t_fnv1a_128 fnv1a_128_prime = { .a = 0, .b = 1<<(88-2*32), .c = 0, .d = 1<<8 | 0x3b };

static inline void split(uint32_t *digit, uint32_t *carry, uint64_t n)
{
    *digit = n & 0xFFFFFFFF;
    *carry = n >> 32;
}

#endif

static inline void fnv1a_128_u8(t_fnv1a_128 *hash, uint8_t b) {
#ifdef HAS_BITINT
     *hash = (*hash ^ b) * fnv1a_128_prime;
#else
    t_fnv1a_128 hash2;
    uint32_t carry;
    hash->d ^= b;
    split(&hash2.d, &carry,         (uint64_t)hash->d*fnv1a_128_prime.d);
    split(&hash2.c, &carry, carry + (uint64_t)hash->c*fnv1a_128_prime.d);
    split(&hash2.b, &carry, carry + (uint64_t)hash->b*fnv1a_128_prime.d + (uint64_t)hash->d*fnv1a_128_prime.b);
    split(&hash2.a, &carry, carry + (uint64_t)hash->a*fnv1a_128_prime.d + (uint64_t)hash->c*fnv1a_128_prime.b);
    *hash = hash2;
#endif
}

static inline void fnv1a_128_u16(t_fnv1a_128 *hash, uint16_t n) {
    for (size_t i = 0; i < sizeof(uint16_t); i++) {
        fnv1a_128_u8(hash, (uint8_t)(n>>(8*i)));
    }
}

static inline void fnv1a_128_u32(t_fnv1a_128 *hash, uint32_t n) {
    for (size_t i = 0; i < sizeof(uint32_t); i++) {
        fnv1a_128_u8(hash, (uint8_t)(n>>(8*i)));
    }
}

static inline void fnv1a_128_u64(t_fnv1a_128 *hash, uint64_t n) {
    for (size_t i = 0; i < sizeof(uint64_t); i++) {
        fnv1a_128_u8(hash, (uint8_t)(n>>(8*i)));
    }
}

static inline void fnv1a_128(t_fnv1a_128 *hash, const uint8_t bs[], size_t len) {
    for (size_t i = 0; i < len; i++) {
        fnv1a_128_u8(hash, bs[i]);
    }
}
