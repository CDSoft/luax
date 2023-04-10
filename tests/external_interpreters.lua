local target = os.getenv "TARGET"

--print("TARGET", os.getenv "TARGET")
--print("arg", F.show(arg))

assert(#arg == 3)
assert(arg[1] == "Lua")
assert(arg[2] == "is")
assert(arg[3] == "great")

if target == "lua" then
    assert(arg[-4] == "lua")
    assert(arg[-3] == "-l") assert(arg[-2] == "luax")       -- load luax.lua
    assert(arg[-1] == "--")
    assert(arg[0] == ".build/test/ext-lua")
    assert(sys.abi == "lua")
    assert(not pandoc)

elseif target == "lua-lua" then
    assert(arg[-4] == "lua")
    assert(arg[-3] == "-l") assert(arg[-2] == "luax")       -- load luax.lua
    assert(arg[-1] == "--")
    assert(arg[0] == ".build/test/ext-lua-lua")
    assert(sys.abi == "lua")
    assert(not pandoc)

elseif target == "lua-luax" then
    assert(arg[-6] == "lua")
    assert(arg[-5] == "-l") assert(arg[-4] == "libluax")    -- load libluax.so
    assert(arg[-3] == "-l") assert(arg[-2] == "rt0")        -- run rt0 from libluax.so
    assert(arg[-1] == "--")
    assert(arg[0] == ".build/test/ext-lua-luax")
    assert(sys.abi == "gnu")
    assert(not pandoc)

elseif target == "luax" then
    assert(arg[-4] == "luax")
    assert(arg[-3] == "-l") assert(arg[-2] == "rt0")        -- run rt0 from libluax.so
    assert(arg[-1] == "--")
    assert(arg[0] == ".build/test/ext-luax")
    assert(not pandoc)

elseif target == "luax-luax" then
    assert(arg[-4] == "luax")
    assert(arg[-3] == "-l") assert(arg[-2] == "rt0")        -- run rt0 from libluax.so
    assert(arg[-1] == "--")
    assert(arg[0] == ".build/test/ext-luax-luax")
    assert(sys.abi == "gnu")
    assert(not pandoc)

elseif target == "pandoc" then
    assert(arg[-4] == "pandoc lua")
    assert(arg[-3] == "-l") assert(arg[-2] == "luax")       -- load luax.lua
    assert(arg[-1] == "--")
    assert(arg[0] == ".build/test/ext-pandoc")
    assert(sys.abi == "lua")
    assert(pandoc and pandoc.Pandoc)

elseif target == "pandoc-lua" then
    assert(arg[-4] == "pandoc lua")
    assert(arg[-3] == "-l") assert(arg[-2] == "luax")       -- load luax.lua
    assert(arg[-1] == "--")
    assert(arg[0] == ".build/test/ext-pandoc-lua")
    assert(sys.abi == "lua")
    assert(pandoc and pandoc.Pandoc)

elseif target == "pandoc-luax" then
    assert(arg[-6] == "pandoc lua")
    assert(arg[-5] == "-l") assert(arg[-4] == "libluax")    -- load libluax.so
    assert(arg[-3] == "-l") assert(arg[-2] == "rt0")        -- run rt0 from libluax.so
    assert(arg[-1] == "--")
    assert(arg[0] == ".build/test/ext-pandoc-luax")
    assert(sys.abi == "gnu")
    assert(pandoc and pandoc.Pandoc)

else
    error(target..": unknown target")
end
