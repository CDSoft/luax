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

/***************************************************************************@@@
# lzip: A compression library for the lzip format

```lua
local lzip = require "lzip"
```

lzip is a data compression library providing in-memory LZMA compression and
decompression functions.

The source code is available at <https://www.nongnu.org/lzip/lzlib.html>.
@@@*/

#include <stdint.h>
#include <stdlib.h>

#include "lzip.h"
#include "ext/c/lzlib/lib/lzlib.h"

#include "tools.h"

#include "lua.h"
#include "lauxlib.h"

/***************************************************************************@@@
## lzip compression
@@@*/

#define LZIP_CLEVEL_MIN         0
#define LZIP_CLEVEL_DEFAULT     6
#define LZIP_CLEVEL_MAX         9

#define COMPRESS_BLOCK_SIZE     (64*1024)

struct Lzma_options {
    int dictionary_size;        /* 4 KiB .. 512 MiB */
    int match_len_limit;        /* 5 .. 273 */
};

static const struct Lzma_options option_mapping[LZIP_CLEVEL_MAX+1] = {
    [0] = {   65535,  16 },     /* -0 (65535,16 chooses fast encoder) */
    [1] = { 1 << 20,   5 },     /* -1 */
    [2] = { 3 << 19,   6 },     /* -2 */
    [3] = { 1 << 21,   8 },     /* -3 */
    [4] = { 3 << 20,  12 },     /* -4 */
    [5] = { 1 << 22,  20 },     /* -5 */
    [6] = { 1 << 23,  36 },     /* -6 */
    [7] = { 1 << 24,  68 },     /* -7 */
    [8] = { 3 << 23, 132 },     /* -8 */
    [9] = { 1 << 25, 273 },     /* -9 */
};

static const char *lzip_compress(const char *src, const size_t src_len, luaL_Buffer *B, int level)
{
    level = level < LZIP_CLEVEL_MIN ? LZIP_CLEVEL_MIN
          : level > LZIP_CLEVEL_MAX ? LZIP_CLEVEL_MAX
          : level;

    const int dictionary_size = option_mapping[level].dictionary_size;
    const int match_len_limit = option_mapping[level].match_len_limit;

    const char *err = "lzip error";
    size_t pos = 0;

    LZ_Encoder *encoder = LZ_compress_open(dictionary_size, match_len_limit, INT64_MAX);
    if (encoder == NULL || LZ_compress_errno(encoder) != LZ_ok) { goto end; }

    while (true) {
        int ret = LZ_compress_write(encoder, (const uint8_t *)&src[pos], (int)(src_len - pos));
        if (ret < 0) { goto end; }
        pos += (size_t)ret;
        if (pos >= src_len) { LZ_compress_finish(encoder); }
        char *outbuf = luaL_prepbuffsize(B, COMPRESS_BLOCK_SIZE);
        ret = LZ_compress_read(encoder, (uint8_t *)outbuf, COMPRESS_BLOCK_SIZE);
        if (ret < 0) { goto end; }
        luaL_addsize(B, (size_t)ret);
        if (LZ_compress_finished(encoder) == 1) break;
    }

    err = NULL; /* no error */

end:
    if (LZ_compress_close(encoder) < 0) { err = "lzip error"; }
    return err;
}

/*@@@
```lua
lzip.lzip(data, [level])
```
compresses `data` with lzip.
The compressed data is an lzip frame that can be stored in a file and
decompressed by the `lzip` command line utility.

The optional `level` parameter is the compression level (from 0 to 9).
The default compression level is 6.
@@@*/

static int compress(lua_State *L)
{
    const char *srcBuffer = luaL_checkstring(L, 1);
    const size_t srcSize = (size_t)lua_rawlen(L, 1);
    const int level = lua_type(L, 2) == LUA_TNUMBER
        ? (int)luaL_checkinteger(L, 2)
        : LZIP_CLEVEL_DEFAULT;
    luaL_Buffer B;
    luaL_buffinit(L, &B);
    const char *err = lzip_compress(srcBuffer, srcSize, &B, level);
    if (err != NULL) {
        lua_pop(L, 1);
        return luax_pusherror(L, "lzip compression error: %s", err);
    }
    luaL_pushresult(&B);
    return 1;
}

/***************************************************************************@@@
## lzip decompression
@@@*/

static const char *lzip_decompress(const char *src, const size_t src_len, luaL_Buffer *B)
{
    const char *err = "lzip error";
    size_t pos = 0;

    LZ_Decoder * const decoder = LZ_decompress_open();
    if (decoder == NULL || LZ_decompress_errno(decoder) != LZ_ok) { goto end; }

    while (true) {
        int ret = LZ_decompress_write(decoder, (const uint8_t *)&src[pos], (int)(src_len - pos));
        if (ret < 0) { goto end; }
        pos += (size_t)ret;
        if (pos >= src_len) { LZ_decompress_finish(decoder); }
        char *outbuf = luaL_prepbuffsize(B, COMPRESS_BLOCK_SIZE);
        ret = LZ_decompress_read(decoder, (uint8_t *)outbuf, COMPRESS_BLOCK_SIZE);
        if (ret < 0) { goto end; }
        luaL_addsize(B, (size_t)ret);
        if (LZ_decompress_finished(decoder) == 1) break;
    }

    err = NULL; /* no error */

end:
    if (LZ_decompress_close(decoder) < 0) { err = "lzip error"; }
    return err;
}

/*@@@
```lua
lzip.unlzip(data)
```
decompresses `data` with lzip.
`data` shall be an lzip frame and
can be the content of a file produced by the `lzip` command line utility.
@@@*/

static int decompress(lua_State *L)
{
    const char *srcBuffer = luaL_checkstring(L, 1);
    const size_t srcTotalSize = (size_t)lua_rawlen(L, 1);
    luaL_Buffer B;
    luaL_buffinit(L, &B);
    const char *err = lzip_decompress(srcBuffer, srcTotalSize, &B);
    if (err != NULL)
    {
        lua_pop(L, 1);
        return luax_pusherror(L, "lzip decompression error: %s", err);
    }
    luaL_pushresult(&B);
    return 1;
}

/******************************************************************************
 * lzlib package
 ******************************************************************************/

static const luaL_Reg lzip_module[] =
{
    {"lzip", compress},
    {"unlzip", decompress},
    {NULL, NULL}
};

LUAMOD_API int luaopen_lzip(lua_State *L)
{
    luaL_newlib(L, lzip_module);
    return 1;
}
