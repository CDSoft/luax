# import: import Lua scripts into tables

``` lua
local import = require "import"
```

The import module can be used to manage simple configuration files,
configuration parameters being global variables defined in the
configuration file.

``` lua
local conf = import("myconf.lua", [env])
```

Evaluates `"myconf.lua"` in a new table and returns this table. All
files are tracked in `package.modpath`.

The execution environment inherits from `env` (or `_ENV` if `env` is not
defined).
