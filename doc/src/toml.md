---
title: Lua eXtended
author: @AUTHORS
---

# tinytoml: a pure Lua TOML parser

```lua
local toml = require "toml"
```

The TOML package is taken from
[tinytoml](https://github.com/FourierTransformer/tinytoml).

toml.lua is a TOML Module for Lua.

Please check [tinytoml](https://github.com/FourierTransformer/tinytoml) for further
information.

LuaX applies a patch to toml.lua to sort keys with `F.pairs` instead of the non-deterministic `pairs` function.

E.g.:

``` lua
local conf = toml.parse("config.toml")
```
