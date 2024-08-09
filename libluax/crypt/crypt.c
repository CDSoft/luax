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
 * http://cdelord.fr/luax
 */

/***************************************************************************@@@
# crypt: cryptography module

```lua
local crypt = require "crypt"
```

`crypt` provides cryptography functions.

**WARNING**: Please do not rely on LuaX `crypt` module if you actually need strong cryptography functions.

@@@*/

#include "crypt.h"

#include "lua.h"
#include "lauxlib.h"

#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/time.h>

#include <unistd.h>

#ifdef _WIN32
#include <windows.h>
#endif

/***************************************************************************@@@
## Random number generator

The LuaX pseudorandom number generator is a
[linear congruential generator](https://en.wikipedia.org/wiki/Linear_congruential_generator).
This generator is not a cryptographically secure pseudorandom number generator.
It can be used as a repeatable generator (e.g. for repeatable tests).

LuaX has a global generator (with a global seed)
and can instantiate independent generators with their own seeds.
@@@*/

#define PRNG_MT "prng"

/* https://www.pcg-random.org/download.html */

typedef struct
{
    uint64_t state;
} t_prng;

#define CRYPT_RAND_MAX 0xFFFFFFFFULL

/* Low level random functions */

static const uint64_t prng_a = 6364136223846793005ULL;
static const uint64_t prng_c = 1ULL;

static inline void prng_advance(t_prng *prng)
{
    // Advance internal state
    prng->state = prng->state*prng_a + prng_c;
}

static inline uint32_t prng_int(t_prng *prng)
{
    const uint64_t oldstate = prng->state;
    // Advance internal state
    prng_advance(prng);
    // Calculate output function (XSH RR), uses old state for max ILP
    const uint32_t xorshifted = (uint32_t)(((oldstate >> 18u) ^ oldstate) >> 27u);
    const uint32_t rot = oldstate >> 59u;
    return (xorshifted >> rot) | (xorshifted << ((-rot) & 31));
}

static inline int64_t prng_int_range(t_prng *prng, int64_t a, int64_t b)
{
    const int64_t n = prng_int(prng);
    return n % (b-a+1) + a;
}

static inline double prng_float(t_prng *prng)
{
    const uint32_t x = prng_int(prng);
    return (double)x / (double)(CRYPT_RAND_MAX);
}

static inline double prng_float_range(t_prng *prng, double a, double b)
{
    const double x = prng_float(prng);
    return x*(b-a) + a;
}

static inline void prng_str(t_prng *prng, size_t size, luaL_Buffer *B)
{
    char *buf = luaL_prepbuffsize(B, size);
    for (size_t i = 0; i < size; i++)
    {
        buf[i] = (char)prng_int(prng);
    }
    luaL_addsize(B, size);
}

static inline void prng_seed(t_prng *prng, uint64_t state)
{
    prng->state = state;
    /* drop the first values */
    prng_advance(prng);
    prng_advance(prng);
}

static inline uint64_t prng_default_seed(void)
{
    struct timeval t;
    gettimeofday(&t, NULL);
    return ((uint64_t)time(NULL) + (uint64_t)t.tv_sec + (uint64_t)t.tv_usec) * (uint64_t)getpid();
}

/***************************************************************************@@@
### Random number generator instance
@@@*/

/*@@@
```lua
local rng = crypt.prng([seed])
```
returns a random number generator starting from the optional seed `seed`.
This object has four methods: `seed([seed])`, `int([m, [n]])`, `float([a, [b]])` and `str(n)`.
@@@*/

static int crypt_prng(lua_State *L)
{
    t_prng *prng = (t_prng *)lua_newuserdata(L, sizeof(t_prng));
    const uint64_t seed = lua_type(L, 1) == LUA_TNUMBER
        ? (uint64_t)luaL_checkinteger(L, 1)
        : prng_default_seed();
    luaL_setmetatable(L, PRNG_MT);
    prng_seed(prng, seed);
    return 1;
}

/*@@@
```lua
rng:seed([seed])
```
sets the seed of the PRNG.
The default seed is a number based on the current time and the process id.
@@@*/

static int crypt_prng_seed(lua_State *L)
{
    t_prng *prng = luaL_checkudata(L, 1, PRNG_MT);
    const uint64_t seed = lua_type(L, 2) == LUA_TNUMBER
        ? (uint64_t)luaL_checkinteger(L, 2)
        : prng_default_seed();
    prng_seed(prng, seed);
    return 0;
}

/*@@@
```lua
rng:int()
```
returns a random integral number between `0` and `crypt.RAND_MAX`.

```lua
rng:int(m)
```
returns a random integral number between `0` and `m`.

```lua
rng:int(m, n)
```
returns a random integral number between `m` and `n`.
@@@*/

static int crypt_prng_int(lua_State *L)
{
    t_prng *prng = luaL_checkudata(L, 1, PRNG_MT);
    if (lua_type(L, 2) == LUA_TNUMBER)
    {
        const lua_Integer m = luaL_checkinteger(L, 2);
        if (lua_type(L, 3) == LUA_TNUMBER)
        {
            const lua_Integer n = luaL_checkinteger(L, 3);
            lua_pushinteger(L, prng_int_range(prng, m, n));
            return 1;
        }
        else
        {
            lua_pushinteger(L, prng_int_range(prng, 0, m));
            return 1;
        }
    }
    else
    {
        lua_pushinteger(L, prng_int(prng));
        return 1;
    }
}

/*@@@
```lua
rng:float()
```
returns a random floating point number between `0.0` and `1.0`.

```lua
rng:float(a)
```
returns a random floating point number between `0.0` and `a`.

```lua
rng:float(a, b)
```
returns a random floating point number between `a` and `b`.
@@@*/

