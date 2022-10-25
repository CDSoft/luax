# ps: Process management module

``` lua
local ps = require "ps"
```

``` lua
ps.sleep(n)
```

sleeps for `n` seconds.

``` lua
ps.time()
```

returns the current time in seconds (the resolution is OS dependant).

``` lua
ps.profile(func)
```

executes `func` and returns its execution time in seconds.
