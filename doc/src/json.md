---
title: Lua eXtended
author: @AUTHORS
---

# (dk)json: JSON Module for Lua

```lua
local json = require "json"
```

The json package is taken from
[dkjson.lua](http://dkolf.de/dkjson-lua/).

dkjson.lua is a JSON Module for Lua.

Please check [dkjson.lua](http://dkolf.de/dkjson-lua/) for further
information.

LuaX applies a patch to dkjson.lua to specify the key order with a function instead of a list.
If the `keyorder` parameter is a function, it is used to build the ordered element list.
Otherwise it shall be a list of fields as implemented in the original dkjson.lua.

E.g.:

``` lua
local t = {x=1, y=2, z=3}
local sorted   = json.encode(t, {keyorder=F.keys})
local reversed = json.encode(t, {keyorder=F.compose{F.reverse, F.keys}})

-- sorted   is {"x":1,"y":2,"z":3}
-- reversed is {"z":3,"y":2,"x":1}
```
