# import: import Lua scripts into tables

``` lua
local import = require "import"
```

The import module can be used to manage simple configuration files,
configuration parameters being global variables defined in the
configuration file.

``` lua
local conf = import "myconf.lua"
```

Evaluates `"myconf.lua"` in a new table and returns this table. All
files are tracked in `import.files`.

`package.modpath` also contains the names of the files loaded by
`import`.

The imported files are stored in a cache. Subsequent calls to `import`
can read files from the cache instead of actually reloading them. The
cache can be disabled with an optional parameter:

``` lua
local conf = import("myconf.lua", {cache=false})
```

Reloads the file instead of using the cache.