static int crypt_prng_float(lua_State *L)
{
    t_prng *prng = luaL_checkudata(L, 1, PRNG_MT);
    if (lua_type(L, 2) == LUA_TNUMBER)
    {
        const lua_Number a = luaL_checknumber(L, 2);
        if (lua_type(L, 3) == LUA_TNUMBER)
        {
            const lua_Number b = luaL_checknumber(L, 3);
            lua_pushnumber(L, prng_float_range(prng, a, b));
            return 1;
        }
        else
        {
            lua_pushnumber(L, prng_float_range(prng, 0, a));
            return 1;
        }
    }
    else
    {
        lua_pushnumber(L, prng_float(prng));
        return 1;
    }
}

/*@@@
```lua
rng:str(bytes)
```
returns a string with `bytes` random bytes.
@@@*/

static int crypt_prng_str(lua_State *L)
{
    t_prng *prng = luaL_checkudata(L, 1, PRNG_MT);
    const size_t bytes = (size_t)luaL_checkinteger(L, 2);
    luaL_Buffer B;
    luaL_buffinit(L, &B);
    prng_str(prng, bytes, &B);
    luaL_pushresult(&B);
    return 1;
}

static const luaL_Reg prng_funcs[] =
{
    {"seed", crypt_prng_seed},
    {"int", crypt_prng_int},
    {"float", crypt_prng_float},
    {"str", crypt_prng_str},
    {NULL, NULL}
};

/***************************************************************************@@@
### Global random number generator
@@@*/

static t_prng prng;

/*@@@
```lua
crypt.seed([seed])
```
sets the seed of the global PRNG.
The default seed is a number based on the current time and the process id.
@@@*/

static int crypt_seed(lua_State *L)
{
    const uint64_t seed = lua_type(L, 1) == LUA_TNUMBER
        ? (uint64_t)luaL_checkinteger(L, 1)
        : prng_default_seed();
    prng_seed(&prng, seed);
    return 0;
}

/*@@@
```lua
crypt.int()
```
returns a random integral number between `0` and `crypt.RAND_MAX`.

```lua
crypt.int(m)
```
returns a random integral number between `0` and `m`.

```lua
crypt.int(m, n)
```
returns a random integral number between `m` and `n`.
@@@*/

static int crypt_int(lua_State *L)
{
    if (lua_type(L, 1) == LUA_TNUMBER)
    {
        const lua_Integer m = luaL_checkinteger(L, 1);
        if (lua_type(L, 2) == LUA_TNUMBER)
        {
            const lua_Integer n = luaL_checkinteger(L, 2);
            lua_pushinteger(L, prng_int_range(&prng, m, n));
            return 1;
        }
        else
        {
            lua_pushinteger(L, prng_int_range(&prng, 0, m));
            return 1;
        }
    }
    else
    {
        lua_pushinteger(L, prng_int(&prng));
    }
    return 1;
}

/*@@@
```lua
crypt.float()
```
returns a random floating point number between `0.0` and `1.0`.

```lua
crypt.float(a)
```
returns a random floating point number between `0.0` and `a`.

```lua
crypt.float(a, b)
```
returns a random floating point number between `a` and `b`.
@@@*/

static int crypt_float(lua_State *L)
{
    if (lua_type(L, 1) == LUA_TNUMBER)
    {
        const lua_Number a = luaL_checknumber(L, 1);
        if (lua_type(L, 2) == LUA_TNUMBER)
        {
            const lua_Number b = luaL_checknumber(L, 2);
            lua_pushnumber(L, prng_float_range(&prng, a, b));
            return 1;
        }
        else
        {
            lua_pushnumber(L, prng_float_range(&prng, 0, a));
            return 1;
        }
    }
    else
    {
        lua_pushnumber(L, prng_float(&prng));
        return 1;
    }
}

/*@@@
```lua
crypt.str(bytes)
```
returns a string with `bytes` random bytes.
@@@*/

static int crypt_str(lua_State *L)
{
    const size_t bytes = (size_t)luaL_checkinteger(L, 1);
    luaL_Buffer B;
    luaL_buffinit(L, &B);
    prng_str(&prng, bytes, &B);
    luaL_pushresult(&B);
    return 1;
}

/***************************************************************************@@@
## Hexadecimal encoding

The hexadecimal encoder transforms a string into a string
where bytes are coded with hexadecimal digits.
@@@*/

static const char hex_map[16] = "0123456789abcdef";

static const char digit[256] =
{
    ['0'] = 0,      ['A'] = 10,     ['a'] = 10,
    ['1'] = 1,      ['B'] = 11,     ['b'] = 11,
    ['2'] = 2,      ['C'] = 12,     ['c'] = 12,
    ['3'] = 3,      ['D'] = 13,     ['d'] = 13,
    ['4'] = 4,      ['E'] = 14,     ['e'] = 14,
    ['5'] = 5,      ['F'] = 15,     ['f'] = 15,
    ['6'] = 6,
    ['7'] = 7,
    ['8'] = 8,
    ['9'] = 9,
};

static void hex_encode(const char *plain, size_t n_in, luaL_Buffer *B)
{
    const size_t n_out = n_in*2;
    char *buf = luaL_prepbuffsize(B, n_out);
    for (size_t i = 0; i < n_in; i++)
    {
        const char c = plain[i];
        buf[2*i+0] = hex_map[(c>>4)&0xF];
        buf[2*i+1] = hex_map[c&0xF];
    }
    luaL_addsize(B, n_out);
}

static void hex_decode(const char *hex, size_t n_in, luaL_Buffer *B)
{
    const size_t n_out = n_in/2;
    char *buf = luaL_prepbuffsize(B, n_out);
    for (size_t i = 0; i < n_in-1; i += 2)
    {
        const size_t d1 = hex[i] & 0xFF;
        const size_t d2 = hex[i+1] & 0xFF;
        buf[i/2] = (char)((digit[d1]<<4) | digit[d2]);
    }
    luaL_addsize(B, n_out);
}

