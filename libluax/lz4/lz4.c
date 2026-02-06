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
# lz4: Extremely Fast Compression algorithm

```lua
local lz4 = require "lz4"
```

LZ4 is an extremely fast compression algorithm by Yann Collet.

The source code is on Github: <https://github.com/lz4/lz4>.

More information on <https://www.lz4.org>.
@@@*/

#include "lz4.h"
#include "ext/c/lz4/lib/lz4hc.h"
#include "ext/c/lz4/lib/lz4frame.h"

#include "tools.h"

#include "lua.h"
#include "lauxlib.h"

#include <stdlib.h>

/***************************************************************************@@@
## LZ4 compression preferences

Some compression preferences are hard coded:

- block size
- linked blocks
- frame checksum enabled

Only the compression level can be changed.

@@@*/

/***************************************************************************@@@
## LZ4 frame compression
@@@*/

#define COMPRESS_BLOCK_SIZE     (64*1024)

#define MIN(a, b) ((a) < (b) ? (a) : (b))

static const char *lz4_compress(const char *src, const size_t src_len, luaL_Buffer *B, int level)
{
    level = level < LZ4HC_CLEVEL_MIN ? LZ4HC_CLEVEL_MIN
          : level > LZ4HC_CLEVEL_MAX ? LZ4HC_CLEVEL_MAX
          : level;
    const LZ4F_preferences_t prefs = {
        .frameInfo = {
            .blockSizeID = src_len <=     64*1024 ? LZ4F_max64KB
                         : src_len <=    256*1024 ? LZ4F_max256KB
                         : src_len <= 1*1024*1024 ? LZ4F_max1MB
                         :                          LZ4F_max4MB,
            .blockMode = LZ4F_blockLinked,
            .contentChecksumFlag = LZ4F_contentChecksumEnabled,
            .frameType = LZ4F_frame,
            .contentSize = 0ULL,
            .dictID = 0U,
            .blockChecksumFlag = LZ4F_noBlockChecksum,
        },
        .compressionLevel = level,
        .autoFlush = 0U,
        .favorDecSpeed = 0U,
    };

    static const LZ4F_compressOptions_t copt = {
        .stableSrc = 1,
    };

    LZ4F_cctx *cctx;
    const LZ4F_errorCode_t cctxRet = LZ4F_createCompressionContext(&cctx, LZ4F_VERSION);
    if (LZ4F_isError(cctxRet)) {
        return LZ4F_getErrorName(cctxRet);
    }

    const char *srcBuffer = src;            /* current byte address to compress */
    size_t src_remaining_size = src_len;    /* remaining bytes to compress */

    size_t dstCapacity = LZ4F_HEADER_SIZE_MAX;
    char *dstBuffer = luaL_prepbuffsize(B, dstCapacity);

    size_t header_size = LZ4F_compressBegin(cctx, dstBuffer, dstCapacity, &prefs);
    if (LZ4F_isError(header_size)) {
        return LZ4F_getErrorName(header_size);
    }
    dstBuffer += header_size;
    dstCapacity -= header_size;
    luaL_addsize(B, header_size);

    const size_t compress_bound = LZ4F_compressBound(MIN(src_len, COMPRESS_BLOCK_SIZE), &prefs);

    while (src_remaining_size > 0) {
        if (dstCapacity < compress_bound) {
            dstCapacity = compress_bound;
            dstBuffer = luaL_prepbuffsize(B, dstCapacity);
        }

        const size_t srcSize = MIN(src_remaining_size, COMPRESS_BLOCK_SIZE);
        const size_t n = LZ4F_compressUpdate(cctx, dstBuffer, dstCapacity, srcBuffer, srcSize, &copt);
        if (LZ4F_isError(n)) {
            return LZ4F_getErrorName(n);
        }

        srcBuffer += srcSize;
        src_remaining_size -= srcSize;

        luaL_addsize(B, n);
        dstBuffer += n;
        dstCapacity -= n;
    }

    const size_t n = LZ4F_compressEnd(cctx, dstBuffer, dstCapacity, &copt);
    if (LZ4F_isError(n)) {
        return LZ4F_getErrorName(n);
    }
    luaL_addsize(B, n);

    LZ4F_freeCompressionContext(cctx);
    return NULL; /* no error */
}

