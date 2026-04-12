generator(false)

rule "foo" { command = true }
build "bar" { "baz", "file" } -- [test/test-err-unknown_rule.lua:4] ERROR: baz: unknown rule
