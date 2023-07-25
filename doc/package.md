# package

The standard Lua package `package` is added some information about
packages loaded by LuaX.

``` lua
package.modpath      -- { module_name = module_path }
```

> table containing the names of the loaded packages and their actual
> paths.
