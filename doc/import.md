# import: import Lua scripts into tables

The import module can be used to manage simple configuration files,
configuration parameters being global variables defined in the
configuration file.

``` lua
local conf = import "myconf.lua"
```

Evaluates `"myconf.lua"` in a new table and returns this table. All
files are tracked in `import.files`.