/*@@@
```lua
crypt.hex(data)
```
encodes `data` in hexa.
@@@*/

static int crypt_hex_encode(lua_State *L)
{
    const char *plain = luaL_checkstring(L, 1);
    const size_t n_in = (size_t)lua_rawlen(L, 1);
    luaL_Buffer B;
    luaL_buffinit(L, &B);
    hex_encode(plain, n_in, &B);
    luaL_pushresult(&B);
    return 1;
}

/*@@@
```lua
crypt.unhex(data)
```
decodes the hexa `data`.
@@@*/

static int crypt_hex_decode(lua_State *L)
{
    const char *hex = luaL_checkstring(L, 1);
    const size_t n_in = (size_t)lua_rawlen(L, 1);
    luaL_Buffer B;
    luaL_buffinit(L, &B);
    hex_decode(hex, n_in, &B);
    luaL_pushresult(&B);
    return 1;
}

/***************************************************************************@@@
## Base64 encoding

The base64 encoder transforms a string with non printable characters
into a printable string (see <https://en.wikipedia.org/wiki/Base64>)
@@@*/

static const char base64_map[64] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                                   "abcdefghijklmnopqrstuvwxyz"
                                   "0123456789+/";

static const char base64_rev[256] =
{
    ['A'] = 0,      ['a'] = 26+0,       ['0'] = 2*26+0,
    ['B'] = 1,      ['b'] = 26+1,       ['1'] = 2*26+1,
    ['C'] = 2,      ['c'] = 26+2,       ['2'] = 2*26+2,
    ['D'] = 3,      ['d'] = 26+3,       ['3'] = 2*26+3,
    ['E'] = 4,      ['e'] = 26+4,       ['4'] = 2*26+4,
    ['F'] = 5,      ['f'] = 26+5,       ['5'] = 2*26+5,
    ['G'] = 6,      ['g'] = 26+6,       ['6'] = 2*26+6,
    ['H'] = 7,      ['h'] = 26+7,       ['7'] = 2*26+7,
    ['I'] = 8,      ['i'] = 26+8,       ['8'] = 2*26+8,
    ['J'] = 9,      ['j'] = 26+9,       ['9'] = 2*26+9,
    ['K'] = 10,     ['k'] = 26+10,      ['+'] = 2*26+10,
    ['L'] = 11,     ['l'] = 26+11,      ['/'] = 2*26+11,
    ['M'] = 12,     ['m'] = 26+12,
    ['N'] = 13,     ['n'] = 26+13,
    ['O'] = 14,     ['o'] = 26+14,
    ['P'] = 15,     ['p'] = 26+15,
    ['Q'] = 16,     ['q'] = 26+16,
    ['R'] = 17,     ['r'] = 26+17,
    ['S'] = 18,     ['s'] = 26+18,
    ['T'] = 19,     ['t'] = 26+19,
    ['U'] = 20,     ['u'] = 26+20,
    ['V'] = 21,     ['v'] = 26+21,
    ['W'] = 22,     ['w'] = 26+22,
    ['X'] = 23,     ['x'] = 26+23,
    ['Y'] = 24,     ['y'] = 26+24,
    ['Z'] = 25,     ['z'] = 26+25,
};

static const char base64url_map[64] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                                      "abcdefghijklmnopqrstuvwxyz"
                                      "0123456789-_";

static const char base64url_rev[256] =
{
    ['A'] = 0,      ['a'] = 26+0,       ['0'] = 2*26+0,
    ['B'] = 1,      ['b'] = 26+1,       ['1'] = 2*26+1,
    ['C'] = 2,      ['c'] = 26+2,       ['2'] = 2*26+2,
    ['D'] = 3,      ['d'] = 26+3,       ['3'] = 2*26+3,
    ['E'] = 4,      ['e'] = 26+4,       ['4'] = 2*26+4,
    ['F'] = 5,      ['f'] = 26+5,       ['5'] = 2*26+5,
    ['G'] = 6,      ['g'] = 26+6,       ['6'] = 2*26+6,
    ['H'] = 7,      ['h'] = 26+7,       ['7'] = 2*26+7,
    ['I'] = 8,      ['i'] = 26+8,       ['8'] = 2*26+8,
    ['J'] = 9,      ['j'] = 26+9,       ['9'] = 2*26+9,
    ['K'] = 10,     ['k'] = 26+10,      ['-'] = 2*26+10,
    ['L'] = 11,     ['l'] = 26+11,      ['_'] = 2*26+11,
    ['M'] = 12,     ['m'] = 26+12,
    ['N'] = 13,     ['n'] = 26+13,
    ['O'] = 14,     ['o'] = 26+14,
    ['P'] = 15,     ['p'] = 26+15,
    ['Q'] = 16,     ['q'] = 26+16,
    ['R'] = 17,     ['r'] = 26+17,
    ['S'] = 18,     ['s'] = 26+18,
    ['T'] = 19,     ['t'] = 26+19,
    ['U'] = 20,     ['u'] = 26+20,
    ['V'] = 21,     ['v'] = 26+21,
    ['W'] = 22,     ['w'] = 26+22,
    ['X'] = 23,     ['x'] = 26+23,
    ['Y'] = 24,     ['y'] = 26+24,
    ['Z'] = 25,     ['z'] = 26+25,
};

