# List

`List` is a module inspired by the Haskell module
[`Data.List`](https://hackage.haskell.org/package/base-4.17.0.0/docs/Data-List.html).

Note: contrary to the original Haskell modules, all these functions are
evaluated strictly (i.e. no lazy evaluation, no infinite list, …).

``` lua
local L = require "List"
```

## Basic functions

``` lua
L.clone(xs)
xs:clone()
```

> Clone a list

``` lua
L.ipairs(xs)
xs:ipairs()
```

> Like Lua ipairs function

``` lua
xs .. ys
```

> Append two lists, i.e.,
>
> ``` lua
> L{x1, ..., xn} .. L{y1, ..., yn} == L{x1, ..., xn, y1, ..., yn}
> ```

``` lua
L.head(xs)
xs:head()
```

> Extract the first element of a list.
>
> ``` lua
> head{1,2,3} == 1
> head{} == nil
> ```

``` lua
L.last(xs)
xs:last()
```

> Extract the last element of a list.
>
> ``` lua
> last{1,2,3} == 3
> last{} == nil
> ```

``` lua
L.tail(xs)
xs:tail()
```

> Extract the elements after the head of a list
>
> ``` lua
> tail{1,2,3} == {2,3}
> tail{} == nil
> ```

``` lua
L.init(xs)
xs:init()
```

> Return all the elements of a list except the last one.
>
> ``` lua
> init{1,2,3} == {1,2}
> init{} = nil
> ```

``` lua
L.uncons(xs)
xs:uncons()
```

> Decompose a list into its head and tail.
>
> ``` lua
> uncons{1,2,3} == 1, {2,3}
> uncons{} = nil, nil
> ```

``` lua
L.singleton(x)
```

> Produce singleton list.
>
> ``` lua
> singleton(true) == {true}
> ```

``` lua
L.null(xs)
xs:null()
```

> Test whether the structure is empty.
>
> ``` lua
> null{} == true
> null{1,2,3} == false
> ```

``` lua
L.length(xs)
xs:length()
```

> Returns the length of a list.
>
> ``` lua
> length{} == 0
> length{1,2,3} == 3
> ```

## List transformations

``` lua
L.map(f, xs)
xs:map(f)
```

> Returns the list obtained by applying f to each element of xs
>
> ``` lua
> map(f, {x1, x2, ...}) == {f(x1), f(x2), ...}
> ```

``` lua
L.mapWithIndex(f, xs)
xs:mapWithIndex(f)
```

> Returns the list obtained by applying f to each element of xs with
> their positions
>
> ``` lua
> mapWithIndex(f, {x1, x2, ...}) == {f(1, x1), f(2, x2), ...}
> ```

``` lua
L.reverse(xs)
xs:reverse()
```

> Returns the elements of xs in reverse order.
>
> ``` lua
> reverse{1,2,3} == {3,2,1}
> ```

``` lua
L.intersperse(x, xs)
xs:intersperse(x)
```

> Intersperses a element x between the elements of xs.
>
> ``` lua
> intersperse(x, {x1, x2, x3}) == {x1, x, x2, x, x3}
> ```

``` lua
intercalate(xs, xss)
xss:intercalate(xs)
```

> Inserts the list xs in between the lists in xss and concatenates the
> result.
>
> ``` lua
> intercalate({x1, x2}, {{y1, y2}, {y3, y4}, {y5, y6}}) ==
>   {y1, y2, x1, x2, y3, y4, x1, x2, y5, y6}
> ```

``` lua
L.transpose(xss)
xss:transpose()
```

> Transposes the rows and columns of its argument.
>
> ``` lua
> transpose{{x1,x2,x3},{y1,y2,y3}} == {{x1,y1},{x2,y2},{x3,y3}}
> ```

``` lua
L.subsequences(xs)
xs:subsequences()
```

> Returns the list of all subsequences of the argument.
>
> ``` lua
> subsequences{"a", "b", "c"} ==
>   {{}, {"a"}, {"b"}, {"a","b"}, {"c"}, {"a","c"}, {"b","c"}, {"a","b","c"}}
> ```

``` lua
L.permutations(xs)
xs:permutations()
```

> Returns the list of all permutations of the argument.
>
> ``` lua
> permutations{"a", "b", "c"} ==
>   { {"a","b","c"}, {"a","c","b"},
>     {"b","a","c"}, {"b","c","a"},
>     {"c","b","a"}, {"c","a","b"} }
> ```

``` lua
L.flatten(xs)
xs:flatten()
```

> Returns a flat list with all elements recursively taken from xs

## Reducing lists (folds)

``` lua
L.foldl(f, x, xs)
xs:foldl(f, x)
```

> Left-associative fold of a structure.
>
> ``` lua
> foldl(f, x, {x1, x2, x3}) == f(f(f(x, x1), x2), x3)
> ```

``` lua
L.foldl1(f, xs)
xs:foldl1(f)
```

> Left-associative fold of a structure (the initial value is `xs[1]`).
>
> ``` lua
> foldl1(f, {x1, x2, x3}) == f(f(x1, x2), x3)
> ```

``` lua
L.foldr(f, x, xs)
xs:foldr(f, x)
```

> Right-associative fold of a structure.
>
> ``` lua
> foldr(f, x, {x1, x2, x3}) == f(x1, f(x2, f(x3, x)))
> ```

``` lua
L.foldr1(f, xs)
xs:foldr1(f)
```

> Right-associative fold of a structure (the initial value is
> `xs[#xs]`).
>
> ``` lua
> foldr1(f, {x1, x2, x3}) == f(x1, f(x2, x3))
> ```

## Special folds

``` lua
L.concat(xss)
xss:concat()
```

> The concatenation of all the elements of a container of lists.
>
> ``` lua
> concat{{x1, x2}, {x3}, {x4, x5}} == {x1,x2,x3,x4,x5}
> ```

``` lua
L.concatMap(f, xs)
xs:concatMap(f)
```

> Map a function over all the elements of a container and concatenate
> the resulting lists.

``` lua
L.and_(bs)
bs:and_()
```

> Returns the conjunction of a container of Bools.

``` lua
L.or_(bs)
bs:or_()
```

> Returns the disjunction of a container of Bools.

``` lua
L.any(p, xs)
xs:any(p)
```

> Determines whether any element of the structure satisfies the
> predicate.

``` lua
L.all(p, xs)
xs:all(p)
```

> Determines whether all elements of the structure satisfy the
> predicate.

``` lua
L.sum(xs)
xs:sum()
```

> Returns the sum of the numbers of a structure.

``` lua
L.product(xs)
xs:product()
```

> Returns the product of the numbers of a structure.

``` lua
L.maximum(xs)
xs:maximum()
```

> The largest element of a non-empty structure.

``` lua
L.minimum(xs)
xs:minimum()
```

> The least element of a non-empty structure.

## Building lists

### Scans

``` lua
L.scanl(f, x, xs)
xs:scanl(f, x)
```

> Similar to `foldl` but returns a list of successive reduced values
> from the left.

``` lua
L.scanl1(f, xs)
xs:scanl1(f)
```

> Like `scanl` but the initial value is `xs[1]`.

``` lua
L.scanr(f, x, xs)
xs:scanr(f, x)
```

> Similar to `foldr` but returns a list of successive reduced values
> from the right.

``` lua
L.scanr1(f, xs)
xs:scanr1(f)
```

> Like `scanr` but the initial value is `xs[#xs]`.

### Infinite lists

``` lua
replicate(n, x)
```

> Returns a list of length n with x the value of every element.

### Unfolding

``` lua
L.unfoldr(f, z)
```

> Builds a list from a seed value (dual of `foldr`).

### Range

``` lua
L.range(a)
L.range(a, b)
L.range(a, b, step)
```

> Returns a range \[1, a\], \[a, b\] or \[a, a+step, … b\]

## Sublists

### Extracting sublists

``` lua
L.take(n, xs)
xs:take(n)
```

> Returns the prefix of xs of length n.

``` lua
L.drop(n, xs)
xs:drop(n)
```

> Returns the suffix of xs after the first n elements.

``` lua
L.splitAt(n, xs)
xs:splitAt(n)
```

> Returns a tuple where first element is xs prefix of length n and
> second element is the remainder of the list.

``` lua
L.takeWhile(p, xs)
xs:takeWhile(p)
```

> Returns the longest prefix (possibly empty) of xs of elements that
> satisfy p.

``` lua
L.dropWhile(p, xs)
xs:dropWhile(p)
```

> Returns the suffix remaining after `takeWhile(p, xs)`.

``` lua
L.dropWhileEnd(p, xs)
xs:dropWhileEnd(p)
```

> Drops the largest suffix of a list in which the given predicate holds
> for all elements.

``` lua
L.span(p, xs)
xs:span(p)
```

> Returns a tuple where first element is longest prefix (possibly empty)
> of xs of elements that satisfy p and second element is the remainder
> of the list.

``` lua
L.break_(p, xs)
xs:break_(p)
```

> Returns a tuple where first element is longest prefix (possibly empty)
> of xs of elements that do not satisfy p and second element is the
> remainder of the list.

``` lua
L.stripPrefix(prefix, xs)
xs:stripPrefix(prefix)
```

> Drops the given prefix from a list.

``` lua
L.group(xs)
xs:group()
```

> Returns a list of lists such that the concatenation of the result is
> equal to the argument. Moreover, each sublist in the result contains
> only equal elements.

``` lua
L.inits(xs)
xs:inits()
```

> Returns all initial segments of the argument, shortest first.

``` lua
L.tails(xs)
xs:tails()
```

> Returns all final segments of the argument, longest first.

### Predicates

``` lua
L.isPrefixOf(prefix, xs)
prefix:isPrefixOf(xs)
```

> Returns `true` iff the first list is a prefix of the second.

``` lua
L.isSuffixOf(suffix, xs)
suffix:isSuffixOf(xs)
```

> Returns `true` iff the first list is a suffix of the second.

``` lua
L.isInfixOf(infix, xs)
infix:isInfixOf(xs)
```

> Returns `true` iff the first list is contained, wholly and intact,
> anywhere within the second.

``` lua
L.isSubsequenceOf(seq, xs)
seq:isSubsequenceOf(xs)
```

> Returns `true` if all the elements of the first list occur, in order,
> in the second. The elements do not have to occur consecutively.

## Searching lists

### Searching by equality

``` lua
L.elem(x, xs)
xs:elem(x)
```

> Returns `true` if x occurs in xs.

``` lua
L.notElem(x, xs)
xs:notElem(x)
```

> Returns `true` if x does not occur in xs.

``` lua
L.lookup(x, xys)
xys:lookup(x)
```

> Looks up a hey `x` in an association list.

### Searching with a predicate

``` lua
L.find(p, xs)
xs:find(p)
```

> Returns the leftmost element of xs matching the predicate p.

``` lua
L.filter(p, xs)
xs:filter(p)
```

> Returns the list of those elements that satisfy the predicate.

``` lua
L.partition(p, xs)
xs:partition(p)
```

> Returns the pair of lists of elements which do and do not satisfy the
> predicate, respectively.

## Indexing lists

``` lua
L.elemIndex(x, xs)
xs:elemIndex(x)
```

> Returns the index of the first element in the given list which is
> equal to the query element.

``` lua
L.elemIndices(x, xs)
xs:elemIndices(x)
```

> Returns the indices of all elements equal to the query element, in
> ascending order.

``` lua
L.findIndex(p, xs)
xs:findIndex(p)
```

> Returns the index of the first element in the list satisfying the
> predicate.

``` lua
L.findIndices(p, xs)
xs:findIndices(p)
```

> Returns the indices of all elements satisfying the predicate, in
> ascending order.

## Zipping and unzipping lists

``` lua
L.zip(as, bs)
L.zip3(as, bs, cs)
L.zip4(as, bs, cs, ds)
L.zip5(as, bs, cs, ds, es)
L.zip6(as, bs, cs, ds, es, fs)
L.zip7(as, bs, cs, ds, es, fs, gs)
as:zip(bs)
as:zip3(bs, cs)
as:zip4(bs, cs, ds)
as:zip5(bs, cs, ds, es)
as:zip6(bs, cs, ds, es, fs)
as:zip7(bs, cs, ds, es, fs, gs)
```

> `zipN` takes `N` lists and returns a list of corresponding tuples.

``` lua
L.zipWith(f, as, bs)
L.zipWith3(f, as, bs, cs)
L.zipWith4(f, as, bs, cs, ds)
L.zipWith5(f, as, bs, cs, ds, es)
L.zipWith6(f, as, bs, cs, ds, es, fs)
L.zipWith7(f, as, bs, cs, ds, es, fs, gs)
as:zipWith(f,bs)
as:zipWith3(f, bs, cs)
as:zipWith4(f, bs, cs, ds)
as:zipWith5(f, bs, cs, ds, es)
as:zipWith6(f, bs, cs, ds, es, fs)
as:zipWith7(f, bs, cs, ds, es, fs, gs)
```

> `zipWith` generalises `zip` by zipping with the function given as the
> first argument, instead of a tupling function.

``` lua
L.unzip(zs)
L.unzip3(zs)
L.unzip4(zs)
L.unzip5(zs)
L.unzip6(zs)
L.unzip7(zs)
zs:unzip()
zs:unzip3()
zs:unzip4()
zs:unzip5()
zs:unzip6()
zs:unzip7()
```

> Transforms a list of n-tuples into a list of n lists

## Special lists

### Functions on strings

``` lua
L.lines(s)
```

> Splits the argument into a list of lines stripped of their terminating
> `\n` characters.

``` lua
L.words(s)
```

> Breaks a string up into a list of words, which were delimited by white
> space.

``` lua
L.unlines(s)
s:unlines()
```

> Appends a `\n` character to each input string, then concatenates the
> results.

``` lua
L.unwords(s)
s:unwords()
```

> Joins words with separating spaces.

### Set operations

``` lua
L.nub(xs)
xs:nub()
```

> Removes duplicate elements from a list. In particular, it keeps only
> the first occurrence of each element.

``` lua
L.delete(x, xs)
xs:delete(x)
```

> Removes the first occurrence of x from its list argument.

``` lua
L.difference(xs, ys)
xs:difference(ys)
```

> Returns the list difference. In `difference(xs, ys)` the first
> occurrence of each element of ys in turn (if any) has been removed
> from xs.

``` lua
L.union(xs, ys)
xs:union(ys)
```

> Returns the list union of the two lists. Duplicates, and elements of
> the first list, are removed from the the second list, but if the first
> list contains duplicates, so will the result.

``` lua
L.intersect(xs, ys)
xs:intersect(ys)
```

> Returns the list intersection of two lists. If the first list contains
> duplicates, so will the result.

### Ordered lists

``` lua
L.sort(xs)
xs:sort()
```

> Sorts xs from lowest to highest.

``` lua
L.sortOn(f, xs)
xs:sortOn(f)
```

> Sorts a list by comparing the results of a key function applied to
> each element.

``` lua
L.insert(x, xs)
xs:insert(x)
```

> Inserts the element into the list at the first position where it is
> less than or equal to the next element.

## Generalized functions

``` lua
L.nubBy(eq, xs)
xs:nubBy(eq)
```

> like nub, except it uses a user-supplied equality predicate instead of
> the overloaded == function.

``` lua
L.deleteBy(eq, x, xs)
xs:deleteBy(eq, x)
```

> like delete, except it uses a user-supplied equality predicate instead
> of the overloaded == function.

``` lua
L.differenceBy(eq, xs, ys)
xs:differenceBy(eq, ys)
```

> like difference, except it uses a user-supplied equality predicate
> instead of the overloaded == function.

``` lua
L.unionBy(eq, xs, ys)
xs:unionBy(eq, ys)
```

> like union, except it uses a user-supplied equality predicate instead
> of the overloaded == function.

``` lua
L.intersectBy(eq, xs, ys)
xs:intersectBy(eq, ys)
```

> like intersect, except it uses a user-supplied equality predicate
> instead of the overloaded == function.

``` lua
L.groupBy(eq, xs)
xs:groupBy(eq)
```

> like group, except it uses a user-supplied equality predicate instead
> of the overloaded == function.

``` lua
L.sortBy(le, xs)
xs:sortBy(le)
```

> like sort, except it uses a user-supplied equality predicate instead
> of the overloaded \<= function.

``` lua
L.insertBy(le, x, xs)
xs:insertBy(le, x)
```

> like insert, except it uses a user-supplied equality predicate instead
> of the overloaded \<= function.

``` lua
L.maximumBy(le, xs)
xs:maximum(le)
```

> like maximum, except it uses a user-supplied equality predicate
> instead of the overloaded \<= function.

``` lua
L.minimumBy(le, xs)
xs:minimum(le)
```

> like minimum, except it uses a user-supplied equality predicate
> instead of the overloaded \<= function.