/*@@@
```lua
lz4.lz4(data, [level])
```
compresses `data` with LZ4.
The compressed data is an LZ4 frame that can be stored in a file and
decompressed by the `lz4` command line utility.

The optional `level` parameter is the compression level (from 0 to 12).
The default compression level is 9.
@@@*/

static int compress(lua_State *L)
{
    const char *srcBuffer = luaL_checkstring(L, 1);
    const size_t srcSize = (size_t)lua_rawlen(L, 1);
    const int level = lua_type(L, 2) == LUA_TNUMBER
        ? (int)luaL_checkinteger(L, 2)
        : LZ4HC_CLEVEL_DEFAULT;
    luaL_Buffer B;
    luaL_buffinit(L, &B);
    const char *err = lz4_compress(srcBuffer, srcSize, &B, level);
    if (err != NULL) {
        lua_pop(L, 1);
        return luax_pusherror(L, "LZ4 compression error: %s", err);
    }
    luaL_pushresult(&B);
    return 1;
}

/***************************************************************************@@@
## LZ4 frame decompression
@@@*/

#define MIN_DECOMPRESSION_BUFFER_SIZE (4*1024)
#define MAX_DECOMPRESSION_BUFFER_SIZE (4*1024*1024)

static const char *lz4_decompress(const char *src, const size_t src_len, luaL_Buffer *B)
{
    LZ4F_dctx *dctx;
    const LZ4F_errorCode_t dctxRet = LZ4F_createDecompressionContext(&dctx, LZ4F_VERSION);
    if (LZ4F_isError(dctxRet)) {
        return LZ4F_getErrorName(dctxRet);
    }

    const char *srcBuffer = src;            /* current byte address to decompress */
    size_t src_remaining_size = src_len;    /* remaining bytes to decompress */

    size_t realloc_size = MIN_DECOMPRESSION_BUFFER_SIZE;
    char *dstBuffer = luaL_prepbuffsize(B, realloc_size);
    size_t dst_capacity = realloc_size;

    while (src_remaining_size > 0) {
        if (dst_capacity < MIN_DECOMPRESSION_BUFFER_SIZE) {
            dstBuffer = luaL_prepbuffsize(B, realloc_size);
            dst_capacity = realloc_size;
            if (realloc_size < MAX_DECOMPRESSION_BUFFER_SIZE) {
                realloc_size *= 2;
            }
        }

        size_t srcSize = src_remaining_size;
        size_t dstSize = dst_capacity;
        const size_t n = LZ4F_decompress(dctx, dstBuffer, &dstSize, srcBuffer, &srcSize, NULL);
        if (LZ4F_isError(n)) {
            LZ4F_freeDecompressionContext(dctx);
            return LZ4F_getErrorName(n);
        }

        srcBuffer += srcSize;
        src_remaining_size -= srcSize;

        luaL_addsize(B, dstSize);
        dstBuffer += dstSize;
        dst_capacity -= dstSize;
    }

    LZ4F_freeDecompressionContext(dctx);
    return NULL; /* no error */
}

/*@@@
```lua
lz4.unlz4(data)
```
decompresses `data` with LZ4.
`data` shall be an LZ4 frame and
can be the content of a file produced by the `lz4` command line utility.
@@@*/

static int decompress(lua_State *L)
{
    const char *srcBuffer = luaL_checkstring(L, 1);
    const size_t srcTotalSize = (size_t)lua_rawlen(L, 1);
    luaL_Buffer B;
    luaL_buffinit(L, &B);
    const char *err = lz4_decompress(srcBuffer, srcTotalSize, &B);
    if (err != NULL)
    {
        lua_pop(L, 1);
        return luax_pusherror(L, "LZ4 decompression error: %s", err);
    }
    luaL_pushresult(&B);
    return 1;
}

/******************************************************************************
 * LZ4 package
 ******************************************************************************/

static const luaL_Reg lz4_module[] =
{
    {"lz4", compress},
    {"unlz4", decompress},
    {NULL, NULL}
};

LUAMOD_API int luaopen_lz4(lua_State *L)
{
    luaL_newlib(L, lz4_module);
    return 1;
}
