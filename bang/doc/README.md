<img src="bang-banner.svg" style="width:100%" />

BANG (Bang Automates Ninja Generation)
======================================

Bang is a [Ninja](https://ninja-build.org) file generator scriptable in [LuaX](https://codeberg.org/cdsoft/luax).

Releases
========

It is strongly recommended to build Bang from source,
as this is the only reliable way to install the exact version you need.

However, if you do require precompiled binaries,
this page offers a selection for various platforms: <https://cdelord.fr/pub>.

Note that the `bin` directory contains prebuilt Bang scripts
that can run with a Lua or LuaX interpreter.

Pricing
=======

Bang is a free and open source software.
But it has a cost. It takes time to develop, maintain and support.

To help Bang remain free, open source and supported,
users are cordially invited to contribute financially to its development.

<a href='https://liberapay.com/LuaX/donate' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://liberapay.com/assets/widgets/donate.svg' border='0' alt='Donate using Liberapay' /></a>
<a href='https://ko-fi.com/K3K11CD108' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi6.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>

Feel free to promote Bang!

Installation
============

Bang is part of [LuaX](https://codeberg.org/cdsoft/luax).

## Pure Lua implementation

Bang also comes with a pure Lua implementation for environments where LuaX can not be executed.
In this case `$PREFIX/bin/bang.lua` can be executed with any standard Lua 5.4 interpreter.

> [!NOTE]
> `bang.lua` may be slower than `bang`,
> especially when dealing with a large amount of source files.

Usage
=====

```
$ bang -h
Usage: bang [-h] [-v] [-q] [-g cmd] [-b builddir] [-o output]
       [<input>]

BANG (Bang Automates Ninja Generation)

Bang is a Ninja build file generator scriptable in LuaX.

Arguments after "--" are given to the input script.

Arguments:
   input                 Lua script (default: build.lua)

Options:
   -h, --help            Show this help message and exit.
   -v                    Print Bang version
   -q                    Quiet mode (no output on stdout)
   -g cmd                Set a custom command for the generator rule
   -b builddir           Build directory (builddir variable)
   -o output             Output file (default: build.ninja)

For more information, see https://codeberg.org/cdsoft/luax
```

* `bang` reads `build.lua` and produces `build.ninja`.
* `bang input.lua -o output.ninja` reads `input.lua` and produces `output.ninja`.

## Ninja functions

### Comments

`bang` can add comments to the Ninja file:

``` lua
comment "This is a comment added to the Ninja file"
```

`section` adds comments separated by horizontal lines:

``` lua
section [[
A large title
that can run on several lines
]]
```

### Variables

`var` adds a new variable definition:

``` lua
var "varname" "string value"
var "varname" (number)
var "varname" {"word_1", "word_2", ...} -- will produce `varname = word_1 word_2 ...`
```

`var` returns the name of the variable (prefixed with `"$"`).

The global variable `vars` is a table containing a copy of all the Ninja variables defined by the `var` function.
`vars` redefines the `%` operator. It takes a string and expands all Ninja variables (i.e. prefixed with `"$"`).

``` lua
var "foo" "xyz"
...
vars.foo    -- "xyz"
vars["foo"] -- same as vars.foo
vars%"$foo/bar" -- "xyz/bar"
```

> [!NOTE]
> the special variable `builddir` can be redefined by the `-b` option.
> Its default value is `".build"`.

### Ninja required version

The special variable `ninja_required_version` shall be set by the `ninja_required_version` function.
`ninja_required_version` will change the default required version only if the script requires a higher version.

``` lua
ninja_required_version "1.42"
```

### Rules

`rule` adds a new rule definition:

``` lua
rule "rule_name" {
    description = "...",
    command = "...",
    -- ...
}
```

Variable values can be strings or lists of strings.
Lists of strings are flattened and concatenated (separated with spaces).

Rules can defined variables (see [Rule variables](https://ninja-build.org/manual.html#ref_rule)).

Bang allows some build statement variables to be defined at the rule level:

- `implicit_in`: list of implicit inputs common to all build statements
- `implicit_out`: list of implicit outputs common to all build statements
- `order_only_deps`: list of order-only dependencies common to all build statements

These variables are added at the beginning of the corresponding variables
in the build statements that use this rule.

The `rule` function returns the name of the rule (`"rule_name"`).

### Build statements

`build` adds a new build statement:

``` lua
build "outputs" { "rule_name", "inputs" }
```

generates the build statement `build outputs: rule_name inputs`.
The first word of the input list (`rule_name`) shall be the rule name applied by the build statement.

The build statement can be added some variable definitions in the `inputs` table:

``` lua
build "outputs" { "rule_name", "inputs",
    varname = "value",
    -- ...
}
```

There are reserved variable names for bang to specify
implicit inputs and outputs, dependency orders and validation statements:

``` lua
build "outputs" { "rule_name", "inputs",
    implicit_out = "implicit outputs",
    implicit_in = "implicit inputs",
    order_only_deps = "order-only dependencies",
    validations = "build statements used as validations",
    -- ...
}
```

The `build` function returns the outputs (`"outputs"`),
as a string if `outputs` contains a single output
or a list of string otherwise.

The `build.files` function returns the current list of outputs of all previous `build` calls:

- `build.files()`: list of all output files
- `build.files(dir)`: list of all output files written in the directory `dir`
- `build.files(predicate)`: list of all output files that match the predicate `predicate`
  (`predicate` takes two arguments: the name of the file and the name of the rule that generates the file)

### Rules embedded in build statements

Some rules are specific to a single output and are used once.
This leads to write pairs of rules and build statements.

Bang can merge rules and build statements into a single build statement
containing the definition of the associated rule.

A build statement with a `command` variable is split into two parts:

1. a rule with all rule variables found in the build statement definition
2. a build statement with the remaining variables

In this case, the build statement definition does not contain any rule name.

E.g.:

``` lua
build "output" { "inputs",
    command = "...",
}
```

is internally translated into:

``` lua
rule "output" {
    command = "...",
}

build "output" { "output", "inputs" }
```

> [!NOTE]
> the rule name is the output name where special characters are replaced with underscores.

### Pools

`pool` adds a pool definition:

``` lua
pool "name" {
    depth = pool_depth
}
```

The `pool` function returns the name of the pool (`"pool_name"`).

### Default targets

`default` adds targets to the default target:

``` lua
default "target1"
default {"target2", "target3"}
```

> [!NOTE]
> if no custom target is defined and if there are help, install or clean targets,
> bang will generate an explicit default target with all targets, except from help, install and clean targets.

### Phony targets

`phony` is a shortcut to `build` that uses the `phony` rule:

``` lua
phony "all" {"target1", "target2"}
-- same as
build "all" {"phony", "target1", "target2"}
```

## Bang variables

### Bang arguments

The command line arguments of bang are stored in a global table named `bang`.
This table contains:

- `bang.input`: name of the Lua input script
- `bang.output`: name of the output Ninja file

### Build script arguments

Arguments after "--" are given to the input script in the global `arg` table.

## Bang functions

### Version

Bang can set a `version` variable and check it matches the latest git tag (when in a git repository).
The curried function `version` takes a version and optionally a date and sets the `version` and `date` variables.

``` lua
version "X.Y.Z" -- equivalent to var "version" "X.Y.Z", but also checks the latest git tag

version "X.Y.Z" "Y/M/D" -- also add var "date" "Y/M/D"
```

The goal of the `version` function is to be able to set/get the version,
even if the project is not a git repository
(e.g. to compile a project from a git archive or any other kind of archive).

### Accumulations

Bang can accumulate names (rules, targets, ...) in a list
that can later be used to define other rules or build statements.

A standard way to do this in Lua would use a Lua table and `table.concat` or the `list[#list+1]` pattern.
Bang provides a simple function to simplify this usage:

``` lua
my_list = {}
-- ...
acc(my_list) "item1"
acc(my_list) {"item2", "item3"}
--...
my_list -- contains {"item1", {"item2", "item3"}}
```

### Case expressions

The `case` function provides a switch-like structure to simplify conditional expressions.
`case` is a curried function that takes a value (generally a string) and a table.
It searches for the value in the keys of the table and returns the associated value.
If the key is not found it returns the value associated to the `Nil` key or `nil`.

E.g.:

``` lua
local cflags = {
    case(mode) {
        debug   = "-g -Og",
        release = "-s -O3",
        [Nil]   = Nil,  -- equivalent to [Nil] = {}
    }
}
```

**Note**: `Nil` is a special value that can be used to represent nothing (no
value) in a list. `Nil` is ignored by bang.

### File listing

The `ls` function lists files in a directory.
It returns a list of filenames,
with the metatable of [LuaX F lists](https://codeberg.org/cdsoft/luax/blob/master/doc/F.md).

- `ls "path"`: list of file names in `path`
- `ls "path/*.c"`: list of file names matching the "`*.c`" pattern in `path`
- `ls "path/**"`: recursive list of file names in `path`
- `ls "path/**.c"`: recursive list of file names matching the "`*.c`" pattern in `path`

E.g.:

``` lua
ls "doc/*.md"
: foreach(function(doc)
    build (doc:chext".pdf") { "md_to_pdf", doc }
end)
-- where md_to_pdf is a rule to convert Markdown files to PDF
```

### Dynamic file creation

The `file` function creates new files.
It returns a callable object to add text to a file (note that the `write` method is deprecated).
The file is actually written when bang exits successfully.

``` lua
file "name" "content"
```

The file can be generated incrementally by calling the file object several times:

``` lua
f = file "name"
-- ...
f "Line 1\n"
-- ...
f "Line 2\n"
-- ...
```

The `file` function returns the name of the file.
It can thus be used in a Lua list.
E.g. to generate a source file containing a version number:

``` lua
local sources = {
    ls "src/*.lua",
    file "src/version" { vars.version },
}
```

### Pipes

It is common in Makefiles to write commands with pipes.
But pipes can be error prone since only the failure of the last process is captured by default.
A simple solution (for Makefiles or Ninja files) is to chain several rules.

The `pipe` function takes a list of rules and returns a function that applies all the rules,
in the order of the list. This function takes two parameters: the output and the inputs of the pipe.

Intermediate outputs are stored in `$builddir/tmp`
(this directory can be changed by adding a `builddir` attribute to the rule list).
If a rule name contains a dot, its « extension » is used to name intermediate outputs.
Otherwise the extension is that of the input file
(note that if the extension is `".in"`, it is considered as a file to be preprocessed
and the `".in"` extension is removed).

E.g.:

``` lua
rule "ypp.md"     { command = "ypp $in -o $out" }
rule "panda.html" { command = "panda $in -o $out", implicit_in = "foo.css" }

local ypp_then_panda = pipe { "ypp.md", "panda.md" }

ypp_then_panda "$builddir/doc/mydoc.html" "doc/mydoc.md"
```

is equivalent to:

``` lua
build "$builddir/tmp/doc/mydoc.md" { "ypp.md", "doc/mydoc.md" }
build "$builddir/doc/mydoc.html"   { "panda.html", "$builddir/tmp/doc/mydoc.md" }
```

Since `rule` returns the name of the rule, this can also be written as:

``` lua
local ypp_then_panda = pipe {
    rule "ypp.md"     { command = "ypp $in -o $out" },
    rule "panda.html" { command = "panda $in -o $out", implicit_in = "foo.css" },
}
```

The input list can contain variable definitions. These variables are added to
**all** build statements, except for `implicit_in` and `implicit_out` that are
added respectively to the first and last build statements only.

e.g.:

``` lua
ypp_then_panda "out.html" { "in.md",
    implicit_in = "foo.in",
    implicit_out = "foo.out",
    other_var = "42",
}
```

is equivalent to:

``` lua
build "$builddir/tmp/doc/out-1.md" { "ypp.md", "doc/in.md",
    implicit_in = "foo.in",
    other_var = "42",
}
build "out.html" { "panda.html", "$builddir/tmp/doc/out-1.md",
    implicit_out = "foo.out",
    other_var = "42",
}
```

### Source preprocessor

Sometimes source files must be preprocessed before usage (configuration, compilation, documentation...).

The `prepro` function takes a list of source files and generates a preprocessed file in the build directory.
It returns the list of preprocessed file names, which can then be used by other builders
(note that if the input file name extension is `".in"`, it is considered as a file to be preprocessed
and the `".in"` extension is removed).

E.g.:

``` lua
build.cc:executable "$builddir/foo" {
    ls "src/*.c",
    prepro { ls "src/*.c.in" },
    implicit_in = prepro { ls "src/*.h.in" },
}
```

The default preprocessor writes files in the `"$builddir"` directory and uses `build.ypp` as a preprocessor.
The `new` method builds a new preprocessor and overloads these parameters using a table with two optional fields:

- `dir`: new destination directory
- `pp`: new preprocessor

E.g.:

``` lua
local new_prepro = prepro:new {
    dir = "$builddir/tmp"
    pp = build.ypp : new "ypp-prepro"
        : add "flags" { build.yppvars { X="x", Y="y" } }
}

build.cc:executable "$builddir/foo" {
    ls "src/*.c",
    new_prepro { ls "src/*.c.in" },
    implicit_in = new_prepro { ls "src/*.h.in" },
}
```

### Clean

Bang can generate targets to clean the generated files.
The `clean` function takes a directory name that shall be deleted by `ninja clean`.

``` lua
clean "$builddir"   -- `ninja clean` cleans $builddir
clean "tmp/foo"     -- `ninja clean` cleans tmp/foo
```

`clean` defines the target `clean` (run by `ninja clean`)
and a line in the help message (see `ninja help`).

In the same vein, `clean.mrproper` takes directories to clean with `ninja mrproper`.

### Install

Bang can generate targets to install files outside the build directories.
The `install` function adds targets to be installed with `ninja install`

The default installation prefix can be set by `install.prefix`:

``` lua
install.prefix "$$HOME/foo/bar"     -- `ninja install` installs to ~/foo/bar
```

The default prefix in `~/.local`.

It can be overridden by the `PREFIX` environment variable when calling Ninja. E.g.:

``` bash
$ PREFIX=~/bar/foo ninja install
```

Artifacts are added to the list of files to be installed by the function `install`.
This function takes the name of the destination directory, relative to the prefix and the file to be installed.

``` lua
install "bin" "$builddir/bang" -- installs bang to $PREFIX/bin/
```

`install` defines the target `install` (run by `ninja install`)
and a line in the help message (see `ninja help`).

Additionally the `DESTDIR` environment variable can be set to do a staged install target (e.g. for packaging).
`DESTDIR` is supported on Linux and MacOS only.
Note that the default prefix is not compatible with `DESTDIR` and must be redefined when `DESTDIR` is used.

``` bash
$ DESTDIR=/foo PREFIX=/opt/xxx ninja install # installs files to `$DESTDIR$PREFIX` (`/foo/opt/xxx`)
```

### Help

Bang can generate an help message (stored in a file next to the Ninja file) displayed by `ninja help`.

The help message is composed of three parts:

- a description of the Ninja file
- a list of targets with their descriptions
- an epilogue

The description and epilogue are defined by the `help.description` and `help.epilog` (or `help.epilogue`) functions.
Targets can be added by the `help` function. It takes the name of a target and its description.

``` lua
help.description "A super useful Ninja file"
help.epilog "See https://codeberg.org/cdsoft/luax"
-- ...
help "compile" "Compile every thing"
-- ...
```

> [!NOTE]
> the `clean` and `install` target are automatically documented
> by the `clean` and `install` functions.

### Generator

Bang generates a generator rule to update the Ninja file when the build description changes.
This behaviour can be customized or disabled with the `generator` function:

- `generator(true)`: bang adds a generator rule at the end of the ninja file (default behaviour)
- `generator(false)`: bang does not add a generator rule
- `generator(t)`: if `t` is a table, bang adds a generator rule with the additional variables defined in `t`

The generator rule runs bang with the same options than the initial bang command.

E.g.:

``` lua
generator {
    implicit_in = { "foo", "bar" },
}
```

In this example, the generator statement will be executed if the Lua script has
changed as well as `foo` and `bar`.

## Higher level build modules

### C compilers

The module `C` creates C compilation objects.
This module is available as a `build` function metamethod.

The module itself is a default compiler that should works on most Linux and MacOS systems
and uses `cc`.

A new compiler can be created by calling the `new` method of an existing compiler with a new name
and changing some options. E.g.:

``` lua
local my_compiler = build.C:new "my_compiler"   -- creates a new C compiler named "my_compiler"
    : set "cc" "gcc"                            -- compiler command
    : add "cflags" { "-O2", "-Iinclude" }       -- compilation flags
    : add "ldlibs" "-lm"                        -- additional libraries
```

A compiler has two methods to modify options:

- `set` changes the value of an option
- `add` adds values to the current value of an option
- `insert` adds values before the current value of an option

| Option        | Description                               | Default value                     |
| ------------- | ----------------------------------------- | --------------------------------- |
| `builddir`    | Build dir for temporary files             | `"$builddir"`                     |
| `cc`          | Compilation command                       | `"cc"`                            |
| `cflags`      | Compilation options                       | `{"-c", "-MD -MF $depfile"}`      |
| `cargs`       | Input and output                          | `"$in -o $out"`                   |
| `depfile`     | Dependency file name                      | `"$out.d"`                        |
| `cvalid`      | Validation rule                           | `{}`                              |
| `ar`          | Archive command (static libraries)        | `"ar"`                            |
| `aflags`      | Archive flags                             | `"-crs"`                          |
| `aargs`       | Inputs and output                         | `"$in -o $out"`                   |
| `so`          | Link command (dynamic libraries)          | `"cc"`                            |
| `soflags`     | Link options                              | `"-shared"`                       |
| `soargs`      | Inputs and output                         | `"$in -o $out"`                   |
| `solibs`      | Additional libraries (e.g. `"-lm"`)       | `{}`                              |
| `ld`          | Link command (executables)                | `"cc"`                            |
| `ldflags`     | Link options                              | `{}`                              |
| `ldargs`      | Inputs and output                         | `"$in -o $out"`                   |
| `ldlibs`      | Additional libraries (e.g. `"-lm"`)       | `{}`                              |
| `c_exts`      | List of C source extensions               | `{ ".c" }`                        |
| `o_ext`       | Object file extension                     | `".o"`                            |
| `a_ext`       | Archive file extension                    | `".a"`                            |
| `so_ext`      | Dynamic library file extension            | `".so"`, `".dylib"` or "`.dll`"   |
| `exe_ext`     | Executable file extension                 | `""` or `".exe"`                  |
| `implicit_in` | Implicit inputs (e.g. custom compiler)    | `Nil`                             |

A compiler can compile a single C source as well as complete libraries and executables.
Inputs of libraries or executables can be C sources
(which will be compiled in a subdirectory of `builddir`)
or other static libraries.

Examples:

``` lua
-- Compilation of a single source file
local obj_file = my_compiler:compile "$builddir/file.o" "file.c"

-- Creation of a static library
local lib_a = my_compiler:static_lib "$builddir/lib.a" {
    obj_file,       -- already compiled
    ls "lib/*.c",   -- compile and archive all sources in the lib directory
}

-- Creation of a dynamic library
local lib_so = my_compiler:dynamic_lib "$builddir/lib.so" {
    lib_a,
    ls "dynlib/*.c",
}

-- Creation of an executable file
local exe = my_compiler:executable "$builddir/file.exe" {
    lib_a,
    "src/main.c",
}

-- Same with an all-in-one statement
local exe = my_compiler:executable "$builddir/file.exe" {
    "file.c",
    ls "lib/*.c",
    "src/main.c",
}

-- The `__call` metamethod is a shortcut to the `executable` method
local exe = my_compiler "$builddir/file.exe" {
    "file.c",
    ls "lib/*.c",
    "src/main.c",
}
```

Bang also defines a function to generate a `compile_flags.txt` file
in the same directory than `build.ninja` which path may be changed by the `-o` option.
This function works pretty much like the `file` function, saving one option per line.
It returns the flag list.

``` lua
build.compile_flags {
    "-DFOO=bar",
    "-I$builddir/inc",
    ...
}
```

The `C` module predefines some C and C++ compilers (cc, gcc, clang and zig).
These compilers are also available as `build` metamethods.

| Compiler                              | Language  | Compiler  | Target                |
|---------------------------------------|-----------|-----------|-----------------------|
| `build.cc`                            | C         | `cc`      | host                  |
| `build.gcc`                           | C         | `gcc`     | host                  |
| `build.clang`                         | C         | `clang`   | host                  |
| `build.zigcc`                         | C         | `zig cc`  | host                  |
| `build.zigcc["linux-x86_64"]`         | C         | `zig cc`  | `linux-x86_64`        |
| `build.zigcc["linux-x86_64-musl"]`    | C         | `zig cc`  | `linux-x86_64-musl`   |
| `build.zigcc["linux-aarch64"]`        | C         | `zig cc`  | `linux-aarch64`       |
| `build.zigcc["linux-aarch64-musl"]`   | C         | `zig cc`  | `linux-aarch64-musl`  |
| `build.zigcc["macos-x86_64"]`         | C         | `zig cc`  | `macos-x86_64`        |
| `build.zigcc["macos-aarch64"]`        | C         | `zig cc`  | `macos-aarch64`       |
| `build.zigcc["windows-x86_64"]`       | C         | `zig cc`  | `windows-x86_64`      |
| `build.zigcc["windows-aarch64"]`      | C         | `zig cc`  | `windows-aarch64`     |
| `build.cpp`                           | C++       | `c++`     | host                  |
| `build.gpp`                           | C++       | `gc++`    | host                  |
| `build.clangpp`                       | C++       | `clang++` | host                  |
| `build.zigcpp`                        | C++       | `zig c++` | host                  |
| `build.zigcpp["linux-x86_64"]`        | C++       | `zig c++` | `linux-x86_64`        |
| `build.zigcpp["linux-x86_64-musl"]`   | C++       | `zig c++` | `linux-x86_64-musl`   |
| `build.zigcpp["linux-aarch64"]`       | C++       | `zig c++` | `linux-aarch64`       |
| `build.zigcpp["linux-aarch64-musl"]`  | C++       | `zig c++` | `linux-aarch64-musl`  |
| `build.zigcpp["macos-x86_64"]`        | C++       | `zig c++` | `macos-x86_64`        |
| `build.zigcpp["macos-aarch64"]`       | C++       | `zig c++` | `macos-aarch64`       |
| `build.zigcpp["windows-x86_64"]`      | C++       | `zig c++` | `windows-x86_64`      |
| `build.zigcpp["windows-aarch64"]`     | C++       | `zig c++` | `windows-aarch64`     |

### LuaX compilers

The module `luax` creates LuaX compilation objects.
This module is available as a `build` function metamethod.

The module itself is a default compiler that generates a Lua script executable by `luax`.

A new compiler can be created by calling the `new` method of an existing compiler with a new name
and changing some options. E.g.:

``` lua
local luaxq = build.luax:new "luax-q"   -- creates a new LuaX compiler named "luax-q"
    : add "flags" "-q"                  -- add some compilation flags
```

A compiler has four methods to modify options:

- `set` changes the value of an option
- `add` adds values to the current value of an option
- `insert` adds values before the current value of an option
- `nocc` (No C Compiler) disables LuaX compilation with a C compiler.
  By default, the `-c` option is added to LuaX flags.
  This method removes this flag.

The module also provides the methods `set_global`, `add_global`, `insert_global` and `nocc`
to add flags to all builtin LuaX compilers.

| Option        | Description                               | Default value                     |
| ------------- | ----------------------------------------- | --------------------------------- |
| `luax`        | LuaX binary to use to compile scripts     | `"luax"`                          |
| `target`      | Name of the target[^targets]              | `"luax"`                          |
| `flags`       | Compilation options                       | `{}`                              |
| `implicit_in` | Implicit inputs (e.g. custom compiler)    | `Nil`                             |

[^targets]: The available LuaX targets can be listed with `luax compile -t list`.

Examples:

``` lua
-- make all LuaX compiler silent
build.luax.add_global "flags" "-q"

-- Compile hello.lua and some libs to a linux-x86_64-musl executable
build.luax["linux-x86_64-musl"] "hello" { "hello.lua", "lib1.lua", "lib2.lua" }
```

### Builders

The `build` function has methods to create new builder objects
(note that these methods are also available in the "builders" module).

The `build` metamethods contain some predefined builders:

| Builder                   | Description                                                                                           |
| ------------------------- | ----------------------------------------------------------------------------------------------------- |
| `build.cat`               | File concatenation.                                                                                   |
| `build.cp`                | Copy a file.                                                                                          |
| `build.ypp`               | Preprocess a file with [ypp](https://codeberg.org/cdsoft/luax).                                        |
| `build.ypp-pandoc`        | Preprocess a file with [ypp](https://codeberg.org/cdsoft/luax) with the Pandoc Lua interpreter.        |
| `build.pandoc`            | Convert a file with [pandoc](https://pandoc.org).                                                     |
| `build.pandoc_gfm`        | Convert a file with [pandoc](https://pandoc.org) for Github.                                          |
| `build.panda`             | Convert a file with [panda](https://codeberg.org/cdsoft/panda).                                       |
| `build.panda_gfm`         | Convert a file with [panda](https://codeberg.org/cdsoft/panda) for Github.                            |
| `build.typst`             | Convert a file with [typst](https://typst.app).                                                       |
| `build.graphviz.prog.img` | [Graphviz](https://graphviz.org/) image rendered with *prog*[^graphviz] as an *img*[^img] image.      |
| `build.plantuml.img`      | [PlantUML](https://plantuml.com) image rendered as an *img*[^img] image.                              |
| `build.ditaa.img`         | [Ditaa](https://ditaa.sourceforge.net/) image rendered as an *img*[^img] image.                       |
| `build.asymptote.img`     | [Asymptote](https://asymptote.sourceforge.io/) image rendered as an *img*[^img] image.                |
| `build.mermaid.img`       | [Mermaid](https://mermaid.js.org/) image rendered as an *img*[^img] image.                            |
| `build.blockdiag.img`     | [Blockdiag](http://blockdiag.com/en/) image rendered with `blockdiag` as an *img*[^img] image.        |
| `build.blockdiag.prog.img`| [Blockdiag](http://blockdiag.com/en/) image rendered with *prog*[^blockdiag] as an *img*[^img] image. |
| `build.gnuplot.img`       | [Gnuplot](http://www.gnuplot.info/) image rendered as an *img*[^img] image.                           |
| `build.octave.img`        | [Octave](https://octave.org/) image rendered as an *img*[^img] image.                                 |
| `build.lsvg.img`          | [Lsvg](https://codeberg.org/cdsoft/luax) image rendered as an *img*[^img] image.                      |

[^img]: The available image formats are: `svg`, `png` and `pdf`.
[^graphviz]: Graphviz renderers are: `dot`, `neato`, `twopi`, `circo`, `fdp`, `sfdp`, `patchwork` and `osage`.
[^blockdiag]: Other Blockdiag renderers are: `activity`, `network`, `packet`, `rack` and `sequence`.

A new builder can be created by calling the `new` method of an existing builder with a new name
and changing some options. E.g.:

``` lua
local tac = build.cat:new "tac"   -- new builder "tac" based on "cat"
    : set "cmd" "tac"
```

The `new` method of the `build` function can also be used to create a new builder from scratch:

``` lua
local tac = build.new "tac"   -- new builder "tac"
    : set "cmd" "tac"
    : set "args" "$in > $out"
```

A builder has two methods to modify options:

- `set` changes the value of an option
- `add` adds values to the current value of an option
- `insert` adds values before the current value of an option

| Option        | Description                           |
| ------------- | ------------------------------------- |
| `cmd`         | Command to execute                    |
| `flags`       | Command options                       |
| `args`        | Input and output                      |
| `depfile`     | Dependency file name                  |

Other options are added to the rule definition (note that `name` can not be used as a rule variable).

`build.lsvg.img` adds a `$args` ninja variable in the `args` field to pass additional arguments to the lsvg script.
E.g.:

> ``` lua
> build.lsvg.png "image.png" { "image.lua", args="arg given to image.lua" }
> ```

Examples:

``` lua
-- preprocess Markdown files with ypp
-- and convert them to a single HTML file with pandoc
build.pandoc "$builddir/output.html" {
    build.ypp "$builddir/output.md" { "input1.md", "input2.md" }
}
```

`build` also provides some helper functions to format arguments:

| Function                          | Description                                                                                   |
| --------------------------------- | --------------------------------------------------------------------------------------------- |
| `build.ypp_var`                   | Build ypp arguments to pass values from an object to ypp variables (serialized Lua object).   |
| `build.ypp_vars`                  | Build ypp arguments to pass values from a table to ypp variables (one variable per field).    |

Examples:

``` lua
build.ypp : add "flags" {
    -- call ypp with « -e 'VARNAME=(\"serialized object\"):read()' »
    build.ypp_var "VARNAME" { VERSION="0.0", NAME="example" },
    -- call ypp with « -e 'VERSION="0.0"' -e 'NAME="example" »
    build.ypp_vars { VERSION="0.0", NAME="example" },
}
```

### Archivers

The `archivers` module define rules to archive files.
These archivers are also available as `build` metamethods.

Currently only [tar](https://en.wikipedia.org/wiki/Tar_(computing)) archives are supported.

#### Tar archives

`build.tar` creates a tar archive from a directory which must be populated by previous build statements.
It takes three arguments:

- `base`: base directory where tar will start archiving files
- `name` (optional): name of the subdirectory (in `base`) that will actually be archived.
  If `name` is not defined, all files and directories below `base` will be archived.
- `transform` (optional): [`sed`]() expression(s) used to transform file names in the archive.

The tar rule uses the `--auto-compress` option to determine the compression program to use according to the archive name.

Example:

``` lua
-- archive $builddir/release/foo in $builddir/foo.tar.gz
build.tar "$builddir/foo.tar.gz" {
    base = "$builddir/release",
    name = "foo",
}
```

Examples
========

The Ninja file of bang ([`build.ninja`](build.ninja)) is generated by `bang` from [`build.lua`](build.lua).

The [`examples`](examples) directory contains larger examples:

- [`multitarget`](examples/multitarget):

    - source files discovering
    - multi-target compilation
    - multiple libraries
    - multiple executables

- [`lua`](examples/lua):

    - source files discovering
    - OS detection to infer compilation options
    - Lua interpreter compilation and installation

License
=======

    This file is part of bang.

    bang is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    bang is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with bang.  If not, see <https://www.gnu.org/licenses/>.

    For further information about bang you can visit
    https://codeberg.org/cdsoft/luax

