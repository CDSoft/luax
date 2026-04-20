![](luax-banner.svg)

> [!IMPORTANT]
>
> This is an important rework of LuaX.
>
> Version 10 simplifies and improves several aspects compared to version 9:
>
> - Faster build system (no option, cross compilers always generated)
> - Smaller binaries
> - No more LuaSec and OpenSSL libraries (heavy to maintain, easily replaced with the HTTP functions of `curl`)
> - Bang, ypp and lsvg are now part of LuaX (more easily maintained and updated)

# Lua eXtended

`luax` is a Lua interpreter and REPL based on Lua 5.5, augmented with some
useful packages. `luax` can also produce executable scripts from Lua scripts.

`luax` runs on several platforms with no dependency:

- Linux (x86_64, aarch64)
- MacOS (x86_64, aarch64)
- Windows (x86_64, aarch64)

`luax` can compile scripts from and to any of these platforms. It can produce
scripts that can run everywhere Lua or LuaX is installed as well as
standalone executables containing the LuaX runtime and the Lua scripts. The
target platform can be explicitly specified to
cross-compile[^cross-compilation] scripts for a supported platform.

[^cross-compilation]: `luax` uses `zig` to cross-compile LuaX loaders.
    These loaders are then appended the Lua bytecode of the "compiled" scripts.
    `luax` produces executables that do not require LuaX to be installed.

LuaX is available on Codeberg: <https://codeberg.org/cdsoft/luax>

## Releases

It is strongly recommended to build LuaX from source,
as this is the only reliable way to install the exact version you need.

However, if you do require precompiled binaries,
this page offers a selection for various platforms: <https://cdelord.fr/pub>.

Note that the `bin` and `lib` directories contain prebuilt LuaX scripts to run
LuaX scripts with a restricted self-contained runtime.

## Pricing

LuaX is a free and open source software.
But it has a cost. It takes time to develop, maintain and support.

To help LuaX remain free, open source and supported,
users are cordially invited to contribute financially to its development.



<a href='https://liberapay.com/LuaX/donate' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://liberapay.com/assets/widgets/donate.svg' border='0' alt='Donate using Liberapay' /></a>
<a href='https://ko-fi.com/K3K11CD108' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi6.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>

Feel free to promote LuaX!

## Requirements

