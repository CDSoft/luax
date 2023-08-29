<img src="doc/luax-banner.svg" style="width:100.0%" />

# Lua eXtended

`luax` is a Lua interpreter and REPL based on Lua 5.4, augmented with
some useful packages. `luax` can also produce standalone executables
from Lua scripts.

`luax` runs on several platforms with no dependency:

- Linux (x86_64, x86, aarch64)
- MacOS (x86_64, aarch64)
- Windows (x86_64, x86)

`luax` can « cross-compile[^1] » scripts from and to any of these
platforms.

## Getting in touch

- [cdelord.fr/luax](https://cdelord.fr/luax)
- [github.com/CDSoft/luax](https://github.com/CDSoft/luax)
- [LuaX on Discord](https://discord.gg/SzFUwYBAzF)

## Requirements

- [Ninja](https://ninja-build.org): needed to compile LuaX using the
  LuaX Ninja file
- [Bang](https://github.com/CDSoft/bang): optional, only needed to
  update the Ninja file

## Compilation

`luax` is written in C and Lua. The build system uses Ninja and Zig
(automatically downloaded by the Ninja file).

Just download `luax` (<https://github.com/CDSoft/luax>) and run `ninja`:

``` sh
$ git clone https://github.com/CDSoft/luax
$ cd luax
$ ninja             # compile LuaX (all targets)
$ ninja test        # run tests on the host
$ ninja doc         # generate LuaX documentation
```

**Note**: `ninja` will download a Zig compiler.

### Precompiled LuaX binaries

In case precompiled binaries are needed (GNU/Linux, MacOS, Windows),
some can be found at [cdelord.fr/pub](http://cdelord.fr/pub). These
archives contain LuaX as well as some other softwares more or less
related to LuaX.

**Warning**: There are Linux binaries linked with musl and glibc. The
musl binaries are platform independent but can not load shared
libraries. The glibc binaries can load shared libraries but may depend
on some specific glibc versions on the host.

## Installation

``` sh
$ ninja install                 # install luax to ~/.local/bin and ~/.local/lib
$ PREFIX=/usr ninja install     # install luax to /usr/bin and /usr/lib
```

`luax` is a single autonomous executable. It does not need to be
installed and can be copied anywhere you want.

### LuaX artifacts

`ninja install` installs:

- `$PREFIX/bin/luax`: symbolic link to the LuaX binary for the host
- `$PREFIX/bin/luax-<ARCH>-<OS>-<LIBC>`: LuaX binary for a specific
  platform
- `$PREFIX/bin/luax-pandoc`: LuaX run in a Pandoc Lua interpreter
- `$PREFIX/bin/luax-lua`: a pure Lua REPL reimplementing some LuaX
  libraries, usable in any Lua 5.4 interpreter (e.g.: lua, pandoc lua,
  …)
- `$PREFIX/lib/libluax-<ARCH>-<OS>-<LIBC>.so`: Linux LuaX shared
  libraries
- `$PREFIX/lib/libluax-<ARCH>-<OS>-<LIBC>.dylib`: MacOS LuaX shared
  libraries
- `$PREFIX/lib/libluax-<ARCH>-<OS>-<LIBC>.dll`: Windows LuaX shared
  libraries
- `$PREFIX/lib/luax.lua`: a pure Lua reimplementation of some LuaX
  libraries, usable in any Lua 5.4 interpreter.

## Usage

`luax` is very similar to `lua` and adds more options to compile
scripts:

    usage: luax-x86_64-linux-gnu [options] [script [args]]

    General options:
      -h                show this help
      -v                show version information
      --                stop handling options

    Lua options:
      -e stat           execute string 'stat'
      -i                enter interactive mode after executing
                        'script'
      -l name           require library 'name' into global 'name'
      -l g=name         require library 'name' into global 'g'
      -l _=name         require library 'name' (no global variable)
      -                 stop handling options and execute stdin
                        (incompatible with -i)

    Compilation options:
      -t target         name of the targetted platform
      -t all            compile for all available LuaX targets
      -t list           list available targets
      -t list-luax      list available native LuaX targets
      -t list-lua       list available Lua/Pandoc targets
      -o file           name the executable file to create
      -q                quiet compilation (error messages only)

    Scripts for compilation:
      file.lua          name of a Lua package to add to the binary.
      file.xxx          file embeded as a module
                        returning the content of the file.

    Lua and Compilation options can not be mixed.

    Environment variables:

      LUA_INIT_5_4, LUA_INIT
                        code executed before handling command line
                        options and scripts (not in compilation
                        mode). When LUA_INIT_5_4 is defined,
                        LUA_INIT is ignored.

      PATH              PATH shall contain the bin directory where
                        LuaX is installed

      LUA_PATH          LUA_PATH shall point to the lib directory
                        where the Lua implementation of LuaX
                        lbraries are installed

      LUA_CPATH         LUA_CPATH shall point to the lib directory
                        where LuaX shared libraries are installed

    PATH, LUA_PATH and LUA_CPATH can be set in .bashrc or .zshrc
    with « luax env ».
    E.g.: eval $(luax env)

When compiling scripts (options `-t` and `-o`), the scripts shall
contain tags (e.g. in comments) showing how the script is used by LuaX:

- `--@MAIN`: main script (must be unique)
- `--@LOAD`: library that is `require`’d before the main script is run
  and stored in a global variable
- `--@LOAD=<global variable name>`: as `--@LOAD` but the module is
  stored in a global variable with the given name
- `--@LIB`: library that must be explicitly `require`’d by the main
  script
- `--@LIB=<new module name>`: library that is `require`’d with
  `<new module name>` instead of the source filename.

Scripts without tags are classified using a simplistic heuristic:

- if the last non empty line starts with `return` then it is a library
  (as if it contained a `@LIB` tag)
- otherwise it is the main script (as if it contained the `@MAIN` tag).

This heuristic should work for most of the Lua scripts but explicit tags
are recommended.

LuaX can also embed files that are not Lua scripts. These files are
embedded as Lua modules that return the file content as a string. In
this case, the module name if the file name.

### Examples

``` bash
# Native compilation (luax is a symlink to the luax binary of the host)
$ luax -o executable main.lua lib1.lua lib2.lua
$ ./executable      # equivalent to luax main.lua

# « Cross compilation » to MacOS x86_64
$ luax -o executable -t x86_64-macos-none main.lua lib1.lua lib2.lua

# Available targets
$ luax -t list
Targets producing standalone LuaX executables:

    x86_64-linux-musl
    x86_64-linux-gnu
    x86-linux-musl
    x86-linux-gnu
    aarch64-linux-musl
    aarch64-linux-gnu
    x86_64-windows-gnu
    x86-windows-gnu
    x86_64-macos-none
    aarch64-macos-none

Targets based on an external Lua interpreter:

    lua
    lua-luax
    luax
    pandoc
    pandoc-luax
```

## Built-in modules

The `luax` runtime comes with a few builtin modules.

Some modules are heavily inspired by [BonaLuna](http://cdelord.fr/bl)
and [lapp](http://cdelord.fr/lapp).

- [LuaX interactive usage](doc/repl.md): improved Lua REPL
- [package](doc/package.md): modified Lua package `package`
- [F](doc/F.md): functional programming inspired functions
- [L](doc/L.md): `pandoc.List` module from the Pandoc Lua interpreter
- [fs](doc/fs.md): file system management
- [sh](doc/sh.md): shell command execution
- [mathx](doc/mathx.md): complete math library for Lua
- [imath](doc/imath.md): arbitrary precision integer and rational
  arithmetic library
- [qmath](doc/qmath.md): rational number library
- [complex](doc/complex.md): math library for complex numbers based on
  C99
- [ps](doc/ps.md): Process management module
- [sys](doc/sys.md): System module
- [term](doc/term.md): Terminal manipulation module
- [crypt](doc/crypt.md): cryptography module
- [lz4](doc/lz4.md): Extremely Fast Compression algorithm
- [lpeg](doc/lpeg.md): Parsing Expression Grammars For Lua
- [luasocket](doc/luasocket.md): Network support for the Lua language
- [argparse](doc/argparse.md): Feature-rich command line parser for Lua
- [inspect](doc/inspect.md): Human-readable representation of Lua tables
- [serpent](doc/serpent.md): Lua serializer and pretty printer

## Shared libraries

LuaX is also available as a shared library. This shared library is a Lua
module that can be loaded with `require`. It provides the same modules
than the LuaX executable and can be used by a regular Lua interpreter
(e.g.: lua, pandoc, …).

E.g.:

    $ lua -l luax-x86_64-linux-gnu
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

## Pure Lua modules

LuaX modules also provides a pure Lua implementation (no LuaX
dependency). The script `lib/luax.lua` can be reused in pure Lua
programs:

- [luax.lua](doc/luax.lua.md): LuaX modules reimplemented in pure Lua
  (except LuaSocket)

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

- **[Zig](https://ziglang.org/)**: General-purpose programming language
  and toolchain for maintaining robust, optimal, and reusable software.
  ([MIT license](https://github.com/ziglang/zig/blob/master/LICENSE))
- **[Lua 5.4](http://www.lua.org)**: Copyright (C) 1994-2023 Lua.org,
  PUC-Rio ([MIT license](http://www.lua.org/license.html))
- **[Lpeg](http://www.inf.puc-rio.br/~roberto/lpeg/)**: Parsing
  Expression Grammars For Lua ([MIT
  license](http://www.lua.org/license.html))
- **[luasocket](https://github.com/diegonehab/luasocket)**: Network
  support for the Lua language ([LuaSocket 3.0
  license](https://github.com/diegonehab/luasocket/blob/master/LICENSE))
- **[inspect](https://github.com/kikito/inspect.lua)**: Human-readable
  representation of Lua tables ([MIT
  license](https://github.com/kikito/inspect.lua/blob/master/MIT-LICENSE.txt))
- **[serpent](https://github.com/pkulchenko/serpent)**: Lua serializer
  and pretty printer. ([MIT
  license](https://github.com/pkulchenko/serpent/blob/master/LICENSE))
- **[LZ4](https://github.com/lz4/lz4)**: Extremely Fast Compression
  algorithm ([License](https://github.com/lz4/lz4/blob/dev/lib/LICENSE))
- **[Argparse](https://github.com/mpeterv/argparse)**: a feature-rich
  command line parser for Lua ([MIT
  license](https://github.com/mpeterv/argparse/blob/master/LICENSE))

[^1]: `luax` is actually not a « cross compiler ».

    It just bundles Lua scripts with a precompiled LuaX runtime that can
    be run on the target with no dependency.
