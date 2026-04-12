#  LuaX-based Development Tools

<img src="doc/luax/luax-banner.svg" style="width:100.0%" />

[Lua]: https://www.lua.org

[LuaX]: doc/luax/README.md
[Bang]: doc/bang/README.md
[Ypp]: doc/ypp/README.md
[Panda]: doc/panda/README.md
[Upp]: https://codeberg.org/cdsoft/upp
[Lsvg]: doc/lsvg/README.md
[Ldc]: https://codeberg.org/cdsoft/ldc
[Yreq]: https://codeberg.org/cdsoft/yreq
[tagref]: https://codeberg.org/cdsoft/tagref
[ninja-builder]: https://codeberg.org/cdsoft/ninja-builder

[Lcc]: https://gitlab.com/CDSoft/lcc

[FizzBuzz]: https://codeberg.org/cdsoft/FizzBuzz

[Pandoc]: https://pandoc.org
[Pandoc Lua filter]: https://pandoc.org/lua-filters.html
[Pandoc Lua filters]: https://pandoc.org/lua-filters.html
[Lua filter]: https://pandoc.org/lua-filters.html
[Lua filters]: https://pandoc.org/lua-filters.html
[Pandoc filters]: https://pandoc.org/filters.html
[Typst]: https://typst.app
[Ninja]: https://ninja-build.org
[Zig]: https://ziglang.org
[Zig cc]: https://ziglang.org
[GraphViz]: https://graphviz.org
[PlantUML]: https://plantuml.org
[Asymptote]: https://asy.marris.fr
[BlockDiag]: http://blockdiag.com
[Mermaid]: https://mermaid.js.org
[Octave]: https://octave.org
[ditaa]: https://github.com/stathissideris/ditaa

> [!IMPORTANT]
> This is an important rework of LuaX.
>
> Version 10 simplifies and improves several aspects compared to version 9:
>
> - Faster build system (no option, cross compilers always generated)
> - Smaller binaries
> - No more compression libraries (not so useful for LuaX, easily replaced with command line tools)
> - No more LuaSocket and OpenSSL libraries (heavy to maintain, easily replaced with the new [`http`](luax/http.md) module, based on `curl`)
> - Bang, ypp and lsvg are now part of LuaX (more easily maintained and updated)

# TL;DR

The LuaX repository now contains some softwares that are closely coupled with LuaX:

- [LuaX]: The LuaX interpreter / compiler itself.
- [Bang]: The LuaX build system that enhances Nina with some powerful Lua scripting capabilities.
- [Ypp]: A generic text preprocessor used to build the LuaX documentation.
- [lsvg]: An SVG image generator scriptable in LuaX used to generate the LuaX logo.

## Installation

``` sh
$ git clone https://codeberg.org/cdsoft/luax
$ cd luax
$ ./build.lua
$ ninja install  # install LuaX to ~/.local/bin and ~/.local/lib
```

or set `$PREFIX` to install LuaX to a custom directory (`$PREFIX/bin`, `$PREFIX/lib`):

``` sh
$ PREFIX=/path ninja install # install luax to /path/bin
```

## Releases

It is strongly recommended to build LuaX from source, as this is the
only reliable way to install the exact version you need.

However, if you do require precompiled binaries, this page offers a
selection for various platforms: <https://cdelord.fr/pub>.

Note that the `bin` and `lib` directories contain prebuilt LuaX scripts
to run LuaX scripts with a restricted self-contained runtime.

## Pricing

LuaX is a free and open source software. But it has a cost. It takes
time to develop, maintain and support.

To help LuaX remain free, open source and supported, users are cordially
invited to contribute financially to its development.

<a href='https://liberapay.com/LuaX/donate' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://liberapay.com/assets/widgets/donate.svg' border='0' alt='Donate using Liberapay' /></a>
<a href='https://ko-fi.com/K3K11CD108' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi6.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>

Feel free to promote LuaX!

# Introduction

Lots of software projects involve various tools, free as well as commercial, to build the software, run the tests, produce the documentation, and more. These tools use different data formats and scripting languages, which makes the projects less scalable and harder to maintain.

Sharing data between configuration files, documentations, and test results can then be painful and counter-productive (the necessary glue is often more complex than the tools themselves).

Usually people script their build systems and processes with languages like Bash, Python, or JavaScript and make them communicate with plain text, YAML, JSON, XML, CSV, INI, or TOML. Every script shall rely on specific (existing or not) libraries to read and write these data formats.

This document presents a common and powerful data format and some tools to script the build process of a project and generate documentation.

To sum up, the suggested solution is:

- a **single data format** ([Lua] tables)
- and a **reduced set of highly configurable tools**

For a practical demonstration of these tools working together, see the [FizzBuzz] example project.

# Core LuaX-based Tools

## LuaX

*Source: <https://codeberg.org/cdsoft/luax>*

[LuaX] is an extended [Lua] interpreter and REPL based on Lua 5.4, augmented with a comprehensive collection of useful modules. It serves as the foundation for the entire ecosystem presented in this document, providing both a powerful runtime environment and a compilation system for creating standalone executables.

**Key features:**

- **Extended [Lua] runtime** with 20+ built-in modules covering file system operations, shell execution, cryptography, compression, networking, and mathematical computations
- **Cross-platform compilation** supporting Linux, macOS, and Windows (both x86_64 and aarch64)
- **Standalone executable generation** from [Lua] scripts with no external dependencies
- **Multiple compilation targets** including native executables, [Lua] bytecode, and [Pandoc]-compatible scripts
- **Pure [Lua] compatibility** through shared libraries and pure [Lua] implementations of core modules

The genius of [Lua] lies in its use of **Lua tables as the universal data format**. Unlike traditional build systems that juggle multiple configuration formats (YAML, JSON, XML, INI), LuaX enables all tools in the ecosystem to share data seamlessly through [Lua]'s native data structures. This eliminates the need for format conversion glue code and makes the entire toolchain more maintainable.

**Integration benefits:** [LuaX] provides the common runtime and data format that allows all other tools in this list to work together harmoniously. Scripts can share configuration data, build rules, and processing results through standard [Lua] tables, creating a cohesive development environment.

**Alternatives:** While Python, Node.js, or shell scripts are common choices for build tooling, they require additional libraries to handle different data formats and often suffer from dependency management issues. [LuaX] provides a self-contained solution with a consistent data model across all tools. Compared to language-specific ecosystems like npm or pip, [LuaX] offers better reproducibility and fewer version conflicts.

## Bang

*Source: <https://codeberg.org/cdsoft/luax>*

[Bang] (Bang Automates Ninja Generation) is a [Ninja] build file generator scriptable in [LuaX]. It serves as the orchestrator of the entire build process, transforming [LuaX]-based build descriptions into high-performance [Ninja] build files.

**Key features:**

- **[LuaX]-scriptable build system** that generates optimized [Ninja] files from readable [LuaX] build scripts
- **High-level abstractions** for common build tasks including C/C++ compilation, cross-compilation, file processing, and archive creation
- **Integrated toolchain support** with built-in, extensible modules for C compilers (gcc, clang, [zig cc]), [LuaX] compilation, and various document processors
- **Advanced build features** including dependency tracking, incremental builds, parallel execution, and cross-platform support
- **Extensible builder system** with predefined builders for [pandoc], [graphviz], [plantuml], and other common tools

[Bang] transforms complex build processes into simple, maintainable [LuaX] scripts. Instead of wrestling with Make's cryptic syntax or CMake's verbose configuration, developers write intuitive [Lua] code that leverages the same data structures used throughout the ecosystem. Build rules, file lists, and configuration data all share the same [Lua] table format, enabling seamless integration with other [LuaX] tools.

**Integration benefits:** [Bang] naturally interfaces with preprocessors like [Ypp] and [Panda] through its builder system, processes documentation with [Pandoc] integration, and can orchestrate complex workflows involving multiple [LuaX] tools. All configuration and build data remains in [Lua] format, eliminating conversion overhead and maintaining consistency across the toolchain.

**Alternatives:** Compared to Make, [Bang] offers better dependency tracking and parallel execution through [Ninja]. Compared to CMake or Meson, [Bang] provides simpler syntax and better integration with [LuaX]-based tools. Unlike Bazel or Buck, [Bang] maintains simplicity while offering powerful abstractions. The combination of [LuaX] scripting with [Ninja]'s performance creates a build system that's both approachable and highly efficient.

## Ypp

*Source: <https://codeberg.org/cdsoft/luax>*

[Ypp] (Yet a PreProcessor) is a minimalist and generic text preprocessor using [LuaX] macros. It represents the evolution of traditional text preprocessing, merging the capabilities of [UPP] (Universal PreProcessor) and [Panda] while extending beyond [Pandoc] to work with modern tools like [Pandoc] and [Typst].

**Key features:**