- [Ninja](https://ninja-build.org): to compile LuaX using the LuaX Ninja file
- a C compiler to bootstrap the standard Lua interpreter
- a decent modern and programming friendly OS...

## Compilation

### Quick compilation

`ninja`, `curl`, `minisign`, `tar` and `xz` are needed to compile LuaX.
They may be installed by `build.lua`.
`zig` is also downloaded by `build.lua` (used as a C cross-compiler).

Optionally, to generate the documentation and run the tests,
[Graphviz](https://graphviz.org/),
[Octave](https://octave.org/)
and [Asymptote](https://asy.marris.fr/asymptote/)
must also be installed.

First run `build.lua` to generate the Ninja build file.

Once done, LuaX can be installed with `ninja install`.
`git` must be installed to clone the LuaX repository but it can also be compiled from a source archive without git.

``` sh
$ git clone https://codeberg.org/cdsoft/luax
$ cd luax
$ ./build.lua
$ ninja install
```

Or from a source archive:

``` sh
$ curl https://codeberg.org/cdsoft/luax/archive/X.Y.Z.tar.gz -o luax-X.Y.Z.tar.gz
$ tar xzf luax-X.Y.Z.tar.gz
$ cd luax
$ ./build.lua
$ ninja install
```

The latest source archives are available at <https://codeberg.org/cdsoft/luax/tags>.

Contributions on non supported platforms are welcome.

## Cross-compilation

`luax` can compile scripts and link them to precompiled libraries for all
supported targets.

The Lua payload is compiled to Lua bytecode and appended to a precompiled LuaX loader.

E.g.: to produce an executable containing the LuaX runtime for the current host
and `hello.lua`:

``` sh
$ luax compile -t native -o hello hello.lua
```

E.g.: to produce an executable containing the LuaX runtime for `linux-x86_64-musl`
and `hello.lua`:

``` sh
$ luax compile -t linux-x86_64-musl -o hello hello.lua
```

E.g.: to produce an executable with the compiled Lua bytecode with no debug
information:

``` sh
$ luax compile -s -t linux-x86_64-musl -o hello hello.lua
```

`luax compile` can compile Lua scripts to Lua bytecode. If scripts are large they will
start quickly but will run as fast as the original Lua scripts.

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
  usable in any Lua 5.4 or 5.5 interpreter (e.g.: lua, pandoc lua, ...)
- `$PREFIX/bin/luax-pandoc.lua`: LuaX run in a Pandoc Lua interpreter
- `$PREFIX/lib/libluax.lua`: a pure Lua reimplementation of some LuaX libraries,
  usable in any Lua 5.4 or 5.5 interpreter.
- `$PREFIX/lib/libluax.xyz`: standard library and precompiled runtime used by the LuaX compiler

### Post installation command

The `postinstall` command can optionally be executed after LuaX is installed or updated.

It checks that all required files are actually installed
and removes obsolete files if any.

``` sh
$ path/to/luax postinstall [-f]
```

The `-f` option forces the removal of obsolete files without confirmation.

## Usage

`luax` is very similar to `lua` and adds more options to compile scripts:

```
usage: luax [cmd] [options]

Commands:
  "help"    (or "-h")   Show this help
  "version" (or "-v")   Show LuaX version
  "run"     (or none)   Run scripts
  "compile" (or "c")    Compile scripts
  "env"                 Set LuaX environment variables
  "postinstall"         Post install updates

"run" options:
  -e stat         execute string 'stat'
  -i              enter interactive mode after executing 'script'
  -l name         require library 'name' into global 'name'
  -l g=name       require library 'name' into global 'g'
  -l _=name       require library 'name' (no global variable)
  -v              show version information
  -W              turn warnings on
  --              stop handling options
  -               stop handling options and execute stdin
  script [args]   script to execute

"compile" options:
  -t target       name of the targetted platform
  -t list         list available targets
  -o file         name the executable file to create
  -b              compile to Lua bytecode
  -s              emit bytecode without debug information
  -k key          script encryption key
  -q              quiet compilation (error messages only)
  scripts         scripts to compile

"postinstall" options:
  -f              do not ask for confirmations

Environment variables:

  LUA_INIT_5_5, LUA_INIT
                code executed before handling command line
                options and scripts (not in compilation
                mode). When LUA_INIT_5_5 is defined,
                LUA_INIT is ignored.

  PATH          PATH shall contain the bin directory where
                LuaX is installed

  LUA_PATH      LUA_PATH shall point to the lib directory
                where the Lua implementation of LuaX
                libraries are installed

PATH and LUA_PATH can be set in .bashrc or .zshrc
with "luax env".
E.g.: eval $(luax env)

"luax env" can also generate shell variables from a script
or a TOML file.
E.g.: eval $(luax env script.lua)
```

When compiling scripts, the scripts shall contain tags
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
In this case, the module name is the file name.

**Note for Windows users**: since Windows does not support shebangs, a script
`script` shall be explicitly launched with `luax` (e.g.: `luax script`). If
`script` is not found, it is searched in the installation directory of `luax`
or in `$PATH`.

### Examples

``` bash
# Compilation (standalone executable script for LuaX)
$ luax compile -o executable main.lua lib1.lua lib2.lua
$ ./executable      # equivalent to luax main.lua

# Compilation for Lua
$ luax compile -o executable -t lua main.lua lib1.lua lib2.lua
$ ./executable      # equivalent to lua main.lua

# Compilation for Pandoc Lua
$ luax compile -o executable -t pandoc main.lua lib1.lua lib2.lua
$ ./executable      # equivalent to pandoc lua main.lua

# Available targets
$ luax compile -t list
Target                Interpreter / LuaX loader
--------------------- -------------------------
luax                  ~/.local/bin/luax
lua                   /usr/bin/lua
pandoc                ~/.local/bin/pandoc
native                ~/.local/lib/luax/luax-loader-linux-x86_64
linux-x86_64          ~/.local/lib/luax/luax-loader-linux-x86_64
linux-x86_64-musl     ~/.local/lib/luax/luax-loader-linux-x86_64-musl
linux-aarch64         ~/.local/lib/luax/luax-loader-linux-aarch64
linux-aarch64-musl    ~/.local/lib/luax/luax-loader-linux-aarch64-musl
macos-x86_64          ~/.local/lib/luax/luax-loader-macos-x86_64
macos-aarch64         ~/.local/lib/luax/luax-loader-macos-aarch64
windows-x86_64        ~/.local/lib/luax/luax-loader-windows-x86_64.exe
windows-aarch64       ~/.local/lib/luax/luax-loader-windows-aarch64.exe
```

## Built-in modules

The `luax` runtime comes with a few builtin modules.

- [LuaX interactive usage](repl.md): improved Lua REPL
- [luax-package](package.md): modified Lua package `package`
- [luax-debug](debug.md): modified Lua package `debug`
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
- [lzip](lzip.md): A compression library for the lzip format
- [tar](tar.md): A minimalistic tar archiving library
- [lpeg](lpeg.md): Parsing Expression Grammars For Lua
- [luasocket](luasocket.md): Network support for the Lua language
- [curl](curl.md): Simple curl command line interface with HTTP functions
- [argparse](argparse.md): Feature-rich command line parser for Lua
- [serpent](serpent.md): Lua serializer and pretty printer
- [cbor](cbor.md): pure Lua implementation of the CBOR
- [readline](readline.md): Command line editing functions
- [linenoise](linenoise.md): A small, portable GNU readline replacement with UTF-8 support
- [json](json.md): JSON Module for Lua
- [toml](toml.md): a pure Lua TOML parser (tinytoml)
- [tomlx](tomlx.md): a layer on top of toml with macros

## Pure Lua modules

LuaX modules also provide pure Lua implementations (no LuaX dependency). The
script `lib/libluax.lua` can be reused in pure Lua programs:

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
    https://codeberg.org/cdsoft/luax

`luax` uses other third party softwares:

- **[Zig](https://ziglang.org/)**: General-purpose programming language and
  toolchain for maintaining robust, optimal, and reusable software. ([MIT
  license](https://github.com/ziglang/zig/blob/master/LICENSE))
- **[Lua 5.5](http://www.lua.org)**: Copyright (C) 1994-2025 Lua.org, PUC-Rio
  ([MIT license](http://www.lua.org/license.html))
- **[Lpeg](http://www.inf.puc-rio.br/~roberto/lpeg/)**: Parsing Expression
  Grammars For Lua ([MIT license](http://www.lua.org/license.html))
- **[luasocket](https://github.com/diegonehab/luasocket)**: Network
  support for the Lua language ([LuaSocket 3.0
  license](https://github.com/diegonehab/luasocket/blob/master/LICENSE))
- **[serpent](https://github.com/pkulchenko/serpent)**: Lua serializer and
  pretty printer. ([MIT
  license](https://github.com/pkulchenko/serpent/blob/master/LICENSE))
- **[LZ4](https://github.com/lz4/lz4)**: Extremely Fast Compression algorithm
  ([License](https://github.com/lz4/lz4/blob/dev/lib/LICENSE))
- **[lzip](https://www.nongnu.org/lzip/)**: A compression library for the lzip
  format ([License](http://www.gnu.org/licenses/gpl-2.0.html))
- **[Argparse](https://github.com/mpeterv/argparse)**: a feature-rich command
  line parser for Lua ([MIT
  license](https://github.com/mpeterv/argparse/blob/master/LICENSE))
- **[readline](https://tiswww.case.edu/php/chet/readline/rltop.html)**:
  Command line editing functions
  [GPLv3 License](https://www.gnu.org/licenses/gpl-3.0.html)
- **[Linenoise](https://github.com/antirez/linenoise)**: A
  minimal, zero-config, BSD licensed, readline replacement ([BSD
  license](https://github.com/antirez/linenoise/blob/master/LICENSE))
- **[dkjson.lua](http://dkolf.de/dkjson-lua/)**: JSON Module for Lua
  ([MIT license](http://www.lua.org/license.html))
- **[CBOR](https://www.zash.se/lua-cbor.html)**: pure Lua implementation of the
  CBOR ([License](https://code.zash.se/lua-cbor/file/tip/COPYING))
- **[tinytoml](https://github.com/FourierTransformer/tinytoml)**: a pure Lua TOML parser
  ([MIT License](https://github.com/FourierTransformer/tinytoml?tab=MIT-1-ov-file#readme))
