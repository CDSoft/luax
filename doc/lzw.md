# lzw: A relatively fast LZW compression algorithm in pure Lua

``` lua
local lzw = require "lzw"
```

LZW is a relatively fast LZW compression algorithm in pure Lua.

The source code in on Github: <https://github.com/Rochet2/lualzw>.

## LZW compression

``` lua
lzw.lzw(data)
```

compresses `data` with LZW.

## LZW decompression

``` lua
lzw.unlzw(data)
```

decompresses `data` with LZW.

## String methods

The `lzw` functions are also available as `string` methods:

``` lua
s:lzw()         == lzw.lzw(s)
s:unlzw()       == lzw.unlzw(s)
```
