# Interpolation of strings

``` lua
local I = require "I"
```

``` lua
I(t)
```

> returns a string interpolator that replaces `$(...)` by the value of
> `...` in the environment defined by the table `t`. An interpolator can
> be given another table to build a new interpolator with new values.
