# Lua eXtended

`luax` is a Lua interpretor and REPL based on Lua 5.4.4, augmented with some useful packages.
`luax` can also produces standalone executables from Lua scripts.

`luax` runs on several platforms with no dependency:

- Linux (x86_64, i386)
- Raspberry Pi (ARM)
- MacOS (x86_64, ARM)
- Windows (x86_64, i386)

`luax` can cross-compile scripts from and to any of these platforms.

## Compilation

`luax` is written in C and Lua and uses the Zig build system. First download `luax` and Zig:

- `luax`: <https://github.com/CDSoft/luax>
- `Zig`: <https://ziglang.org/download/>

Install Zig and compile `luax`:

```sh
$ git clone https://github.com/CDSoft/luax
$ cd luax
$ make                  # compile and test
```

## Installation

``` sh
$ make install                  # install luax to ~/.local/bin or ~/bin
$ make install PREFIX=/usr/bin  # install luax to /usr/bin
```

`luax` is a single autonomous executable.
It does not need to be installed and can be copied anywhere you want.

## Precompiled binaries

It is usually highly recommended to build `luax` from sources.
Some precompiled binaries are available here: [luax release](http://cdelord.fr/luax/luax.tar.xz).

The Linux and Raspberry Pi binaries are linked statically with
[musl](https://musl.libc.org/) and are not dynamic executables. They should
work on any Linux distributions.

## Usage

`luax` is very similar to `lua` and adds more options to compile scripts:

```
usage: luax [options] [script [args]]

General options:
  -h            show this help
  -v            show version information
  --            stop handling options

Lua options:
  -e stat       execute string 'stat'
  -i            enter interactive mode after executing 'script'
  -l name       require library 'name' into global 'name'
  -             stop handling options and execute stdin (incompatible with -i)

Compilation options:
  -t target     name of the luax binary compiled for the targetted platform
  -o file       name the executable file to create

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
$ luax -t luax-x86_64-macos-gnu main.lua lib1.lua lib2.lua -o executable
```

## Built-in modules

The `luax` runtime comes with a few builtin modules.

These modules are heavily inspired by [BonaLuna](http://cdelord.fr/bl) and [lapp](http://cdelord.fr/lapp).

### "Standard" library

```lua
local fun = require "fun"
```

**`fun.id(...)`{.lua}** is the identity function.

**`fun.const(...)`{.lua}** returns a constant function that returns `...`.

**`fun.keys(t)`{.lua}** returns a sorted list of keys from the table `t`.

**`fun.values(t)`{.lua}** returns a list of values from the table `t`, in the same order than `fun.keys(t)`{.lua}.

**`fun.pairs(t)`{.lua}** returns a `pairs`{.lua} like iterator, in the same order than `fun.keys(t)`{.lua}.

**`fun.concat(...)`{.lua}** returns a concatenated list from input lists.

**`fun.merge(...)`{.lua}** returns a merged table from input tables.

**`fun.flatten(...)`{.lua}** flattens input lists and non list parameters.

**`fun.replicate(n, x)`{.lua}** returns a list containing `n`{.lua} times the Lua object `x`{.lua}.

**`fun.compose(...)`{.lua}** returns a function that composes input functions.

**`fun.map(f, xs)`{.lua}** returns the list of `f(x)`{.lua} for all `x`{.lua} in `xs`{.lua}.

**`fun.tmap(f, t)`{.lua}** returns the table of `{k = f(t[k])}`{.lua} for all `k`{.lua} in `keys(t)`{.lua}.

**`fun.filter(p, xs)`{.lua}** returns the list of `x`{.lua} such that `p(x)`{.lua} is true.

**`fun.tfilter(p, t)`{.lua}** returns the table of `{k = v}`{.lua} for all `k`{.lua} in `keys(t)` such that `p(v)`{.lua} is true.

**`fun.foreach(xs, f)`{.lua}** executes `f(x)`{.lua} for all `x` in `xs`.

**`fun.tforeach(t, f)`{.lua}** executes `f(t[k])`{.lua} for all `k`{.lua} in `keys(t)`{.lua}.

**`fun.prefix(pre)`{.lua}** returns a function that adds a prefix `pre` to a string.

**`fun.suffix(suf)`{.lua}** returns a function that adds a suffix `suf` to a string.

**`fun.range(a, b [, step])`{.lua}** returns a list of values `[a, a+step, ... b]`. The default step value is 1.

**`fun.I(t)`{.lua}** returns a string interpolator that replaces `$(...)` by
the value of `...` in the environment defined by the table `t`. An interpolator
can be given another table to build a new interpolator with new values.

`luax` adds a few functions to the builtin `string` module:

**`string.split(s, sep, maxsplit, plain)`{.lua}** splits `s` using `sep` as a separator.
If `plain` is true, the separator is considered as plain text.
`maxsplit` is the maximum number of separators to find (ie the remaining string is returned unsplit.
This function returns a list of strings.

**`string.lines(s)`{.lua}** splits `s` using '\n' as a separator.

**`string.words(s)`{.lua}** splits `s` using '%s' as a separator.

**`string.ltrim(s)`{.lua}, `string.rtrim(s)`{.lua}, `string.trim(s)`{.lua}** remove left/right/both end spaces

### fs: File System module

```lua
local fs = require "fs"
```

**`fs.getcwd()`{.lua}** returns the current working directory.

**`fs.chdir(path)`{.lua}** changes the current directory to `path`.

**`fs.dir([path])`{.lua}** returns the list of files and directories in
`path` (the default path is the current directory).

**`fs.walk([path], [reverse])`{.lua}** returns a list listing directory and
file names in `path` and its subdirectories (the default path is the current
directory). If `reverse` is true, the list is built in a reverse order
(suitable for recursive directory removal)

**`fs.mkdir(path)`{.lua}** creates a new directory `path`.

**`fs.mkdirs(path)`{.lua}** creates a new directory `path` and its parent
directories.

**`fs.rename(old_name, new_name)`{.lua}** renames the file `old_name` to
`new_name`.

**`fs.mv(old_name, new_name)`{.lua}** alias for `fs.rename(old_name, new_name)`{.lua}.

**`fs.remove(name)`{.lua}** deletes the file `name`.

**`fs.rm(name)`{.lua}** alias for `fs.remove(name)`{.lua}.

**`fs.rmdir(path, [params])`{.lua}** deletes the directory `path`{.lua} (recursively if `params.recursive`{.lua} is `true`{.lua}.

**`fs.copy(source_name, target_name)`{.lua}** copies file `source_name` to
`target_name`. The attributes and times are preserved.

**`fs.is_file(name)`** returns `true` if `name` is a file.

**`fs.is_dir(name)`** returns `true` if `name` is a directory.

**`fs.stat(name)`{.lua}** reads attributes of the file `name`.  Attributes are:

- `name`: name
- `type`: `"file"` or `"directory"`
- `size`: size in bytes
- `mtime`, `atime`, `ctime`: modification, access and creation times.
- `mode`: file permissions
- `uR`, `uW`, `uX`: user Read/Write/eXecute permissions (Linux only)
- `gR`, `gW`, `gX`: group Read/Write/eXecute permissions (Linux only)
- `oR`, `oW`, `oX`: other Read/Write/eXecute permissions (Linux only)
- `aR`, `aW`, `aX`: anybody Read/Write/eXecute permissions

**`fs.inode(name)`{.lua}** reads device and inode attributes of the file `name`.
Attributes are:

- `dev`, `ino`: device and inode numbers

**`fs.chmod(name, other_file_name)`{.lua}** sets file `name` permissions as
file `other_file_name` (string containing the name of another file).

**`fs.chmod(name, bit1, ..., bitn)`{.lua}** sets file `name` permissions as
`bit1` or ... or `bitn` (integers).

**`fs.touch(name)`{.lua}** sets the access time and the modification time of
file `name` with the current time.

**`fs.touch(name, number)`{.lua}** sets the access time and the modification
time of file `name` with `number`.

**`fs.touch(name, other_name)`{.lua}** sets the access time and the
modification time of file `name` with the times of file `other_name`.

**`fs.basename(path)`{.lua}** return the last component of path.

**`fs.dirname(path)`{.lua}** return all but the last component of path.

**`fs.absname(path)`{.lua}** return the absolute path name of path.

**`fs.join(...)`{.lua}** return a path name made of several path components
(separated by `fs.sep`).

**`fs.with_tmpfile(f)`{.lua}** calls `f(tmp)`{.lua} where `tmp`{.lua} is the name of a temporary file.

**`fs.with_tmpdir(f)`{.lua}** calls `f(tmp)`{.lua} where `tmp`{.lua} is the name of a temporary directory.

**`fs.sep`{.lua}** is the directory separator.

**`fs.uR, fs.uW, fs.uX`{.lua}** are the User Read/Write/eXecute mask for
`fs.chmod`.

**`fs.gR, fs.gW, fs.gX`{.lua}** are the Group Read/Write/eXecute mask for
`fs.chmod`.

**`fs.oR, fs.oW, fs.oX`{.lua}** are the Other Read/Write/eXecute mask for
`fs.chmod`.

**`fs.aR, fs.aW, fs.aX`{.lua}** are All Read/Write/eXecute mask for `fs.chmod`.

### mathx: complete math library for Lua

```lua
local mathx = require "mathx"
```

`mathx` is taken from [Libraries and tools for Lua](https://web.tecgraf.puc-rio.br/~lhf/ftp/lua/#lmathx).

This is a complete math library for Lua 5.3 with the functions available
in C99. It can replace the standard Lua math library, except that mathx
deals exclusively with floats.

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

`imath` is taken from [Libraries and tools for Lua](https://web.tecgraf.puc-rio.br/~lhf/ftp/lua/#limath).

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

`qmath` is taken from [Libraries and tools for Lua](https://web.tecgraf.puc-rio.br/~lhf/ftp/lua/#lqmath).

`qmath` is a rational number library for Lua based on [imath](https://github.com/creachadair/imath).

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

`complex` is taken from [Libraries and tools for Lua](https://web.tecgraf.puc-rio.br/~lhf/ftp/lua/#lcomplex).

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

**`ps.sleep(n)`{.lua}** sleeps for `n` seconds.

**`ps.time()`{.lua}** returns the current time in seconds (the resolution is OS dependant).

### sys: System module

```lua
local sys = require "sys"
```

**`sys.arch`{.lua}** is `"x86_64"`, `"i386"` or `"aarch64"`

**`sys.os`{.lua}** is `"linux"`, `"macos"` or `"windows"`

**`sys.libc`{.lua}** is `"musl"` or `"gnu"`

### crypt: cryptography module

```lua
local crypt = require "crypt"
```

**`crypt.hex_encode(data)`{.lua}** encodes `data` in hexa.

**`crypt.hex_decode(data)`{.lua}** decodes the hexa `data`.

**`crypt.base64_encode(data)`{.lua}** encodes `data` in base64.

**`crypt.base64_decode(data)`{.lua}** decodes the base64 `data`.

**`crypt.crc32(data)`{.lua}** computes the CRC32 of `data`.

**`crypt.crc64(data)`{.lua}** computes the CRC64 of `data`.

**`crypt.rand_encode(key, data)`{.lua}** encrypts `data` using a random number generator and the encryption key `key`.

**`crypt.rand_decode(key, data)`{.lua}** decrypts `data` using a random number generator and the encryption key `key`.

**`crypt.srand(seed)`{.lua}** sets the random seed.

**`crypt.rand()`{.lua}** returns a random integral number between `0` and `crypt.RAND_MAX`{.lua}.

**`crypt.rand(bytes)`{.lua}** returns a string with `bytes` random bytes.

**`crypt.frand()`{.lua}** returns a random floating point number between `0.0` and `1.0`{.lua}.

**`crypt.prng(seed)`{.lua}** returns a random number generator starting from the optional seed `seed`{.lua}.
This object has three methods: `srand(seed)`, `rand([bytes])` and `frand()`.

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

**Warning**: `rl` is no longer related to the Linux readline library.
If you need readline, you can use `rlwrap` on Linux.

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
