# LuaX interactive usage

The `luax` repl provides a few functions for the interactive mode.

In interactive mode, these functions are available as global functions.
`show` is used by the LuaX REPL to print results.

``` lua
F
```

is the `fun` module.

``` lua
fs
```

is the `fs` module.

``` lua
show(x)
```

returns a string representing `x` with nice formatting for tables and
numbers.

``` lua
precision(len, frac)
```

changes the format of floats. `len` is the total number of characters
and `frac` the number of decimals after the floating point (`frac` can
be `nil`). `len` can also be a string (custom format string) or `nil`
(to reset the float format). `b` can be `10` (decimal numbers), `16`
(hexadecimal numbers), `8` (octal numbers), a custom format string or
`nil` (to reset the integer format).

``` lua
base(b)
```

changes the format of integers. `b` can be `10` (decimal numbers), `16`
(hexadecimal numbers), `8` (octal numbers), a custom format string or
`nil` (to reset the integer format).

``` lua
indent(i)
```

indents tables (`i` spaces). If `i` is `nil`, tables are not indented.

``` lua
prints(x)
```

prints `show(x)`

``` lua
inspect(x)
```

calls `inspect(x)` to build a human readable representation of `x` (see
the `inspect` package).

``` lua
printi(x)
```

prints `inspect(x)` (without the metatables).
