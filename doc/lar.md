## Lua Archive

``` lua
local lar = require "lar"
```

`lar` is a simple archive format for Lua values (e.g. Lua tables). It
contains a Lua value:

- serialized with `cbor`
- compressed with `lz4`
- encrypted with `rc4`

The Lua value is only encrypted if a key is provided.

``` lua
lar.lar(lua_value, [key])
```

Returns a string with `lua_value` serialized, compressed and encrypted.

``` lua
lar.unlar(archive, [key])
```

Returns the Lua value contained in a serialized, compressed and
encrypted string.
