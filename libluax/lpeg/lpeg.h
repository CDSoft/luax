/* This file is part of luax.
 *
 * luax is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * luax is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with luax.  If not, see <https://www.gnu.org/licenses/>.
 *
 * For further information about luax you can visit
 * https://codeberg.org/cdsoft/luax
 */

#pragma once

/***************************************************************************@@@
# lpeg: Parsing Expression Grammars For Lua

LPeg is a pattern-matching library for Lua.

```lua
local lpeg = require "lpeg"
local re = require "re"
```

The documentation of these modules are available on Lpeg web site:

- [Lpeg](http://www.inf.puc-rio.br/~roberto/lpeg/)
- [Re](http://www.inf.puc-rio.br/~roberto/lpeg/re.html)
@@@*/

#include "lua.h"

/* C module registration function */
LUAMOD_API int luaopen_lpeg(lua_State *L); /* defined in lptree.c */
