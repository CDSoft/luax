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

---------------------------------------------------------------------
-- string
---------------------------------------------------------------------

return function()

    eq(("ab/cd/efg/hij"):split("/"), {"ab","cd","efg","hij"})
    eq(("ab/cd/efg/hij"):split("/", 2), {"ab","cd","efg/hij"})
    eq(("ab/cd/efg/hij/"):split("/"), {"ab","cd","efg","hij",""})
    eq(("ab/cd/efg/hij/"):split("/", 2), {"ab","cd","efg/hij/"})
    eq(("/ab/cd/efg/hij"):split("/"), {"", "ab","cd","efg","hij"})
    eq(("/ab/cd/efg/hij"):split("/", 2), {"","ab","cd/efg/hij"})
    eq(("abcz+defzzzghi"):split("z+", nil, false), {"abc","+def","ghi"})
    eq(("abcz+defzzzghi"):split("z+", nil, true), {"abc","defzzzghi"})

    eq(("aa bb cc\ndd ee ff\nhh ii jj"):lines(), {"aa bb cc","dd ee ff","hh ii jj"})
    eq(("\naa bb cc\ndd ee ff\nhh ii jj\n"):lines(), {"","aa bb cc","dd ee ff","hh ii jj"})

    eq(("aa bb cc\ndd ee ff\nhh ii jj"):words(), {"aa","bb","cc","dd","ee","ff","hh","ii","jj"})
    eq(("\naa bb cc\ndd ee ff\nhh ii jj"):words(), {"aa","bb","cc","dd","ee","ff","hh","ii","jj"})

    eq(("abc"):ltrim(), "abc")
    eq(("  abc"):ltrim(), "abc")
    eq(("abc  "):ltrim(), "abc  ")
    eq(("  abc  "):ltrim(), "abc  ")

    eq(("abc"):rtrim(), "abc")
    eq(("  abc"):rtrim(), "  abc")
    eq(("abc  "):rtrim(), "abc")
    eq(("  abc  "):rtrim(), "  abc")

    eq(("abc"):trim(), "abc")
    eq(("  abc"):trim(), "abc")
    eq(("abc  "):trim(), "abc")
    eq(("  abc  "):trim(), "abc")

end
