---
title: Lua eXtended
author: Christophe Delord
---

![](luax-banner.svg){width=100%}

# Lua eXtended

`luax` is a Lua interpreter and REPL based on Lua 5.4, augmented with some
useful packages. `luax` can also produce executable scripts from Lua scripts.

`luax` runs on several platforms with no dependency:

- Linux (x86_64, aarch64)
- MacOS (x86_64, aarch64)
- Windows (x86_64)

`luax` can « compile[^compilation] » scripts from and to any of these platforms.

[^compilation]: `luax` is actually not a « compiler ».

    It just bundles Lua scripts into a single script that can be run everywhere
    LuaX is installed.

`luaxc` compiles[^cross-compilation] scripts into a single executable containing
the LuaX runtime and the Lua scripts. The target platform can be explicitly
specified to cross-compile scripts for a supported platform.

[^cross-compilation]: `luaxc` uses `zig` to link the LuaX runtime with the Lua
    scripts. @[[BYTECODE
        and "The Lua scripts are actually compiled to Lua bytecode."
        or  "The Lua scripts are actually not compiled to Lua bytecode unless explicitely required."
    ]] Contrary to `luax`, `luaxc` produces executables that do not require LuaX
    to be installed.

## Getting in touch

- [cdelord.fr/luax](https://cdelord.fr/luax)
- [github.com/CDSoft/luax](https://github.com/CDSoft/luax)

## Requirements

- [Ninja](https://ninja-build.org): to compile LuaX using the LuaX Ninja file
- C compiler (`cc`, `gcc`, `clang`, ...), [Lua 5.4](https://lua.org): to generate the Ninja file

## Compilation

`luax` is written in C and Lua.
The build system uses Ninja and Zig (automatically downloaded by the Ninja file).

Just download `luax` (<https://github.com/CDSoft/luax>),
generate `build.ninja` and run `ninja`:

```sh
$ git clone https://github.com/CDSoft/luax
$ cd luax
$ ninja -f bootstrap.ninja  # compile Lua and generate build.ninja
$ ninja             # compile LuaX
$ ninja test        # run tests
$ ninja doc         # generate LuaX documentation
```

**Note**: `ninja` will download a Zig compiler.

If the bootstrap stage fails, you can try:

1. to use another C compiler:
    - `CC=gcc ninja -f bootstrap.ninja` to compile Lua with `gcc` instead of `cc`
    - `CC=clang ninja -f bootstrap.ninja` to compile Lua with `clang` instead of `cc`
    - ...
2. or install Lua and generate `build.ninja` manually:
    - `apt install lua`, `dnf install lua`, ...
    - `lua tools/bang.lua` to generate `build.lua` with the Lua interpreter provided by your OS

### Compilation options

Option              Description
------------------- ------------------------------------------------------------------------------
`bang -- fast`      Optimized for speed
`bang -- small`     Optimized for size
`bang -- debug`     Debug symbols kept, not optimized
`bang -- san`       Compiled with ASan and UBSan (implies clang)
`bang -- zig`       Compile LuaX with Zig
`bang -- gcc`       Compile LuaX with gcc
`bang -- clang`     Compile LuaX with clang

`bang` must be run before `ninja` to change the compilation options.

`lua tools/bang.lua` can be used instead of [bang](https://cdelord.fr/bang) if
it is not installed.

The default compilation options are `fast` and `zig`.

Zig is downloaded by the ninja file.
gcc and clang must be already installed.

### Compilation in debug mode

LuaX can be compiled in debug mode
(less optimization, debug symbols kept in the binaries).
With the `san` option, the tests are executed with
[ASan](https://clang.llvm.org/docs/AddressSanitizer.html)
and [UBSan](https://clang.llvm.org/docs/UndefinedBehaviorSanitizer.html).
They run slower but this helps finding tricky bugs.

``` sh
$ git clone https://github.com/CDSoft/luax
$ cd luax
$ tools/bang.lua -- debug san # generate build.ninja in debug mode with sanitizers
$ ninja                       # compile LuaX
$ ninja test                  # run tests on the host
```

## Cross-compilation

When compiled with Zig, ninja will compile `luax` and `luaxc`.

`luaxc` is a Bash script containing precompiled libraries for all supported
targets. This script can bundle Lua scripts and link them with the LuaX runtime
of the specified target.

E.g.: to produce an executable containing the LuaX runtime for `linux-x86_64`
and `hello.lua`:

``` sh
$ luaxc -t linux-x86_64-musl -o hello hello.lua
```

@when(not BYTECODE)[===[

E.g.: to produce an executable with the compiled Lua bytecode:

``` sh
$ luaxc -b -t linux-x86_64-musl -o hello hello.lua
```

]===]

E.g.: to produce an executable with the compiled Lua bytecode with no debug
information:

``` sh
$ luaxc -s -t linux-x86_64-musl -o hello hello.lua
```

`luaxc` can compile Lua scripts to Lua bytecode. If scripts are large they will
start quickly but will run as fast as the original Lua scripts.

## Precompiled LuaX binaries

In case precompiled binaries are needed (GNU/Linux, MacOS, Windows),
some can be found at [cdelord.fr/hey](http://cdelord.fr/hey).
These archives contain LuaX as well as some other softwares more or less related to LuaX.

**Warning**: There are Linux binaries linked with musl and glibc. The musl
binaries are platform independent but can not load shared libraries. The glibc
binaries can load shared libraries but may depend on some specific glibc
versions on the host.

## Installation

``` sh
$ ninja install                 # install luax to ~/.local/bin and ~/.local/lib
$ PREFIX=/usr ninja install     # install luax to /usr/bin and /usr/lib
```

`luax` is a single autonomous executable.
It does not need to be installed and can be copied anywhere you want.

### LuaX artifacts

`ninja install` installs:

- `$PREFIX/bin/luax`: LuaX binary
- `$PREFIX/bin/luax.lua`: a pure Lua REPL reimplementing some LuaX libraries,
  usable in any Lua 5.4 interpreter (e.g.: lua, pandoc lua, ...)
- `$PREFIX/bin/luax-pandoc.lua`: LuaX run in a Pandoc Lua interpreter
- `$PREFIX/lib/libluax.so`: Linux LuaX shared libraries
- `$PREFIX/lib/libluax.dylib`: MacOS LuaX shared libraries
- `$PREFIX/lib/libluax.dll`: Windows LuaX shared libraries
- `$PREFIX/lib/luax.lua`: a pure Lua reimplementation of some LuaX libraries,
  usable in any Lua 5.4 interpreter.

## Usage

`luax` is very similar to `lua` and adds more options to compile scripts:

```
@sh(LUAX, '-h')
    : lines()
    : drop_while(function(l) return not l:match"^usage:" end)
    : take_while(function(l) return not l:match"^Copyright:" end)
    : unlines()
    : trim()
```

When compiling scripts (options `-t` and `-o`), the scripts shall contain tags
(e.g. in comments) showing how the script is used by LuaX:

- `--@MAIN`: main script (must be unique)
- `--@LOAD`: library that is `require`'d before the main script is run and
  stored in a global variable
- `--@LOAD=<global variable name>`: as `--@LOAD` but the module is stored
  in a global variable with the given name
- `--@LIB`: library that must be explicitly `require`'d by the main script
- `--@LIB=<new module name>`: library that is `require`'d with `<new module name>`
  instead of the source filename.

Scripts without tags are classified using a simplistic heuristic:

- if the last non empty line starts with `return` then it is a library (as if
  it contained a `@LIB` tag)
- otherwise it is the main script (as if it contained the `@MAIN` tag).

This heuristic should work for most of the Lua scripts but explicit tags are
recommended.

LuaX can also embed files that are not Lua scripts.
These files are embedded as Lua modules that return the file content as a string.
In this case, the module name if the file name.

**Note for Windows users**: since Windows does not support shebangs, a script
`script` shall be explicitly launched with `luax` (e.g.: `luax script`). If
`script` is not found, it is searched in the installation directory of `luax`
or in `$PATH`.

### Examples

``` bash
# Compilation (standalone executable script for LuaX)
$ luax -o executable main.lua lib1.lua lib2.lua
$ ./executable      # equivalent to luax main.lua

# Compilation for Lua
$ luax -o executable -t lua main.lua lib1.lua lib2.lua
$ ./executable      # equivalent to lua main.lua

# Compilation for Pandoc Lua
$ luax -o executable -t pandoc main.lua lib1.lua lib2.lua
$ ./executable      # equivalent to pandoc lua main.lua

# Available targets
$ luax -t list
@sh(LUAX, '-t list')
    : lines()
    : map(F.compose{F.head, string.words})
```

## Built-in modules

The `luax` runtime comes with a few builtin modules.

Some modules are heavily inspired by [BonaLuna](http://cdelord.fr/bl) and
[lapp](http://cdelord.fr/lapp).

- [LuaX interactive usage](repl.md): improved Lua REPL
- [package](package.md): modified Lua package `package`
- [import](import.md): import Lua scripts to user table instead of `_G`
- [F](F.md): functional programming inspired functions
- [fs](fs.md): file system management
- [sh](sh.md): shell command execution
- [mathx](mathx.md): complete math library for Lua
- [imath](imath.md): arbitrary precision integer and rational arithmetic library
- [qmath](qmath.md): rational number library
- [complex](complex.md): math library for complex numbers based on C99
- [ps](ps.md): Process management module
- [sys](sys.md): System module
- [term](term.md): Terminal manipulation module
- [crypt](crypt.md): cryptography module
- [lz4](lz4.md): Extremely Fast Compression algorithm
- [lzw](lzw.md): A relatively fast LZW compression algorithm in pure Lua
- [lpeg](lpeg.md): Parsing Expression Grammars For Lua
- [luasocket](luasocket.md): Network support for the Lua language
- [argparse](argparse.md): Feature-rich command line parser for Lua
- [inspect](inspect.md): Human-readable representation of Lua tables
- [serpent](serpent.md): Lua serializer and pretty printer
- [cbor](cbor.md): pure Lua implementation of the CBOR
- [linenoise](linenoise.md): A small, portable GNU readline replacement with UTF-8 support
- [json](json.md): JSON Module for Lua

## Shared libraries

LuaX is also available as a shared library. This shared library is a Lua module
that can be loaded with `require`. It provides the same modules than the LuaX
executable and can be used by a regular Lua interpreter (e.g.: lua, pandoc,
...).

E.g.:

```
$ lua -l libluax
Lua 5.4.6  Copyright (C) 1994-2023 Lua.org, PUC-Rio
> F = require "F"
> F.range(100):sum()
5050
> F.show({x=1, y=2})
{x=1, y=2}
> F.show({x=1, y=2}, {indent=4})
{
    x = 1,
    y = 2,
}
```

## Pure Lua modules

LuaX modules also provide pure Lua implementations (no LuaX dependency). The
script `lib/luax.lua` can be reused in pure Lua programs:

- [luax.lua](luax.lua.md): LuaX modules reimplemented in pure Lua (except
  LuaSocket and lpeg)

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

* **[Zig](https://ziglang.org/)**: General-purpose programming language and
  toolchain for maintaining robust, optimal, and reusable software. ([MIT
  license](https://github.com/ziglang/zig/blob/master/LICENSE))
* **[Lua 5.4](http://www.lua.org)**: Copyright (C) 1994-2023 Lua.org, PUC-Rio
  ([MIT license](http://www.lua.org/license.html))
* **[Lpeg](http://www.inf.puc-rio.br/~roberto/lpeg/)**: Parsing Expression
  Grammars For Lua ([MIT license](http://www.lua.org/license.html))
* **[luasocket](https://github.com/diegonehab/luasocket)**: Network support for
  the Lua language ([LuaSocket 3.0
  license](https://github.com/diegonehab/luasocket/blob/master/LICENSE))
* **[inspect](https://github.com/kikito/inspect.lua)**: Human-readable
  representation of Lua tables ([MIT
  license](https://github.com/kikito/inspect.lua/blob/master/MIT-LICENSE.txt))
* **[serpent](https://github.com/pkulchenko/serpent)**: Lua serializer and
  pretty printer. ([MIT
  license](https://github.com/pkulchenko/serpent/blob/master/LICENSE))
* **[LZ4](https://github.com/lz4/lz4)**: Extremely Fast Compression algorithm
  ([License](https://github.com/lz4/lz4/blob/dev/lib/LICENSE))
* **[LZW](https://github.com/Rochet2/lualzw)**: A relatively fast LZW
  compression algorithm in pure Lua
  ([License](https://github.com/Rochet2/lualzw/blob/master/LICENSE))
- **[Argparse](https://github.com/mpeterv/argparse)**: a feature-rich command
  line parser for Lua ([MIT
  license](https://github.com/mpeterv/argparse/blob/master/LICENSE))
- **[Linenoise](https://github.com/yhirose/linenoise/tree/utf8-support)**: A
  minimal, zero-config, BSD licensed, readline replacement ([BSD
  license](https://github.com/antirez/linenoise/blob/master/LICENSE))
* **[json.lua](https://github.com/rxi/json.lua)**: A lightweight JSON library
  for Lua ([MIT license](https://github.com/rxi/json.lua/blob/master/LICENSE))
* **[CBOR](https://www.zash.se/lua-cbor.html)**: pure Lua implementation of the
  CBOR ([License](https://code.zash.se/lua-cbor/file/tip/COPYING))
