<img src="luax-banner.svg" style="width:100.0%" />

# Lua eXtended

`luax` is a Lua interpreter and REPL based on Lua 5.4, augmented with
some useful packages. `luax` can also produce executable scripts from
Lua scripts.

`luax` runs on several platforms with no dependency:

- Linux (x86_64, aarch64)
- MacOS (x86_64, aarch64)
- Windows (x86_64, aarch64)

`luax` can compile scripts from and to any of these platforms. It can
produce scripts that can run everywhere Lua or LuaX is installed as well
as standalone executables containing the LuaX runtime and the Lua
scripts. The target platform can be explicitly specified to
cross-compile[^1] scripts for a supported platform.

LuaX is available on Codeberg: <https://codeberg.org/cdsoft/luax>

## Pricing

LuaX is a free and open source software. But it has a cost. It takes
time to develop, maintain and support.

To help LuaX remain free, open source and supported, users are cordially
invited to contribute financially to its development.

| LuaX price         | Europe        | United States | Rest of the World |
|--------------------|---------------|---------------|-------------------|
| Personal usage     | Free donation | Free donation | Free donation     |
| Academic usage     | €10 or more   | \$20 or more  | \$15 or more      |
| Professional usage | €20 or more   | \$40 or more  | \$25 or more      |

These prices are per month and per tools (see [`PRICING`](PRICING)).

<a href='https://liberapay.com/LuaX/donate' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://liberapay.com/assets/widgets/donate.svg' border='0' alt='Donate using Liberapay' /></a>
<a href='https://ko-fi.com/K3K11CD108' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi6.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>

Feel free to promote LuaX!

## Requirements

