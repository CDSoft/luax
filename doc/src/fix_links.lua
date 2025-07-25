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
https://codeberg.org/cdsoft/luax
--]]

local path = _ENV.pandoc.path
local output_path = path.directory(_ENV.PANDOC_STATE.output_file)

if _ENV.FORMAT == "gfm" and _ENV.PANDOC_STATE.output_file == "README.md" then

    function Link(el)
        if el.target:match"%.md$" then
            local new_target = path.join{output_path, "doc", el.target}
            el.target = path.make_relative(new_target, output_path)
            return el
        end
    end

    function Image(el)
        if el.src:match"%.svg$" then
            local new_src = path.join{output_path, "doc", el.src}
            el.src = path.make_relative(new_src, output_path)
            return el
        end
    end

end

if _ENV.FORMAT == "html5" then

    function Link(el)
        el.target = el.target:gsub("%.md$", ".html")
        return el
    end

    function Image(el)
        el.src = path.join{"doc", el.src}
        return el
    end

end
