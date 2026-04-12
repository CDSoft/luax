![](ypp-banner.svg)

# Yet a PreProcessor

[ypp]: https://codeberg.org/cdsoft/luax "Yet another PreProcessor"
[UPP]: https://codeberg.org/cdsoft/upp "Universal PreProcessor"
[Panda]: https://codeberg.org/cdsoft/panda "Pandoc add-ons (Lua filters for Pandoc)"
[Pandoc]: https://pandoc.org "A universal document converter"
[Typst]: https://typst.app/ "Compose papers faster"
[Lua]: http://www.lua.org/
[Codeberg]: https://codeberg.org/cdsoft/
[CDSoft]: https://cdsoft.codeberg.page
[GraphViz]: http://graphviz.org/
[PlantUML]: http://plantuml.sourceforge.net/
[ditaa]: http://ditaa.sourceforge.net/
[blockdiag]: http://blockdiag.com/
[Asymptote]: http://asymptote.sourceforge.net/
[mermaid]: https://mermaidjs.github.io/
[Pandoc Lua filter]: http://pandoc.org/lua-filters.html
[Python]: https://www.python.org/
[Lua]: http://www.lua.org/
[gnuplot]: http://www.gnuplot.info/
[lsvg]: https://codeberg.org/cdsoft/luax/
[LuaX]: https://codeberg.org/cdsoft/luax "Lua eXtended interpreter"
[LuaX documentation]: https://codeberg.org/cdsoft/luax
[Octave]: https://octave.org/
[bang]: https://codeberg.org/cdsoft/luax "Ninja file generator"
[Ninja]: https://ninja-build.org

`ypp` is yet another preprocessor. It's an attempt to merge [UPP] and [Panda].
It acts as a generic text preprocessor as [UPP] and comes with macros
reimplementing most of the [Panda] functionalities (i.e. [Panda] facilities not
restricted to [Pandoc] but also available to softwares like [Typst]).

Ypp is a minimalist and generic text preprocessor using Lua macros.

It provides several interesting features:

- full [Lua]/[LuaX] interpreter
- variable expansion (minimalistic templating)
- conditional blocks
- file inclusion (e.g. for source code examples)
- script execution (e.g. to include the result of a command)
- diagrams ([Graphviz], [PlantUML], [Asymptote], [blockdiag], [mermaid], [Octave], [lsvg], ...)
- documentation extraction (e.g. from comments in source files)

# Releases

It is strongly recommended to build Ypp from source,
as this is the only reliable way to install the exact version you need.

However, if you do require precompiled binaries,
this page offers a selection for various platforms: <https://cdelord.fr/pub>.

Note that the `bin` directory contains prebuilt ypp scripts
that can run with a Lua or LuaX interpreter.

# Pricing

Ypp is a free and open source software.
But it has a cost. It takes time to develop, maintain and support.

To help Ypp remain free, open source and supported,
users are cordially invited to contribute financially to its development.

@@[[ donate = function(url) return function(img) return function(alt)
    return ("<a href='%s' target='_blank'><img height='36' style='border:0px;height:36px;' src='%s' border='0' alt='%s' /></a>"):format(url, img, alt)
end end end]]

@donate "https://liberapay.com/LuaX/donate"  "https://liberapay.com/assets/widgets/donate.svg"                                              "Donate using Liberapay"
@donate "https://ko-fi.com/K3K11CD108"       "https://storage.ko-fi.com/cdn/kofi6.png?v=6"                                                  "Buy Me a Coffee at ko-fi.com"

Feel free to promote Ypp!

# Open source

[ypp] is an Open source software.
Anybody can contribute on [Codeberg] to:

- suggest or add new features
- report or fix bugs
- improve the documentation
- add some nicer examples
- find new usages
- ...

# Installation

Ypp is now part of [LuaX].

# Usage

```
@script.sh(BUILD/"bin/ypp -h") : gsub("ypp %d+.%d+[0-9a-g.-]*", "ypp")
```

**Note for Windows users**: since Windows does not support shebangs, `ypp`
shall be explicitly launched with `luax` (e.g.: `luax ypp`). If `ypp` is not
found, it is searched in the installation directory of `luax` or in `$PATH`.

| Option                | Description                                                   |
| --------------------- | ------------------------------------------------------------- |
| `-v`                  | Prints ypp version                                            |
| `-a`                  | Forces message colorization even is not writing to a terminal |
| `-l module`           | Loads a module or an external Lua script with `require`, the module is stored in the global variable `module` |
| `-l name=module`      | Loads a module or an external Lua script, the module is stored in the global variable `name` |
| `-l _=module`         | Loads a module or an external Lua script, the module is not stored in a global variable |
| `-e stat`             | Executes a Lua statement `stat` in the ypp Lua interpreter    |
| `-D name=val`         | Defines a Lua variable (shortcut for `-e 'name="val"'`)       |
| `p path`              | Adds a search path to `package.path`                          |
| `-o file`             | Redirects the output to `file` instead of the standard output |
| `-t {svg,pdf,png}`    | Sets the default format of generated images                   |
| `--MT target`         | Adds `target` to the target list (implies `--MD`)             |
| `--MF name`           | Sets the dependency file name (implies `--MD`)                |
| `--MD`                | Generates a dependency file                                   |
| `--img path`          | Sets the path for generated images                            |
| `--meta path`         | Sets the path for generated meta image files                  |
| `-m char`             | Sets the default macro character (default: '@')               |
| `-s`                  | Separate files with a blank line                              |

