## Shell

``` lua
local sh = require "sh"
```

``` lua
sh.run(...)
```

Runs the command `...` with `os.execute`.

``` lua
sh.read(...)
```

Runs the command `...` with `io.popen`. When `sh.read` succeeds, it
returns the content of stdout. Otherwise it returns the error identified
by `io.popen`.

``` lua
sh.write(...)(data)
```

Runs the command `...` with `io.popen` and feeds `stdin` with `data`.
`sh.write` returns the same values returned by `os.execute`.

``` lua
sh.pipe(...)(data)
```

Runs the command `...` with `io.popen` or `pandoc.pipe` and feeds
`stdin` with `data`. When `sh.pipe` succeeds, it returns the content of
stdout. Otherwise it returns the error identified by `op.popen` or
`pandoc.pipe`.

``` lua
sh(...)
```

`sh` can be called as a function. `sh(...)` is a shortcut to
`sh.read(...)`.
