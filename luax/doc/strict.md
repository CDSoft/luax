
# strict: checks uses of undeclared global variables

The `strict` module checks uses of undeclared global variables.
All global variables must be 'declared' through a regular assignment
(even assigning nil will do) in a main chunk before being used
anywhere or assigned to inside a function.

`strict` is distributed under the Lua license: <http://www.lua.org/license.html>

```lua
require "strict"
```

This module is `strict.lua` from <https://www.lua.org/extras/>
adpated for LuaX.

This module not loaded by default since some global variables are tested when LuaX start but may not be defined.