- [Ninja](https://ninja-build.org): to compile LuaX using the LuaX Ninja
  file
- a decent modern and programmer friendly OS…

The bootstrap script will try to install `ninja` on some known Linux
distributions (Debian, Fedora and Arch Linux) or on MacOS.

## Compilation

### Quick compilation

The script `bootstrap.sh` installs `ninja`, `zig` (if required) and
compiles LuaX. Once done, LuaX can be installed with `ninja install`.
`git` must be installed to clone the LuaX repository but it can also be
compiled from a source archive without git.

The installation path of Zig is defined in the `build.lua` file. On
Linux or MacOS, the installation path is defined by the variable
`ZIG_PATH` (`~` is replaced with `$HOME`). On Windows, the installation
path is defined by the variable `ZIG_PATH_WIN` (`~` is replaced with
`%LOCALAPPDATA%`).

``` sh
$ git clone https://codeberg.org/cdsoft/luax
$ cd luax
$ ./bootstrap.sh
$ ninja install
```

Or from a source archive (LuaX 8.9.2 or later):

``` sh
$ curl https://codeberg.org/cdsoft/luax/archive/X.Y.Z.tar.gz -o luax-X.Y.Z.tar.gz
$ tar xzf luax-X.Y.Z.tar.gz
$ cd luax
$ ./bootstrap.sh
$ ninja install
```

The latest source archives are available at
<https://codeberg.org/cdsoft/luax/tags>.

Contributions on non supported platforms are welcome.

### Compilation options

| Option | Description |
|:---|:---|
| `bang -- fast` | Optimize for speed |
| `bang -- small` | Optimize for size (default) |
| `bang -- debug` | Debug symbols kept, not optimized |
| `bang -- san` | Compile with ASan and UBSan (implies clang) and enable `LUA_USE_APICHECK` |
| `bang -- lax` | Disable strict compilation options |
| `bang -- strip` | Remove debug information from precompiled bytecode |
| `bang -- lto` | Enable LTO optimizations |
| `bang -- nolto` | Disable LTO optimizations (default) |
| `bang -- lz4` | Add LZ4 support |
| `bang -- nolz4` | No LZ4 support (default) |
| `bang -- socket` | Add socket support via luasocket |
| `bang -- nosocket` | No socket support via luasocket (default) |
| `bang -- ssl` | Add SSL support via LuaSec and OpenSSL |
| `bang -- nossl` | No SSL support via LuaSec and OpenSSL (default) |
| `bang -- cross` | Generate cross-compilers (implies compilation with zig) |
| `bang -- nocross` | Do not generate cross-compilers (default) |
| `bang -- gcc` | Compile LuaX with gcc (no cross-compilation) (default) |
| `bang -- clang` | Compile LuaX with clang (no cross-compilation) |
| `bang -- zig` | Compile LuaX with Zig |

`bang` must be run before `ninja` to change the compilation options.

`lua tools/bang.luax` can be used instead of
[bang](https://codeberg.org/cdsoft/bang) if it is not installed.

The default compilation options are `small`, `notlo`, `nossl`, `nocross`
and `gcc`.

Zig is downloaded by the ninja file or `bootstrap.sh`. gcc and clang
must be already installed.

These options can also be given to the bootstrap script. E.g.:
`./bootstrap.sh fast lto strip`.

`bootstrap.sh` also support options to choose a different build
directory:

| Option | Description |
|:---|:---|
| `-b dir` | Compile LuaX in the directory `dir` instead of the default one (`.build`) |
| `-o dir/file.ninja` | Generate the ninja file in `dir/file.ninja` instead of the default one (`build.ninja`) |

### Optional features

| Option | Description |
|:---|:---|
| `lz4` | Add the LZ4 compression module to LuaX |
| `socket` | Add the socket support (LuaSocket) to LuaX |
| `ssl` | Add the HTTPS/SSL support (LuaSec + OpenSSL) to LuaX (`ssl` implies `socket`) |

OpenSSL is not included in LuaX source. It is downloaded and recompiled
when needed. Hence an Internet connection is required to compile LuaX
with the `ssl` option.

Example:

``` sh
$ git clone https://codeberg.org/cdsoft/luax
$ cd luax
$ ./bootstrap.sh lz4 ssl
$ ninja install
```

These options are disabled by default.

Note that LuaSocket and LuaSec can also be installed apart from Luax
(e.g. with LuaRocks).

### Compilation in debug mode

LuaX can be compiled in debug mode (less optimization, debug symbols
kept in the binaries). With the `san` option, the tests are executed
with [ASan](https://clang.llvm.org/docs/AddressSanitizer.html) and
[UBSan](https://clang.llvm.org/docs/UndefinedBehaviorSanitizer.html).
They run slower but this helps finding tricky bugs.

``` sh
$ git clone https://codeberg.org/cdsoft/luax
$ cd luax
$ ./bootstrap.sh debug san    # generate build.ninja in debug mode with sanitizers
$ ninja test                  # run tests on the host
```

## Cross-compilation

`luax` can compile scripts and link them to precompiled libraries for
all supported targets.

There are two compilation methods:

- Lua payload (bytecode) appended to a precompiled LuaX loader (default
  method)
- Lua payload in a C source compiled and linked with LuaX libraries.
  This method requires a C compiler and is enabled by the `-c` option.

E.g.: to produce an executable containing the LuaX runtime for the
current host and `hello.lua`:

``` sh
$ luax compile -t native -o hello hello.lua
```

It seems on some platforms (e.g. MacOS) reading the payload in the
executable file while being executed does not work. In this case, the
payload can be added to be binary with the `-c` option. It requires a C
compiler but should work better on MacOS.

``` sh
$ luax compile -c -t native -o hello hello.lua
```

E.g.: to produce an executable containing the LuaX runtime for
`linux-x86_64-musl` and `hello.lua`:

``` sh
$ luax compile -t linux-x86_64-musl -o hello hello.lua
```

E.g.: to produce an executable with the compiled Lua bytecode with no
debug information:

``` sh
$ luax compile -s -t linux-x86_64-musl -o hello hello.lua
```

`luax compile` can compile Lua scripts to Lua bytecode. If scripts are
large they will start quickly but will run as fast as the original Lua
scripts.

## Installation

``` sh
$ ninja install                 # install luax to ~/.local/bin and ~/.local/lib
$ PREFIX=/usr ninja install     # install luax to /usr/bin and /usr/lib
```

`luax` is a single autonomous executable. It does not need to be
installed and can be copied anywhere you want.

### LuaX artifacts

`ninja install` installs:

- `$PREFIX/bin/luax`: LuaX binary
- `$PREFIX/bin/luax.lua`: a pure Lua REPL reimplementing some LuaX
  libraries, usable in any Lua 5.4 interpreter (e.g.: lua, pandoc lua,
  …)
- `$PREFIX/bin/luax-pandoc.lua`: LuaX run in a Pandoc Lua interpreter
- `$PREFIX/lib/libluax.so`: Linux LuaX shared libraries
- `$PREFIX/lib/libluax.dylib`: MacOS LuaX shared libraries
- `$PREFIX/lib/libluax.dll`: Windows LuaX shared libraries
- `$PREFIX/lib/luax.lua`: a pure Lua reimplementation of some LuaX
  libraries, usable in any Lua 5.4 interpreter.
- `$PREFIX/lib/luax.lar`: a compressed archive containing the
  precompiled LuaX runtimes for all supported platforms (if the
  cross-compilation is enabled).

## Usage

`luax` is very similar to `lua` and adds more options to compile
scripts:

    usage: luax [cmd] [options]

    Commands:
      "help"    (or "-h")   Show this help
      "version" (or "-v")   Show LuaX version
      "run"     (or none)   Run scripts
      "compile" (or "c")    Compile scripts
      "env"                 Set LuaX environment variables

    "run" options:
      -e stat         execute string 'stat'
      -i              enter interactive mode after executing 'script'
      -l name         require library 'name' into global 'name'
      -l g=name       require library 'name' into global 'g'
      -l _=name       require library 'name' (no global variable)
      -v              show version information
      --              stop handling options
      -               stop handling options and execute stdin
      script [args]   script to execute

    "compile" options:
      -t target       name of the targetted platform
      -t list         list available targets
      -o file         name the executable file to create
      -c              use a C compiler instead of the loader
      -b              compile to Lua bytecode
      -s              emit bytecode without debug information
      -k key          script encryption key
      -q              quiet compilation (error messages only)
      scripts         scripts to compile

    Environment variables:

      LUA_INIT_5_4, LUA_INIT
                    code executed before handling command line
                    options and scripts (not in compilation
                    mode). When LUA_INIT_5_4 is defined,
                    LUA_INIT is ignored.

      PATH          PATH shall contain the bin directory where
                    LuaX is installed

      LUA_PATH      LUA_PATH shall point to the lib directory
                    where the Lua implementation of LuaX
                    lbraries are installed

      LUA_CPATH     LUA_CPATH shall point to the lib directory
                    where LuaX shared libraries are installed

    PATH, LUA_PATH and LUA_CPATH can be set in .bashrc or .zshrc
    with "luax env".
    E.g.: eval $(luax env)

    "luax env" can also generate shell variables from a script.
    E.g.: eval $(luax env script.lua)

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
this case, the module name is the file name.

**Note for Windows users**: since Windows does not support shebangs, a
script `script` shall be explicitly launched with `luax` (e.g.:
`luax script`). If `script` is not found, it is searched in the
installation directory of `luax` or in `$PATH`.

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
Target                Interpreter / LuaX archive
--------------------- -------------------------
luax                  ~/.local/bin/luax
lua                   ~/.local/bin/lua
pandoc                ~/.local/bin/pandoc
native                ~/.local/lib/luax.lar
linux-x86_64          ~/.local/lib/luax.lar
linux-x86_64-musl     ~/.local/lib/luax.lar
linux-aarch64         ~/.local/lib/luax.lar
linux-aarch64-musl    ~/.local/lib/luax.lar
macos-x86_64          ~/.local/lib/luax.lar
macos-aarch64         ~/.local/lib/luax.lar
windows-x86_64        ~/.local/lib/luax.lar
```

## Built-in modules

The `luax` runtime comes with a few builtin modules.

Some modules are heavily inspired by
[BonaLuna](https://codeberg.org/cdsoft/bonaluna) and
[lapp](https://codeberg.org/cdsoft/lapp).

- [LuaX interactive usage](repl.md): improved Lua REPL
- [package](package.md): modified Lua package `package`
- [debug](debug.md): modified Lua package `debug`
- [import](import.md): import Lua scripts to user table instead of `_G`
- [F](F.md): functional programming inspired functions
- [fs](fs.md): file system management
- [sh](sh.md): shell command execution
- [mathx](mathx.md): complete math library for Lua
- [imath](imath.md): arbitrary precision integer and rational arithmetic
  library
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
- [luasec](luasec.md): add secure connections to luasocket
- [curl](curl.md), [wget](wget.md): simple curl and wget command line
  interfaces
- [argparse](argparse.md): Feature-rich command line parser for Lua
- [serpent](serpent.md): Lua serializer and pretty printer
- [cbor](cbor.md): pure Lua implementation of the CBOR
- [lar](lar.md): Simple archive format for Lua values
- [linenoise](linenoise.md): A small, portable GNU readline replacement
  with UTF-8 support
- [json](json.md): JSON Module for Lua

## Shared libraries

LuaX is also available as a shared library. This shared library is a Lua
module that can be loaded with `require`. It provides the same modules
than the LuaX executable and can be used by a regular Lua interpreter
(e.g.: lua, pandoc, …).

E.g.:

    $ lua -l libluax
    Lua 5.4.7  Copyright (C) 1994-2024 Lua.org, PUC-Rio
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

LuaX modules also provide pure Lua implementations (no LuaX dependency).
The script `lib/luax.lua` can be reused in pure Lua programs:

- [luax.lua](luax.lua.md): LuaX modules reimplemented in pure Lua
  (except LuaSocket and lpeg)

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
- **[luasec](https://github.com/lunarmodules/luasec)**: integrates with
  LuaSocket to make it easy to add secure connections to any Lua
  applications or scripts. ([LuaSec
  license](https://github.com/lunarmodules/luasec/blob/master/LICENSE))
- **[OpenSSL](https://www.openssl.org/)**: robust, commercial-grade,
  full-featured toolkit for general-purpose cryptography and secure
  communication ([Apache License
  2.0](https://github.com/openssl/openssl/blob/master/LICENSE.txt))
- **[serpent](https://github.com/pkulchenko/serpent)**: Lua serializer
  and pretty printer. ([MIT
  license](https://github.com/pkulchenko/serpent/blob/master/LICENSE))
- **[LZ4](https://github.com/lz4/lz4)**: Extremely Fast Compression
  algorithm ([License](https://github.com/lz4/lz4/blob/dev/lib/LICENSE))
- **[lzip](https://www.nongnu.org/lzip/)**: A compression library for
  the lzip format ([License](http://www.gnu.org/licenses/gpl-2.0.html))
- **[Argparse](https://github.com/mpeterv/argparse)**: a feature-rich
  command line parser for Lua ([MIT
  license](https://github.com/mpeterv/argparse/blob/master/LICENSE))
- **[Linenoise](https://github.com/yhirose/linenoise/tree/utf8-support)**:
  A minimal, zero-config, BSD licensed, readline replacement ([BSD
  license](https://github.com/antirez/linenoise/blob/master/LICENSE))
- **[dkjson.lua](http://dkolf.de/dkjson-lua/)**: JSON Module for Lua
  ([MIT license](http://www.lua.org/license.html))
- **[CBOR](https://www.zash.se/lua-cbor.html)**: pure Lua implementation
  of the CBOR
  ([License](https://code.zash.se/lua-cbor/file/tip/COPYING))

[^1]: `luax` uses `zig` to link the LuaX runtime with the Lua scripts.
    The Lua scripts are actually compiled to Lua bytecode. `luax`
    produces executables that do not require LuaX to be installed.