static void base64_encode(const char *map, const unsigned char *plain, size_t n_in, luaL_Buffer *B)
{
    const size_t n_out = n_in*4/3 + 4;
    char *buf = luaL_prepbuffsize(B, n_out);

    size_t i = 0;
    size_t j = 0;
    while (i + 2 < n_in)
    {
        buf[j++] = map[plain[i] >> 2];
        buf[j++] = map[((plain[i] & 0x03) << 4) | (plain[i+1] >> 4)];
        buf[j++] = map[((plain[i+1] & 0x0f) << 2) | (plain[i+2] >> 6)];
        buf[j++] = map[(plain[i+2] & 0x3f)];
        i = i + 3;
    }
    switch (n_in - i)
    {
        case 1:     /* i == n_in - 1 */
            buf[j++] = map[plain[i] >> 2];
            buf[j++] = map[(plain[i] & 0x03) << 4];
            buf[j++] = '=';
            buf[j++] = '=';
            break;
        case 2:     /* i+1 == n_in - 1 */
            buf[j++] = map[plain[i] >> 2];
            buf[j++] = map[((plain[i] & 0x03) << 4) | (plain[i+1] >> 4)];
            buf[j++] = map[(plain[i+1] & 0x0f) << 2];
            buf[j++] = '=';
            break;
        case 0:
        default:
            /* i + 2 >= n_in
             * 3 cases:
             *      i+2 == n_in     => n_in-i == 2  => case 2
             *      i+2 == n_in+1   => n_in-i == 1  => case 1
             *      i+2 == n_in+2   => n_in-i == 0  => nothing more to add
             */
            break;
    }
    luaL_addsize(B, j);
}

static void base64_decode(const char *rev, const unsigned char *b64, size_t n_in, luaL_Buffer *B)
{
    const size_t n_out = n_in*3 / 4;
    char *buf = luaL_prepbuffsize(B, n_out);

    size_t i = 0;
    size_t j = 0;
    while (i + 3 < n_in)
    {
        buf[j++] = (char)((rev[b64[i]]   << 2) | (rev[b64[i+1]] >> 4));
        buf[j++] = (char)((rev[b64[i+1]] << 4) | (rev[b64[i+2]] >> 2));
        buf[j++] = (char)((rev[b64[i+2]] << 6) |  rev[b64[i+3]]);
        i = i + 4;
    }
    if (n_in >= 1)
    {
        if (b64[n_in-1] == '=') j--;
        if (n_in >= 2)
        {
            if (b64[n_in-2] == '=') j--;
        }
    }
    luaL_addsize(B, j);
}

/*@@@
```lua
crypt.base64(data)
```
encodes `data` in base64.
@@@*/

static int crypt_base64_encode(lua_State *L)
{
    const unsigned char *plain = (const unsigned char *)luaL_checkstring(L, 1);
    const size_t n_in = (size_t)lua_rawlen(L, 1);
    luaL_Buffer B;
    luaL_buffinit(L, &B);
    base64_encode(base64_map, plain, n_in, &B);
    luaL_pushresult(&B);
    return 1;
}

/*@@@
```lua
crypt.unbase64(data)
```
decodes the base64 `data`.
@@@*/

static int crypt_base64_decode(lua_State *L)
{
    const unsigned char *b64 = (const unsigned char *)luaL_checkstring(L, 1);
    const size_t n_in = (size_t)lua_rawlen(L, 1);
    luaL_Buffer B;
    luaL_buffinit(L, &B);
    base64_decode(base64_rev, b64, n_in, &B);
    luaL_pushresult(&B);
    return 1;
}

/*@@@
```lua
crypt.base64url(data)
```
encodes `data` in base64url.
@@@*/

static int crypt_base64url_encode(lua_State *L)
{
    const unsigned char *plain = (const unsigned char *)luaL_checkstring(L, 1);
    const size_t n_in = (size_t)lua_rawlen(L, 1);
    luaL_Buffer B;
    luaL_buffinit(L, &B);
    base64_encode(base64url_map, plain, n_in, &B);
    luaL_pushresult(&B);
    return 1;
}

/*@@@
```lua
crypt.unbase64url(data)
```
decodes the base64url `data`.
@@@*/

static int crypt_base64url_decode(lua_State *L)
{
    const unsigned char *b64 = (const unsigned char *)luaL_checkstring(L, 1);
    const size_t n_in = (size_t)lua_rawlen(L, 1);
    luaL_Buffer B;
    luaL_buffinit(L, &B);
    base64_decode(base64url_rev, b64, n_in, &B);
    luaL_pushresult(&B);
    return 1;
}

/***************************************************************************@@@
## CRC32 hash

The CRC-32 algorithm has been generated by [pycrc](https://pycrc.org/)
with the `crc-32` algorithm.
@@@*/

