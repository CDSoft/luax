# ps: Process management module

```lua
local ps = require "ps"
```

```lua
ps.sleep(n)
```
> sleeps for `n` seconds.

```lua
ps.time()
```
> returns the current time in seconds (the resolution is OS dependant).

```lua
ps.clock()
```
> returns an approximation of the amount in seconds of CPU time used by the program,
> as returned by the underlying ISO C function `clock`.

```lua
ps.profile(func, ...)
```
> executes `func` with the provided arguments and returns:
>
> - On success: execution time (number) followed by all return values of `func`
> - On error: `false`, error message
