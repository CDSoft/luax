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
https://codeberg.org/cdsoft/ypp
--]]

local F = require "F"

local function format_value(x)
    local mt = getmetatable(x)
    if mt and mt.__tostring then return tostring(x) end
    if type(x) == "table" then return F.flatten(x):map(tostring):unlines() end
    return tostring(x)
end

local function traceback(tag, expr, conf)
    if tag==conf.expr and expr:match("^[%w_.]*$") then return F.const() end
    return function(message, opts)
        if opts and opts.erroneous_source then
            -- Compilation error
            ypp.error_in(opts.erroneous_source, "%s", message)
        else
            -- Execution error => print the traceback
            ypp.error("%s", message)
        end
        os.exit(1)
    end
end

local function eval(s, tag, expr, state)
    local msgh = traceback(tag, expr, state.conf)
    local expr_tag = state.conf.expr -- must be read before eval since they may be modified by the macro function
    local stat_tag = state.conf.stat
    local ok_compile, chunk, compile_error = xpcall(load, msgh, (tag==expr_tag and "return " or "")..expr, expr, "t")
    if not ok_compile then return s end -- load execution error
    if not chunk then -- compilation error
        msgh(compile_error, {erroneous_source=expr})
        return s
    end
    local ok_eval, val = xpcall(chunk, msgh)
    if not ok_eval then return s end
    if val == nil and tag==expr_tag and expr:match("^[%w_]+$") then return s end
    if tag == stat_tag then
        if val ~= nil then
            return format_value(val)
        else
            return ""
        end
    end
    return format_value(val)
end

-- a parser is a function that takes a string and a position
-- and returns the start and stop of the next expression

-- VOID -> ""
local function VOID(_, i0) return i0, i0 end

local function parse_token(skip)
    return function(x)
        local pattern = "^"..skip.."()"..x.."()"
        return function(s, i0)
            if not i0 then return end
            return s:match(pattern, i0)
        end
    end
end

local function seq(ps)
    return function(s, i0)
        if not i0 then return end
        local i1, i2 = ps[1](s, i0)
        local _
        for i = 2, #ps do
            _, i2 = ps[i](s, i2)
        end
        if i2 then return i1, i2 end
    end
end

local function alt(ps)
    return function(s, i0)
        if not i0 then return end
        for _, p in ipairs(ps) do
            local i1, i2 = p(s, i0)
            if i1 then return i1, i2 end
        end
    end
end

local function zero_or_more(p)
    return function(s, i0)
        if not i0 then return end
        local i1, i2 = i0, i0
        repeat
            local i3, i4 = p(s, i2)
            i2 = i4 or i2
        until not i3
        return i1, i2
    end
end

local token         = parse_token "%s*"
local jump_to_token = parse_token ".-"

local PARENS          = token "%b()" -- (...)
local BRACKETS        = token "%b{}" -- {...}
local SQUARE_BRACKETS = token "%b[]" -- [...]

local LONGSTRING_OPEN  = token"%[=-%["
local LONGSTRING_CLOSE = function(level) return jump_to_token("]"..level.."]") end

local function LONGSTRING(s, i0)
    -- [==[ ... ]==]
    local o1, o2 = LONGSTRING_OPEN(s, i0)
    if not o1 then return end
    local c1, c2 = LONGSTRING_CLOSE(s:sub(o1+1, o2-2))(s, o2)
    if c1 then return o1, c2 end
end

local function parse_quoted_string(c)
    local boundary = token(c)
    return function(s, i0)
        local i1, i2 = boundary(s, i0)
        if not i1 then return end
        local i = i2
        while i <= #s do
            local ci = s:sub(i, i)
            if ci == c then return i1, i+1 end
            if ci == '\n' or ci == '\r' then return end
            if ci == '\\' then i = i + 1 end
            i = i + 1
        end
    end
end

local SINGLE_QUOTE_STRING = parse_quoted_string "'"
local DOUBLE_QUOTE_STRING = parse_quoted_string '"'
local IDENT = token"[%w_]+"
local COLON = token":"
local DOT   = token"%."
local EQUAL = token"="

local SE_rules

local function SE(s, i0)
    return SE_rules(s, i0)
end

-- E -> IDENT SE
local E = seq{IDENT, SE}