static const uint32_t crc32_table[256] =
{
    0x00000000, 0x77073096, 0xee0e612c, 0x990951ba, 0x076dc419, 0x706af48f, 0xe963a535, 0x9e6495a3,
    0x0edb8832, 0x79dcb8a4, 0xe0d5e91e, 0x97d2d988, 0x09b64c2b, 0x7eb17cbd, 0xe7b82d07, 0x90bf1d91,
    0x1db71064, 0x6ab020f2, 0xf3b97148, 0x84be41de, 0x1adad47d, 0x6ddde4eb, 0xf4d4b551, 0x83d385c7,
    0x136c9856, 0x646ba8c0, 0xfd62f97a, 0x8a65c9ec, 0x14015c4f, 0x63066cd9, 0xfa0f3d63, 0x8d080df5,
    0x3b6e20c8, 0x4c69105e, 0xd56041e4, 0xa2677172, 0x3c03e4d1, 0x4b04d447, 0xd20d85fd, 0xa50ab56b,
    0x35b5a8fa, 0x42b2986c, 0xdbbbc9d6, 0xacbcf940, 0x32d86ce3, 0x45df5c75, 0xdcd60dcf, 0xabd13d59,
    0x26d930ac, 0x51de003a, 0xc8d75180, 0xbfd06116, 0x21b4f4b5, 0x56b3c423, 0xcfba9599, 0xb8bda50f,
    0x2802b89e, 0x5f058808, 0xc60cd9b2, 0xb10be924, 0x2f6f7c87, 0x58684c11, 0xc1611dab, 0xb6662d3d,
    0x76dc4190, 0x01db7106, 0x98d220bc, 0xefd5102a, 0x71b18589, 0x06b6b51f, 0x9fbfe4a5, 0xe8b8d433,
    0x7807c9a2, 0x0f00f934, 0x9609a88e, 0xe10e9818, 0x7f6a0dbb, 0x086d3d2d, 0x91646c97, 0xe6635c01,
    0x6b6b51f4, 0x1c6c6162, 0x856530d8, 0xf262004e, 0x6c0695ed, 0x1b01a57b, 0x8208f4c1, 0xf50fc457,
    0x65b0d9c6, 0x12b7e950, 0x8bbeb8ea, 0xfcb9887c, 0x62dd1ddf, 0x15da2d49, 0x8cd37cf3, 0xfbd44c65,
    0x4db26158, 0x3ab551ce, 0xa3bc0074, 0xd4bb30e2, 0x4adfa541, 0x3dd895d7, 0xa4d1c46d, 0xd3d6f4fb,
    0x4369e96a, 0x346ed9fc, 0xad678846, 0xda60b8d0, 0x44042d73, 0x33031de5, 0xaa0a4c5f, 0xdd0d7cc9,
    0x5005713c, 0x270241aa, 0xbe0b1010, 0xc90c2086, 0x5768b525, 0x206f85b3, 0xb966d409, 0xce61e49f,
    0x5edef90e, 0x29d9c998, 0xb0d09822, 0xc7d7a8b4, 0x59b33d17, 0x2eb40d81, 0xb7bd5c3b, 0xc0ba6cad,
    0xedb88320, 0x9abfb3b6, 0x03b6e20c, 0x74b1d29a, 0xead54739, 0x9dd277af, 0x04db2615, 0x73dc1683,
    0xe3630b12, 0x94643b84, 0x0d6d6a3e, 0x7a6a5aa8, 0xe40ecf0b, 0x9309ff9d, 0x0a00ae27, 0x7d079eb1,
    0xf00f9344, 0x8708a3d2, 0x1e01f268, 0x6906c2fe, 0xf762575d, 0x806567cb, 0x196c3671, 0x6e6b06e7,
    0xfed41b76, 0x89d32be0, 0x10da7a5a, 0x67dd4acc, 0xf9b9df6f, 0x8ebeeff9, 0x17b7be43, 0x60b08ed5,
    0xd6d6a3e8, 0xa1d1937e, 0x38d8c2c4, 0x4fdff252, 0xd1bb67f1, 0xa6bc5767, 0x3fb506dd, 0x48b2364b,
    0xd80d2bda, 0xaf0a1b4c, 0x36034af6, 0x41047a60, 0xdf60efc3, 0xa867df55, 0x316e8eef, 0x4669be79,
    0xcb61b38c, 0xbc66831a, 0x256fd2a0, 0x5268e236, 0xcc0c7795, 0xbb0b4703, 0x220216b9, 0x5505262f,
    0xc5ba3bbe, 0xb2bd0b28, 0x2bb45a92, 0x5cb36a04, 0xc2d7ffa7, 0xb5d0cf31, 0x2cd99e8b, 0x5bdeae1d,
    0x9b64c2b0, 0xec63f226, 0x756aa39c, 0x026d930a, 0x9c0906a9, 0xeb0e363f, 0x72076785, 0x05005713,
    0x95bf4a82, 0xe2b87a14, 0x7bb12bae, 0x0cb61b38, 0x92d28e9b, 0xe5d5be0d, 0x7cdcefb7, 0x0bdbdf21,
    0x86d3d2d4, 0xf1d4e242, 0x68ddb3f8, 0x1fda836e, 0x81be16cd, 0xf6b9265b, 0x6fb077e1, 0x18b74777,
    0x88085ae6, 0xff0f6a70, 0x66063bca, 0x11010b5c, 0x8f659eff, 0xf862ae69, 0x616bffd3, 0x166ccf45,
    0xa00ae278, 0xd70dd2ee, 0x4e048354, 0x3903b3c2, 0xa7672661, 0xd06016f7, 0x4969474d, 0x3e6e77db,
    0xaed16a4a, 0xd9d65adc, 0x40df0b66, 0x37d83bf0, 0xa9bcae53, 0xdebb9ec5, 0x47b2cf7f, 0x30b5ffe9,
    0xbdbdf21c, 0xcabac28a, 0x53b39330, 0x24b4a3a6, 0xbad03605, 0xcdd70693, 0x54de5729, 0x23d967bf,
    0xb3667a2e, 0xc4614ab8, 0x5d681b02, 0x2a6f2b94, 0xb40bbe37, 0xc30c8ea1, 0x5a05df1b, 0x2d02ef8d
};

static uint32_t crc32(const char *s, size_t n)
{
    uint32_t crc = 0xFFFFFFFF;
    for (size_t i = 0; i < n; i++)
    {
        crc = (crc>>8) ^ crc32_table[(crc^(uint32_t)s[i])&0xFF];
    }
    return crc ^ 0xFFFFFFFF;
}

/*@@@
```lua
crypt.crc32(data)
```
computes the CRC32 of `data`.
@@@*/

static int crypt_crc32(lua_State *L)
{
    const char *s = luaL_checkstring(L, 1);
    const size_t n = (size_t)lua_rawlen(L, 1);
    const uint32_t crc = crc32(s, n);
    lua_pushinteger(L, (lua_Integer)crc);
    return 1;
}

