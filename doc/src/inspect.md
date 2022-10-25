---
title: Lua eXtended
author: Christophe Delord
---

# inspect: Human-readable representation of Lua tables

```lua
local inspect = require "inspect"
```

The inspect package is taken from
[inspect.lua](https://github.com/kikito/inspect.lua).

This library transforms any Lua value into a human-readable representation. It
is especially useful for debugging errors in tables.

The objective here is human understanding (i.e. for debugging), not
serialization or compactness.

Please check [inspect.lua](https://github.com/kikito/inspect.lua) for further
information.
