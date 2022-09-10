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

-- functions added to the string package

local crypt = require "crypt"

function string.hex_encode(s) return crypt.hex_encode(s) end
function string.hex_decode(s) return crypt.hex_decode(s) end
function string.base64_encode(s) return crypt.base64_encode(s) end
function string.base64_decode(s) return crypt.base64_decode(s) end
function string.base64url_encode(s) return crypt.base64url_encode(s) end
function string.base64url_decode(s) return crypt.base64url_decode(s) end
function string.rc4(s, k, d) return crypt.rc4(s, k, d) end
function string.crc32(s) return crypt.crc32(s) end
function string.crc64(s) return crypt.crc64(s) end
