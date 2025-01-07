# LuaX interactive usage

The LuaX REPL can be run in various environments:

- the full featured LuaX interpreter based on the LuaX runtime
- the reduced version running on a plain Lua interpreter

## Full featured LuaX interpreter

### Self-contained interpreter

``` sh
$ luax
```

### Shared library usable with a standard Lua interpreter

``` sh
$ lua -l luax
```

## Reduced version for plain Lua interpreters

### LuaX with a plain Lua interpreter

``` sh
luax.lua
```

### LuaX with the Pandoc Lua interpreter

``` sh
luax-pandoc.lua
```

The integration with Pandoc is interesting to debug Pandoc Lua filters
and inspect Pandoc AST. E.g.:

``` sh
$ rlwrap luax-pandoc.lua

 _               __  __  |  https://github.com/cdsoft/luax
| |   _   _  __ _\ \/ /  |
| |  | | | |/ _` |\  /   |  Version X.Y
| |__| |_| | (_| |/  \   |  Powered by Lua X.Y
|_____\__,_|\__,_/_/\_\  |  and Pandoc X.Y
                         |  <OS> <ARCH>

>> pandoc.read "*Pandoc* is **great**!"
Pandoc (Meta {unMeta = fromList []}) [Para [Emph [Str "Pandoc"],Space,Str "is",Space,Strong [Str "great"],Str "!"]]
```

Note that [rlwrap](https://github.com/hanslub42/rlwrap) can be used to
give nice edition facilities to the Pandoc Lua interpreter.

## Additional modules

The `luax` repl provides a few functions for the interactive mode.

In interactive mode, these functions are available as global functions
and modules.

LuaX preloads the following modules with the `-e` option or before
entering the REPL:

- F
- complex
- crypt
- fs
- imath
- lz4
- lzip
- mathx
- ps
- qmath
- sh
- sys

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