- **Full [LuaX] interpreter integration** enabling complex preprocessing logic with access to all [LuaX] modules
- **Rich macro system** supporting variable expansion, conditional blocks, file inclusion, and script execution
- **Diagram generation** with built-in support for [Graphviz], [PlantUML], [Asymptote], [blockdiag], [mermaid], [Octave], and [lsvg]
- **Document format conversion** through [Pandoc] integration with header level shifting and format transformation
- **Documentation extraction** from source code comments with customizable patterns
- **Incremental file generation** with dependency tracking

[Ypp] transforms static text files into dynamic documents by embedding [Lua] expressions directly in the source. Instead of learning domain-specific templating languages, users leverage the same [Lua] syntax used throughout the ecosystem. This creates unprecedented flexibility—from simple variable substitution to complex document generation involving data processing, external script execution, and automated diagram creation.

**Integration benefits:** [Ypp] seamlessly interfaces with other [LuaX] tools through shared [Lua] data structures. Build configurations from Bang can be used to generate documentation, processed data from [LuaX] scripts can be embedded in documents, and generated content can be further processed by [Panda] or converted by [Pandoc]. The common [Lua] runtime eliminates the impedance mismatch typically found between preprocessing and processing tools.

**Alternatives:** Compared to traditional preprocessors like M4 or CPP, [Ypp] offers a modern, readable syntax with powerful built-in capabilities. Unlike template engines like Jinja2 or Mustache, [Ypp] provides full programming language capabilities rather than limited logic constructs. Compared to documentation generators like Sphinx or GitBook, [Ypp] offers more flexibility and direct integration with the build process while maintaining simplicity.

## Lsvg

*Source: <https://codeberg.org/cdsoft/luax>*

[Lsvg] is a [LuaX] scriptable SVG image generator that enables programmatic creation of vector graphics through [Lua] code. It provides a pure [Lua] library for SVG generation, making it an ideal tool for creating diagrams, charts, and illustrations directly from data or algorithms.

**Key features:**

- **Pure [Lua] SVG generation** with a comprehensive library covering all major SVG elements and attributes
- **Programmatic image creation** enabling data-driven graphics, algorithmic art, and dynamic diagram generation
- **Multiple output formats** supporting SVG natively, with PNG, JPEG, and PDF conversion through ImageMagick integration
- **[LuaX] integration** providing access to all [LuaX] modules for data processing, mathematical computations, and file operations
- **Build system integration** with dependency tracking for automatic image regeneration when source scripts change

[Lsvg] transforms the traditionally manual process of graphic design into a programmable workflow. Instead of using complex GUI tools or wrestling with verbose SVG markup, developers can generate precise graphics using familiar [Lua] syntax. This approach excels for creating technical diagrams, data visualizations, and any graphics that need to be generated dynamically or maintained alongside code.

**Integration benefits:** [Lsvg] integrates seamlessly with the [LuaX] ecosystem, sharing data structures and processing capabilities with other tools. Build configurations from [Bang] can include [Lsvg] scripts, [Ypp] can embed [Lsvg]-generated diagrams using the `@q"@"image.lsvg` macro, and [Panda] can render [Lsvg] code blocks directly. The shared [Lua] runtime ensures consistent data handling and eliminates format conversion overhead.

**Alternatives:** Compared to traditional vector graphics editors like Inkscape or Illustrator, [Lsvg] offers version control friendliness and reproducible results. Unlike libraries like D3.js or matplotlib, [Lsvg] provides simpler syntax and better integration with [Lua]-based workflows. Compared to other programmatic SVG generators like Python's svgwrite or JavaScript's Fabric.js, [Lsvg] benefits from [Lua]'s lightweight syntax and the rich [LuaX] module ecosystem for mathematical and data processing operations.

# More LuaX-based Tools

## Panda

*Source: <https://codeberg.org/cdsoft/panda>*

[Panda] is a powerful [Pandoc Lua filter] that operates on [Pandoc]'s internal AST (Abstract Syntax Tree), providing advanced document processing capabilities within the [Pandoc] ecosystem. It represents a specialized approach to document processing, working directly with structured document representations rather than raw text.

**Key features:**

- **AST-based processing** working directly on [Pandoc]'s internal document structure for reliable transformations
- **Advanced templating** with variable expansion, conditional blocks, and [LuaX] scripting integration
- **Intelligent file inclusion** supporting multiple formats with automatic parsing and header level adjustment
- **Script execution and diagram generation** with built-in support for [Graphviz], [PlantUML], [ditaa], [Asymptote], [blockdiag], [mermaid], and more
- **Documentation extraction** from source code with customizable delimiters and formatting options
- **Dependency tracking** with automatic generation of Makefile-compatible dependency files

