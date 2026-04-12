@@[[

    -- Lorem ipsum dolor sit amet, consectetur adipiscing elit,
    -- sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
    -- Ut enim ad minim veniam,
    -- quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.

    -- only a context of 5 lines shall be printed in error messages
    function foo()
        -- call bar from test.lua that should raise a runtime error
        bar()
    end

    -- Lorem ipsum dolor sit amet, consectetur adipiscing elit,
    -- sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
    -- Ut enim ad minim veniam,
    -- quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.

]]

@@[[
    -- call foo from another chunk
    foo()
]]
