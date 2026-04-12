generator(false)

var "foo" "foo"
var "bar" "bar"
var "baz" "baz"
var "foo" "baz" -- [test/test-err-multiple_var.lua:6] ERROR: var foo: multiple definition
