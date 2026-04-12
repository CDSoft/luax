# debug

The standard Lua package `debug` is added some functions to help
debugging.

``` lua
debug.locals(level)
```

> table containing the local variables at a given level `level`. The
> default level is the caller level (1). If `level` is a function,
> `locals` returns the names of the function parameters.
