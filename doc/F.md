# Functional programming utilities

``` lua
local F = require "F"
```

`F` provides some useful functions inspired by functional programming
languages, especially by these Haskell modules:

- [`Data.List`](https://hackage.haskell.org/package/base-4.17.0.0/docs/Data-List.html)
- [`Data.Map`](https://hackage.haskell.org/package/containers-0.6.6/docs/Data-Map.html)
- [`Data.String`](https://hackage.haskell.org/package/base-4.17.0.0/docs/Data-String.html)
- [`Prelude`](https://hackage.haskell.org/package/base-4.17.0.0/docs/Prelude.html)

This module provides functions for Lua tables that can represent both
arrays (i.e. integral indices) and tables (i.e. any indice types). The
`F` constructor adds methods to tables which may interfere with table
fields that could have the same names. In this case, F also defines a
method alias (same name prefixed with `__`). E.g.:

``` lua
t = F{foo = 12, mapk = 42} -- note that mapk is also a method of F tables

t:mapk(func)   -- fails because mapk is a field of t
t:__mapk(func) -- works and is equivalent to F.mapk(func, t)
```

## Standard types, and related functions

### Operators

``` lua
F.op.land(a, b)             -- a and b
F.op.lor(a, b)              -- a or b
F.op.lxor(a, b)             -- (not a and b) or (not b and a)
F.op.lnot(a)                -- not a
```

> Logical operators

``` lua
F.op.band(a, b)             -- a & b
F.op.bor(a, b)              -- a | b
F.op.bxor(a, b)             -- a ~ b
F.op.bnot(a)                -- ~a
F.op.shl(a, b)              -- a << b
F.op.shr(a, b)              -- a >> b
```

> Bitwise operators

``` lua
F.op.eq(a, b)               -- a == b
F.op.ne(a, b)               -- a ~= b
F.op.lt(a, b)               -- a < b
F.op.le(a, b)               -- a <= b
F.op.gt(a, b)               -- a > b
F.op.ge(a, b)               -- a >= b
```

> Comparison operators

``` lua
F.op.ueq(a, b)              -- a == b  (†)
F.op.une(a, b)              -- a ~= b  (†)
F.op.ult(a, b)              -- a < b   (†)
F.op.ule(a, b)              -- a <= b  (†)
F.op.ugt(a, b)              -- a > b   (†)
F.op.uge(a, b)              -- a >= b  (†)
```

> Universal comparison operators ((†) comparisons on elements of
> possibly different Lua types)

``` lua
F.op.add(a, b)              -- a + b
F.op.sub(a, b)              -- a - b
F.op.mul(a, b)              -- a * b
F.op.div(a, b)              -- a / b
F.op.idiv(a, b)             -- a // b
F.op.mod(a, b)              -- a % b
F.op.neg(a)                 -- -a
F.op.pow(a, b)              -- a ^ b
```

> Arithmetic operators

``` lua
F.op.concat(a, b)           -- a .. b
F.op.len(a)                 -- #a
```

> String/list operators

### Basic data types

``` lua
F.maybe(b, f, a)
```

> Returns f(a) if f(a) is not nil, otherwise b

``` lua
F.default(def, x)
```

> Returns x if x is not nil, otherwise def

``` lua
F.case(x) {
    t1 = v1,
    ...
    tn = vn,
    [F.Nil] = default_value,
}
```

> returns `vi` such that `ti == x` or `default_value` if no `ti` is
> equal to `x`.

#### Tuples

``` lua
F.fst(xs)
xs:fst()
```

> Extract the first component of a list.

``` lua
F.snd(xs)
xs:snd()
```

> Extract the second component of a list.

``` lua
F.thd(xs)
xs:thd()
```

> Extract the third component of a list.

``` lua
F.nth(n, xs)
xs:nth(n)
```

> Extract the n-th component of a list.

### Basic type classes

``` lua
F.comp(a, b)
```

> Comparison (-1, 0, 1)

``` lua
F.ucomp(a, b)
```

> Comparison (-1, 0, 1) (using universal comparison operators)

``` lua
F.max(a, b)
```

> max(a, b)

``` lua
F.min(a, b)
```

> min(a, b)

``` lua
F.succ(a)
```

> a + 1

``` lua
F.pred(a)
```

> a - 1

### Numbers

#### Numeric type classes

``` lua
F.negate(a)
```

> -a

``` lua
F.abs(a)
```

> absolute value of a

``` lua
F.signum(a)
```

> sign of a (-1, 0 or +1)

``` lua
F.quot(a, b)
```

> integer division truncated toward zero

``` lua
F.rem(a, b)
```

> integer remainder satisfying quot(a, b)\*b + rem(a, b) == a, 0 \<=
> rem(a, b) \< abs(b)

``` lua
F.quot_rem(a, b)
```

> simultaneous quot and rem

``` lua
F.div(a, b)
```

> integer division truncated toward negative infinity

``` lua
F.mod(a, b)
```

> integer modulus satisfying div(a, b)\*b + mod(a, b) == a, 0 \<= mod(a,
> b) \< abs(b)

``` lua
F.div_mod(a, b)
```

> simultaneous div and mod

``` lua
F.recip(a)
```

> Reciprocal fraction.

``` lua
F.pi
F.exp(x)
F.log(x), F.log(x, base)
F.sqrt(x)
F.sin(x)
F.cos(x)
F.tan(x)
F.asin(x)
F.acos(x)
F.atan(x)
F.sinh(x)
F.cosh(x)
F.tanh(x)
F.asinh(x)
F.acosh(x)
F.atanh(x)
```

> standard math constants and functions

``` lua
F.proper_fraction(x)
```

> returns a pair (n,f) such that x = n+f, and:
>
> - n is an integral number with the same sign as x
> - f is a fraction with the same type and sign as x, and with absolute
>   value less than 1.

``` lua
F.truncate(x)
```

> returns the integer nearest x between zero and x and the fractional
> part of x.

``` lua
F.round(x)
```

> returns the nearest integer to x; the even integer if x is equidistant
> between two integers

``` lua
F.ceiling(x)
F.ceil(x)
```

> returns the least integer not less than x.

``` lua
F.floor(x)
```

> returns the greatest integer not greater than x.

``` lua
F.is_nan(x)
```

> True if the argument is an IEEE “not-a-number” (NaN) value

``` lua
F.is_infinite(x)
```

> True if the argument is an IEEE infinity or negative infinity

``` lua
F.is_normalized(x)
```

> True if the argument is represented in normalized format

``` lua
F.is_denormalized(x)
```

> True if the argument is too small to be represented in normalized
> format

``` lua
F.is_negative_zero(x)
```

> True if the argument is an IEEE negative zero

``` lua
F.atan2(y, x)
```

> computes the angle (from the positive x-axis) of the vector from the
> origin to the point (x,y).

``` lua
F.even(n)
F.odd(n)
```

> parity check

``` lua
F.gcd(a, b)
F.lcm(a, b)
```

> Greatest Common Divisor and Least Common Multiple of a and b.

### Miscellaneous functions

``` lua
F.id(x)
```

> Identity function.

``` lua
F.const(...)
```

> Constant function. const(…)(y) always returns …

``` lua
F.compose(fs)
```

> Function composition. compose{f, g, h}(…) returns f(g(h(…))).

``` lua
F.flip(f)
```

> takes its (first) two arguments in the reverse order of f.

``` lua
F.curry(f)
```

> curry(f)(x)(…) calls f(x, …)

``` lua
F.uncurry(f)
```

> uncurry(f)(x, …) calls f(x)(…)

``` lua
F.partial(f, ...)
```

> F.partial(f, xs)(ys) calls f(xs..ys)

``` lua
F.call(f, ...)
```

> calls `f(...)`

``` lua
F.until_(p, f, x)
```

> yields the result of applying f until p holds.

``` lua
F.error(message, level)
F.error_without_stack_trace(message, level)
```

> stops execution and displays an error message (with out without a
> stack trace).

``` lua
F.prefix(pre)
```

> returns a function that adds the prefix pre to a string

``` lua
F.suffix(suf)
```

> returns a function that adds the suffix suf to a string

``` lua
F.memo1(f)
```

> returns a memoized function (one argument)
>
> Note that the memoized function has a `reset` method to forget all the
> previously computed values.

``` lua
F.memo(f)
```

> returns a memoized function (any number of arguments)
>
> Note that the memoized function has a `reset` method to forget all the
> previously computed values.

## Converting to and from string

### Converting to string

``` lua
F.show(x, [opt])
```

> Convert x to a string
>
> `opt` is an optional table that customizes the output string:
>
> - `opt.int`: integer format
> - `opt.flt`: floating point number format
> - `opt.indent`: number of spaces use to indent tables (`nil` for a
>   single line output)

### Converting from string

``` lua
F.read(s)
```

> Convert s to a Lua value

## Table construction

``` lua
F(t)
```

> `F(t)` sets the metatable of `t` and returns `t`. Most of the
> functions of `F` will be methods of `t`.
>
> Note that other `F` functions that return tables actually return `F`
> tables.

``` lua
F.clone(t)
t:clone()
```

> `F.clone(t)` clones the first level of `t`.

``` lua
F.deep_clone(t)
t:deep_clone()
```

> `F.deep_clone(t)` recursively clones `t`.

``` lua
F.rep(n, x)
```

> Returns a list of length n with x the value of every element.

``` lua
F.range(a)
F.range(a, b)
F.range(a, b, step)
```

> Returns a range \[1, a\], \[a, b\] or \[a, a+step, … b\]

``` lua
F.concat{xs1, xs2, ... xsn}
F{xs1, xs2, ... xsn}:concat()
xs1 .. xs2
```

> concatenates lists

``` lua
F.flatten(xs, [leaf])
xs:flatten([leaf])
```

> Returns a flat list with all elements recursively taken from xs. The
> optional `leaf` parameter is a predicate that can stop `flatten` on
> some kind of nodes. By default, `flatten` only recurses on tables with
> no metatable or on `F` tables.

``` lua
F.str({s1, s2, ... sn}, [separator, [last_separator]])
ss:str([separator, [last_separator]])
```

> concatenates strings (separated with an optional separator) and
> returns a string.

``` lua
F.from_set(f, ks)
ks:from_set(f)
```

> Build a map from a set of keys and a function which for each key
> computes its value.

``` lua
F.from_list(kvs)
kvs:from_list()
```

> Build a map from a list of key/value pairs.

## Iterators

``` lua
F.pairs(t, [comp_lt])
t:pairs([comp_lt])
F.ipairs(xs, [comp_lt])
xs:ipairs([comp_lt])
```

> behave like the Lua `pairs` and `ipairs` iterators. `F.pairs` sorts
> keys using the function `comp_lt` or the universal `<=` operator
> (`F.op.ult`).

``` lua
F.keys(t, [comp_lt])
t:keys([comp_lt])
F.values(t, [comp_lt])
t:values([comp_lt])
F.items(t, [comp_lt])
t:items([comp_lt])
```

> returns the list of keys, values or pairs of keys/values (same order
> than F.pairs).

## Table extraction

``` lua
F.head(xs)
xs:head()
F.last(xs)
xs:last()
```

> returns the first element (head) or the last element (last) of a list.

``` lua
F.tail(xs)
xs:tail()
F.init(xs)
xs:init()
```

> returns the list after the head (tail) or before the last element
> (init).

``` lua
F.uncons(xs)
xs:uncons()
```

> returns the head and the tail of a list.

``` lua
F.unpack(xs, [ i, [j] ])
xs:unpack([ i, [j] ])
```

> returns the elements of xs between indices i and j

``` lua
F.take(n, xs)
xs:take(n)
```

> Returns the prefix of xs of length n.

``` lua
F.drop(n, xs)
xs:drop(n)
```

> Returns the suffix of xs after the first n elements.

``` lua
F.split_at(n, xs)
xs:split_at(n)
```

> Returns a tuple where first element is xs prefix of length n and
> second element is the remainder of the list.

``` lua
F.take_while(p, xs)
xs:take_while(p)
```

> Returns the longest prefix (possibly empty) of xs of elements that
> satisfy p.

``` lua
F.drop_while(p, xs)
xs:drop_while(p)
```

> Returns the suffix remaining after `take_while(p, xs)`.

``` lua
F.drop_while_end(p, xs)
xs:drop_while_end(p)
```

> Drops the largest suffix of a list in which the given predicate holds
> for all elements.

``` lua
F.span(p, xs)
xs:span(p)
```

> Returns a tuple where first element is longest prefix (possibly empty)
> of xs of elements that satisfy p and second element is the remainder
> of the list.

``` lua
F.break_(p, xs)
xs:break_(p)
```

> Returns a tuple where first element is longest prefix (possibly empty)
> of xs of elements that do not satisfy p and second element is the
> remainder of the list.

``` lua
F.strip_prefix(prefix, xs)
xs:strip_prefix(prefix)
```

> Drops the given prefix from a list.

``` lua
F.strip_suffix(suffix, xs)
xs:strip_suffix(suffix)
```

> Drops the given suffix from a list.

``` lua
F.group(xs, [comp_eq])
xs:group([comp_eq])
```

> Returns a list of lists such that the concatenation of the result is
> equal to the argument. Moreover, each sublist in the result contains
> only equal elements.

``` lua
F.inits(xs)
xs:inits()
```

> Returns all initial segments of the argument, shortest first.

``` lua
F.tails(xs)
xs:tails()
```

> Returns all final segments of the argument, longest first.

## Predicates

``` lua
F.is_prefix_of(prefix, xs)
prefix:is_prefix_of(xs)
```

> Returns `true` iff `xs` starts with `prefix`

``` lua
F.is_suffix_of(suffix, xs)
suffix:is_suffix_of(xs)
```

> Returns `true` iff `xs` ends with `suffix`

``` lua
F.is_infix_of(infix, xs)
infix:is_infix_of(xs)
```

> Returns `true` iff `xs` caontains `infix`

``` lua
F.has_prefix(xs, prefix)
xs:has_prefix(prefix)
```

> Returns `true` iff `xs` starts with `prefix`

``` lua
F.has_suffix(xs, suffix)
xs:has_suffix(suffix)
```

> Returns `true` iff `xs` ends with `suffix`

``` lua
F.has_infix(xs, infix)
xs:has_infix(infix)
```

> Returns `true` iff `xs` caontains `infix`

``` lua
F.is_subsequence_of(seq, xs)
seq:is_subsequence_of(xs)
```

> Returns `true` if all the elements of the first list occur, in order,
> in the second. The elements do not have to occur consecutively.

``` lua
F.is_submap_of(t1, t2)
t1:is_submap_of(t2)
```

> returns true if all keys in t1 are in t2.

``` lua
F.map_contains(t1, t2, [comp_eq])
t1:map_contains(t2, [comp_eq])
```

> returns true if all keys in t2 are in t1.

``` lua
F.is_proper_submap_of(t1, t2)
t1:is_proper_submap_of(t2)
```

> returns true if all keys in t1 are in t2 and t1 keys and t2 keys are
> different.

``` lua
F.map_strictly_contains(t1, t2, [comp_eq])
t1:map_strictly_contains(t2, [comp_eq])
```

> returns true if all keys in t2 are in t1.

## Searching

``` lua
F.elem(x, xs, [comp_eq])
xs:elem(x, [comp_eq])
```

> Returns `true` if x occurs in xs (using the optional comp_eq
> function).

``` lua
F.not_elem(x, xs, [comp_eq])
xs:not_elem(x, [comp_eq])
```

> Returns `true` if x does not occur in xs (using the optional comp_eq
> function).

``` lua
F.lookup(x, xys, [comp_eq])
xys:lookup(x, [comp_eq])
```

> Looks up a key `x` in an association list (using the optional comp_eq
> function).

``` lua
F.find(p, xs)
xs:find(p)
```

> Returns the leftmost element of xs matching the predicate p.

``` lua
F.filter(p, xs)
xs:filter(p)
```

> Returns the list of those elements that satisfy the predicate p(x).

``` lua
F.filteri(p, xs)
xs:filteri(p)
```

> Returns the list of those elements that satisfy the predicate p(i, x).

``` lua
F.filtert(p, t)
t:filtert(p)
```

> Returns the table of those values that satisfy the predicate p(v).

``` lua
F.filterk(p, t)
t:filterk(p)
```

> Returns the table of those values that satisfy the predicate p(k, v).

``` lua
F.restrict_keys(t, ks)
t:restrict_keys(ks)
```

> Restrict a map to only those keys found in a list.

``` lua
F.without_keys(t, ks)
t:without_keys(ks)
```

> Restrict a map to only those keys found in a list.

``` lua
F.partition(p, xs)
xs:partition(p)
```

> Returns the pair of lists of elements which do and do not satisfy the
> predicate, respectively.

``` lua
F.table_partition(p, t)
t:table_partition(p)
```

> Partition the map according to a predicate. The first map contains all
> elements that satisfy the predicate, the second all elements that fail
> the predicate.

``` lua
F.table_partition_with_key(p, t)
t:table_partition_with_key(p)
```

> Partition the map according to a predicate. The first map contains all
> elements that satisfy the predicate, the second all elements that fail
> the predicate.

``` lua
F.elem_index(x, xs)
xs:elem_index(x)
```

> Returns the index of the first element in the given list which is
> equal to the query element.

``` lua
F.elem_indices(x, xs)
xs:elem_indices(x)
```

> Returns the indices of all elements equal to the query element, in
> ascending order.

``` lua
F.find_index(p, xs)
xs:find_index(p)
```

> Returns the index of the first element in the list satisfying the
> predicate.

``` lua
F.find_indices(p, xs)
xs:find_indices(p)
```

> Returns the indices of all elements satisfying the predicate, in
> ascending order.

## Table size

``` lua
F.null(xs)
xs:null()
F.null(t)
t:null("t")
```

> checks wether a list or a table is empty.

``` lua
#xs
F.length(xs)
xs:length()
```

> Length of a list.

``` lua
F.size(t)
t:size()
```

> Size of a table (number of (key, value) pairs).

## Table transformations

``` lua
F.map(f, xs)
xs:map(f)
```

> maps `f` to the elements of `xs` and returns
> `{f(xs[1]), f(xs[2]), ...}`

``` lua
F.mapi(f, xs)
xs:mapi(f)
```

> maps `f` to the indices and elements of `xs` and returns
> `{f(1, xs[1]), f(2, xs[2]), ...}`

``` lua
F.mapt(f, t)
t:mapt(f)
```

> maps `f` to the values of `t` and returns
> `{k1=f(t[k1]), k2=f(t[k2]), ...}`

``` lua
F.mapk(f, t)
t:mapk(f)
```

> maps `f` to the keys and values of `t` and returns
> `{k1=f(k1, t[k1]), k2=f(k2, t[k2]), ...}`

``` lua
F.reverse(xs)
xs:reverse()
```

> reverses the order of a list

``` lua
F.transpose(xss)
xss:transpose()
```

> Transposes the rows and columns of its argument.

``` lua
F.update(f, k, t)
t:update(f, k)
```

> Updates the value `x` at `k`. If `f(x)` is nil, the element is
> deleted. Otherwise the key `k` is bound to the value `f(x)`.
>
> **Warning**: in-place modification.

``` lua
F.updatek(f, k, t)
t:updatek(f, k)
```

> Updates the value `x` at `k`. If `f(k, x)` is nil, the element is
> deleted. Otherwise the key `k` is bound to the value `f(k, x)`.
>
> **Warning**: in-place modification.

## Table transversal

``` lua
F.foreach(xs, f)
xs:foreach(f)
```

> calls `f` with the elements of `xs` (`f(xi)` for `xi` in `xs`)

``` lua
F.foreachi(xs, f)
xs:foreachi(f)
```

> calls `f` with the indices and elements of `xs` (`f(i, xi)` for `xi`
> in `xs`)

``` lua
F.foreacht(t, f)
t:foreacht(f)
```

> calls `f` with the values of `t` (`f(v)` for `v` in `t` such that
> `v = t[k]`)

``` lua
F.foreachk(t, f)
t:foreachk(f)
```

> calls `f` with the keys and values of `t` (`f(k, v)` for (`k`, `v`) in
> `t` such that `v = t[k]`)

## Table reductions (folds)

``` lua
F.fold(f, x, xs)
xs:fold(f, x)
```

> Left-associative fold of a list (`f(...f(f(x, xs[1]), xs[2]), ...)`).

``` lua
F.foldi(f, x, xs)
xs:foldi(f, x)
```

> Left-associative fold of a list
> (`f(...f(f(x, 1, xs[1]), 2, xs[2]), ...)`).

``` lua
F.fold1(f, xs)
xs:fold1(f)
```

> Left-associative fold of a list, the initial value is `xs[1]`.

``` lua
F.foldt(f, x, t)
t:foldt(f, x)
```

> Left-associative fold of a table (in the order given by F.pairs).

``` lua
F.foldk(f, x, t)
t:foldk(f, x)
```

> Left-associative fold of a table (in the order given by F.pairs).

``` lua
F.land(bs)
bs:land()
```

> Returns the conjunction of a container of booleans.

``` lua
F.lor(bs)
bs:lor()
```

> Returns the disjunction of a container of booleans.

``` lua
F.any(p, xs)
xs:any(p)
```

> Determines whether any element of the structure satisfies the
> predicate.

``` lua
F.all(p, xs)
xs:all(p)
```

> Determines whether all elements of the structure satisfy the
> predicate.

``` lua
F.sum(xs)
xs:sum()
```

> Returns the sum of the numbers of a structure.

``` lua
F.product(xs)
xs:product()
```

> Returns the product of the numbers of a structure.

``` lua
F.maximum(xs, [comp_lt])
xs:maximum([comp_lt])
```

> The largest element of a non-empty structure, according to the
> optional comparison function.

``` lua
F.minimum(xs, [comp_lt])
xs:minimum([comp_lt])
```

> The least element of a non-empty structure, according to the optional
> comparison function.

``` lua
F.scan(f, x, xs)
xs:scan(f, x)
```

> Similar to `fold` but returns a list of successive reduced values from
> the left.

``` lua
F.scan1(f, xs)
xs:scan1(f)
```

> Like `scan` but the initial value is `xs[1]`.

``` lua
F.concat_map(f, xs)
xs:concat_map(f)
```

> Map a function over all the elements of a container and concatenate
> the resulting lists.

## Zipping

``` lua
F.zip(xss, [f])
xss:zip([f])
```

> `zip` takes a list of lists and returns a list of corresponding
> tuples.

``` lua
F.unzip(xss)
xss:unzip()
```

> Transforms a list of n-tuples into n lists

``` lua
F.zip_with(f, xss)
xss:zip_with(f)
```

> `zip_with` generalises `zip` by zipping with the function given as the
> first argument, instead of a tupling function.

## Set operations

``` lua
F.nub(xs, [comp_eq])
xs:nub([comp_eq])
```

> Removes duplicate elements from a list. In particular, it keeps only
> the first occurrence of each element, according to the optional
> comp_eq function.

``` lua
F.delete(x, xs, [comp_eq])
xs:delete(x, [comp_eq])
```

> Removes the first occurrence of x from its list argument, according to
> the optional comp_eq function.

``` lua
F.difference(xs, ys, [comp_eq])
xs:difference(ys, [comp_eq])
```

> Returns the list difference. In `difference(xs, ys)` the first
> occurrence of each element of ys in turn (if any) has been removed
> from xs, according to the optional comp_eq function.

``` lua
F.union(xs, ys, [comp_eq])
xs:union(ys, [comp_eq])
```

> Returns the list union of the two lists. Duplicates, and elements of
> the first list, are removed from the the second list, but if the first
> list contains duplicates, so will the result, according to the
> optional comp_eq function.

``` lua
F.intersection(xs, ys, [comp_eq])
xs:intersection(ys, [comp_eq])
```

> Returns the list intersection of two lists. If the first list contains
> duplicates, so will the result, according to the optional comp_eq
> function.

## Table operations

``` lua
F.merge(ts)
ts:merge()
F.table_union(ts)
ts:table_union()
```

> Right-biased union of tables.

``` lua
F.merge_with(f, ts)
ts:merge_with(f)
F.table_union_with(f, ts)
ts:table_union_with(f)
```

> Right-biased union of tables with a combining function.

``` lua
F.merge_with_key(f, ts)
ts:merge_with_key(f)
F.table_union_with_key(f, ts)
ts:table_union_with_key(f)
```

> Right-biased union of tables with a combining function.

``` lua
F.table_difference(t1, t2)
t1:table_difference(t2)
```

> Difference of two maps. Return elements of the first map not existing
> in the second map.

``` lua
F.table_difference_with(f, t1, t2)
t1:table_difference_with(f, t2)
```

> Difference with a combining function. When two equal keys are
> encountered, the combining function is applied to the values of these
> keys.

``` lua
F.table_difference_with_key(f, t1, t2)
t1:table_difference_with_key(f, t2)
```

> Union with a combining function.

``` lua
F.table_intersection(t1, t2)
t1:table_intersection(t2)
```

> Intersection of two maps. Return data in the first map for the keys
> existing in both maps.

``` lua
F.table_intersection_with(f, t1, t2)
t1:table_intersection_with(f, t2)
```

> Difference with a combining function. When two equal keys are
> encountered, the combining function is applied to the values of these
> keys.

``` lua
F.table_intersection_with_key(f, t1, t2)
t1:table_intersection_with_key(f, t2)
```

> Union with a combining function.

``` lua
F.disjoint(t1, t2)
t1:disjoint(t2)
```

> Check the intersection of two maps is empty.

``` lua
F.table_compose(t1, t2)
t1:table_compose(t2)
```

> Relate the keys of one map to the values of the other, by using the
> values of the former as keys for lookups in the latter.

``` lua
F.Nil
```

> `F.Nil` is a singleton used to represent `nil` (see `F.patch`)

``` lua
F.patch(t1, t2)
t1:patch(t2)
```

> returns a copy of `t1` where some fields are replaced by values from
> `t2`. Keys not found in `t2` are not modified. If `t2` contains
> `F.Nil` then the corresponding key is removed from `t1`. Unmodified
> subtrees are not cloned but returned as is (common subtrees are
> shared).

## Ordered lists

``` lua
F.sort(xs, [comp_lt])
xs:sort([comp_lt])
```

> Sorts xs from lowest to highest, according to the optional comp_lt
> function.

``` lua
F.sort_on(f, xs, [comp_lt])
xs:sort_on(f, [comp_lt])
```

> Sorts a list by comparing the results of a key function applied to
> each element, according to the optional comp_lt function.

``` lua
F.insert(x, xs, [comp_lt])
xs:insert(x, [comp_lt])
```

> Inserts the element into the list at the first position where it is
> less than or equal to the next element, according to the optional
> comp_lt function.

## Miscellaneous functions

``` lua
F.subsequences(xs)
xs:subsequences()
```

> Returns the list of all subsequences of the argument.

``` lua
F.permutations(xs)
xs:permutations()
```

> Returns the list of all permutations of the argument.

## Functions on strings

``` lua
string.chars(s, i, j)
s:chars(i, j)
```

> Returns the list of characters of a string between indices i and j, or
> the whole string if i and j are not provided.

``` lua
string.bytes(s, i, j)
s:bytes(i, j)
```

> Returns the list of byte codes of a string between indices i and j, or
> the whole string if i and j are not provided.

``` lua
string.head(s)
s:head()
```

> Extract the first element of a string.

``` lua
sting.last(s)
s:last()
```

> Extract the last element of a string.

``` lua
string.tail(s)
s:tail()
```

> Extract the elements after the head of a string

``` lua
string.init(s)
s:init()
```

> Return all the elements of a string except the last one.

``` lua
string.uncons(s)
s:uncons()
```

> Decompose a string into its head and tail.

``` lua
string.null(s)
s:null()
```

> Test whether the string is empty.

``` lua
string.length(s)
s:length()
```

> Returns the length of a string.

``` lua
string.intersperse(c, s)
c:intersperse(s)
```

> Intersperses a element c between the elements of s.

``` lua
string.intercalate(s, ss)
s:intercalate(ss)
```

> Inserts the string s in between the strings in ss and concatenates the
> result.

``` lua
string.subsequences(s)
s:subsequences()
```

> Returns the list of all subsequences of the argument.

``` lua
string.permutations(s)
s:permutations()
```

> Returns the list of all permutations of the argument.

``` lua
string.take(s, n)
s:take(n)
```

> Returns the prefix of s of length n.

``` lua
string.drop(s, n)
s:drop(n)
```

> Returns the suffix of s after the first n elements.

``` lua
string.split_at(s, n)
s:split_at(n)
```

> Returns a tuple where first element is s prefix of length n and second
> element is the remainder of the string.

``` lua
string.take_while(s, p)
s:take_while(p)
```

> Returns the longest prefix (possibly empty) of s of elements that
> satisfy p.

``` lua
string.drop_while(s, p)
s:drop_while(p)
```

> Returns the suffix remaining after `s:take_while(p)`.

``` lua
string.drop_while_end(s, p)
s:drop_while_end(p)
```

> Drops the largest suffix of a string in which the given predicate
> holds for all elements.

``` lua
string.strip_prefix(s, prefix)
s:strip_prefix(prefix)
```

> Drops the given prefix from a string.

``` lua
string.strip_suffix(s, suffix)
s:strip_suffix(suffix)
```

> Drops the given suffix from a string.

``` lua
string.inits(s)
s:inits()
```

> Returns all initial segments of the argument, shortest first.

``` lua
string.tails(s)
s:tails()
```

> Returns all final segments of the argument, longest first.

``` lua
string.is_prefix_of(prefix, s)
prefix:is_prefix_of(s)
```

> Returns `true` iff the first string is a prefix of the second.

``` lua
string.has_prefix(s, prefix)
s:has_prefix(prefix)
```

> Returns `true` iff the second string is a prefix of the first.

``` lua
string.is_suffix_of(suffix, s)
suffix:is_suffix_of(s)
```

> Returns `true` iff the first string is a suffix of the second.

``` lua
string.has_suffix(s, suffix)
s:has_suffix(suffix)
```

> Returns `true` iff the second string is a suffix of the first.

``` lua
string.is_infix_of(infix, s)
infix:is_infix_of(s)
```

> Returns `true` iff the first string is contained, wholly and intact,
> anywhere within the second.

``` lua
string.has_infix(s, infix)
s:has_infix(infix)
```

> Returns `true` iff the second string is contained, wholly and intact,
> anywhere within the first.

``` lua
string.matches(s, pattern, [init])
s:matches(pattern, [init])
```

> Returns the list of the captures from `pattern` by iterating on
> `string.gmatch`. If `pattern` defines two or more captures, the result
> is a list of list of captures.

``` lua
string.split(s, sep, maxsplit, plain)
s:split(sep, maxsplit, plain)
```

> Splits a string `s` around the separator `sep`. `maxsplit` is the
> maximal number of separators. If `plain` is true then the separator is
> a plain string instead of a Lua string pattern.

``` lua
string.lines(s)
s:lines()
```

> Splits the argument into a list of lines stripped of their terminating
> `\n` characters.

``` lua
string.words(s)
s:words()
```

> Breaks a string up into a list of words, which were delimited by white
> space.

``` lua
F.unlines(xs)
xs:unlines()
```

> Appends a `\n` character to each input string, then concatenates the
> results.

``` lua
string.unwords(xs)
xs:unwords()
```

> Joins words with separating spaces.

``` lua
string.ltrim(s)
s:ltrim()
```

> Removes heading spaces

``` lua
string.rtrim(s)
s:rtrim()
```

> Removes trailing spaces

``` lua
string.trim(s)
s:trim()
```

> Removes heading and trailing spaces

``` lua
string.ljust(s, w)
s:ljust(w)
```

> Left-justify `s` by appending spaces. The result is at least `w` byte
> long. `s` is not truncated.

``` lua
string.rjust(s, w)
s:rjust(w)
```

> Right-justify `s` by prepending spaces. The result is at least `w`
> byte long. `s` is not truncated.

``` lua
string.center(s, w)
s:center(w)
```

> Center `s` by appending and prepending spaces. The result is at least
> `w` byte long. `s` is not truncated.

``` lua
string.cap(s)
s:cap()
```

> Capitalizes a string. The first character is upper case, other are
> lower case.

## Identifier formatting

``` lua
string.lower_snake_case(s)              -- e.g.: hello_world
string.upper_snake_case(s)              -- e.g.: HELLO_WORLD
string.lower_camel_case(s)              -- e.g.: helloWorld
string.upper_camel_case(s)              -- e.g.: HelloWorld
string.dotted_lower_snake_case(s)       -- e.g.: hello.world
string.dotted_upper_snake_case(s)       -- e.g.: hello.world

F.lower_snake_case(s)                   -- e.g.: hello_world
F.upper_snake_case(s)                   -- e.g.: HELLO_WORLD
F.lower_camel_case(s)                   -- e.g.: helloWorld
F.upper_camel_case(s)                   -- e.g.: HelloWorld
F.dotted_lower_snake_case(s)            -- e.g.: hello.world
F.dotted_upper_snake_case(s)            -- e.g.: hello.world

s:lower_snake_case()                    -- e.g.: hello_world
s:upper_snake_case()                    -- e.g.: HELLO_WORLD
s:lower_camel_case()                    -- e.g.: helloWorld
s:upper_camel_case()                    -- e.g.: HelloWorld
s:dotted_lower_snake_case()             -- e.g.: hello.world
s:dotted_upper_snake_case()             -- e.g.: hello.world
```

> Convert an identifier using some wellknown naming conventions. `s` can
> be a string or a list of strings.

## String evaluation

``` lua
string.read(s)
s:read()
```

> Convert s to a Lua value (like `F.read`)

## String interpolation

``` lua
F.I(t)
```

> returns a string interpolator that replaces `$(...)` with the value of
> `...` in the environment defined by the table `t`. An interpolator can
> be given another table to build a new interpolator with new values.
>
> The mod operator (`%`) produces a new interpolator with a custom
> pattern. E.g. `F.I % "@[]"` is an interpolator that replaces `@[...]`
> with the value of `...`.

## Random array access

``` lua
F.choose(xs, prng)
F.choose(xs)    -- using the global PRNG
xs:choose(prng)
xs:choose()     -- using the global PRNG
```

returns a random item from `xs`

``` lua
F.shuffle(xs, prng)
F.shuffle(xs)   -- using the global PRNG
xs:shuffle(prng)
xs:shuffle()    -- using the global PRNG
```

returns a shuffled copy of `xs`
