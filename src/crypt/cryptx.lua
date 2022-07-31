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

local crypt = require "crypt"

local strlen  = string.len
local strchar = string.char
local strbyte = string.byte
local strsub  = string.sub
local strgsub = string.gsub
local format  = string.format
local concat  = table.concat
local ceil    = math.ceil
local random  = math.random
local max     = math.max
local lshift  = function(a,n) return (a << n) & 0xFFFFFFFF end
local rshift  = function(a,n) return (a&0xFFFFFFFF) >> n end
local lrot    = function(a,n) return lshift(a, n) | rshift(a, 32-n) end

-----------------------------------------------------------------------
-- crypt.hex
-----------------------------------------------------------------------

crypt.hex = {}
do
    function crypt.hex.encode(s)
        return (s:gsub(".", function(c)
            return format("%02x", c:byte())
        end))
    end
    function crypt.hex.decode(s)
        return (s:gsub("..", function(h)
            return strchar("0x"..h)
        end))
    end
end

-----------------------------------------------------------------------
-- crypt.base64
-----------------------------------------------------------------------

crypt.base64 = {}

do  -- http://lua-users.org/wiki/BaseSixtyFour

    -- character table string
    local b64_chars='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

    -- encoding
    function crypt.base64.encode(data)
        return ((data:gsub('.', function(x)
            local r,b='',x:byte()
            for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
            return r;
        end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
            if (#x < 6) then return '' end
            local c=0
            for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
            return b64_chars:sub(c+1,c+1)
        end)..({ '', '==', '=' })[#data%3+1])
    end

    -- decoding
    function crypt.base64.decode(data)
        data = strgsub(data, '[^'..b64_chars..'=]', '')
        return (data:gsub('.', function(x)
            if (x == '=') then return '' end
            local r,f='',(b64_chars:find(x)-1)
            for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
            return r;
        end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
            if (#x ~= 8) then return '' end
            local c=0
            for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
            return strchar(c)
        end))
    end

end

-----------------------------------------------------------------------
-- crypt.crc32
-----------------------------------------------------------------------

do
    local consts = { 0x00000000, 0x77073096, 0xEE0E612C, 0x990951BA, 0x076DC419, 0x706AF48F, 0xE963A535, 0x9E6495A3,
                     0x0EDB8832, 0x79DCB8A4, 0xE0D5E91E, 0x97D2D988, 0x09B64C2B, 0x7EB17CBD, 0xE7B82D07, 0x90BF1D91,
                     0x1DB71064, 0x6AB020F2, 0xF3B97148, 0x84BE41DE, 0x1ADAD47D, 0x6DDDE4EB, 0xF4D4B551, 0x83D385C7,
                     0x136C9856, 0x646BA8C0, 0xFD62F97A, 0x8A65C9EC, 0x14015C4F, 0x63066CD9, 0xFA0F3D63, 0x8D080DF5,
                     0x3B6E20C8, 0x4C69105E, 0xD56041E4, 0xA2677172, 0x3C03E4D1, 0x4B04D447, 0xD20D85FD, 0xA50AB56B,
                     0x35B5A8FA, 0x42B2986C, 0xDBBBC9D6, 0xACBCF940, 0x32D86CE3, 0x45DF5C75, 0xDCD60DCF, 0xABD13D59,
                     0x26D930AC, 0x51DE003A, 0xC8D75180, 0xBFD06116, 0x21B4F4B5, 0x56B3C423, 0xCFBA9599, 0xB8BDA50F,
                     0x2802B89E, 0x5F058808, 0xC60CD9B2, 0xB10BE924, 0x2F6F7C87, 0x58684C11, 0xC1611DAB, 0xB6662D3D,
                     0x76DC4190, 0x01DB7106, 0x98D220BC, 0xEFD5102A, 0x71B18589, 0x06B6B51F, 0x9FBFE4A5, 0xE8B8D433,
                     0x7807C9A2, 0x0F00F934, 0x9609A88E, 0xE10E9818, 0x7F6A0DBB, 0x086D3D2D, 0x91646C97, 0xE6635C01,
                     0x6B6B51F4, 0x1C6C6162, 0x856530D8, 0xF262004E, 0x6C0695ED, 0x1B01A57B, 0x8208F4C1, 0xF50FC457,
                     0x65B0D9C6, 0x12B7E950, 0x8BBEB8EA, 0xFCB9887C, 0x62DD1DDF, 0x15DA2D49, 0x8CD37CF3, 0xFBD44C65,
                     0x4DB26158, 0x3AB551CE, 0xA3BC0074, 0xD4BB30E2, 0x4ADFA541, 0x3DD895D7, 0xA4D1C46D, 0xD3D6F4FB,
                     0x4369E96A, 0x346ED9FC, 0xAD678846, 0xDA60B8D0, 0x44042D73, 0x33031DE5, 0xAA0A4C5F, 0xDD0D7CC9,
                     0x5005713C, 0x270241AA, 0xBE0B1010, 0xC90C2086, 0x5768B525, 0x206F85B3, 0xB966D409, 0xCE61E49F,
                     0x5EDEF90E, 0x29D9C998, 0xB0D09822, 0xC7D7A8B4, 0x59B33D17, 0x2EB40D81, 0xB7BD5C3B, 0xC0BA6CAD,
                     0xEDB88320, 0x9ABFB3B6, 0x03B6E20C, 0x74B1D29A, 0xEAD54739, 0x9DD277AF, 0x04DB2615, 0x73DC1683,
                     0xE3630B12, 0x94643B84, 0x0D6D6A3E, 0x7A6A5AA8, 0xE40ECF0B, 0x9309FF9D, 0x0A00AE27, 0x7D079EB1,
                     0xF00F9344, 0x8708A3D2, 0x1E01F268, 0x6906C2FE, 0xF762575D, 0x806567CB, 0x196C3671, 0x6E6B06E7,
                     0xFED41B76, 0x89D32BE0, 0x10DA7A5A, 0x67DD4ACC, 0xF9B9DF6F, 0x8EBEEFF9, 0x17B7BE43, 0x60B08ED5,
                     0xD6D6A3E8, 0xA1D1937E, 0x38D8C2C4, 0x4FDFF252, 0xD1BB67F1, 0xA6BC5767, 0x3FB506DD, 0x48B2364B,
                     0xD80D2BDA, 0xAF0A1B4C, 0x36034AF6, 0x41047A60, 0xDF60EFC3, 0xA867DF55, 0x316E8EEF, 0x4669BE79,
                     0xCB61B38C, 0xBC66831A, 0x256FD2A0, 0x5268E236, 0xCC0C7795, 0xBB0B4703, 0x220216B9, 0x5505262F,
                     0xC5BA3BBE, 0xB2BD0B28, 0x2BB45A92, 0x5CB36A04, 0xC2D7FFA7, 0xB5D0CF31, 0x2CD99E8B, 0x5BDEAE1D,
                     0x9B64C2B0, 0xEC63F226, 0x756AA39C, 0x026D930A, 0x9C0906A9, 0xEB0E363F, 0x72076785, 0x05005713,
                     0x95BF4A82, 0xE2B87A14, 0x7BB12BAE, 0x0CB61B38, 0x92D28E9B, 0xE5D5BE0D, 0x7CDCEFB7, 0x0BDBDF21,
                     0x86D3D2D4, 0xF1D4E242, 0x68DDB3F8, 0x1FDA836E, 0x81BE16CD, 0xF6B9265B, 0x6FB077E1, 0x18B74777,
                     0x88085AE6, 0xFF0F6A70, 0x66063BCA, 0x11010B5C, 0x8F659EFF, 0xF862AE69, 0x616BFFD3, 0x166CCF45,
                     0xA00AE278, 0xD70DD2EE, 0x4E048354, 0x3903B3C2, 0xA7672661, 0xD06016F7, 0x4969474D, 0x3E6E77DB,
                     0xAED16A4A, 0xD9D65ADC, 0x40DF0B66, 0x37D83BF0, 0xA9BCAE53, 0xDEBB9EC5, 0x47B2CF7F, 0x30B5FFE9,
                     0xBDBDF21C, 0xCABAC28A, 0x53B39330, 0x24B4A3A6, 0xBAD03605, 0xCDD70693, 0x54DE5729, 0x23D967BF,
                     0xB3667A2E, 0xC4614AB8, 0x5D681B02, 0x2A6F2B94, 0xB40BBE37, 0xC30C8EA1, 0x5A05DF1B, 0x2D02EF8D }

    function crypt.crc32(s)
        local crc, l = 0xFFFFFFFF, strlen(s)
        for i = 1, l, 1 do
            crc = (crc>>8) ~ consts[((crc~strbyte(s, i)) & 0xFF) + 1]
        end
        return crc ~ 0xFFFFFFFF
    end
end

-----------------------------------------------------------------------
-- crypt.AES
-----------------------------------------------------------------------

--[[ based on aeslua (https://github.com/bighil/aeslua/tree/master/src)
aeslua: Lua AES implementation
Copyright (c) 2006,2007 Matthias Hilbig

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU Lesser Public License as published by the
Free Software Foundation; either version 2.1 of the License, or (at your
option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser Public License for more details.

A copy of the terms and conditions of the license can be found in
License.txt or online at

    http://www.gnu.org/copyleft/lesser.html

To obtain a copy, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

Author
-------
Matthias Hilbig
http://homepages.upb.de/hilbig/aeslua/
hilbig@upb.de
--]]

do

    local AES_IV = nil

    local function Buffer()
        local buffer = {}
        local stack = {}
        function buffer.addString(s)
            table.insert(stack, s)
            for i = #stack-1, 1, -1 do
                if #stack[i] > #stack[i+1] then
                    break
                end
                stack[i] = stack[i]..table.remove(stack)
            end
        end
        function buffer.toString()
            for i = #stack-1, 1, -1 do
                stack[i] = stack[i]..table.remove(stack)
            end
            return stack[1]
        end
        return buffer
    end

    local function byteParity(byte)
        byte = byte ~ rshift(byte, 4)
        byte = byte ~ rshift(byte, 2)
        byte = byte ~ rshift(byte, 1)
        return byte & 1
    end

    local function getByte(number, index)
        if index == 0 then
            return number & 0xFF
        else
            return rshift(number, index*8) & 0xFF
        end
    end

    local function putByte(number, index)
        if index == 0 then
            return number & 0xFF
        else
            return lshift(number & 0xFF, index*8)
        end
    end

    local function bytesToInts(bytes, start, n)
        local ints = {}
        for i = 0, n-1 do
            ints[i] = putByte(bytes[start+(i*4)  ], 3)
                    + putByte(bytes[start+(i*4)+1], 2)
                    + putByte(bytes[start+(i*4)+2], 1)
                    + putByte(bytes[start+(i*4)+3], 0)
        end
        return ints
    end

    local function intsToBytes(ints, output, outputoffset, n)
        n = n or #ints
        for i = 0, n do
            for j = 0, 3 do
                output[outputoffset+i*4+(3-j)] = getByte(ints[i], j)
            end
        end
        return output
    end

    local function padByteString(data)
        local dataLen = #data
        local random1 = random(0, 255)
        local random2 = random(0, 255)
        local prefix = strchar(random1, random2,
                               random1, random2,
                               getByte(dataLen, 3),
                               getByte(dataLen, 2),
                               getByte(dataLen, 1),
                               getByte(dataLen, 0))
        data = prefix..data
        local paddingLen = ceil(#data/16)*16 - #data
        local padding = ""
        for _ = 1, paddingLen do
            padding = padding..strchar(random(0, 255))
        end
        return data..padding
    end

    local function properlyDecrypted(data)
        local bytes = {strbyte(data, 1, 4)}
        return bytes[1]==bytes[3] and bytes[2]==bytes[4]
    end

    local function unpadByteString(data)
        if properlyDecrypted(data) then
            local dataLen = putByte(strbyte(data, 5), 3)
                          + putByte(strbyte(data, 6), 2)
                          + putByte(strbyte(data, 7), 1)
                          + putByte(strbyte(data, 8), 0)
            return strsub(data, 9, 8+dataLen)
        end
    end

    local function xorIV(data, IV)
        for i = 1, 16 do
            data[i] = data[i] ~ IV[i]
        end
    end

    -- finite field with base 2 and modulo irreducible polynom x^8+x^4+x^3+x+1 = 0x11d
    local ord = 0xff
    local irrPolynom = 0x11b
    local exp = {}
    local log = {}

    -- add two polynoms (its simply xor)
    local add = function(a, b) return a ~ b end

    -- subtract two polynoms (same as addition)
    local sub = add

    -- inverts element
    -- a^(-1) = g^(order - log(a))
    local function invert(operand)
        if operand == 1 then return 1 end
        return exp[ord - log[operand]]
    end

    -- multiply two elements using a logarithm table
    -- a*b = g^(log(a)+log(b))
    local function mul(operand1, operand2)
        if operand1==0 or operand2==0 then return 0 end
        local exponent = log[operand1] + log[operand2]
        if exponent >= ord then
            exponent = exponent - ord
        end
        return exp[exponent]
    end

    -- calculate logarithmic and exponentiation table
    local function initMulTable()
        local a = 1
        for i = 0, ord-1 do
            exp[i] = a
            log[a] = i
            a = lshift(a, 1) ~ a
            if a > ord then
                a = sub(a, irrPolynom)
            end
        end
    end

    initMulTable()

    -- Implementation of AES with pure lua
    --
    -- AES with lua is slow, really slow :-)

    -- some constants
    local ROUNDS = "rounds"
    local KEY_TYPE = "type"
    local ENCRYPTION_KEY = 1
    local DECRYPTION_KEY = 2

    -- aes SBOX
    local SBox = {}
    local iSBox = {}

    -- aes tables
    local table0 = {}
    local table1 = {}
    local table2 = {}
    local table3 = {}

    local tableInv0 = {}
    local tableInv1 = {}
    local tableInv2 = {}
    local tableInv3 = {}

    -- round constants
    local rCon = {0x01000000, 0x02000000, 0x04000000, 0x08000000,
                  0x10000000, 0x20000000, 0x40000000, 0x80000000,
                  0x1b000000, 0x36000000, 0x6c000000, 0xd8000000,
                  0xab000000, 0x4d000000, 0x9a000000, 0x2f000000}

    -- affine transformation for calculating the S-Box of AES
    local function affinMap(byte)
        local mask = 0xf8
        local result = 0
        for _ = 1, 8 do
            result = lshift(result, 1)

            result = result + byteParity(byte & mask)

            -- simulate roll
            mask = rshift(mask, 1) & 0xff
            if mask & 1 ~= 0 then
                mask = mask | 0x80
            else
                mask = mask & 0x7f
            end
        end

        return result ~ 0x63
    end

    -- calculate S-Box and inverse S-Box of AES
    -- apply affine transformation to inverse in finite field 2^8
    local function calcSBox()
        for i = 0, 255 do
            local inverse = (i~=0) and invert(i) or i
            local mapped = affinMap(inverse)
            SBox[i] = mapped
            iSBox[mapped] = i
        end
    end

    -- Calculate round tables
    -- round tables are used to calculate shiftRow, MixColumn and SubBytes
    -- with 4 table lookups and 4 xor operations.
    local function calcRoundTables()
        for x = 0, 255 do
            local byte = SBox[x]
            table0[x] = putByte(mul(0x03, byte), 0)
                      + putByte(          byte , 1)
                      + putByte(          byte , 2)
                      + putByte(mul(0x02, byte), 3)
            table1[x] = putByte(          byte , 0)
                      + putByte(          byte , 1)
                      + putByte(mul(0x02, byte), 2)
                      + putByte(mul(0x03, byte), 3)
            table2[x] = putByte(          byte , 0)
                      + putByte(mul(0x02, byte), 1)
                      + putByte(mul(0x03, byte), 2)
                      + putByte(          byte , 3)
            table3[x] = putByte(mul(0x02, byte), 0)
                      + putByte(mul(0x03, byte), 1)
                      + putByte(          byte , 2)
                      + putByte(          byte , 3)
        end
    end

    -- Calculate inverse round tables
    -- does the inverse of the normal roundtables for the equivalent
    -- decryption algorithm.
    local function calcInvRoundTables()
        for x = 0, 255 do
            local byte = iSBox[x]
            tableInv0[x] = putByte(mul(0x0b, byte), 0)
                         + putByte(mul(0x0d, byte), 1)
                         + putByte(mul(0x09, byte), 2)
                         + putByte(mul(0x0e, byte), 3)
            tableInv1[x] = putByte(mul(0x0d, byte), 0)
                         + putByte(mul(0x09, byte), 1)
                         + putByte(mul(0x0e, byte), 2)
                         + putByte(mul(0x0b, byte), 3)
            tableInv2[x] = putByte(mul(0x09, byte), 0)
                         + putByte(mul(0x0e, byte), 1)
                         + putByte(mul(0x0b, byte), 2)
                         + putByte(mul(0x0d, byte), 3)
            tableInv3[x] = putByte(mul(0x0e, byte), 0)
                         + putByte(mul(0x0b, byte), 1)
                         + putByte(mul(0x0d, byte), 2)
                         + putByte(mul(0x09, byte), 3)
        end
    end

    -- replace all bytes in a word with the SBox.
    -- used for key schedule
    local function subWord(word)
        return putByte(SBox[getByte(word, 0)], 0)
             + putByte(SBox[getByte(word, 1)], 1)
             + putByte(SBox[getByte(word, 2)], 2)
             + putByte(SBox[getByte(word, 3)], 3)
    end

    -- generate key schedule for aes encryption
    --
    -- returns table with all round keys and
    -- the necessary number of rounds saved in ROUNDS
    local function expandEncryptionKey(key)
        local keySchedule = {}
        local keyWords = #key // 4

        if (keyWords ~= 4 and keyWords ~= 6 and keyWords ~= 8)
        or (keyWords * 4 ~= #key) then
            print("Invalid key size: ", keyWords)
            return nil
        end

        keySchedule[ROUNDS] = keyWords + 6
        keySchedule[KEY_TYPE] = ENCRYPTION_KEY

        for i = 0, keyWords-1 do
            keySchedule[i] = putByte(key[i*4+1], 3)
                           + putByte(key[i*4+2], 2)
                           + putByte(key[i*4+3], 1)
                           + putByte(key[i*4+4], 0)
        end

        for i = keyWords, (keySchedule[ROUNDS]+1)*4 - 1 do
            local tmp = keySchedule[i-1]
            if i % keyWords == 0 then
                tmp = lrot(tmp, 8)
                tmp = subWord(tmp)
                local index = i//keyWords
                tmp = tmp ~ rCon[index]
            elseif keyWords > 6 and i % keyWords == 4 then
                tmp = subWord(tmp)
            end
            keySchedule[i] = keySchedule[(i-keyWords)] ~ tmp
        end

        return keySchedule
    end

    -- Inverse mix column
    -- used for key schedule of decryption key
    local function invMixColumnOld(word)
        local b0 = getByte(word, 3)
        local b1 = getByte(word, 2)
        local b2 = getByte(word, 1)
        local b3 = getByte(word, 0)

        return putByte(add(add(add(mul(0x0b, b1),
                                   mul(0x0d, b2)),
                                   mul(0x09, b3)),
                                   mul(0x0e, b0)), 3)
             + putByte(add(add(add(mul(0x0b, b2),
                                   mul(0x0d, b3)),
                                   mul(0x09, b0)),
                                   mul(0x0e, b1)), 2)
             + putByte(add(add(add(mul(0x0b, b3),
                                   mul(0x0d, b0)),
                                   mul(0x09, b1)),
                                   mul(0x0e, b2)), 1)
             + putByte(add(add(add(mul(0x0b, b0),
                                   mul(0x0d, b1)),
                                   mul(0x09, b2)),
                                   mul(0x0e, b3)), 0)
    end

    -- generate key schedule for aes decryption
    --
    -- uses key schedule for aes encryption and transforms each
    -- key by inverse mix column.
    local function expandDecryptionKey(key)
        local keySchedule = expandEncryptionKey(key)
        if keySchedule == nil then
            return nil
        end

        keySchedule[KEY_TYPE] = DECRYPTION_KEY

        for i = 4, (keySchedule[ROUNDS] + 1)*4 - 5 do
            keySchedule[i] = invMixColumnOld(keySchedule[i])
        end

        return keySchedule
    end

    -- xor round key to state
    local function addRoundKey(state, key, round)
        for i = 0, 3 do
            state[i] = state[i] ~ key[round*4+i]
        end
    end

    -- do encryption round (ShiftRow, SubBytes, MixColumn together)
    local function doRound(origState, dstState)
        dstState[0] =
                    table0[getByte(origState[0], 3)] ~
                    table1[getByte(origState[1], 2)] ~
                    table2[getByte(origState[2], 1)] ~
                    table3[getByte(origState[3], 0)]

        dstState[1] =
                    table0[getByte(origState[1], 3)] ~
                    table1[getByte(origState[2], 2)] ~
                    table2[getByte(origState[3], 1)] ~
                    table3[getByte(origState[0], 0)]

        dstState[2] =
                    table0[getByte(origState[2], 3)] ~
                    table1[getByte(origState[3], 2)] ~
                    table2[getByte(origState[0], 1)] ~
                    table3[getByte(origState[1], 0)]

        dstState[3] =
                    table0[getByte(origState[3], 3)] ~
                    table1[getByte(origState[0], 2)] ~
                    table2[getByte(origState[1], 1)] ~
                    table3[getByte(origState[2], 0)]
    end

    -- do last encryption round (ShiftRow and SubBytes)
    local function doLastRound(origState, dstState)
        dstState[0] = putByte(SBox[getByte(origState[0], 3)], 3)
                    + putByte(SBox[getByte(origState[1], 2)], 2)
                    + putByte(SBox[getByte(origState[2], 1)], 1)
                    + putByte(SBox[getByte(origState[3], 0)], 0)

        dstState[1] = putByte(SBox[getByte(origState[1], 3)], 3)
                    + putByte(SBox[getByte(origState[2], 2)], 2)
                    + putByte(SBox[getByte(origState[3], 1)], 1)
                    + putByte(SBox[getByte(origState[0], 0)], 0)

        dstState[2] = putByte(SBox[getByte(origState[2], 3)], 3)
                    + putByte(SBox[getByte(origState[3], 2)], 2)
                    + putByte(SBox[getByte(origState[0], 1)], 1)
                    + putByte(SBox[getByte(origState[1], 0)], 0)

        dstState[3] = putByte(SBox[getByte(origState[3], 3)], 3)
                    + putByte(SBox[getByte(origState[0], 2)], 2)
                    + putByte(SBox[getByte(origState[1], 1)], 1)
                    + putByte(SBox[getByte(origState[2], 0)], 0)
    end

    -- do decryption round
    local function doInvRound(origState, dstState)
        dstState[0] =
                    tableInv0[getByte(origState[0], 3)] ~
                    tableInv1[getByte(origState[3], 2)] ~
                    tableInv2[getByte(origState[2], 1)] ~
                    tableInv3[getByte(origState[1], 0)]

        dstState[1] =
                    tableInv0[getByte(origState[1], 3)] ~
                    tableInv1[getByte(origState[0], 2)] ~
                    tableInv2[getByte(origState[3], 1)] ~
                    tableInv3[getByte(origState[2], 0)]

        dstState[2] =
                    tableInv0[getByte(origState[2], 3)] ~
                    tableInv1[getByte(origState[1], 2)] ~
                    tableInv2[getByte(origState[0], 1)] ~
                    tableInv3[getByte(origState[3], 0)]

        dstState[3] =
                    tableInv0[getByte(origState[3], 3)] ~
                    tableInv1[getByte(origState[2], 2)] ~
                    tableInv2[getByte(origState[1], 1)] ~
                    tableInv3[getByte(origState[0], 0)]
    end

    -- do last decryption round
    local function doInvLastRound(origState, dstState)
        dstState[0] = putByte(iSBox[getByte(origState[0], 3)], 3)
                    + putByte(iSBox[getByte(origState[3], 2)], 2)
                    + putByte(iSBox[getByte(origState[2], 1)], 1)
                    + putByte(iSBox[getByte(origState[1], 0)], 0)

        dstState[1] = putByte(iSBox[getByte(origState[1], 3)], 3)
                    + putByte(iSBox[getByte(origState[0], 2)], 2)
                    + putByte(iSBox[getByte(origState[3], 1)], 1)
                    + putByte(iSBox[getByte(origState[2], 0)], 0)

        dstState[2] = putByte(iSBox[getByte(origState[2], 3)], 3)
                    + putByte(iSBox[getByte(origState[1], 2)], 2)
                    + putByte(iSBox[getByte(origState[0], 1)], 1)
                    + putByte(iSBox[getByte(origState[3], 0)], 0)

        dstState[3] = putByte(iSBox[getByte(origState[3], 3)], 3)
                    + putByte(iSBox[getByte(origState[2], 2)], 2)
                    + putByte(iSBox[getByte(origState[1], 1)], 1)
                    + putByte(iSBox[getByte(origState[0], 0)], 0)
    end

    -- encrypts 16 Bytes
    -- key           encryption key schedule
    -- input         array with input data
    -- inputOffset   start index for input
    -- output        array for encrypted data
    -- outputOffset  start index for output
    local function encrypt(key, input, inputOffset, output, outputOffset)
        --default parameters
        inputOffset = inputOffset or 1
        output = output or {}
        outputOffset = outputOffset or 1

        local state = {}
        local tmpState = {}

        if key[KEY_TYPE] ~= ENCRYPTION_KEY then
            print("No encryption key: ", key[KEY_TYPE])
            return
        end

        state = bytesToInts(input, inputOffset, 4)
        addRoundKey(state, key, 0)

        local round = 1
        while (round < key[ROUNDS] - 1) do
            -- do a double round to save temporary assignments
            doRound(state, tmpState)
            addRoundKey(tmpState, key, round)
            round = round + 1

            doRound(tmpState, state)
            addRoundKey(state, key, round)
            round = round + 1
        end

        doRound(state, tmpState)
        addRoundKey(tmpState, key, round)
        round = round +1

        doLastRound(tmpState, state)
        addRoundKey(state, key, round)

        return intsToBytes(state, output, outputOffset)
    end

    -- decrypt 16 bytes
    -- key           decryption key schedule
    -- input         array with input data
    -- inputOffset   start index for input
    -- output        array for decrypted data
    -- outputOffset  start index for output
    local function decrypt(key, input, inputOffset, output, outputOffset)
        -- default arguments
        inputOffset = inputOffset or 1
        output = output or {}
        outputOffset = outputOffset or 1

        local state = {}
        local tmpState = {}

        if key[KEY_TYPE] ~= DECRYPTION_KEY then
            print("No decryption key: ", key[KEY_TYPE])
            return
        end

        state = bytesToInts(input, inputOffset, 4)
        addRoundKey(state, key, key[ROUNDS])

        local round = key[ROUNDS] - 1
        while (round > 2) do
            -- do a double round to save temporary assignments
            doInvRound(state, tmpState)
            addRoundKey(tmpState, key, round)
            round = round - 1

            doInvRound(tmpState, state)
            addRoundKey(state, key, round)
            round = round - 1
        end

        doInvRound(state, tmpState)
        addRoundKey(tmpState, key, round)
        round = round - 1

        doInvLastRound(tmpState, state)
        addRoundKey(state, key, round)

        return intsToBytes(state, output, outputOffset)
    end

    -- calculate all tables when loading this file
    calcSBox()
    calcRoundTables()
    calcInvRoundTables()

    -- Encrypt strings
    -- key - byte array with key
    -- string - string to encrypt
    -- modeFunction - function for cipher mode to use
    local function encryptString(key, data, modeFunction)
        local IV = AES_IV or {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
        local keySched = expandEncryptionKey(key)
        local encryptedData = Buffer()
        for i = 1, #data/16 do
            local offset = (i-1)*16 + 1
            local byteData = {strbyte(data, offset, offset+15)}
            modeFunction(keySched, byteData, IV)
            encryptedData.addString(strchar(table.unpack(byteData)))
        end
        return encryptedData.toString()
    end

    -- Electronic code book mode encrypt function
    local function encryptECB(keySched, byteData)
        encrypt(keySched, byteData, 1, byteData, 1)
    end

    -- Cipher block chaining mode encrypt function
    local function encryptCBC(keySched, byteData, IV)
        xorIV(byteData, IV)
        encrypt(keySched, byteData, 1, byteData, 1)
        for j = 1, 16 do
            IV[j] = byteData[j]
        end
    end

    -- Decrypt strings
    -- key - byte array with key
    -- string - string to decrypt
    -- modeFunction - function for cipher mode to use
    local function decryptString(key, data, modeFunction)
        local IV = AES_IV or {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
        local keySched = expandDecryptionKey(key)
        local decryptedData = Buffer()
        for i = 1, #data/16 do
            local offset = (i-1)*16 + 1
            local byteData = {strbyte(data, offset, offset +15)}
            IV = modeFunction(keySched, byteData, IV)
            decryptedData.addString(strchar(table.unpack(byteData)))
        end
        return decryptedData.toString()
    end

    -- Electronic code book mode decrypt function
    local function decryptECB(keySched, byteData, IV)
        decrypt(keySched, byteData, 1, byteData, 1)
        return IV
    end

    -- Cipher block chaining mode decrypt function
    local function decryptCBC(keySched, byteData, IV)
        local nextIV = {}
        for j = 1, 16 do
            nextIV[j] = byteData[j]
        end
        decrypt(keySched, byteData, 1, byteData, 1)
        xorIV(byteData, IV)
        return nextIV
    end

    local function pwToKey(password, keyLen)
        keyLen = keyLen / 8
        local padlen = keyLen
        if keyLen == 192/8 then padlen = 32 end
        if padlen > #password then
            password = password .. strchar(0):rep(padlen-#password)
        else
            password = password:sub(1, padlen)
        end
        local pwBytes = {strbyte(password, 1, keyLen)}
        password = encryptString(pwBytes, password, encryptCBC)
        password = strsub(password, 1, keyLen)
        return {strbyte(password, 1, #password)}
    end

    local encryptModeFunctions = {
        ecb = encryptECB,
        cbc = encryptCBC,
    }

    local decryptModeFunctions = {
        ecb = decryptECB,
        cbc = decryptCBC,
    }

    function crypt.AES(password, keyLen, mode)
        assert(password and #password > 0, "Empty password")
        keyLen = keyLen or 128
        mode = mode or "cbc"
        local encryptModeFunction = encryptModeFunctions[mode]
        local decryptModeFunction = decryptModeFunctions[mode]
        assert(keyLen==128 or keyLen==192 or keyLen==256, "Invalid key length")
        assert(encryptModeFunction and decryptModeFunction, "Invalid mode")
        local key = pwToKey(password, keyLen)
        local aes = {}
        function aes.encrypt(data)
            return encryptString(key, padByteString(data), encryptModeFunction)
        end
        function aes.decrypt(data)
            return unpadByteString(decryptString(key, data, decryptModeFunction))
        end
        return aes
    end

end

-----------------------------------------------------------------------
-- crypt.btea
-----------------------------------------------------------------------

-- [[ based on BTEA (http://en.wikipedia.org/wiki/XXTEA)
-- ]]

do
    function crypt.BTEA(key)

        local key16 = strsub(key, 1, 16)
        for i = 17, #key, 16 do
            key16 = crypt.btea_encrypt(strsub(key, i, i+15), key16)
        end

        local btea = {}

        function btea.encrypt(data)
            return crypt.btea_encrypt(key16, data)
        end

        function btea.decrypt(data)
            return crypt.btea_decrypt(key16, data)
        end

        return btea

    end
end

-----------------------------------------------------------------------
-- crypt.RC4
-----------------------------------------------------------------------

-- [[ based http://en.wikipedia.org/wiki/RC4
--          http://www.users.zetnet.co.uk/hopwood/crypto/scan/cs.html#RC4-drop
-- ]]

do
    function crypt.RC4(key, drop)

        -- Key Scheduling
        local s = {}
        local i = 1
        local j = 1
        for i = 1, 256 do s[i] = i-1 end
        for i = 1, 256 do
            j = ((j-1 + s[i] + strbyte(key, (i%#key)+1)) & 0xFF) + 1
            s[i], s[j] = s[j], s[i]
        end
        i = 1
        j = 1

        -- RC4 encoding
        function rc4(input)
            local output = {}
            for p = 1, #input do
                i = (i & 0xFF) + 1
                local si = s[i]
                j = ((j-1 + si) & 0xFF) + 1
                local sj = s[j]
                s[i] = sj
                s[j] = si
                output[p] = strchar(strbyte(input, p) ~ s[((si+sj)&0xFF)+1])
            end
            return concat(output)
        end

        -- throw the first bytes
        rc4(string.rep("\0", drop or 768))

        return rc4

    end
end

-----------------------------------------------------------------------
-- crypt.random
-----------------------------------------------------------------------

do
    function crypt.random(bits)
        local bytes = max((bits+7)//8, 1)
        return crypt.RC4(crypt.rnd(8), 0)(crypt.rnd(bytes))
    end
end