[Panda] bridges the gap between simple text processing and sophisticated document generation. Unlike text-based preprocessors, [Panda] understands document structure and can perform intelligent transformations that respect the semantic meaning of content. This enables complex operations like conditional content inclusion, format-aware file embedding, and automatic diagram generation while maintaining document integrity.

**Integration benefits:** [Panda] complements [Ypp] by providing [Pandoc]-specific processing capabilities. While [Ypp] handles generic text preprocessing, [Panda] specializes in document structure manipulation. Both tools share the same [Lua] runtime and can access [LuaX] modules, ensuring consistent data handling. Documents can be preprocessed with [Ypp] and then processed with [Panda] for final formatting, creating a powerful two-stage processing pipeline.

**Alternatives:** Compared to basic [Pandoc filters], [Panda] provides a comprehensive suite of document processing features in a single tool. Unlike template engines that work on plain text, [Panda] operates on structured documents, preventing malformed output. Compared to custom Python or Haskell [Pandoc filters], [Panda] offers easier maintenance through [Lua]'s simplicity. The AST-based approach provides more reliability than regex-based text processors like sed or awk.

## Ldc

*Source: <https://codeberg.org/cdsoft/ldc>*

[Ldc] (Lua Data Compiler) is a cross-language code generator that parses [LuaX] scripts containing data definitions and produces equivalent source code in multiple target languages. It bridges the gap between [Lua]-based configuration and multi-language development environments.

**Key features:**

- **Multi-language code generation** supporting C, Haskell, Asymptote, reStructuredText, Shell, and YAML backends
- **Intelligent type inference** automatically determining appropriate types for scalars, structures, and arrays in target languages
- **Custom type system** allowing users to define specialized types with custom patterns for each backend
- **Immutable design** ensuring better modularity and reusability compared to its predecessor [lcc]
- **Configuration-driven approach** using pure [LuaX] scripts as the single source of truth for multi-language constants and data structures

[Ldc] solves the common problem of maintaining synchronized constants and data structures across multiple programming languages. Instead of manually duplicating definitions in C headers, Haskell modules, and shell scripts, developers maintain a single [LuaX] configuration file that generates consistent code for all target languages. This eliminates synchronization errors and reduces maintenance overhead in polyglot projects.

**Integration benefits:** [Ldc] leverages the same [LuaX] data structures used throughout the [LuaX] ecosystem, enabling seamless integration with build systems and documentation tools. Configuration data from [Bang] can be processed by [Ldc] to generate language-specific constants, while [Ypp] and [Panda] can embed generated code or include it in documentation. The shared [Lua] runtime ensures data consistency across the entire toolchain.

**Alternatives:** Compared to language-specific code generators like Protocol Buffers or Apache Avro, [Ldc] offers simpler configuration syntax using native [Lua] tables. Unlike template-based approaches like Jinja2 or M4, [Ldc] provides intelligent type inference and language-specific optimizations. Compared to maintaining separate constant files for each language, [Ldc] guarantees consistency and significantly reduces maintenance effort while providing better tooling integration through its [LuaX] foundation.

## Yreq

*Source: <https://codeberg.org/cdsoft/yreq>*

[Yreq] is a minimalistic requirement management tool implemented as a [Ypp] plugin. It enables traceability and coverage analysis in technical documentation by establishing relationships between requirements, implementations, and tests through a tag-and-reference system.

**Key features:**

- **Tag-based requirement tracking** using customizable nouns (spec, code, test) and verbs (implements, tests, refines) to describe relationships
- **Automatic coverage matrix generation** showing upstream and downstream relationships between all requirements
- **Traceability analysis** enabling verification that specifications are implemented and tested
- **[Ypp] integration** leveraging the preprocessing capabilities for dynamic requirement documentation
- **Hyperlink generation** creating navigable connections between related requirements within documents

[Yreq] addresses the critical challenge of maintaining traceability in complex projects where requirements, design, implementation, and testing must remain synchronized. Traditional requirement management tools are often heavyweight and disconnected from the development workflow. [Yreq] embeds requirement tracking directly into the documentation using the same [LuaX]-based ecosystem, ensuring requirements remain close to the code and automatically updated.

**Integration benefits:** [Yreq] leverages [Ypp]'s preprocessing capabilities to create dynamic, interconnected documentation. Requirements can reference data from Bang build configurations, include code snippets processed by other [LuaX] tools, and generate coverage reports that reflect the actual state of the project. The shared [LuaX] runtime ensures consistency between build logic, documentation, and requirement tracking.

