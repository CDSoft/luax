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
ps.clock()
```

returns an approximation of the amount in seconds of CPU time used by
the program, as returned by the underlying ISO C function `clock`.

``` lua
ps.profile(func)
```

executes `func` and returns its execution time in seconds (using
`ps.clock`).
