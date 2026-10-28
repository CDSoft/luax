--[[
This file is part of ypp.

ypp is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

ypp is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

Software freedom is inseparable from freedom of thought. Fascism -
in all its forms - is incompatible with the values this project stands
on, even though the GPL itself cannot and does not restrict who may
use this software. See FREEDOM.md.

You should have received a copy of the GNU General Public License
along with ypp.  If not, see <https://www.gnu.org/licenses/>.

For further information about ypp you can visit
https://codeberg.org/cdsoft/luax
--]]

--[[@@@
- `comment(...)`: returns an empty string (useful for commenting some text)

E.g.:

@q[=====[
```
@comment [===[
This paragraph is a comment
and is not part of the output document.
]===]
```
]=====]
@@@]]

local F = require "F"

return F.const ""
