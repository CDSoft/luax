# File System

`fs` is a File System module. It provides functions to handle files and
directory in a portable way.

``` lua
local fs = require "fs"
```

## Core module (C)

``` lua
fs.getcwd()
```

returns the current working directory.

``` lua
fs.chdir(path)
```

changes the current directory to `path`.

``` lua
fs.dir([path])
```

returns the list of files and directories in `path` (the default path is
the current directory).

``` lua
fs.glob(pattern)
```

returns the list of path names matching a pattern.

*Note*: not implemented on Windows.

``` lua
fs.remove(name)
```

deletes the file `name`.

``` lua
fs.rename(old_name, new_name)
```

renames the file `old_name` to `new_name`.

``` lua
fs.copy(source_name, target_name)
```

copies file `source_name` to `target_name`. The attributes and times are
preserved.

``` lua
fs.mkdir(path)
```

creates a new directory `path`.

``` lua
fs.stat(name)
```

reads attributes of the file `name`. Attributes are:

- `name`: name
- `type`: `"file"` or `"directory"`
- `size`: size in bytes
- `mtime`, `atime`, `ctime`: modification, access and creation times.
- `mode`: file permissions
- `uR`, `uW`, `uX`: user Read/Write/eXecute permissions
- `gR`, `gW`, `gX`: group Read/Write/eXecute permissions
- `oR`, `oW`, `oX`: other Read/Write/eXecute permissions
- `aR`, `aW`, `aX`: anybody Read/Write/eXecute permissions

``` lua
fs.inode(name)
```

reads device and inode attributes of the file `name`. Attributes are:

- `dev`, `ino`: device and inode numbers

``` lua
fs.chmod(name, other_file_name)
```

sets file `name` permissions as file `other_file_name` (string
containing the name of another file).

``` lua
fs.chmod(name, bit1, ..., bitn)
```

sets file `name` permissions as `bit1` or … or `bitn` (integers).

``` lua
fs.touch(name)
```

sets the access time and the modification time of file `name` with the
current time.

``` lua
fs.touch(name, number)
```

sets the access time and the modification time of file `name` with
`number`.

``` lua
fs.touch(name, other_name)
```

sets the access time and the modification time of file `name` with the
times of file `other_name`.

``` lua
fs.basename(path)
```

return the last component of path.

``` lua
fs.dirname(path)
```

return all but the last component of path.

``` lua
fs.splitext(path)
```

return the name without the extension and the extension.

``` lua
fs.realpath(path)
```

return the resolved path name of path.

``` lua
fs.readlink(path)
```

return the content of a symbolic link.

``` lua
fs.absname(path)
```

return the absolute path name of path.

``` lua
fs.sep
```

is the directory separator.

``` lua
fs.path_sep
```

is the path separator in `$LUA_PATH`.

``` lua
fs.uR, fs.uW, fs.uX
fs.gR, fs.gW, fs.gX
fs.oR, fs.oW, fs.oX
fs.aR, fs.aW, fs.aX
```

are the User/Group/Other/All Read/Write/eXecute mask for `fs.chmod`.

## Additional functions (Lua)

``` lua
fs.join(...)
```

return a path name made of several path components (separated by
`fs.sep`). If a component is absolute, the previous components are
removed.

``` lua
fs.is_file(name)
```

returns `true` if `name` is a file.

``` lua
fs.is_dir(name)
```

returns `true` if `name` is a directory.

``` lua
fs.findpath(name)
```

returns the full path of `name` if `name` is found in `$PATH` or `nil`.

``` lua
fs.mkdirs(path)
```

creates a new directory `path` and its parent directories.

``` lua
fs.mv(old_name, new_name)
```

alias for `fs.rename(old_name, new_name)`.

``` lua
fs.rm(name)
```

alias for `fs.remove(name)`.

``` lua
fs.rmdir(path, [params])
```

deletes the directory `path` and its content recursively.

``` lua
fs.walk([path], [{reverse=true|false, links=true|false, cross=true|false}])
```

returns a list listing directory and file names in `path` and its
subdirectories (the default path is the current directory).

Options:

- `reverse`: the list is built in a reverse order (suitable for
  recursive directory removal)
- `links`: follow symbolic links
- `cross`: walk across several devices
- `func`: function applied to the current file or directory. `func`
  takes two parameters (path of the file or directory and the stat
  object returned by `fs.stat`) and returns a boolean (to continue or
  not walking recursively through the subdirectories) and a value
  (e.g. the name of the file) to be added to the listed returned by
  `walk`.

``` lua
fs.with_tmpfile(f)
```

calls `f(tmp)` where `tmp` is the name of a temporary file.

``` lua
fs.with_tmpdir(f)
```

calls `f(tmp)` where `tmp` is the name of a temporary directory.

``` lua
fs.with_dir(path, f)
```

changes the current working directory to `path` and calls `f()`.

``` lua
fs.with_env(env, f)
```

changes the environnement to `env` and calls `f()`.

``` lua
fs.read(filename)
```

returns the content of the text file `filename`.

``` lua
fs.write(filename, ...)
```

write `...` to the text file `filename`.

``` lua
fs.read_bin(filename)
```

returns the content of the binary file `filename`.

``` lua
fs.write_bin(filename, ...)
```

write `...` to the binary file `filename`.
