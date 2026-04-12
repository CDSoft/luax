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

You should have received a copy of the GNU General Public License
along with ypp.  If not, see <https://www.gnu.org/licenses/>.

For further information about ypp you can visit
https://codeberg.org/cdsoft/luax
--]]

--[[@@@
* `script(cmd)(source)`: execute `cmd` to interpret `source`.
  `source` is first saved to a temporary file which name is added to the command `cmd`.
  If `cmd` contains `%s` then `%s` is replaces by the temporary script name.
  Otherwise the script name is appended to the command.
  An explicit file extension can be given after `%s` for languages that require
  specific file extensions (e.g. `%s.fs` for F#).

`script` also predefines shortcuts for some popular languages:

@@( local descr = {
        bat = "`command` (DOS/Windows)",
        cmd = "`cmd` (DOS/Windows)",
        sh = "sh",
        bash = "bash",
        zsh = "zsh",
    }
    return F.keys(script):map(function(lang)
        return ("- `script.%s(source)`: run a script with %s"):format(lang, descr[lang] or lang:cap())
    end)
)

Example:

@q[=====[
```
$\sum_{i=0}^100 = @script.python "print(sum(range(101)))"$
```
]=====]
is rendered as
```
$\sum_{i=0}^100 = @script.python "print(sum(range(101)))"$
```
@@@]]

local fs = require "fs"
local sh = require "sh"
local flex = require "flex"
local convert = require "convert"

local function make_script_cmd(cmd, arg, ext)
    arg = arg..ext
    local n1, n2
    cmd, n1 = cmd:gsub("%%s"..(ext~="" and "%"..ext or ""), arg)
    cmd, n2 = cmd:gsub("%%s", arg)
    if n1+n2 == 0 then cmd = cmd .. " " .. arg end
    return cmd
end

local function script_ext(cmd)
    local ext = cmd:match("%%s(%.%w+)") -- extension given by the command line
    return ext or ""
end

local function run(cmd)
    return flex.str(function(content, opts)
        content = tostring(content)
        return fs.with_tmpdir(function (tmpdir)
            local name = fs.join(tmpdir, "script")
            local ext = script_ext(cmd)
            fs.write(name..ext, content)
            local output = sh.read(make_script_cmd(cmd, name, ext))
            if output then
                output = output:gsub("%s*$", "")
                output = convert.if_required(output, opts)
                return output
            else
                error("script error")
            end
        end)
    end)
end

return setmetatable({
    python = run "python %s.py",
    lua = run "lua %s.lua",
    bash = run "bash %s.sh",
    zsh = run "zsh %s.sh",
    sh = run "sh %s.sh",
    cmd = run "cmd %s.cmd",
    bat = run "command %s.bat",
}, {
    __call = function(_, cmd) return run(cmd) end,
})
