---
title: Lua eXtended - pure Lua implementation
author: @AUTHORS
---

# LuaX in Lua

The script `lib/luax.lua` is a standalone Lua package that reimplements some
LuaX modules. It can be used in Lua projects without any other LuaX dependency.

These modules may have slightly different and degraded behaviours compared to
the LuaX modules. Especially `fs` and `ps` may be incomplete and less accurate
than the same functions implemented in C in LuaX.

```lua
require "luax"
```
> changes the `package` module such that `require` can load LuaX modules.
