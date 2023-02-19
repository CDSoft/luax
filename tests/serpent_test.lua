--[[
This file is part of luax.

luax is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

luax is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with luax.  If not, see <https://www.gnu.org/licenses/>.

For further information about luax you can visit
http://cdelord.fr/luax
--]]

return function()

    local serpent = require "serpent"
    assert(serpent)

    local line = function(a) return serpent.line(a, {comment=false, sortkeys=true}) end
    local dump = function(a) return serpent.dump(a, {indent="  ", sortkeys=true, compact=false}) end

    eq(line(42), "42")
    eq(line("Hello"), '"Hello"')

    eq(line({}), "{}")
    eq(line({1, 2, 3}), "{1, 2, 3}")
    eq(line({x=1, y=2, z=3}), "{x = 1, y = 2, z = 3}")
    eq(line({a={x=1, y=2}, {x=3, y=4}, 5, 6}), "{{x = 3, y = 4}, 5, 6, a = {x = 1, y = 2}}")

    local t = {
        "a", "b",
        p = {x=10, y=20},
        refs = {},
        func = math.sin,
    }
    t.refs[1] = t -- recursive table
    eq(dump(t), [[
do local _ = {
  [1] = "a",
  [2] = "b",
  func = math.sin,
  p = {
    x = 10,
    y = 20
  },
  refs = {
    nil
  }
}
local __={}
_.refs[1] = _
return _
end]])

end
