## Lua Archive

``` lua
local lar = require "lar"
```

`lar` is a simple archive format for Lua values (e.g. Lua tables). It
contains a Lua value:

- serialized with `cbor`
- compressed with `lz4` or `lzip`
- encrypted with `rc4`

The Lua value is only encrypted if a key is provided.

``` lua
lar.lar(lua_value, [opt])
```

Returns a string with `lua_value` serialized, compressed and encrypted.

Options:

- `opt.compress`: compression algorithm (`"lz4"` by default):

  - `"none"`: no compression
  - `"lz4"`: compression with LZ4 (default compression level)
  - `"lz4-#"`: compression with LZ4 (compression level `#` with `#`
    between 0 and 12)
  - `"lzip"`: compression with lzip (default compression level)
  - `"lzip-#"`: compression with lzip (compression level `#` with `#`
    between 0 and 9)

- `opt.key`: encryption key (no encryption by default)

``` lua
lar.unlar(archive, [opt])
```

Returns the Lua value contained in a serialized, compressed and
encrypted string.

Options:

- `opt.key`: encryption key (no encryption by default)
