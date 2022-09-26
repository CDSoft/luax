# lz4: Extremely Fast Compression algorithm

``` lua
local lz4 = require "lz4"
```

LZ4 is an extremely fast compression algorithm by Yann Collet.

The source code in on Github: <https://github.com/lz4/lz4>.

More information on <https://www.lz4.org>.

**`lz4.compress(data)`** compresses `data` with LZ4 (highest compression
level). The compressed data is an LZ4 frame that can be stored in a file
and decompressed by the `lz4` command line utility.

**`lz4.decompress(data)`** decompresses `data` with LZ4. `data` shall be
an LZ4 frame and can be the content of a file produced by the `lz4`
command line utility.

The `lz4` functions are also available as `string` methods:

**`s:lz4_compress()`** is `lz4.compress(s)`.

**`s:lz4_decompress()`** is `lz4.decompress(s)`.