# Documentation

@q[=====[

Lua expressions and chunks are embedded in the document to process.
Expressions are introduced by `@` and chunks by `@@`.
Several syntaxes are provided.

The first syntax is more generic and can execute any kind of Lua expression or chunk:

- `@(Lua expression)` or `@[===[ Lua expression ]===]`
- `@@(Lua chunk)` or `@@[===[ Lua chunk ]===]`

The second one can be used to read a variable or execute a Lua function with a subset of the Lua grammar:

- `@ident`: get the value of `ident` (which can be a field of a table. E.g. `@math.pi`)
- `@func(...)`, `@func{...}`, `@@func(...)`, `@@func{...}`
- `@func[===[ ... ]===]` or `@@func[===[ ... ]===]`

The expression grammar is:

```
expression ::= <identifier> expr_cont

call_cont ::= '(' well parenthesized substring ')' expr_cont
            | '{' well bracketed substring '}' expr_cont
            | <single quoted string> expr_cont
            | <double quoted string> expr_cont
            | <long string> expr_cont

expr_cont ::= call_cont
            | '[' well bracketed substring ']' expr_cont
            | '.' expression
            | ':' <identifier> call_cont
            | <empty string>
```

And the third one is an assignment to Lua variables:

- `@@var = ...`

The assignment grammar is:

```
assignment ::= <identifier> ( '.' <identifier>
                            | '[' well bracketed expression ']'
                            )*
               '='
               ( <number>
               | 'true' | 'false'
               | '(' well parenthesized substring ')'
               | '{' well bracketed substring '}'
               | <single quoted string>
               | <double quoted string>
               | <long string>
               | expression
               )
```

Note: the number of equal signs in long strings is variable, as in Lua long strings

The Lua code can be delimited with parentheses or long brackets.
The code delimited with parentheses shall only contain well-balanced parentheses.
The long bracket delimiters shall have the same number of equal signs (which can be null),
similarly to Lua literal strings

A macro is just a Lua function. Some macros are predefined by `ypp`. New macros
can be defined by loading Lua scripts (options `-l` and `-e`) or embedded as
Lua chunks.

Expression and chunks can return values. These values are formatted according
to their types:

- `__tostring` method from a custom metatable: if the value has a `__tostring`
  metamethod, it is used to format the value
- arrays (with no `__tostring` metamethod): items are concatenated (one line per item)
- other types are formatted by the default `tostring` function.

For documentation purpose, ypp macros can be disabled with the `q` macro:

```
@q[[
Here, @ has no special meaning.
]]
```

## Examples

### Lua expression

```
The user's home is @(os.getenv "HOME").

$\sum_{i=0}^100 = @(F.range(100):sum())$
```

### Lua chunk

```
@@[[
    sum = 0
    for i = 1, 100 do
        sum = sum + i
    end
]]

$\sum_{i=0}^100 = @sum$
```

]=====]

## Builtin ypp functions

@@[[

    function module(modname)
        return {
            "### `"..modname.."`",
            "",
            doc("ypp"/modname..".lua"),
        }
    end

]]

@module "ypp"

## Builtin ypp modules

@module "atexit"
@module "comment"
@module "convert"
@module "defer"
@module "doc"
@module "file"
@module "image"
@module "include"
@module "q"
@module "script"
@module "when"

## LuaX modules

ypp is written in [Lua] and [LuaX].
All Lua and LuaX libraries are available to ypp.

[LuaX] is a Lua interpreter and REPL based on Lua 5.4, augmented with some useful packages.

LuaX comes with a standard Lua interpreter and provides some libraries (embedded
in a single executable, no external dependency required).
Here are some LuaX modules that can be useful in ypp documents:

@@ luaxdoc = F.curry(function(name, descr)
    return ("[%s](https://codeberg.org/cdsoft/luax/blob/master/doc/%s.md): %s"):format(name, name, descr)
end)

- @luaxdoc "F"       "functional programming inspired functions"
- @luaxdoc "fs"      "file system management"
- @luaxdoc "sh"      "shell command execution"
- @luaxdoc "mathx"   "complete math library for Lua"
- @luaxdoc "imath"   "arbitrary precision integer and rational arithmetic library"
- @luaxdoc "qmath"   "rational number library"
- @luaxdoc "complex" "math library for complex numbers based on C99"
- @luaxdoc "crypt"   "cryptography module"
- @luaxdoc "lpeg"    "Parsing Expression Grammars For Lua"
- @luaxdoc "serpent" "Lua serializer and pretty printer"
- @luaxdoc "json"    "JSON encoder/decoder"

More information here: <https://codeberg.org/cdsoft/luax>

# License

    Ypp is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Ypp is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with ypp.  If not, see <https://www.gnu.org/licenses/>.

    For further information about ypp you can visit
    https://codeberg.org/cdsoft/luax

Feedback
========

Your feedback and contributions are welcome.
You can contact me at [CDSoft].
