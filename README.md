# Lua eXtended

`luax` is a Lua interpretor and REPL based on Lua 5.4.4, augmented with some
useful packages. `luax` can also produces standalone executables from Lua
scripts.

`luax` runs on several platforms with no dependency:

- Linux (x86_64, i386, aarch64)
- MacOS (x86_64, aarch64)
- Windows (x86_64, i386)

`luax` can cross-compile scripts from and to any of these platforms.

## Compilation

`luax` is written in C and Lua and uses the Zig build system. Just download
`luax` (<https://github.com/CDSoft/luax>) and run `make`:

```sh
$ git clone https://github.com/CDSoft/luax
$ cd luax
$ make                  # compile and test
```

**Note**: `make` will download a Zig compiler if necessary.

## Installation

### Installation of luax for the current host only

``` sh
$ make install                  # install luax to ~/.local/bin or ~/bin
$ make install PREFIX=/usr/bin  # install luax to /usr/bin
```

`luax` is a single autonomous executable.
It does not need to be installed and can be copied anywhere you want.

### Installation of luax for all supported platforms (cross compilation support)

``` sh
$ make install-all                  # install luax to ~/.local/bin or ~/bin
$ make install-all PREFIX=/usr/bin  # install luax to /usr/bin
```

## Precompiled binaries

It is usually highly recommended to build `luax` from sources. The latest
binaries are available here: [luax.tar.xz](http://cdelord.fr/luax/luax.tar.xz).

The Linux and Raspberry Pi binaries are linked statically with
[musl](https://musl.libc.org/) and are not dynamic executables. They should
work on any Linux distributions.

## Usage

`luax` is very similar to `lua` and adds more options to compile scripts:

```
usage: luax [options] [script [args]]

General options:
  -h                show this help
  -v                show version information
  --                stop handling options

Lua options:
  -e stat           execute string 'stat'
  -i                enter interactive mode after executing 'script'
  -l name           require library 'name' into global 'name'
  -                 stop handling options and execute stdin
                    (incompatible with -i)

Compilation options:
  -t target         name of the targetted platform
  -t all            compile for all available targets
  -t list           list available targets
  -o file           name the executable file to create

Scripts for compilation:
  file name         name of a Lua package to add to the binary
                    (the first one is the main script)
  -autoload         the next package will be loaded with require
                    and stored in a global variable of the same name
                    when the binary starts
  -autoload-all     all following packages (until -autoload-none)
                    are loaded with require when the binary starts
  -autoload-none    cancel -autoload-all
  -autoexec         the next package will be executed with require
                    when the binary start
  -autoexec-all     all following packages (until -autoexec-none)
                    are executed with require when the binary starts
  -autoexec-none    cancel -autoexec-all

Lua and Compilation options can not be mixed.
```

When compiling scripts (options `-t` and `-o`), the main script shall be the
first one. Other scripts are libraries that can be loaded by the main script.

#### Examples

``` bash
# Native compilation (luax is a symlink to the luax binary of the host)
$ luax main.lua lib1.lua lib2.lua -o executable
$ ./executable      # equivalent to luax main.lua

# Cross compilation to MacOS x86_64
$ luax -t x86_64-macos-gnu main.lua lib1.lua lib2.lua -o executable

# Available targets
$ luax -t list
aarch64-linux-musl  <path to>/luax-aarch64-linux-musl
aarch64-macos-gnu   <path to>/luax-aarch64-macos-gnu
i386-linux-musl     <path to>/luax-i386-linux-musl
i386-windows-gnu    <path to>/luax-i386-windows-gnu.exe
x86_64-linux-musl   <path to>/luax-x86_64-linux-musl
x86_64-macos-gnu    <path to>/luax-x86_64-macos-gnu
x86_64-windows-gnu  <path to>/luax-x86_64-windows-gnu.exe
```

## Built-in modules

The `luax` runtime comes with a few builtin modules.

These modules are heavily inspired by [BonaLuna](http://cdelord.fr/bl) and
[lapp](http://cdelord.fr/lapp).

### "Standard" library

```lua
local fun = require "fun"
```

**`fun.id(...)`** is the identity function.

**`fun.const(...)`** returns a constant function that returns `...`.

**`fun.keys(t)`** returns a sorted list of keys from the table `t`.

**`fun.values(t)`** returns a list of values from the table `t`, in the same order than `fun.keys(t)`.

**`fun.pairs(t)`** returns a `pairs` like iterator, in the same order than `fun.keys(t)`.

**`fun.concat(...)`** returns a concatenated list from input lists.

**`fun.merge(...)`** returns a merged table from input tables.

**`fun.flatten(...)`** flattens input lists and non list parameters.

**`fun.replicate(n, x)`** returns a list containing `n` times the Lua object `x`.

**`fun.compose(...)`** returns a function that composes input functions.

**`fun.map(f, xs)`** returns the list of `f(x)` for all `x` in `xs`.

**`fun.tmap(f, t)`** returns the table of `{k = f(t[k])}` for all `k` in `keys(t)`.

**`fun.filter(p, xs)`** returns the list of `x` such that `p(x)` is true.

**`fun.tfilter(p, t)`** returns the table of `{k = v}` for all `k` in `keys(t)` such that `p(v)` is true.

**`fun.foreach(xs, f)`** executes `f(x)` for all `x` in `xs`.

**`fun.tforeach(t, f)`** executes `f(t[k])` for all `k` in `keys(t)`.

**`fun.prefix(pre)`** returns a function that adds a prefix `pre` to a string.

**`fun.suffix(suf)`** returns a function that adds a suffix `suf` to a string.

**`fun.range(a, b [, step])`** returns a list of values `[a, a+step, ... b]`. The default step value is 1.

**`fun.I(t)`** returns a string interpolator that replaces `$(...)` by
the value of `...` in the environment defined by the table `t`. An interpolator
can be given another table to build a new interpolator with new values.

`luax` adds a few functions to the builtin `string` module:

**`string.split(s, sep, maxsplit, plain)`** splits `s` using `sep` as a separator.
If `plain` is true, the separator is considered as plain text.
`maxsplit` is the maximum number of separators to find (ie the remaining string is returned unsplit.
This function returns a list of strings.

**`string.lines(s)`** splits `s` using `'\n'` as a separator.

**`string.words(s)`** splits `s` using `'%s'` as a separator.

**`string.ltrim(s)`, `string.rtrim(s)`, `string.trim(s)`** removes left/right/both end spaces.

**`string.cap(s)`** capitalizes `s`.

### fs: File System module

```lua
local fs = require "fs"
```

**`fs.getcwd()`** returns the current working directory.

**`fs.chdir(path)`** changes the current directory to `path`.

**`fs.dir([path])`** returns the list of files and directories in
`path` (the default path is the current directory).

**`fs.walk([path], [reverse])`** returns a list listing directory and
file names in `path` and its subdirectories (the default path is the current
directory). If `reverse` is true, the list is built in a reverse order
(suitable for recursive directory removal)

**`fs.mkdir(path)`** creates a new directory `path`.

**`fs.mkdirs(path)`** creates a new directory `path` and its parent
directories.

**`fs.rename(old_name, new_name)`** renames the file `old_name` to
`new_name`.

**`fs.mv(old_name, new_name)`** alias for `fs.rename(old_name, new_name)`.

**`fs.remove(name)`** deletes the file `name`.

**`fs.rm(name)`** alias for `fs.remove(name)`.

**`fs.rmdir(path, [params])`** deletes the directory `path` (recursively if `params.recursive` is `true`.

**`fs.copy(source_name, target_name)`** copies file `source_name` to
`target_name`. The attributes and times are preserved.

**`fs.is_file(name)`** returns `true` if `name` is a file.

**`fs.is_dir(name)`** returns `true` if `name` is a directory.

**`fs.stat(name)`** reads attributes of the file `name`.  Attributes are:

- `name`: name
- `type`: `"file"` or `"directory"`
- `size`: size in bytes
- `mtime`, `atime`, `ctime`: modification, access and creation times.
- `mode`: file permissions
- `uR`, `uW`, `uX`: user Read/Write/eXecute permissions
- `gR`, `gW`, `gX`: group Read/Write/eXecute permissions
- `oR`, `oW`, `oX`: other Read/Write/eXecute permissions
- `aR`, `aW`, `aX`: anybody Read/Write/eXecute permissions

**`fs.inode(name)`** reads device and inode attributes of the file `name`.
Attributes are:

- `dev`, `ino`: device and inode numbers

**`fs.chmod(name, other_file_name)`** sets file `name` permissions as
file `other_file_name` (string containing the name of another file).

**`fs.chmod(name, bit1, ..., bitn)`** sets file `name` permissions as
`bit1` or ... or `bitn` (integers).

**`fs.touch(name)`** sets the access time and the modification time of
file `name` with the current time.

**`fs.touch(name, number)`** sets the access time and the modification
time of file `name` with `number`.

**`fs.touch(name, other_name)`** sets the access time and the
modification time of file `name` with the times of file `other_name`.

**`fs.basename(path)`** return the last component of path.

**`fs.dirname(path)`** return all but the last component of path.

**`fs.realpath(path)`** return the resolved path name of path.

**`fs.absname(path)`** return the absolute path name of path.

**`fs.join(...)`** return a path name made of several path components
(separated by `fs.sep`).

**`fs.with_tmpfile(f)`** calls `f(tmp)` where `tmp` is the name of a temporary file.

**`fs.with_tmpdir(f)`** calls `f(tmp)` where `tmp` is the name of a temporary directory.

**`fs.sep`** is the directory separator.

**`fs.uR, fs.uW, fs.uX`** are the User Read/Write/eXecute mask for
`fs.chmod`.

**`fs.gR, fs.gW, fs.gX`** are the Group Read/Write/eXecute mask for
`fs.chmod`.

**`fs.oR, fs.oW, fs.oX`** are the Other Read/Write/eXecute mask for
`fs.chmod`.

**`fs.aR, fs.aW, fs.aX`** are All Read/Write/eXecute mask for `fs.chmod`.

### mathx: complete math library for Lua

```lua
local mathx = require "mathx"
```

`mathx` is taken from [Libraries and tools for
Lua](https://web.tecgraf.puc-rio.br/~lhf/ftp/lua/#lmathx).

This is a complete math library for Lua 5.3 with the functions available in
C99. It can replace the standard Lua math library, except that mathx deals
exclusively with floats.

There is no manual: see the summary below and a C99 reference manual, e.g.
<http://en.wikipedia.org/wiki/C_mathematical_functions>

mathx library:

    acos        cosh        fmax        lgamma      remainder
    acosh       deg         fmin        log         round
    asin        erf         fmod        log10       scalbn
    asinh       erfc        frexp       log1p       sin
    atan        exp         gamma       log2        sinh
    atan2       exp2        hypot       logb        sqrt
    atanh       expm1       isfinite    modf        tan
    cbrt        fabs        isinf       nearbyint   tanh
    ceil        fdim        isnan       nextafter   trunc
    copysign    floor       isnormal    pow         version
    cos         fma         ldexp       rad

### imath: arbitrary precision integer and rational arithmetic library

```lua
local imath = require "imath"
```

`imath` is taken from [Libraries and tools for
Lua](https://web.tecgraf.puc-rio.br/~lhf/ftp/lua/#limath).

`imath` is an [arbitrary-precision](http://en.wikipedia.org/wiki/Bignum)
integer library for Lua based on [imath](https://github.com/creachadair/imath).

imath library:

    __add(x,y)          add(x,y)            pow(x,y)
    __div(x,y)          bits(x)             powmod(x,y,m)
    __eq(x,y)           compare(x,y)        quotrem(x,y)
    __idiv(x,y)         div(x,y)            root(x,n)
    __le(x,y)           egcd(x,y)           shift(x,n)
    __lt(x,y)           gcd(x,y)            sqr(x)
    __mod(x,y)          invmod(x,m)         sqrt(x)
    __mul(x,y)          iseven(x)           sub(x,y)
    __pow(x,y)          isodd(x)            text(t)
    __shl(x,n)          iszero(x)           tonumber(x)
    __shr(x,n)          lcm(x,y)            tostring(x,[base])
    __sub(x,y)          mod(x,y)            totext(x)
    __tostring(x)       mul(x,y)            version
    __unm(x)            neg(x)
    abs(x)              new(x,[base])

### qmath: rational number library

```lua
local qmath = require "qmath"
```

`qmath` is taken from [Libraries and tools for
Lua](https://web.tecgraf.puc-rio.br/~lhf/ftp/lua/#lqmath).

`qmath` is a rational number library for Lua based on
[imath](https://github.com/creachadair/imath).

qmath library:

    __add(x,y)          abs(x)              neg(x)
    __div(x,y)          add(x,y)            new(x,[d])
    __eq(x,y)           compare(x,y)        numer(x)
    __le(x,y)           denom(x)            pow(x,y)
    __lt(x,y)           div(x,y)            sign(x)
    __mul(x,y)          int(x)              sub(x,y)
    __pow(x,y)          inv(x)              todecimal(x,[n])
    __sub(x,y)          isinteger(x)        tonumber(x)
    __tostring(x)       iszero(x)           tostring(x)
    __unm(x)            mul(x,y)            version

### complex: math library for complex numbers based on C99

```lua
local complex = require "complex"
```

`complex` is taken from [Libraries and tools for
Lua](https://web.tecgraf.puc-rio.br/~lhf/ftp/lua/#lcomplex).

`complex` is a math library for complex numbers based on C99.

complex library:

    I       __tostring(z)   asinh(z)    imag(z)     sinh(z)
    __add(z,w)  __unm(z)    atan(z)     log(z)      sqrt(z)
    __div(z,w)  abs(z)      atanh(z)    new(x,y)    tan(z)
    __eq(z,w)   acos(z)     conj(z)     pow(z,w)    tanh(z)
    __mul(z,w)  acosh(z)    cos(z)      proj(z)     tostring(z)
    __pow(z,w)  arg(z)      cosh(z)     real(z)     version
    __sub(z,w)  asin(z)     exp(z)      sin(z)

### ps: Process management module

```lua
local ps = require "ps"
```

**`ps.sleep(n)`** sleeps for `n` seconds.

**`ps.time()`** returns the current time in seconds (the resolution is OS dependant).

### sys: System module

```lua
local sys = require "sys"
```

**`sys.os`** is `"linux"`, `"macos"` or `"windows"`.

**`sys.arch`** is `"x86_64"`, `"i386"` or `"aarch64"`.

**`sys.abi`** is `"musl"` or `"gnu"`.

### crypt: cryptography module

```lua
local crypt = require "crypt"
```

**`crypt.hex_encode(data)`** encodes `data` in hexa.

**`crypt.hex_decode(data)`** decodes the hexa `data`.

**`crypt.base64_encode(data)`** encodes `data` in base64.

**`crypt.base64_decode(data)`** decodes the base64 `data`.

**`crypt.crc32(data)`** computes the CRC32 of `data`.

**`crypt.crc64(data)`** computes the CRC64 of `data`.

**`crypt.rc4(data, key, [drop])`** encrypts/decrypts `data` using the RC4Drop
algorithm and the encryption key `key` (drops the first `drop` encryption
steps, the default value of `drop` is 768).

**`crypt.srand(seed)`** sets the random seed.

**`crypt.rand()`** returns a random integral number between `0` and `crypt.RAND_MAX`.

**`crypt.rand(bytes)`** returns a string with `bytes` random bytes.

**`crypt.frand()`** returns a random floating point number between `0.0` and `1.0`.

**`crypt.prng(seed)`** returns a random number generator starting from the optional seed `seed`.
This object has three methods: `srand(seed)`, `rand([bytes])` and `frand()`.

Some functions of the `crypt` package are added to the string module:

**`s:hex_encode()`** is `crypt.hex_encode(s)`.

**`s:hex_decode()`** is `crypt.hex_decode(s)`.

**`s:base64_encode()`** is `crypt.base64_encode(s)`.

**`s:base64_decode()`** is `crypt.base64_decode(s)`.

**`s:crc32()`** is `crypt.crc32(s)`.

**`s:crc64()`** is `crypt.crc64(s)`.

**`s:rc4(key, drop)`** is `crypt.crc64(s, key, drop)`.

### lpeg: Parsing Expression Grammars For Lua

LPeg is a pattern-matching library for Lua.

```lua
local lpeg = require "lpeg"
local re = require "re"
```

The documentation of these modules are available on Lpeg web site:

- [Lpeg](http://www.inf.puc-rio.br/~roberto/lpeg/)
- [Re](http://www.inf.puc-rio.br/~roberto/lpeg/re.html)

### rl: readline

**rl.read(prompt)** prints `prompt` and returns the string entered by the user.

**Warning**: `rl` is no longer related to the Linux readline library. If you
need readline, you can use `rlwrap` on Linux.

### linenoise: light readline alternative

**linenoise.read(prompt)** prints `prompt` and returns the string entered by
the user.

**linenoise.read_mask(prompt)** is the same as **linenoise.read(prompt)** the
the characters are not echoed but replaced with `*`.

**linenoise.add(line)** adds `line` to the current history.

**linenoise.set_len(len)** sets the maximal history length to `len`.

**linenoise.save(filename)** saves the history to the file `filename`.

**linenoise.load(filename)** loads the history from the file `filename`.

**linenoise.clear()** clears the screen.

**linenoise.multi_line(ml)** enable/disable the multi line mode.

**linenoise.mask(b)** enable/disable the mask mode.

## License

    luax is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    luax is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with luax.  If not, see <https://www.gnu.org/licenses/>.

    For further information about luax you can visit
    http://cdelord.fr/luax

`luax` uses other third party softwares:

* **[Zig 0.9.1](https://ziglang.org/)**: General-purpose programming language
  and toolchain for maintaining robust, optimal, and reusable software. ([MIT
  license](https://github.com/ziglang/zig/blob/master/LICENSE))
* **[Lua 5.4](http://www.lua.org)**: Copyright (C) 1994-2022 Lua.org, PUC-Rio
  ([MIT license](http://www.lua.org/license.html))
* **[Lpeg](http://www.inf.puc-rio.br/~roberto/lpeg/)**: Parsing Expression
  Grammars For Lua ([MIT license](http://www.lua.org/license.html))
