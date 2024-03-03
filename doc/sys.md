# sys: System module

``` lua
local sys = require "sys"
```

``` lua
sys.os
```

`"linux"`, `"macos"` or `"windows"`.

``` lua
sys.arch
```

`"x86_64"` or `"aarch64"`.

``` lua
sys.libc
```

`"musl"` or `"gnu"`. Note that `libc` is `"lua"` when using the pure Lua
implementation of LuaX.

``` lua
sys.build
```

Build platform used to compile LuaX.

``` lua
sys.host
```

Host platform where LuaX is currently running.
