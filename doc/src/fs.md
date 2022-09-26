# fs

`fs` is a File System module. It provides functions to handle files and directory in a portable way.

```lua
local fs = require "fs"
```

```lua
fs.getcwd()
```
returns the current working directory.

```lua
fs.chdir(path)
```
changes the current directory to `path`.

```lua
fs.dir([path])
```
returns the list of files and directories in
`path` (the default path is the current directory).

```lua
fs.walk([path], [reverse])
```
returns a list listing directory and
file names in `path` and its subdirectories (the default path is the current
directory). If `reverse` is true, the list is built in a reverse order
(suitable for recursive directory removal)

```lua
fs.mkdir(path)
```
creates a new directory `path`.

```lua
fs.mkdirs(path)
```
creates a new directory `path` and its parent
directories.

```lua
fs.rename(old_name, new_name)
```
renames the file `old_name` to
`new_name`.

```lua
fs.mv(old_name, new_name)
```
alias for `fs.rename(old_name, new_name)`.

```lua
fs.remove(name)
```
deletes the file `name`.

```lua
fs.rm(name)
```
alias for `fs.remove(name)`.

```lua
fs.rmdir(path, [params])
```
deletes the directory `path` (recursively if `params.recursive` is `true`.

```lua
fs.copy(source_name, target_name)
```
copies file `source_name` to
`target_name`. The attributes and times are preserved.

```lua
fs.is_file(name)
```
returns `true` if `name` is a file.

```lua
fs.is_dir(name)
```
returns `true` if `name` is a directory.

```lua
fs.findpath(name)
```
returns the full path of `name` if `name` is found in `$PATH` or `nil`.

```lua
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

```lua
fs.inode(name)
```
reads device and inode attributes of the file `name`.
Attributes are:

- `dev`, `ino`: device and inode numbers

```lua
fs.chmod(name, other_file_name)
```
sets file `name` permissions as
file `other_file_name` (string containing the name of another file).

```lua
fs.chmod(name, bit1, ..., bitn)
```
sets file `name` permissions as
`bit1` or ... or `bitn` (integers).

```lua
fs.touch(name)
```
sets the access time and the modification time of
file `name` with the current time.

```lua
fs.touch(name, number)
```
sets the access time and the modification
time of file `name` with `number`.

```lua
fs.touch(name, other_name)
```
sets the access time and the
modification time of file `name` with the times of file `other_name`.

```lua
fs.basename(path)
```
return the last component of path.

```lua
fs.dirname(path)
```
return all but the last component of path.

```lua
fs.realpath(path)
```
return the resolved path name of path.

```lua
fs.absname(path)
```
return the absolute path name of path.

```lua
fs.join(...)
```
return a path name made of several path components
(separated by `fs.sep`).

```lua
fs.with_tmpfile(f)
```
calls `f(tmp)` where `tmp` is the name of a temporary file.

```lua
fs.with_tmpdir(f)
```
calls `f(tmp)` where `tmp` is the name of a temporary directory.

```lua
fs.sep
```
is the directory separator.

```lua
fs.uR, fs.uW, fs.uX
fs.gR, fs.gW, fs.gX
fs.oR, fs.oW, fs.oX
fs.aR, fs.aW, fs.aX
```
are the User/Group/Other/All Read/Write/eXecute mask for
`fs.chmod`.
