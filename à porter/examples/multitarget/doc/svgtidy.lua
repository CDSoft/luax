#!/usr/bin/env lua

-- remove comments and title tags in an SVG file

local img = io.stdin:read "a"

img = img
    : gsub("<!%-%-.-%-%->", "")
    : gsub("<title>.-</title>", "")
    : gsub("\n+", "\n")

io.stdout:write(img)
