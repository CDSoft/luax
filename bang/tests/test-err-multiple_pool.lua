generator(false)

pool "bar" { }
pool "baz" { }
pool "bar" { } -- [test/test-err-multiple_pool.lua:5] ERROR: pool bar: multiple definition
