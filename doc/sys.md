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

`"x86_64"`, `"i386"` or `"aarch64"`.

``` lua
sys.abi
```

`"musl"` or `"gnu"`.

``` lua
sys.type
```

`"static"`, `"dynamic"` or `"lua"`
