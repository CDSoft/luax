#!/usr/bin/env lua

-- Ninja generates ids that look like random arbitrary addresses
-- which produces a different graph even when the ninja file is unchanged.
-- This script replaces these addresses with deterministic ids.

local function hash(s)
    local h = 1844674407370955155*10+7
    for i = 1, #s do
        local c = s:byte(i)
        h = h * 6364136223846793005 + ((c << 1) | 1)
    end
    return ("%08x"):format(h&0xFFFFFFFF)
end

local graph = io.stdin:read "a"
local ids = {}
graph:gsub('\n"(0x[0-9a-f]+)"%s*%[(.-)%]', function(ptr, label)
    ids[ptr] = ids[ptr] or hash(label)
end)
graph = graph:gsub('0x[0-9a-f]+', ids)
io.stdout:write(graph)
