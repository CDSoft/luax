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

--@LIB

--[[------------------------------------------------------------------------@@@
# Simple wget interface

```lua
local wget = require "wget"
```

`wget` provides functions to execute wget.
wget must be installed separately.

@@@]]

local M = {}

local sh = require "sh"

local errs = {
    [ 0] = "No problems occurred.",
    [ 1] = "Generic error code.",
    [ 2] = "Parse error. For instance, when parsing command-line options, the .wget2rc or .netrc...",
    [ 3] = "File I/O error.",
    [ 4] = "Network failure.",
    [ 5] = "SSL verification failure.",
    [ 6] = "Username/password authentication failure.",
    [ 7] = "Protocol errors.",
    [ 8] = "Server issued an error response.",
    [ 9] = "Public key missing from keyring.",
    [10] = "A Signature verification failed.",

    -- This error is returned by the shell, not wget
    [127] = "wget: command not found",
}

local default_wget_options = {
    "--quiet",
}

local function wget(...)
    local res, _, err = sh("wget", ...)
    if not res then return nil, errs[tonumber(err)] or "wget: unknown error", err end
    return res
end

M.request = wget

--[[@@@
```lua
wget.request(...)
```
> Execute `wget` with arguments `...` and returns the output of `wget` (`stdout`).
> Arguments can be a nested list (it will be flattened).
> In case of error, `wget` returns `nil`, an error message and an error code
> (see [wget man page](https://www.gnu.org/software/wget/manual/html_node/Exit-Status.html)).

```lua
wget(...)
```
> Like `wget.request(...)` with some default options:
>
> - `--quiet`: quiet mode

@@@]]

return setmetatable(M, {
    __call = function(_, ...) return wget(default_wget_options, ...) end,
})
