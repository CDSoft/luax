# Minimal tar file support

``` lua
local tar = require "tar"
```

The `tar` module can read and write tar archives. Only files,
directories and symbolic links are supported.

``` lua
tar.tar(files, [xform])
```

> returns a string that can be saved as a tar file. `files` is a list of
> file names or `stat` like structures. `stat` structures shall contain
> these fields:
>
> - `name`: file name
> - `mtime`: last modification time
> - `content`: file content (the default value is the actual content of
>   the file `name`).
>
> **Note**: these structures can also be produced by `fs.stat`.
>
> `xform` is an optional function used to transform filenames in the
> archive.

``` lua
tar.untar(archive, [xform])
```

> returns a list of files (`stat` like structures with a `content`
> field).
>
> `xform` is an optional function used to transform filenames in the
> archive.

``` lua
tar.chain(xforms)
```

> returns a filename transformation function that applies all functions
> from `funcs`.

``` lua
tar.strip(x)
```

> returns a transformation function that removes part of the beginning
> of a filename. If `x` is a number, the function removes `x` path
> components in the filename. If `x` is a string, the function removes
> `x` at the beginning of the filename.

``` lua
tar.add(p)
```

> returns a transformation function that adds `p` at the beginning of a
> filename.

``` lua
tar.xform(x, y)
```

> returns a transformation function that chains `tar.strip(x)` and
> `tar.add(y)`.