**Alternatives:** Compared to heavyweight tools like IBM DOORS or PTC Integrity, [Yreq] offers lightweight integration with development workflows and version control systems. Unlike documentation-only approaches such as wiki-based requirement tracking, [Yreq] provides automated relationship validation and coverage analysis. Compared to code annotation systems like Doxygen comments, [Yreq] offers bidirectional traceability and cross-document relationship mapping. The integration with [Ypp] provides more sophistication than simple tagging systems while maintaining simplicity and maintainability.

## Tagref

*Source: <https://codeberg.org/cdsoft/tagref>*

[Tagref] is a cross-reference maintenance tool for codebases, reimplemented in [LuaX] from the original Rust version. It helps maintain consistency in code documentation by ensuring that cross-references between different parts of a codebase remain valid as the code evolves.

**Key features:**

- **Tag-based cross-referencing** allowing developers to create stable references to code sections using `[tag:name]` and `[ref:name]` annotations in comments
- **Multi-language support** working with any programming language through comment-based annotations
- **Git integration** respecting `.gitignore` files and working seamlessly with version control workflows
- **Reference validation** ensuring that all references point to existing tags and that all tags are unique
- **CI-friendly design** providing fast validation suitable for automated continuous integration checks

[Tagref] addresses the brittleness of traditional code cross-references that rely on file paths and line numbers. When code evolves, line numbers shift and files get renamed, breaking these references. [Tagref]'s tag-based system creates stable anchors that can be referenced from anywhere in the codebase, with automatic validation to prevent broken references.

**Integration benefits**: [Tagref] is simple to use and easy to integrate into [Bang]-managed build systems. It can be seamlessly added to build pipelines as a validation step, ensuring code cross-references remain consistent throughout the development process. The tool's straightforward command-line interface makes it ideal for automated CI/CD workflows alongside other [LuaX] ecosystem tools.

**Alternatives:** Compared to the original Rust implementation, this [LuaX] version offers better integration with [Lua]-based development workflows, though it may be slower for very large codebases. Unlike documentation tools like Doxygen that require specific comment formats, [Tagref] works with any comment style in any language. Compared to manual cross-reference maintenance or commit-based references, [Tagref] provides automated validation and eliminates the maintenance burden of keeping references current.

# Complementary Tools

## Pandoc

*Source: <https://pandoc.org>*

[Pandoc] is a universal document converter that can transform documents between numerous formats. It supports [Lua filters], making it an excellent companion to [LuaX]-based tools for document processing workflows. The [Lua] scripting capability allows for seamless integration with the ecosystem presented here.

**Key features:**

- Universal document conversion between 40+ formats
- [Lua filter] system for custom transformations
- Extensible through [Lua] scripting
- Command-line interface perfect for automated workflows

**Integration with [LuaX] tools:** [Pandoc]'s [Lua filters] can be easily extended with [LuaX] libraries, and preprocessors like [Ypp] or [Panda] can generate content that [Pandoc] then converts to final formats.

**Alternatives:** While tools like Sphinx, GitBook, or Asciidoctor exist, [Pandoc]'s [Lua] integration and format versatility make it uniquely suitable for [Lua]-based workflows.

## Typst

*Source: <https://typst.app>*

[Typst] is a modern typesetting system designed as an alternative to LaTeX. While not [Lua]-based itself, it integrates well with [LuaX] preprocessing tools and offers a more approachable syntax for document creation.

**Key features**

- Modern, clean syntax for document typesetting
- Fast compilation and real-time preview
- Programmable with its own scripting language
- Web-based and local tooling available

**Integration with [LuaX] tools:** Preprocessors like [Ypp] or [Panda] can generate [Typst] source files, allowing for dynamic document generation using [LuaX] scripting while leveraging [Typst]'s superior typesetting capabilities.

**Alternatives:** Compared to LaTeX, [Typst] offers faster compilation and cleaner syntax. Compared to Markdown-based solutions, it provides more sophisticated typesetting control.

## Ninja

*Source: <https://ninja-build.org> (Ninja cross-compilation: <https://codeberg.org/cdsoft/ninja-builder>)*

[Ninja] is a small build system focused on speed. It's designed to have its input files generated by higher-level build systems rather than being hand-authored.

**Key features:**

- Extremely fast build execution
- Simple, generated build file format
- Minimal dependencies and overhead
- Excellent incremental build support

**Integration with [LuaX] tools:** Build generators like [Bang] can produce [Ninja] build files, creating a powerful combination where [LuaX] scripts define the build logic and [Ninja] executes it efficiently. The [ninja-builder] project simplifies cross-compilation scenarios.

**Alternatives:** Compared to Make, [Ninja] is faster and more reliable for large projects. Compared to CMake or Meson, it's lower-level but more predictable and faster when paired with appropriate generators.

