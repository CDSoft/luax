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
sys.exe
```

Extension of executable files on the platform.

``` lua
sys.so
```

Extension of shared libraries on the platform (`".so"`, `".dylib"` or
`".dll"`).

``` lua
sys.name
```

Name of the platform.
