Only the text between 3 = is included

===
# Included from another file

This paragraph has been included.

@@[[
    function rel(name) return name:gsub(fs.getcwd(), ".") end
]]

Caller:

- `input_file(1)`: `@rel(ypp.input_file(1))`
- `input_path(1)`: `@rel(ypp.input_path(1))`

Callee:

- `input_file()`: `@rel(ypp.input_file())`
- `input_path()`: `@rel(ypp.input_path())`

This part is not included: ignored {
    not included { ... }
}

This part is also not included: ignored {
    not included as well { ... }
}

===
