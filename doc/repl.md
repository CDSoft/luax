# LuaX interactive usage

The `luax` repl provides a few functions for the interactive mode.

In interactive mode, these functions are available as global functions.
`pretty` is used by the LuaX REPL to print results.

``` lua
luax.F
```

is the `fun` module.

``` lua
luax.fs
```

is the `fs` module.

``` lua
luax.pretty(x)
```

returns a string representing `x` with nice formatting for tables and
numbers.

``` lua
luax.precision(len, frac)
```

changes the format of floats. `len` is the total number of characters
and `frac` the number of decimals after the floating point (`frac` can
be `nil`). `len` can also be a string (custom format string) or `nil`
(to reset the float format). `b` can be `10` (decimal numbers), `16`
(hexadecimal numbers), `8` (octal numbers), a custom format string or
`nil` (to reset the integer format).

``` lua
luax.base(b)
```

changes the format of integers. `b` can be `10` (decimal numbers), `16`
(hexadecimal numbers), `8` (octal numbers), a custom format string or
`nil` (to reset the integer format).

``` lua
luax.inspect(x)
```

calls `inspect(x)` to build a human readable representation of `x` (see
the `inspect` package).

``` lua
luax.printi(x)
```

prints `inspect(x)` (without the metatables).