/***************************************************************************@@@
## CRC64 hash

The CRC-64 algorithm has been generated by [pycrc](https://pycrc.org/)
with the `crc-64-xz` algorithm.
@@@*/

static const uint64_t crc64_table[256] =
{
    0x0000000000000000, 0xb32e4cbe03a75f6f, 0xf4843657a840a05b, 0x47aa7ae9abe7ff34,
    0x7bd0c384ff8f5e33, 0xc8fe8f3afc28015c, 0x8f54f5d357cffe68, 0x3c7ab96d5468a107,
    0xf7a18709ff1ebc66, 0x448fcbb7fcb9e309, 0x0325b15e575e1c3d, 0xb00bfde054f94352,
    0x8c71448d0091e255, 0x3f5f08330336bd3a, 0x78f572daa8d1420e, 0xcbdb3e64ab761d61,
    0x7d9ba13851336649, 0xceb5ed8652943926, 0x891f976ff973c612, 0x3a31dbd1fad4997d,
    0x064b62bcaebc387a, 0xb5652e02ad1b6715, 0xf2cf54eb06fc9821, 0x41e11855055bc74e,
    0x8a3a2631ae2dda2f, 0x39146a8fad8a8540, 0x7ebe1066066d7a74, 0xcd905cd805ca251b,
    0xf1eae5b551a2841c, 0x42c4a90b5205db73, 0x056ed3e2f9e22447, 0xb6409f5cfa457b28,
    0xfb374270a266cc92, 0x48190ecea1c193fd, 0x0fb374270a266cc9, 0xbc9d3899098133a6,
    0x80e781f45de992a1, 0x33c9cd4a5e4ecdce, 0x7463b7a3f5a932fa, 0xc74dfb1df60e6d95,
    0x0c96c5795d7870f4, 0xbfb889c75edf2f9b, 0xf812f32ef538d0af, 0x4b3cbf90f69f8fc0,
    0x774606fda2f72ec7, 0xc4684a43a15071a8, 0x83c230aa0ab78e9c, 0x30ec7c140910d1f3,
    0x86ace348f355aadb, 0x3582aff6f0f2f5b4, 0x7228d51f5b150a80, 0xc10699a158b255ef,
    0xfd7c20cc0cdaf4e8, 0x4e526c720f7dab87, 0x09f8169ba49a54b3, 0xbad65a25a73d0bdc,
    0x710d64410c4b16bd, 0xc22328ff0fec49d2, 0x85895216a40bb6e6, 0x36a71ea8a7ace989,
    0x0adda7c5f3c4488e, 0xb9f3eb7bf06317e1, 0xfe5991925b84e8d5, 0x4d77dd2c5823b7ba,
    0x64b62bcaebc387a1, 0xd7986774e864d8ce, 0x90321d9d438327fa, 0x231c512340247895,
    0x1f66e84e144cd992, 0xac48a4f017eb86fd, 0xebe2de19bc0c79c9, 0x58cc92a7bfab26a6,
    0x9317acc314dd3bc7, 0x2039e07d177a64a8, 0x67939a94bc9d9b9c, 0xd4bdd62abf3ac4f3,
    0xe8c76f47eb5265f4, 0x5be923f9e8f53a9b, 0x1c4359104312c5af, 0xaf6d15ae40b59ac0,
    0x192d8af2baf0e1e8, 0xaa03c64cb957be87, 0xeda9bca512b041b3, 0x5e87f01b11171edc,
    0x62fd4976457fbfdb, 0xd1d305c846d8e0b4, 0x96797f21ed3f1f80, 0x2557339fee9840ef,
    0xee8c0dfb45ee5d8e, 0x5da24145464902e1, 0x1a083bacedaefdd5, 0xa9267712ee09a2ba,
    0x955cce7fba6103bd, 0x267282c1b9c65cd2, 0x61d8f8281221a3e6, 0xd2f6b4961186fc89,
    0x9f8169ba49a54b33, 0x2caf25044a02145c, 0x6b055fede1e5eb68, 0xd82b1353e242b407,
    0xe451aa3eb62a1500, 0x577fe680b58d4a6f, 0x10d59c691e6ab55b, 0xa3fbd0d71dcdea34,
    0x6820eeb3b6bbf755, 0xdb0ea20db51ca83a, 0x9ca4d8e41efb570e, 0x2f8a945a1d5c0861,
    0x13f02d374934a966, 0xa0de61894a93f609, 0xe7741b60e174093d, 0x545a57dee2d35652,
    0xe21ac88218962d7a, 0x5134843c1b317215, 0x169efed5b0d68d21, 0xa5b0b26bb371d24e,
    0x99ca0b06e7197349, 0x2ae447b8e4be2c26, 0x6d4e3d514f59d312, 0xde6071ef4cfe8c7d,
    0x15bb4f8be788911c, 0xa6950335e42fce73, 0xe13f79dc4fc83147, 0x521135624c6f6e28,
    0x6e6b8c0f1807cf2f, 0xdd45c0b11ba09040, 0x9aefba58b0476f74, 0x29c1f6e6b3e0301b,
    0xc96c5795d7870f42, 0x7a421b2bd420502d, 0x3de861c27fc7af19, 0x8ec62d7c7c60f076,
    0xb2bc941128085171, 0x0192d8af2baf0e1e, 0x4638a2468048f12a, 0xf516eef883efae45,
    0x3ecdd09c2899b324, 0x8de39c222b3eec4b, 0xca49e6cb80d9137f, 0x7967aa75837e4c10,
    0x451d1318d716ed17, 0xf6335fa6d4b1b278, 0xb199254f7f564d4c, 0x02b769f17cf11223,
    0xb4f7f6ad86b4690b, 0x07d9ba1385133664, 0x4073c0fa2ef4c950, 0xf35d8c442d53963f,
    0xcf273529793b3738, 0x7c0979977a9c6857, 0x3ba3037ed17b9763, 0x888d4fc0d2dcc80c,
    0x435671a479aad56d, 0xf0783d1a7a0d8a02, 0xb7d247f3d1ea7536, 0x04fc0b4dd24d2a59,
    0x3886b22086258b5e, 0x8ba8fe9e8582d431, 0xcc0284772e652b05, 0x7f2cc8c92dc2746a,
    0x325b15e575e1c3d0, 0x8175595b76469cbf, 0xc6df23b2dda1638b, 0x75f16f0cde063ce4,
    0x498bd6618a6e9de3, 0xfaa59adf89c9c28c, 0xbd0fe036222e3db8, 0x0e21ac88218962d7,
    0xc5fa92ec8aff7fb6, 0x76d4de52895820d9, 0x317ea4bb22bfdfed, 0x8250e80521188082,
    0xbe2a516875702185, 0x0d041dd676d77eea, 0x4aae673fdd3081de, 0xf9802b81de97deb1,
    0x4fc0b4dd24d2a599, 0xfceef8632775faf6, 0xbb44828a8c9205c2, 0x086ace348f355aad,
    0x34107759db5dfbaa, 0x873e3be7d8faa4c5, 0xc094410e731d5bf1, 0x73ba0db070ba049e,
    0xb86133d4dbcc19ff, 0x0b4f7f6ad86b4690, 0x4ce50583738cb9a4, 0xffcb493d702be6cb,
    0xc3b1f050244347cc, 0x709fbcee27e418a3, 0x3735c6078c03e797, 0x841b8ab98fa4b8f8,
    0xadda7c5f3c4488e3, 0x1ef430e13fe3d78c, 0x595e4a08940428b8, 0xea7006b697a377d7,
    0xd60abfdbc3cbd6d0, 0x6524f365c06c89bf, 0x228e898c6b8b768b, 0x91a0c532682c29e4,
    0x5a7bfb56c35a3485, 0xe955b7e8c0fd6bea, 0xaeffcd016b1a94de, 0x1dd181bf68bdcbb1,
    0x21ab38d23cd56ab6, 0x9285746c3f7235d9, 0xd52f0e859495caed, 0x6601423b97329582,
    0xd041dd676d77eeaa, 0x636f91d96ed0b1c5, 0x24c5eb30c5374ef1, 0x97eba78ec690119e,
    0xab911ee392f8b099, 0x18bf525d915feff6, 0x5f1528b43ab810c2, 0xec3b640a391f4fad,
    0x27e05a6e926952cc, 0x94ce16d091ce0da3, 0xd3646c393a29f297, 0x604a2087398eadf8,
    0x5c3099ea6de60cff, 0xef1ed5546e415390, 0xa8b4afbdc5a6aca4, 0x1b9ae303c601f3cb,
    0x56ed3e2f9e224471, 0xe5c372919d851b1e, 0xa26908783662e42a, 0x114744c635c5bb45,
    0x2d3dfdab61ad1a42, 0x9e13b115620a452d, 0xd9b9cbfcc9edba19, 0x6a978742ca4ae576,
    0xa14cb926613cf817, 0x1262f598629ba778, 0x55c88f71c97c584c, 0xe6e6c3cfcadb0723,
    0xda9c7aa29eb3a624, 0x69b2361c9d14f94b, 0x2e184cf536f3067f, 0x9d36004b35545910,
    0x2b769f17cf112238, 0x9858d3a9ccb67d57, 0xdff2a94067518263, 0x6cdce5fe64f6dd0c,
    0x50a65c93309e7c0b, 0xe388102d33392364, 0xa4226ac498dedc50, 0x170c267a9b79833f,
    0xdcd7181e300f9e5e, 0x6ff954a033a8c131, 0x28532e49984f3e05, 0x9b7d62f79be8616a,
    0xa707db9acf80c06d, 0x14299724cc279f02, 0x5383edcd67c06036, 0xe0ada17364673f59
};

