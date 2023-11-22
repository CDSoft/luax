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
# lz4:  Extremely Fast Compression algorithm

```lua
local lz4 = require "lz4"
```

LZ4 is an extremely fast compression algorithm by Yann Collet.

The source code in on Github: <https://github.com/lz4/lz4>.

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

The compression preferences are hard coded:

- linked blocks
- frame checksum enabled
- default compression level

@@@*/

/***************************************************************************@@@
## LZ4 frame compression
@@@*/

const char *lz4_compress(const char *src, const size_t src_len, char **dst, size_t *dst_len)
{
    const char *srcBuffer = src;
    const size_t srcSize = src_len;
    LZ4F_preferences_t prefs = LZ4F_INIT_PREFERENCES;
    prefs.frameInfo.blockMode = LZ4F_blockLinked;
    prefs.frameInfo.contentChecksumFlag = LZ4F_contentChecksumEnabled;
    prefs.compressionLevel = LZ4HC_CLEVEL_DEFAULT;
    const size_t dstCapacity = LZ4F_compressFrameBound(srcSize, &prefs);
    char *dstBuffer = safe_malloc(dstCapacity);
    const size_t n = LZ4F_compressFrame(dstBuffer, dstCapacity, srcBuffer, srcSize, &prefs);
    if (LZ4F_isError(n))
    {
        free(dstBuffer);
        return LZ4F_getErrorName(n);
    }
    *dst = dstBuffer;
    *dst_len = n;
    return NULL; /* no error */
}

/*@@@
```lua
lz4.compress(data)
```
compresses `data` with LZ4.
The compressed data is an LZ4 frame that can be stored in a file and
decompressed by the `lz4` command line utility.
@@@*/

static int compress(lua_State *L)
{
    const char *srcBuffer = luaL_checkstring(L, 1);
    const size_t srcSize = (size_t)lua_rawlen(L, 1);
    char *dstBuffer = NULL;
    size_t dstSize = 0;
    const char *err = lz4_compress(srcBuffer, srcSize, &dstBuffer, &dstSize);
    if (err != NULL)
    {
        return luax_pusherror1(L, "LZ4 compression error: %s", err);
    }
    lua_pushlstring(L, dstBuffer, dstSize);
    free(dstBuffer);
    return 1;
}

/***************************************************************************@@@
## LZ4 frame decompression
@@@*/

#define MIN_DECOMPRESSION_BUFFER_SIZE 4096
#define COMPRESSION_RATIO_GUESS 4 /* The compression ratio of the LuaX library is about 3.5 */

const char *lz4_decompress(const char *src, const size_t src_len, char **dst, size_t *dst_len)
{
    const char *srcBuffer = src;
    const size_t srcTotalSize = src_len;
    const char *srcPtr = srcBuffer;
    size_t srcSize = srcTotalSize;
    LZ4F_dctx *dctx;
    const LZ4F_errorCode_t dctxRet = LZ4F_createDecompressionContext(&dctx, LZ4F_VERSION);
    if (LZ4F_isError(dctxRet))
    {
        return LZ4F_getErrorName(dctxRet);
    }
    size_t dstBufferCapacity = COMPRESSION_RATIO_GUESS*srcTotalSize + MIN_DECOMPRESSION_BUFFER_SIZE;
    char *dstBuffer = safe_malloc(dstBufferCapacity);
    char *dstPtr = dstBuffer;
    size_t dstSize = dstBufferCapacity;
    size_t dstOffset = 0;
    while (srcSize > 0)
    {
        if (dstSize < MIN_DECOMPRESSION_BUFFER_SIZE)
        {
            dstSize += dstBufferCapacity;
            dstBufferCapacity += dstBufferCapacity;
            dstBuffer = safe_realloc(dstBuffer, dstBufferCapacity);
            dstPtr = dstBuffer + dstOffset;
        }
        size_t consumedSize = srcSize;
        size_t decompressedSize = dstSize;
        const size_t n = LZ4F_decompress(dctx, dstPtr, &decompressedSize, srcPtr, &consumedSize, NULL);
        if (LZ4F_isError(n))
        {
            free(dstBuffer);
            LZ4F_freeDecompressionContext(dctx);
            return LZ4F_getErrorName(n);
        }
        srcPtr += consumedSize;
        srcSize -= consumedSize;
        dstPtr += decompressedSize;
        dstOffset += decompressedSize;
        dstSize -= decompressedSize;
    }
    LZ4F_freeDecompressionContext(dctx);
    *dst = dstBuffer;
    *dst_len = dstOffset;
    return NULL; /* no error */
}

/*@@@
```lua
lz4.decompress(data)
```
decompresses `data` with LZ4.
`data` shall be an LZ4 frame and
can be the content of a file produced by the `lz4` command line utility.
@@@*/

static int decompress(lua_State *L)
{
    const char *srcBuffer = luaL_checkstring(L, 1);
    const size_t srcTotalSize = (size_t)lua_rawlen(L, 1);
    char *dstBuffer = NULL;
    size_t dstOffset = 0;
    const char *err = lz4_decompress(srcBuffer, srcTotalSize, &dstBuffer, &dstOffset);
    if (err != NULL)
    {
        return luax_pusherror1(L, "LZ4 decompression error: %s", err);
    }
    lua_pushlstring(L, dstBuffer, dstOffset);
    free(dstBuffer);
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
