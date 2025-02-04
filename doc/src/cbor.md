---
title: Lua eXtended
author: @AUTHORS
---

# cbor: pure Lua implementation of the CBOR

```lua
local cbor = require "cbor"
```

The cbor package is taken from
[Lua-CBOR](https://www.zash.se/lua-cbor.html).

Lua-CBOR is a (mostly) pure Lua implementation of the [CBOR](http://cbor.io/),
a compact data serialization format, defined in [RFC 7049](https://datatracker.ietf.org/doc/html/rfc7049).

Please check [Lua-CBOR](https://www.zash.se/lua-cbor.html) for further
information.

LuaX applies a patch to cbor to specify the key order with a function overloading `pairs`.
If the `pairs` parameter is a function, it is used to iterate over tables instead of the standard `pairs` function.

E.g.:

``` lua
local t = {x=1, y=2, z=3}
local sorted = cbor.encode(t, {pairs=F.pairs})

-- sorted is a CBOR string where fields in all tables are ordered according to F.pairs
```