static uint64_t crc64(const char *s, size_t n)
{
    uint64_t crc = 0xFFFFFFFFFFFFFFFF;
    for (size_t i = 0; i < n; i++)
    {
        crc = (crc>>8) ^ crc64_table[(crc^(uint64_t)s[i])&0xFF];
    }
    return crc ^ 0xFFFFFFFFFFFFFFFF;
}

/*@@@
```lua
crypt.crc64(data)
```
computes the CRC64 of `data`.
@@@*/

static int crypt_crc64(lua_State *L)
{
    const char *s = luaL_checkstring(L, 1);
    const size_t n = (size_t)lua_rawlen(L, 1);
    const uint64_t crc = crc64(s, n);
    lua_pushinteger(L, (lua_Integer)crc);
    return 1;
}

/***************************************************************************@@@
## ARC4 encryption

ARC4 is a stream cipher (see <https://en.wikipedia.org/wiki/ARC4>).
It is designed to be fast and simple.
@@@*/

/* https://en.wikipedia.org/wiki/ARC4 */

#define ARC4_DROP       768

typedef struct
{
    uint8_t S[256];
    size_t i, j;
} t_arc4;

static inline void swap(uint8_t *a, uint8_t *b)
{
    const uint8_t tmp = *a;
    *a = *b;
    *b = tmp;
}

static inline void arc4_init(t_arc4 *arc4)
{
    uint8_t *S = arc4->S;
    for (size_t i = 0; i < 256; i++)
    {
        S[i] = (uint8_t)i;
    }
    arc4->i = 0;
    arc4->j = 0;
}

