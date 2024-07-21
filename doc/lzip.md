# lzip: A compression library for the lzip format

``` lua
local lzip = require "lzip"
```

lzip is a data compression library providing in-memory LZMA compression
and decompression functions.

The source code is available at
<https://www.nongnu.org/lzip/lzlib.html>.

## lzip compression

``` lua
lzip.compress(data, [level])
```

compresses `data` with lzip. The compressed data is an lzip frame that
can be stored in a file and decompressed by the `lzip` command line
utility.

The optional `level` parameter is the compression level (from 0 to 9).
The default compression level is 6.

## lzip decompression

``` lua
lzip.decompress(data)
```

decompresses `data` with lzip. `data` shall be an lzip frame and can be
the content of a file produced by the `lzip` command line utility.

## String methods

The `lzip` functions are also available as `string` methods:

``` lua
s:lzip()        == lzip.lzip(s)
s:unlzip()      == lzip.unlzip(s)
```
