generator(false)

pool "doit" {
    depth = "...",
    foo = "this is not a pool variable", -- [test/test-err-unknown_pool_var.lua:3] ERROR: pool doit: unknown variables: foo
}
