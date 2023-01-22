# LuaX interactive usage

The LuaX REPL can be run in various environments:

- the full featured LuaX interpretor based on the LuaX runtime
- the reduced version running on a vanilla Lua interpretor

## Full featured LuaX interpretor

### Self-contained interpretor

``` sh
$ luax
```

### Shared library usable with a standard Lua interpretor

``` sh
$ LUA_CPATH="lib/?.so" lua -l luax-x86_64-linux-gnu
```

## Reduced version for vanilla Lua interpretors

### LuaX with a vanilla Lua interpretor

``` sh
lua luaxcli.lua
```

### LuaX with the Pandoc Lua interpretor

``` sh
pandoc lua luaxcli.lua
```

The integration with Pandoc is interresting to debug Pandoc Lua filters
and inspect Pandoc AST. E.g.:

``` sh
$ rlwrap pandoc lua luaxcli.lua

 _               __  __  |  http://cdelord.fr/luax
| |   _   _  __ _\ \/ /  |
| |  | | | |/ _` |\  /   |  Version 1.13.1
| |__| |_| | (_| |/  \   |  Powered by Lua 5.4
|_____\__,_|\__,_/_/\_\  |  and Pandoc 3.0
                         |  Linux x86_64 lua

>> pandoc.read "*Pandoc* is **great**!"
Pandoc (Meta {unMeta = fromList []}) [Para [Emph [Str "Pandoc"],Space,Str "is",Space,Strong [Str "great"],Str "!"]]
```

Note that [rlwrap](https://github.com/hanslub42/rlwrap) can be used to
give nice edition facilities to the Pandoc Lua interpretor.

## Additional modules

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
