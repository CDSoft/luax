-- Stress test for Bang/ninja

local fs = require "fs"

local root = arg[1]
assert(fs.is_dir(root))

var "builddir" (root/".build")

build.cc : set "cvalid" {
    build.new "clang-tidy"
    : set "cmd" "clang-tidy"
    : set "flags" "--quiet --warnings-as-errors=*"
    : set "args" "$in > $out 2>/dev/null"
}

build.cc:executable "$builddir/stress" {
    build.cc:compile "$builddir/main.o" { root/"main.c" },
    ls(root/"*")
    : filter(fs.is_dir)
    : map(function(lib)
        return build.cc:static_lib("$builddir"/lib..".a") { ls(lib/"**.c") }
    end)
}
