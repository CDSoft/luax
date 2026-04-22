![](luax/doc/luax-banner.svg)

> [!IMPORTANT]
> Version 10 is a significant rework: Bang, Ypp and Lsvg are now part of the
> LuaX repository. Binaries are smaller and the build system is faster.
> LuaSec and OpenSSL have been removed (use `curl.http` instead).

#  LuaX-based Development Tools

[Lua]: https://www.lua.org

[LuaX]: https://codeberg.org/cdsoft/luax
[Bang]: https://codeberg.org/cdsoft/luax
[Ypp]: https://codeberg.org/cdsoft/luax
[Panda]: doc/panda/README.md
[Upp]: https://codeberg.org/cdsoft/upp
[Lsvg]: doc/lsvg/README.md
[Ldc]: https://codeberg.org/cdsoft/ldc
[Yreq]: https://codeberg.org/cdsoft/yreq

[Pandoc]: https://pandoc.org
[Pandoc Lua filter]: https://pandoc.org/lua-filters.html
[Typst]: https://typst.app
[Ninja]: https://ninja-build.org
[GraphViz]: https://graphviz.org
[PlantUML]: https://plantuml.org
[Asymptote]: https://asy.marris.fr
[BlockDiag]: http://blockdiag.com
[Mermaid]: https://mermaid.js.org
[Octave]: https://octave.org
[ditaa]: https://github.com/stathissideris/ditaa

## TL;DR

The LuaX repository now contains some softwares that are closely coupled with LuaX:

[LuaX](luax/doc/README.md)
: The LuaX interpreter / compiler itself.

[Bang](bang/doc/README.md)
: The LuaX build system that enhances Nina with some powerful Lua scripting capabilities.

[Ypp](ypp/doc/README.md)
: A generic text preprocessor used to build the LuaX documentation.

[lsvg](lsvg/doc/README.md)
: An SVG image generator scriptable in LuaX used to generate the LuaX logo.

### Installation

``` sh
git clone https://codeberg.org/cdsoft/luax
cd luax
./build.lua
ninja install  # installs to ~/.local/bin and ~/.local/lib
```

Precompiled binaries for various platforms are also available at <https://cdelord.fr/pub>,
but building from source is recommended.

### Support

LuaX is free and open source. Contributions are welcome:

<a href='https://liberapay.com/LuaX/donate' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://liberapay.com/assets/widgets/donate.svg' border='0' alt='Donate using Liberapay' /></a>
<a href='https://ko-fi.com/K3K11CD108' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi6.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>

Feel free to promote LuaX!

## Core tools

**[LuaX]**
: is an extended [Lua] 5.5 interpreter and compiler. It enriches Lua
  with 20+ built-in modules (file system, shell, cryptography, compression…) and
  can produce standalone cross-platform executables. LuaX uses **Lua tables as a
  universal data format**, allowing all tools in the ecosystem to share
  configuration and data without any conversion glue.

**[Bang]** (Bang Automates Ninja Generation)
: is a [Ninja] build file generator
  scriptable in LuaX. It turns readable LuaX build scripts into fast, incremental
  Ninja build files, with built-in support for C/C++ compilation,
  cross-compilation, and common document processors.

**[Ypp]** (Yet a PreProcessor)
: is a generic text preprocessor driven by LuaX
  macros. It supports variable expansion, file inclusion, diagram generation
  ([Graphviz], [PlantUML], [Mermaid], [Lsvg]…) and [Pandoc]-based format
  conversion, and works equally well with [Pandoc] and [Typst] documents.

**[Lsvg]**
: is a LuaX-scriptable SVG image generator. It exposes a pure Lua
  library covering all major SVG elements and can output SVG, PNG, JPEG or PDF.
  It is used, for example, to generate the LuaX logo, and integrates naturally
  with Ypp and Bang.

## Other tools in the ecosystem

These tools extend the ecosystem and rely on LuaX as their scripting foundation:

**[Panda]**
: a [Pandoc Lua filter] that processes documents at the AST level,
  adding templating, file inclusion, diagram rendering and dependency tracking.
  Complements Ypp for Pandoc-specific workflows.

**[Ldc]**
: a cross-language code generator: reads LuaX data definitions and
  emits equivalent source code in C, Haskell, Shell, YAML, etc., keeping
  constants in sync across a polyglot project.

**[Yreq]**
: a lightweight requirement-tracking plugin for Ypp, providing
  traceability tags, coverage matrices and hyperlinks within technical
  documentation.
