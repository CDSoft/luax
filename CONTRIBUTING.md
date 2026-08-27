# Contributing to LuaX

## Branches

`master`
: stable versions

`dev`
: main development branch

`feature/xxx` or `fix/yyy`
: development branch for a feature `xxx` or a bug fix `yyy`

``` mermaid
---
config:
    gitGraph:
        mainBranchName: 'master'
        showCommitLabel: false
---
gitGraph
    commit
    branch dev
    checkout dev
    commit
    branch feature/x
    checkout feature/x
    commit
    commit
    checkout dev
    merge feature/x
    branch fix/y
    checkout fix/y
    commit
    commit
    checkout dev
    merge fix/y
    commit tag: "X.Y.Z"
    checkout master
    merge dev
```

Feature/fix branches are merged on `dev`, `dev` is merged on `master` (stable versions).

## Commits

Commit messages should briefly describe the change.

One-line messages are preferred for small and trivial patches.

For larger changes, the commit message should explain the motivation
and relevant implementation details and choices when necessary.

## Documentation

Documentation is maintained it several places:

- Ypp preprocessed Markdown files (`*.md.in`)
- Markdown files (`*.md` that are not generated with the `ypp` preprocessor)
- Source files (`@@@` tags)

The documentation shall be updated before any PR:

- `./build.lua` to update the Ninja build file
- `ninja doc` to generate the documentation
- or `ninja all` to build everything

The generated documentation shall be available online and thus shall be committed.

## Tests

The tests shall be updated and pass before any PR:

- `./build.lua` to update the Ninja build file
- `ninja test` to run the tests
- or `ninja all` to build everything

Tests should be added or updated when the behavior of the software changes.

When C code is modified, it shall also be tested with Address and Undefined Behaviour Sanitizers:

``` sh
bang -- -d
ninja test
```

## Pull Requests

A pull request can be merged when:

- documentation and tests are updated as appropriate
- the coding style is respected
- `ninja test` passes
- `ninja doc` succeeds
- generated documentation is up to date (i.e. generated and pushed)
- it has been reviewed and approved by a LuaX admin

## Versioning

LuaX follows the Semantic Versioning paradigm.

The version number is defined in `luax/luax-version.lua` (see [ref:luax-version]).

The release commit on `dev` shall be tagged with the version number before merging to `master`.

## Coding style

No coding style is currently specified.
It shall be pretty easy to infer it from the existing code.

Coding style should be defined in the future if necessary.

The C and Lua language servers are required:

- [clangd](https://clangd.llvm.org/installation.html)
- [Lua LS](https://github.com/LuaLS/lua-language-server)

## Release

Before merging a release from `dev` into `master`:

1. Update the version in `luax/luax-version.lua`.
2. Run `ninja all` (it shall pass).
3. Commit the changes.
4. Tag the release commit with the version number.
5. Merge the branch into `master`.
