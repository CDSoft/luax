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
fs.ls(path, [dotted])
```

returns a list of file names. `path` can be a directory name or a simple
file pattern. Patterns can contain jokers (`*` to match any character
and `**` to search files recursively). If `dotted` is true, hidden files
are also listed.

Examples:

- `fs.ls "src"`: list all files/directories in `src`
- `fs.ls "src/*.c"`: list all C files in `src`
- `fs.ls "src/**.c"`: list all C files in `src` and its subdirectories

``` lua
fs.glob(pattern)
```

returns the list of path names matching a pattern.

*Note*: not implemented on Windows.

``` lua
fs.remove(name)
fs.rm(name)
```

deletes the file `name`.

``` lua
fs.rename(old_name, new_name)
fs.mv(old_name, new_name)
```

renames the file `old_name` to `new_name`.

``` lua
fs.copy(source_name, target_name)
```

copies file `source_name` to `target_name`. The attributes and times are
preserved.

``` lua
fs.symlink(target, linkpath)
```

creates a symbolic link `linkpath` pointing to `target`.

``` lua
fs.mkdir(path)
```

creates a new directory `path`.

``` lua
fs.mkdirs(path)
```

creates a new directory `path` and its parent directories.

``` lua
fs.stat(name)
fs.lstat(name)
```

reads attributes of the file `name`. Attributes are:

- `name`: name
- `type`: `"file"`, `"directory"` or `"link"`
- `size`: size in bytes
- `mtime`, `atime`, `ctime`: modification, access and creation times.
- `mode`: file permissions
- `uR`, `uW`, `uX`: user Read/Write/eXecute permissions
- `gR`, `gW`, `gX`: group Read/Write/eXecute permissions
- `oR`, `oW`, `oX`: other Read/Write/eXecute permissions
- `aR`, `aW`, `aX`: anybody Read/Write/eXecute permissions

`fs.lstat` is like `fs.stat` but gives information on links instead of
pointed files.

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
fs.ext(path)
```

return the extension of a filename.

``` lua
fs.chext(path, ext)
```

replace the extension of `path` with `ext`.

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
fs.is_file(name)
```

returns `true` if `name` is a file.

``` lua
fs.is_dir(name)
```

returns `true` if `name` is a directory.

``` lua
fs.is_link(name)
```

returns `true` if `name` is a symbolic link.

``` lua
fs.tmpfile()
```

return the name of a temporary file.

``` lua
fs.tmpdir()
```

return the name of a temporary directory.

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
fs.splitpath(path)
```

return a list of path components.

``` lua
fs.findpath(name)
```

returns the full path of `name` if `name` is found in `$PATH` or `nil`.

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

- `stat`: returns the list of stat results instead of just filenames
- `reverse`: the list is built in a reverse order (suitable for
  recursive directory removal)
- `cross`: walk across several devices
- `func`: function applied to the current file or directory. `func`
  takes two parameters (path of the file or directory and the stat
  object returned by `fs.stat`) and returns a boolean (to continue or
  not walking recursively through the subdirectories) and the value to
  add to the list.

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

## String methods

Some functions of the `fs` package are added to the string module:

``` lua
path:dir()              == fs.dir(path)
path:stat()             == fs.stat(path)
path:inode()            == fs.inode(path)
path:basename()         == fs.basename(path)
path:dirname()          == fs.dirname(path)
path:splitext()         == fs.splitext(path)
path:ext()              == fs.ext(path)
path:chext()            == fs.chext(path)
path:realpath()         == fs.realpath(path)
path:readlink()         == fs.readlink(path)
path:absname()          == fs.absname(path)
path1 / path2           == fs.join(path1, path2)
path:is_file()          == fs.is_file(path)
path:is_dir()           == fs.is_dir(path)
path:findpath()         == fs.findpath(path)
path:walk(...)          == fs.walk(path, ...)
```
