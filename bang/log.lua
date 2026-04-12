-- This file is part of bang.
--
-- bang is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- bang is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with bang.  If not, see <https://www.gnu.org/licenses/>.
--
-- For further information about bang you can visit
-- https://codeberg.org/cdsoft/bang

local F = require "F"

local where = require "where"

local log = {}

local quiet = false

function log.config(args)
    quiet = args.quiet
end

function log.error(...)
    io.stderr:write(F.flatten{where(), "ERROR: ", {...}, "\n"}:unpack())
    os.exit(1)
end

function log.warning(...)
    io.stderr:write(F.flatten{where(), "WARNING: ", {...}, "\n"}:unpack())
end

function log.info(...)
    if not quiet then
        io.stdout:write(F.flatten{{...}, "\n"}:unpack())
    end
end

return log
