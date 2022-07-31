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

#include "crypt.h"

#include "tools.h"

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#include <stdint.h>
#include <string.h>

#ifdef _WIN32
#include <windows.h>
#include <wincrypt.h>
#endif

#ifdef _WIN32
static HCRYPTPROV hProv = 0;
#endif

static int crypt_rnd(lua_State *L)
{
    size_t bytes = (size_t)luaL_checkinteger(L, 1);
    char *buffer = (char*)safe_malloc(bytes);
#ifdef _WIN32
    if (hProv == 0)
    {
        if (!CryptAcquireContext(&hProv, NULL, NULL, PROV_RSA_FULL, CRYPT_VERIFYCONTEXT))
            luaL_error(L, "crypt: CryptAcquireContext error");
    }
    CryptGenRandom(hProv, bytes, (BYTE*)buffer);
#else
    FILE *f = fopen("/dev/urandom", "rb");
    if (f == NULL) luaL_error(L, "crypt: can not read /dev/urandom");
    unsigned long r = fread(buffer, 1, bytes, f);
    if (r != bytes) luaL_error(L, "crypt: can not read /dev/urandom");
    fclose(f);
#endif
    lua_pushlstring(L, buffer, bytes);
    free(buffer);
    return 1;
}

/* XXTEA
From Wikipedia, the free encyclopedia

http://en.wikipedia.org/wiki/XXTEA
*/

#define DELTA 0x9e3779b9
#define MX (((z>>5^y<<2) + (y>>3^z<<4)) ^ ((sum^y) + (key[(p&3)^e] ^ z)))

static void btea_encode(uint32_t *v, size_t n, uint32_t const key[4])
{
    uint32_t y, z, sum;
    unsigned int rounds, e;
    size_t p;
    if (n > 1)
    {
        /* Coding Part */
        rounds = 6 + 52/n;
        sum = 0;
        z = v[n-1];
        do
        {
            sum += DELTA;
            e = (sum >> 2) & 3;
            for (p=0; p<n-1; p++)
            {
                y = v[p+1]; 
                z = v[p] += MX;
            }
            y = v[0];
            z = v[n-1] += MX;
        } while (--rounds);
    }
}

static void btea_decode(uint32_t *v, size_t n, uint32_t const key[4])
{
    uint32_t y, z, sum;
    unsigned int rounds, e;
    size_t p;
    if (n > 1)
    {
        /* Decoding Part */
        rounds = 6 + 52/n;
        sum = rounds*DELTA;
        y = v[0];
        do
        {
            e = (sum >> 2) & 3;
            for (p=n-1; p>0; p--)
            {
                z = v[p-1];
                y = v[p] -= MX;
            }
            z = v[n-1];
            y = v[0] -= MX;
            sum -= DELTA;
        } while (--rounds);
    }
}

#undef DELTA
#undef MX

#define MIN(a, b) ((a) <= (b) ? (a) : (b))

static int crypt_btea(lua_State *L, void (*encrypt)(uint32_t*, size_t, const uint32_t *))
{
    const char *key_str = luaL_checkstring(L, 1);
    size_t key_len = lua_rawlen(L, 1);
    const char *src = luaL_checkstring(L, 2);
    size_t src_len = lua_rawlen(L, 2);

    uint32_t key[4] = {0, 0, 0, 0};
    memcpy(key, key_str, MIN(16, key_len));

    size_t buffer_len = (src_len + sizeof(uint32_t) - 1) / sizeof(uint32_t);
    uint32_t *buffer = (uint32_t*)safe_malloc(buffer_len*sizeof(uint32_t));
    memset(buffer, 0, buffer_len*sizeof(uint32_t));
    memcpy(buffer, src, src_len);
    encrypt(buffer, buffer_len, key);

    lua_pushlstring(L, (const char *)buffer, buffer_len*sizeof(uint32_t));
    free(buffer);
    return 1;
}

static int crypt_btea_encrypt(lua_State *L)
{
    return crypt_btea(L, btea_encode);
}

static int crypt_btea_decrypt(lua_State *L)
{
    return crypt_btea(L, btea_decode);
}

static const luaL_Reg crypt[] =
{
    {"rnd", crypt_rnd},
    {"btea_encrypt", crypt_btea_encrypt},
    {"btea_decrypt", crypt_btea_decrypt},
    {NULL, NULL}
};

LUAMOD_API int luaopen_crypt(lua_State *L)
{
    luaL_newlib(L, crypt);
    return 1;
}
