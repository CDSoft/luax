# Lua eXtended

`luax` is a Lua interpretor and REPL based on Lua 5.4.4, augmented with
some useful packages. `luax` can also produces standalone executables
from Lua scripts.

`luax` runs on several platforms with no dependency:

- Linux (x86_64, i386, aarch64)
- MacOS (x86_64, aarch64)
- Windows (x86_64, i386)

`luax` can cross-compile scripts from and to any of these platforms.

## Compilation

`luax` is written in C and Lua and uses the Zig build system. Just
download `luax` (<https://github.com/CDSoft/luax>) and run `make`:

``` sh
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

`luax` is a single autonomous executable. It does not need to be
installed and can be copied anywhere you want.

### Installation of luax for all supported platforms (cross compilation support)

``` sh
$ make install-all                  # install luax to ~/.local/bin or ~/bin
$ make install-all PREFIX=/usr/bin  # install luax to /usr/bin
```

## Precompiled binaries

It is usually highly recommended to build `luax` from sources. The
latest binaries are available here:
[luax.tar.xz](http://cdelord.fr/luax/luax.tar.xz).

The Linux and Raspberry Pi binaries are linked statically with
[musl](https://musl.libc.org/) and are not dynamic executables. They
should work on any Linux distributions.

## Usage

`luax` is very similar to `lua` and adds more options to compile
scripts:

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

When compiling scripts (options `-t` and `-o`), the main script shall be
the first one. Other scripts are libraries that can be loaded by the
main script.

### Examples

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

Some modules are heavily inspired by [BonaLuna](http://cdelord.fr/bl)
and [lapp](http://cdelord.fr/lapp).

- [LuaX interactive usage](repl.md): improved Lua REPL
- [fun](fun.md): functional programming inspired function
- [fs](fs.md): file system management
- [sh](sh.md): shell command execution
- [mathx](mathx.md): complete math library for Lua
- [imath](imath.md): arbitrary precision integer and rational arithmetic
  library
- [qmath](qmath.md): rational number library
- [complex](complex.md): math library for complex numbers based on C99
- [ps](ps.md): Process management module
- [sys](sys.md): System module
- [crypt](crypt.md): cryptography module
- [lz4](lz4.md): Extremely Fast Compression algorithm
- [lpeg](lpeg.md): Parsing Expression Grammars For Lua
- [linenoise](linenoise.md): light readline alternative
- [luasocket](luasocket.md): Network support for the Lua language
- [inspect](inspect.md): Human-readable representation of Lua tables

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

- **[Zig 0.9.1](https://ziglang.org/)**: General-purpose programming
  language and toolchain for maintaining robust, optimal, and reusable
  software. ([MIT
  license](https://github.com/ziglang/zig/blob/master/LICENSE))
- **[Lua 5.4](http://www.lua.org)**: Copyright (C) 1994-2022 Lua.org,
  PUC-Rio ([MIT license](http://www.lua.org/license.html))
- **[Lpeg](http://www.inf.puc-rio.br/~roberto/lpeg/)**: Parsing
  Expression Grammars For Lua ([MIT
  license](http://www.lua.org/license.html))
- **[luasocket](https://github.com/diegonehab/luasocket)**: Network
  support for the Lua language ([LuaSocket 3.0
  license](https://github.com/diegonehab/luasocket/blob/master/LICENSE))
- **[linenoise](https://github.com/antirez/linenoise)**: A small
  self-contained alternative to readline and libedit ([BSD-2-Clause
  license](https://github.com/antirez/linenoise/blob/master/LICENSE))
- **[inspect](https://github.com/kikito/inspect.lua)**: Human-readable
  representation of Lua tables ([MIT
  license](https://github.com/kikito/inspect.lua/blob/master/MIT-LICENSE.txt))
- **[TinyCrypt](https://github.com/intel/tinycrypt)**: tinycrypt is a
  library of cryptographic algorithms with a focus on small, simple
  implementation
  ([License](https://github.com/intel/tinycrypt/blob/master/LICENSE))
- **[LZ4](https://github.com/lz4/lz4)**: Extremely Fast Compression
  algorithm ([License](https://github.com/lz4/lz4/blob/dev/lib/LICENSE))