local CALL = alt {
    PARENS,                 -- CALL -> (...)
    BRACKETS,               -- CALL -> {...}
    DOUBLE_QUOTE_STRING,    -- CALL -> "..."
    SINGLE_QUOTE_STRING,    -- CALL -> '...'
    LONGSTRING              -- CALL -> [[...]]
}

SE_rules = alt {
    seq{CALL, SE},                  -- SE -> CALL SE
    seq{SQUARE_BRACKETS, SE},       -- SE -> [...] SE
    seq{DOT, E},                    -- SE -> . E
    seq{COLON, IDENT, CALL, SE},    -- SE -> : IDENT CALL SE
    VOID,                           -- SE -> VOID
}

-- LHS -> IDENT ([...] | '.' IDENT)*
local LHS = seq {
    IDENT,
    zero_or_more(alt {
        SQUARE_BRACKETS,
        seq{DOT, IDENT}
    })
}

local RHS = alt {
    token"0[xX]%x+",                -- RHS -> hexadecimal number
    token"%-?%d+%.%d+[eE]%-?%d+",   -- RHS -> real number
    token"%-?%d+%.[eE]%-?%d+",      -- RHS -> real number
    token"%-?%.%d+[eE]%-?%d+",      -- RHS -> real number
    token"%-?%d+[eE]%-?%d+",        -- RHS -> real number
    token"%-?%d+%.%d+",             -- RHS -> real number
    token"%-?%d+%.",                -- RHS -> real number
    token"%-?%.%d+",                -- RHS -> real number
    token"%-?%d+",                  -- RHS -> integral number
    token"true",                    -- RHS -> boolean
    token"false",                   -- RHS -> boolean
    PARENS,                         -- RHS -> (...)
    BRACKETS,                       -- RHS -> {...}
    DOUBLE_QUOTE_STRING,            -- RHS -> "..."
    SINGLE_QUOTE_STRING,            -- RHS -> '...'
    LONGSTRING,                     -- RHS -> [=[ ... ]=]
    E,                              -- RHS -> E
}

-- assignement -> LHS "=" RHS
local ASSIGN = seq{LHS, EQUAL, RHS}

local function parse(s, i0, state)

    local expr_tag = state.conf.expr
    local esc_expr_tag = state.conf.esc_expr
    local stat_tag = state.conf.stat

    local TAG = jump_to_token(esc_expr_tag.."+")

    -- find the start of the next expression
    local i1, i2 = TAG(s, i0)
    if not i1 then return #s+1, #s+1, "" end
    local tag = s:sub(i1, i2-1)

    -- S -> "@@ LHS = RHS"
    if tag == stat_tag then
        local i3, i4 = ASSIGN(s, i2)
        if i3 then return i1, i4, eval(s:sub(i1, i4-1), tag, s:sub(i3, i4-1), state) end
    end

    -- S -> "(@|@@)..."
    if tag == expr_tag or tag == stat_tag then
        do -- S -> "(@|@@)(...)"
            local i3, i4 = PARENS(s, i2)
            if i3 then return i1, i4, eval(s:sub(i1, i4-1), tag, s:sub(i3+1, i4-2), state) end
        end
        do -- S -> "(@|@@)[==[...]==]"
            local i3, i4 = LONGSTRING(s, i2)
            if i3 then
                local expr = s:sub(i3, i4-1):gsub("^%[=*%[(.*)%]=*%]$", "%1")
                return i1, i4, eval(s:sub(i1, i4-1), tag, expr, state)
            end
        end
        do -- S -> "(@|@@)"expr
            local i3, i4 = E(s, i2)
            if i3 then return i1, i4, eval(s:sub(i1, i4-1), tag, s:sub(i3, i4-1), state) end
        end
    end

    -- S -> @+ (return the invalid tag unchanged)
    return i1, i2, tag

end

return function(s, conf)
    local ts = {}
    local state = {conf=conf}
    local i = 1
    while i <= #s do
        local i1, i2, out = parse(s, i, state)
        ts[#ts+1] = s:sub(i, i1-1)
        ts[#ts+1] = out
        i = i2 ---@diagnostic disable-line: cast-local-type (i2 can not be nil here)
    end
    return table.concat(ts)
end