static inline void arc4_schedule(t_arc4 *arc4, const char *key, size_t key_size)
{
    if (key_size > 0)
    {
        uint8_t *S = arc4->S;
        size_t j = 0;
        for (size_t i = 0; i < 256; i++)
        {
            j = (j + (size_t)S[i] + (size_t)key[i % key_size]) % 256;
            swap(&S[i], &S[j]);
        }
    }
}

static inline void arc4_step(t_arc4 *arc4)
{
    uint8_t *S = arc4->S;
    arc4->i = (arc4->i + 1) % 256;
    arc4->j = (arc4->j + S[arc4->i]) % 256;
    swap(&S[arc4->i], &S[arc4->j]);
}

static inline void arc4_drop(t_arc4 *arc4, size_t n)
{
    for (size_t i = 0; i < n; i++)
    {
        arc4_step(arc4);
    }
}

static inline uint8_t arc4_byte(t_arc4 *arc4)
{
    const uint8_t *S = arc4->S;
    return S[(S[arc4->i] + S[arc4->j]) % 256];
}

static inline void arc4_xor(t_arc4 *arc4, size_t n, const char *input, luaL_Buffer *B)
{
    char *buf = luaL_prepbuffsize(B, n);
    for (size_t k = 0; k < n; k++)
    {
        arc4_step(arc4);
        buf[k] = (char)(input[k] ^ arc4_byte(arc4));
    }
    luaL_addsize(B, n);
}

static void arc4(const char *key, size_t key_size, size_t drop, const char *input, size_t size, luaL_Buffer *B)
{
    t_arc4 arc4;
    arc4_init(&arc4);
    arc4_schedule(&arc4, key, key_size);
    arc4_drop(&arc4, drop);
    arc4_xor(&arc4, size, input, B);
}

/*@@@
```lua
crypt.arc4(data, key, [drop])
crypt.unarc4(data, key, [drop])     -- note that unarc4 == arc4
```
encrypts/decrypts `data` using the ARC4Drop
algorithm and the encryption key `key` (drops the first `drop` encryption
steps, the default value of `drop` is 768).
@@@*/

static int crypt_arc4(lua_State *L)
{
    size_t drop = ARC4_DROP;    /* default number of steps dropped before encryption */

    /* arg 1: input data */
    const char *in = luaL_checkstring(L, 1);
    const size_t n = (size_t)lua_rawlen(L, 1);

    /* arg 2: key */
    const char *key = luaL_checkstring(L, 2);
    const size_t key_size = (size_t)lua_rawlen(L, 2);

    /* arg 3: drop (optional) */
    if (!lua_isnoneornil(L, 3)) {
        drop = (size_t)luaL_checkinteger(L, 3);
    }

    luaL_Buffer B;
    luaL_buffinit(L, &B);
    arc4(key, key_size, drop, in, n, &B);
    luaL_pushresult(&B);
    return 1;
}

/***************************************************************************@@@
### Fast PRNG-base hash

@@@*/

/*@@@
```lua
crypt.hash(data)
```
returns digest of `data` based on the LuaX PRNG (not suitable for cryptographic usage).
@@@*/

static inline uint64_t prng_hash(const char *input, size_t input_size)
{
    /* 2^64-59 = 0xFFFFFFFFFFFFFFC5 */
    register uint64_t hash = 0xFFFFFFFFFFFFFFC5;
    hash = hash*prng_a + prng_c;
    for (size_t i = 0; i < input_size; i++)
    {
        const uint64_t c = (uint64_t)input[i];
        hash = hash*prng_a + ((c << 1) | prng_c);
    }
    hash = hash*prng_a + prng_c;
    return hash;
}

static int crypt_hash(lua_State *L)
{
    const char *data = (const char *)luaL_checkstring(L, 1);
    const size_t datalen = (size_t)lua_rawlen(L, 1);

    const uint64_t hash = prng_hash(data, datalen);

    char hex[2*sizeof(hash)];

    for (size_t i = 0; i < sizeof(hash); i++)
    {
        const char c = (char)((hash >> (i*8)) & 0xFF);
        hex[2*i+0] = hex_map[(c>>4)&0xF];
        hex[2*i+1] = hex_map[(c>>0)&0xF];
    }

    lua_pushlstring(L, (const char *)hex, sizeof(hex));
    return 1;
}

/******************************************************************************
 * Crypt package
 ******************************************************************************/

static const luaL_Reg crypt_module[] =
{
    /* LuaX functions */
    {"seed", crypt_seed},
    {"int", crypt_int},
    {"float", crypt_float},
    {"str", crypt_str},
    {"prng", crypt_prng},
    {"hex", crypt_hex_encode},
    {"unhex", crypt_hex_decode},
    {"base64", crypt_base64_encode},
    {"unbase64", crypt_base64_decode},
    {"base64url", crypt_base64url_encode},
    {"unbase64url", crypt_base64url_decode},
    {"arc4", crypt_arc4},
    {"unarc4", crypt_arc4}, /* unarc4 == arc4 */
    {"crc32", crypt_crc32},
    {"crc64", crypt_crc64},
    {"hash", crypt_hash},

    {NULL, NULL}
};

static inline void set_integer(lua_State *L, const char *name, lua_Integer val)
{
    lua_pushinteger(L, val);
    lua_setfield(L, -2, name);
}

LUAMOD_API int luaopen_crypt(lua_State *L)
{
    /* LuaX crypt initialization */

    luaL_newmetatable(L, PRNG_MT);
    luaL_setfuncs(L, prng_funcs, 0);
    lua_pushliteral(L, "__index");
    lua_pushvalue(L, -2);
    lua_settable(L, -3);

    prng_seed(&prng, prng_default_seed());

    /* module initialization */

    luaL_newlib(L, crypt_module);
    set_integer(L, "RAND_MAX", CRYPT_RAND_MAX);
    return 1;
}
