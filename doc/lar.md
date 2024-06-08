## Lua Archive

``` lua
local lar = require "lar"
```

`lar` is a simple archive format for Lua values (e.g. Lua tables). It
contains a Lua value:

- serialized with `cbor`
- compressed with `lz4`
- encrypted with `rc4` (e.g. to avoid unintended modifications)

``` lua
lar.lar(lua_value, [key])
```

Returns a string with `lua_value` serialized, compressed and encrypted.

``` lua
lar.unlar(archive, [key])
```

Returns the Lua value contained in serialized, compressed and encrypted
string.
