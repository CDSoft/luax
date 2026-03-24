# tomlx

`tomlx` is a layer on top of `toml`
([tinytoml](https://github.com/FourierTransformer/tinytoml)).

It uses Lua as a macro language to transform values. Macros are string
values starting with `=`. The expression following `=` is a Lua
expression which value replaces the macro in the table.

The evaluation environment contains two specific symbols:

- `__up`: environment one level above the current level
- `__root`: root level of the environment levels

``` lua
local tomlx = require "tomlx"
```

The default environment contains the global variables (`_G`) and some
LuaX modules (`crypt`, `F`, `fs`, `sh`).

``` lua
tomlx.read(filename, [options])
```

> calls `toml.parse` to parse a TOML file. Options are optional and
> described in the [tinytoml
> documentation](https://github.com/FourierTransformer/tinytoml?tab=readme-ov-file#parsing-toml).
> tomlx adds the env option (`options.env`) to define the initial
> evaluation environment. The table returned by `tinytoml` is then
> processed to evaluate `tomlx` macros.

``` lua
tomlx.decode(s, [options])
```

> calls `toml.parse` to parse a TOML string. Options are optional and
> described in the [tinytoml
> documentation](https://github.com/FourierTransformer/tinytoml?tab=readme-ov-file#parsing-toml).
> tomlx adds the env option (`options.env`) to define the initial
> evaluation environment. The table returned by `tinytoml` is then
> processed to evaluate `tomlx` macros.

``` lua
tomlx.encode(s, [options])
```

> calls `toml.encode` to encode a Lua table into a TOML string. Options
> are optional and described in the [tinytoml
> documentation](https://github.com/FourierTransformer/tinytoml?tab=readme-ov-file#encoding-toml).

``` lua
tomlx.write(filename, t, [options])
```

> calls `toml.encode` to encode a Lua table into a TOML string and save
> it the file `filename`. Options are optional and described in the
> [tinytoml
> documentation](https://github.com/FourierTransformer/tinytoml?tab=readme-ov-file#encoding-toml).

``` lua
tomlx.validate(schema, filename, [options])
```

> returns `true` if `filename` is validated by `schema`. Otherwise it
> returns `false` and a list of failures.
>
> The `schema` file is a TOML file used to validate the TOML file
> `filename`. Both files are read with `tomlx.read` and the
> corresponding tables are validated with `F.validate`.
