generator(false)

rule "doit" {
    description = "...",
    command = "...",
    depfile = "...",
    deps = "...",
    dyndep = "...",
    pool = "...",
    msvc_deps_prefix = "...",
    generator = "...",
    restat = "...",
    rspfile = "...",
    rspfile_content = "...",
    foo = "this is not a rule variable", -- [test/test-err-unknown_rule_var.lua:3] ERROR: rule doit: unknown variables: foo
}
