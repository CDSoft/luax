generator(false)

rule "foo" { command = true }
rule "bar" { command = true }
rule "baz" { command = true }
rule "foo" { command = true } -- [test/test-err-multiple_rule.lua:6] ERROR: rule foo: multiple definition
