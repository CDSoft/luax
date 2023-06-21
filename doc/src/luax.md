---
title: Lua eXtended
author: Christophe Delord
---

![](luax-banner.svg){width=100%}

# Lua eXtended

`luax` is a Lua interpreter and REPL based on Lua 5.4, augmented with some
useful packages. `luax` can also produces standalone executables from Lua
scripts.

`luax` runs on several platforms with no dependency:

- Linux (x86_64, i386, aarch64)
- MacOS (x86_64, aarch64)
- Windows (x86_64, i386)

`luax` can « cross-compile[^cross] » scripts from and to any of these platforms.

[^cross]: `luax` is actually not a « cross compiler ».

    It just bundles Lua scripts with a precompiled LuaX runtime that can be run
    on the target with no dependency.

## Compilation

`luax` is written in C and Lua and uses the Zig build system. Just download
`luax` (<https://github.com/CDSoft/luax>) and run `make`:

```sh
$ git clone https://github.com/CDSoft/luax
$ cd luax
$ make              # compile for the host
$ make all          # compile for all known targets (« cross compilation »)
$ make test         # run tests on the host
$ make doc          # generate LuaX documentation
```

**Note**: `make` will download a Zig compiler.

### Precompiled LuaX binaries

In case precompiled binaries are needed (GNU/Linux, MacOS, Windows),
some can be found at [cdelord.fr/pub](http://cdelord.fr/pub).
These archives contain LuaX as well as some other softwares more or less related to LuaX.

**Warning**: There are Linux binaries linked with musl and glibc. The musl
binaries are platform independent but can not load shared libraries. The glibc
binaries can load shared libraries but may depend on some specific glibc
versions on the host.

## Installation

### Installation of luax for the current host only

``` sh
$ make install              # install luax to ~/.local/bin or ~/bin
$ make install PREFIX=/usr  # install luax to /usr/bin
```

`luax` is a single autonomous executable.
It does not need to be installed and can be copied anywhere you want.

### Installation of luax for all supported platforms (« cross compilation » support)

``` sh
$ make install-all              # install luax to ~/.local/bin or ~/bin
$ make install-all PREFIX=/usr  # install luax to /usr/bin
```

### LuaX artifacts

`make install` and `make install-all` install:

- `$PREFIX/bin/luax`: symbolic link to the LuaX binary for the host
- `$PREFIX/bin/luax-<ARCH>-<OS>-<LIBC>`: LuaX binary for a specific platform
- `$PREFIX/bin/luax-pandoc`: LuaX run in a Pandoc Lua interpreter
- `$PREFIX/bin/luax-lua`: a pure Lua REPL reimplementing some LuaX libraries,
  usable in any Lua 5.4 interpreter (e.g.: lua, pandoc lua, ...)
- `$PREFIX/lib/libluax-<ARCH>-<OS>-<LIBC>.so`: Linux LuaX shared libraries
- `$PREFIX/lib/libluax-<ARCH>-<OS>-<LIBC>.dylib`: MacOS LuaX shared libraries
- `$PREFIX/lib/libluax-<ARCH>-<OS>-<LIBC>.dll`: Windows LuaX shared libraries
- `$PREFIX/lib/luax.lua`: a pure Lua reimplementation of some LuaX libraries,
  usable in any Lua 5.4 interpreter.

## Usage

`luax` is very similar to `lua` and adds more options to compile scripts:

```
@sh(fs.join(os.getenv'BUILD_BIN', 'luax'), '-h')
    : lines()
    : drop_while(function(l) return not l:match"^usage:" end)
    : unlines()
    : trim()
```

When compiling scripts (options `-t` and `-o`), the scripts shall contain tags
(e.g. in comments) showing how the script is used by LuaX:

- `--@MAIN`: main script (must be unique)
- `--@LOAD`: library that is `require`'d before the main script is run and
  stored in a global variable
- `--@LIB`: library that must be explicitly `require`'d by the main script
- `--@NAME=<new module name>`: library that is `require`'d with `<new module name>`
  instead of the source filename.

Scripts without tags are classified using a simplistic heuristic:

- if the last non empty line starts with `return` then it is a library (as if
  it contained a `@LIB` tag)
- otherwise it is the main script (as if it contained the `@MAIN` tag).

This heuristic should work for most of the Lua scripts but explicit tags are
recommended.

### Examples

``` bash
# Native compilation (luax is a symlink to the luax binary of the host)
$ luax -o executable main.lua lib1.lua lib2.lua
$ ./executable      # equivalent to luax main.lua

# « Cross compilation » to MacOS x86_64
$ luax -o executable -t x86_64-macos-gnu main.lua lib1.lua lib2.lua

# Available targets
$ luax -t list
@sh("PATH="..os.getenv'BUILD_BIN', 'luax', '-t list')
    : lines()
    : map(function(l)
        return l:match "^    "
            and "    "..l:words():head()
            or l
    end)
```

## Built-in modules

The `luax` runtime comes with a few builtin modules.

Some modules are heavily inspired by [BonaLuna](http://cdelord.fr/bl) and
[lapp](http://cdelord.fr/lapp).

- [LuaX interactive usage](repl.md): improved Lua REPL
- [F](F.md): functional programming inspired functions
- [L](L.md): `pandoc.List` module from the Pandoc Lua interpreter
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
- [lpeg](lpeg.md): Parsing Expression Grammars For Lua
- [luasocket](luasocket.md): Network support for the Lua language
- [argparse](argparse.md): Feature-rich command line parser for Lua
- [inspect](inspect.md): Human-readable representation of Lua tables
- [serpent](serpent.md): Lua serializer and pretty printer

## Shared libraries

LuaX is also available as a shared library. This shared library is a Lua module
that can be loaded with `require`. It provides the same modules than the LuaX
executable and can be used by a regular Lua interpreter (e.g.: lua, pandoc,
...).

E.g.:

```
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
```

## Pure Lua modules

LuaX modules also provides a pure Lua implementation (no LuaX dependency). The
script `lib/luax.lua` can be reused in pure Lua programs:

- [luax.lua](luax.lua.md): LuaX modules reimplemented in pure Lua (except
  LuaSocket)

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

* **[Zig](https://ziglang.org/)**: General-purpose programming language
  and toolchain for maintaining robust, optimal, and reusable software. ([MIT
  license](https://github.com/ziglang/zig/blob/master/LICENSE))
* **[Lua 5.4](http://www.lua.org)**: Copyright (C) 1994-2022 Lua.org, PUC-Rio
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
- **[Argparse](https://github.com/mpeterv/argparse)**: a feature-rich
  command line parser for Lua ([MIT
  license](https://github.com/mpeterv/argparse/blob/master/LICENSE))
