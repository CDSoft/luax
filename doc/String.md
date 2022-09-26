# String

`String` is a module inspired by the Haskell modules
[`Data.List`](https://hackage.haskell.org/package/base-4.17.0.0/docs/Data-List.html)
and
[`Data.String`](https://hackage.haskell.org/package/base-4.17.0.0/docs/Data-String.html).

Note: contrary to the original Haskell modules, all these functions are
evaluated strictly (i.e. no lazy evaluation, no infinite string, …).

``` lua
local S = require "String"
```

## Basic functions

``` lua
S.toChars(s)
s:toChars()
```

> Returns the list of characters of a string

``` lua
s1 .. s2
```

> Append two strings, i.e.,

``` lua
S.head(s)
s:head()
```

> Extract the first element of a string.
>
> ``` lua
> head"123" == "1"
> head"" == nil
> ```

``` lua
S.last(s)
s:last()
```

> Extract the last element of a string.

``` lua
S.tail(s)
s:tail()
```

> Extract the elements after the head of a string

``` lua
S.init(s)
s:init()
```

> Return all the elements of a string except the last one.

``` lua
S.uncons(s)
S:uncons()
```

> Decompose a string into its head and tail.

``` lua
S.null(s)
s:null()
```

> Test whether the string is empty.

``` lua
S.length(s)
s:length()
```

> Returns the length of a string.

## String transformations

``` lua
S.map(f, s)
s:map(f)
```

> Returns the string obtained by applying f to each element of s

``` lua
S.mapWithIndex(f, s)
s:mapWithIndex(f)
```

> Returns the string obtained by applying f to each element of xs with
> their positions

``` lua
S.reverse(s)
s:reverse()
```

> Returns the elements of s in reverse order.

``` lua
S.intersperse(c, s)
c:intersperse(s)
```

> Intersperses a element c between the elements of s.

``` lua
S.intercalate(s, ss)
s:intercalate(ss)
```

> Inserts the string s in between the strings in ss and concatenates the
> result.

``` lua
S.subsequences(s)
s:subsequences()
```

> Returns the list of all subsequences of the argument.

``` lua
S.permutations(s)
s:permutations()
```

> Returns the list of all permutations of the argument.

## Reducing strings (folds)

``` lua
S.foldl(f, z, s)
s:foldl(f, z)
```

> Left-associative fold of a string.

``` lua
S.foldl1(f, s)
s:foldl1(f)
```

> Left-associative fold of a string (the initial value is `s[1]`).

``` lua
S.foldr(f, z, s)
s:foldr(f, z)
```

> Right-associative fold of a string.

``` lua
S.foldr1(f, s)
s:foldr1(f)
```

> Right-associative fold of a string (the initial value is `s[#s]`).

## Special folds

``` lua
S.concat(ss)
```

> The concatenation of all the elements of a container of strings.

``` lua
S.any(p, xs)
xs:any(p)
```

> Determines whether any element of the string satisfies the predicate.

``` lua
S.all(p, s)
s:all(p)
```

> Determines whether all elements of the string satisfy the predicate.

``` lua
S.maximum(s)
s:maximum()
```

> The largest element of a non-empty string.

``` lua
S.minimum(s)
s:minimum()
```

> The least element of a non-empty string.

## Building strings

### Scans

``` lua
S.scanl(f, z, s)
s:scanl(f, z)
```

> Similar to `foldl` but returns a list of successive reduced values
> from the left.

``` lua
S.scanl1(f, s)
s:scanl1(f)
```

> Like `scanl` but the initial value is `s[1]`.

``` lua
S.scanr(f, z, s)
s:scanr(f, z)
```

> Similar to `foldr` but returns a list of successive reduced values
> from the right.

``` lua
S.scanr1(f, s)
s:scanr1(f)
```

> Like `scanr` but the initial value is `s[#s]`.

### Infinite strings

``` lua
S.replicate(n, c)
c:replicate(n)
```

> Returns a string of length n with x the value of every element.

### Unfolding

``` lua
S.unfoldr(f, z)
```

> Builds a string from a seed value (dual of `foldr`).

## Substrings

### Extracting strings

``` lua
S.take(n, s)
s:take(n)
```

> Returns the prefix of s of length n.

``` lua
S.drop(n, s)
s:drop(n)
```

> Returns the suffix of s after the first n elements.

``` lua
S.splitAt(n, s)
s:splitAt(n)
```

> Returns a tuple where first element is s prefix of length n and second
> element is the remainder of the list.

``` lua
S.takeWhile(p, s)
s:takeWhile(p)
```

> Returns the longest prefix (possibly empty) of s of elements that
> satisfy p.

``` lua
S.dropWhile(p, s)
s:dropWhile(p)
```

> Returns the suffix remaining after `takeWhile(p, s)`.

``` lua
L.dropWhileEnd(p, s)
s:dropWhileEnd(p)
```

> Drops the largest suffix of a list in which the given predicate holds
> for all elements.

``` lua
L.span(p, s)
s:span(p)
```

> Returns a tuple where first element is longest prefix (possibly empty)
> of xs of elements that satisfy p and second element is the remainder
> of the list.

``` lua
S.break_(p, s)
s:break_(p)
```

> Returns a tuple where first element is longest prefix (possibly empty)
> of s of elements that do not satisfy p and second element is the
> remainder of the list.

``` lua
S.stripPrefix(prefix, s)
s:stripPrefix(prefix)
```

> Drops the given prefix from a list.

``` lua
L.group(s)
s:group()
```

> Returns a list of strings such that the concatenation of the result is
> equal to the argument. Moreover, each sublist in the result contains
> only equal elements.

``` lua
S.inits(s)
s:inits()
```

> Returns all initial segments of the argument, shortest first.

``` lua
L.tails(s)
s:tails()
```

> Returns all final segments of the argument, longest first.

### Predicates

``` lua
S.isPrefixOf(prefix, s)
prefix:isPrefixOf(s)
```

> Returns `true` iff the first string is a prefix of the second.

``` lua
S.isSuffixOf(suffix, s)
suffix:isSuffixOf(s)
```

> Returns `true` iff the first string is a suffix of the second.

``` lua
S.isInfixOf(infix, s)
infix:isInfixOf(s)
```

> Returns `true` iff the first string is contained, wholly and intact,
> anywhere within the second.

``` lua
S.isSubsequenceOf(seq, s)
seq:isSubsequenceOf(s)
```

> Returns `true` if all the elements of the first string occur, in
> order, in the second. The elements do not have to occur consecutively.

## Searching strings

### Searching by equality

``` lua
S.elem(x, s)
x:elem(s)
```

> Returns `true` if x occurs in s.

``` lua
S.notElem(x, s)
x:notElem(s)
```

> Returns `true` if x does not occur in s.

### Searching with a predicate

``` lua
S.find(p, s)
s:find(p)
```

> Returns the leftmost element of s matching the predicate p.

``` lua
S.filter(p, s)
s:filter(p)
```

> Returns the string of those elements that satisfy the predicate.

``` lua
S.partition(p, s)
s:partition(p)
```

> Returns the pair of strings of elements which do and do not satisfy
> the predicate, respectively.

## Indexing strings

``` lua
S.elemIndex(x, s)
s:elemIndex(x)
```

> Returns the index of the first element in the given string which is
> equal to the query element.

``` lua
S.elemIndices(x, s)
s:elemIndices(x)
```

> Returns the indices of all elements equal to the query element, in
> ascending order.

``` lua
S.findIndex(p, s)
s:findIndex(p)
```

> Returns the index of the first element in the string satisfying the
> predicate.

``` lua
S.findIndices(p, s)
s:findIndices(p)
```

> Returns the indices of all elements satisfying the predicate, in
> ascending order.

## Special lists

### Functions on strings

``` lua
S.split(s, sep, maxsplit, plain)
s:split(sep, maxsplit, plain)
```

> Splits a string `s` around the separator `sep`. `maxsplit` is the
> maximal number of separators. If `plain` is true then the separator is
> a plain string instead of a Lua string pattern.

``` lua
S.lines(s)
s:lines()
```

> Splits the argument into a list of lines stripped of their terminating
> `\n` characters.

``` lua
S.words(s)
s:words()
```

> Breaks a string up into a list of words, which were delimited by white
> space.

``` lua
S.unlines(xs)
```

> Appends a `\n` character to each input string, then concatenates the
> results.

``` lua
S.unwords(xs)
```

> Joins words with separating spaces.

``` lua
S.ltrim(s)
s:ltrim()
```

> Removes heading spaces

``` lua
S.rtrim(s)
s:rtrim()
```

> Removes trailing spaces

``` lua
S.trim(s)
s:trim()
```

> Removes heading and trailing spaces

``` lua
S.cap(s)
s:cap()
```

> Capitalizes a string. The first character is upper case, other are
> lower case.

### Set operations

``` lua
S.nub(s)
s:nub()
```

> Removes duplicate elements from a string. In particular, it keeps only
> the first occurrence of each element.

``` lua
S.delete(x, s)
s:delete(x)
```

> Removes the first occurrence of x from its string argument.

``` lua
S.difference(xs, ys)
xs:difference(ys)
```

> Returns the list difference. In `difference(xs, ys)` the first
> occurrence of each element of ys in turn (if any) has been removed
> from xs.

``` lua
S.union(xs, ys)
xs:union(ys)
```

> Returns the list union of the two lists. Duplicates, and elements of
> the first list, are removed from the the second list, but if the first
> list contains duplicates, so will the result.

``` lua
S.intersect(xs, ys)
xs:intersect(ys)
```

> Returns the list intersection of two lists. If the first list contains
> duplicates, so will the result.

### Ordered lists

``` lua
S.sort(xs)
xs:sort(xs)
```

> Sorts xs from lowest to highest.

``` lua
S.sortOn(f, xs)
xs:sortOn(f)
```

> Sorts a list by comparing the results of a key function applied to
> each element.

``` lua
S.insert(x, xs)
xs:insert(x)
```

> Inserts the element into the list at the first position where it is
> less than or equal to the next element.

## Generalized functions

``` lua
S.nubBy(eq, xs)
xs:nubBy(eq)
```

> like nub, except it uses a user-supplied equality predicate instead of
> the overloaded == function.

``` lua
S.deleteBy(eq, x, xs)
xs:deleteBy(eq, x)
```

> like delete, except it uses a user-supplied equality predicate instead
> of the overloaded == function.

``` lua
S.differenceBy(eq, xs, ys)
xs:differenceBy(eq, ys)
```

> like difference, except it uses a user-supplied equality predicate
> instead of the overloaded == function.

``` lua
S.unionBy(eq, xs, ys)
xs:unionBy(eq, ys)
```

> like union, except it uses a user-supplied equality predicate instead
> of the overloaded == function.

``` lua
S.intersectBy(eq, xs, ys)
xs:intersectBy(eq, ys)
```

> like intersect, except it uses a user-supplied equality predicate
> instead of the overloaded == function.

``` lua
S.groupBy(eq, xs)
xs:groupBy(eq)
```

> like group, except it uses a user-supplied equality predicate instead
> of the overloaded == function.

``` lua
S.sortBy(le, xs)
xs:sortBy(le)
```

> like sort, except it uses a user-supplied equality predicate instead
> of the overloaded \<= function.

``` lua
S.insertBy(le, x, xs)
xs:insertBy(le, x)
```

> like insert, except it uses a user-supplied equality predicate instead
> of the overloaded \<= function.

``` lua
S.maximumBy(le, xs)
xs:maximumBy(le)
```

> like maximum, except it uses a user-supplied equality predicate
> instead of the overloaded \<= function.

``` lua
S.minimumBy(le, xs)
xs:minimumBy(le)
```

> like minimum, except it uses a user-supplied equality predicate
> instead of the overloaded \<= function.
