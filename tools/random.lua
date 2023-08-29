#!/usr/bin/env lua

local bits = tonumber(arg[1] or 2048)
local fmt = arg[2] or "\\x%02x"

print(
    assert(io.open("/dev/random", "rb"))
    : read(bits//8)
    : gsub(".", function(c) return string.format(fmt, string.byte(c)) end)
)
