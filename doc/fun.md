# Functional programming inspired functions

**Warning**: This module is deprecated

``` lua
local fun = require "fun"
```

**`fun.id(...)`** is the identity function.

**`fun.const(...)`** returns a constant function that returns `...`.

**`fun.keys(t)`** returns a sorted list of keys from the table `t`.

**`fun.values(t)`** returns a list of values from the table `t`, in the
same order than `fun.keys(t)`.

**`fun.pairs(t)`** returns a `pairs` like iterator, in the same order
than `fun.keys(t)`.

**`fun.concat(...)`** returns a concatenated list from input lists.

**`fun.merge(...)`** returns a merged table from input tables.

**`fun.flatten(...)`** flattens input lists and non list parameters.

**`fun.replicate(n, x)`** returns a list containing `n` times the Lua
object `x`.

**`fun.compose(...)`** returns a function that composes input functions.

**`fun.map(f, xs)`** returns the list of `f(x)` for all `x` in `xs`.

**`fun.tmap(f, t)`** returns the table of `{k = f(t[k])}` for all `k` in
`keys(t)`.

**`fun.filter(p, xs)`** returns the list of `x` such that `p(x)` is
true.

**`fun.tfilter(p, t)`** returns the table of `{k = v}` for all `k` in
`keys(t)` such that `p(v)` is true.

**`fun.foreach(xs, f)`** executes `f(x)` for all `x` in `xs`.

**`fun.tforeach(t, f)`** executes `f(t[k])` for all `k` in `keys(t)`.

**`fun.prefix(pre)`** returns a function that adds a prefix `pre` to a
string.

**`fun.suffix(suf)`** returns a function that adds a suffix `suf` to a
string.

**`fun.range(a, b [, step])`** returns a list of values
`[a, a+step, ... b]`. The default step value is 1.

**`fun.memo(func)`** returns a memoized version of the function `func`.

**`fun.I(t)`** returns a string interpolator that replaces `$(...)` by
the value of `...` in the environment defined by the table `t`. An
interpolator can be given another table to build a new interpolator with
new values.

`luax` adds a few functions to the builtin `string` module:

**`string.split(s, sep, maxsplit, plain)`** splits `s` using `sep` as a
separator. If `plain` is true, the separator is considered as plain
text. `maxsplit` is the maximum number of separators to find (ie the
remaining string is returned unsplit. This function returns a list of
strings.

**`string.lines(s)`** splits `s` using `'\n'` as a separator.

**`string.words(s)`** splits `s` using `'%s'` as a separator.

**`string.ltrim(s)`, `string.rtrim(s)`, `string.trim(s)`** removes
left/right/both end spaces.

**`string.cap(s)`** capitalizes `s`.
