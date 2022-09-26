--[[
This file is part of luax.

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
--]]

--[[------------------------------------------------------------------------@@@
# String

[`Data.List`]: https://hackage.haskell.org/package/base-4.17.0.0/docs/Data-List.html
[`Data.String`]: https://hackage.haskell.org/package/base-4.17.0.0/docs/Data-String.html

`String` is a module inspired by the Haskell modules [`Data.List`] and [`Data.String`].

Note: contrary to the original Haskell modules, all these functions are evaluated strictly
(i.e. no lazy evaluation, no infinite string, ...).

```lua
local S = require "String"
```
@@@]]

local S = {}

local L = require "List"

--[[------------------------------------------------------------------------@@@
## Basic functions
@@@]]

--[[@@@
```lua
S.toChars(s)
s:toChars()
```
> Returns the list of characters of a string
@@@]]

function S.toChars(s)
    local cs = {}
    for i = 1, #s do cs[i] = s:sub(i, i) end
    return L(cs)
end

string.toChars = S.toChars

--[[@@@
```lua
s1 .. s2
```
> Append two strings, i.e.,
@@@]]

--[[@@@
```lua
S.head(s)
s:head()
```
> Extract the first element of a string.
  ```lua
  head"123" == "1"
  head"" == nil
  ```
@@@]]
function S.head(s)
    if #s == 0 then return nil end
    return s:sub(1, 1)
end

string.head = S.head

--[[@@@
```lua
S.last(s)
s:last()
```
> Extract the last element of a string.
@@@]]
function S.last(s)
    if #s == 0 then return nil end
    return s:sub(#s)
end

string.last = S.last

--[[@@@
```lua
S.tail(s)
s:tail()
```
> Extract the elements after the head of a string
@@@]]
function S.tail(s)
    if #s == 0 then return nil end
    return s:sub(2)
end

string.tail = S.tail

--[[@@@
```lua
S.init(s)
s:init()
```
> Return all the elements of a string except the last one.
@@@]]
function S.init(s)
    if #s == 0 then return nil end
    return s:sub(1, #s-1)
end

string.init = S.init

--[[@@@
```lua
S.uncons(s)
S:uncons()
```
> Decompose a string into its head and tail.
@@@]]
function S.uncons(s)
    return S.head(s), S.tail(s)
end

string.uncons = S.uncons

--[[@@@
```lua
S.null(s)
s:null()
```
> Test whether the string is empty.
@@@]]
function S.null(s)
    return #s == 0
end

string.null = S.null

--[[@@@
```lua
S.length(s)
s:length()
```
> Returns the length of a string.
@@@]]
function S.length(s)
    return #s
end

string.length = S.length

--[[------------------------------------------------------------------------@@@
## String transformations
@@@]]

--[[@@@
```lua
S.map(f, s)
s:map(f)
```
> Returns the string obtained by applying f to each element of s
@@@]]
function S.map(f, s)
    return S.toChars(s):map(f)
end

string.map = function(s, f) return S.map(f, s) end

--[[@@@
```lua
S.mapWithIndex(f, s)
s:mapWithIndex(f)
```
> Returns the string obtained by applying f to each element of xs with their positions
@@@]]
function S.mapWithIndex(f, s)
    return S.toChars(s):mapWithIndex(f)
end

string.mapWithIndex = function(s, f) return S.mapWithIndex(f, s) end

--[[@@@
```lua
S.reverse(s)
s:reverse()
```
> Returns the elements of s in reverse order.
@@@]]
function S.reverse(s)
    return s:reverse()
end

--[[@@@
```lua
S.intersperse(c, s)
c:intersperse(s)
```
> Intersperses a element c between the elements of s.
@@@]]
function S.intersperse(c, s)
    if #s < 2 then return s end
    local chars = {}
    for i = 1, #s-1 do
        chars[#chars+1] = s:sub(i, i)
        chars[#chars+1] = c
    end
    chars[#chars+1] = s:sub(#s)
    return table.concat(chars)
end

string.intersperse = S.intersperse

--[[@@@
```lua
S.intercalate(s, ss)
s:intercalate(ss)
```
> Inserts the string s in between the strings in ss and concatenates the result.
@@@]]
function S.intercalate(s, ss)
    return table.concat(ss, s)
end

string.intercalate = S.intercalate

--[[@@@
```lua
S.subsequences(s)
s:subsequences()
```
> Returns the list of all subsequences of the argument.
@@@]]
function S.subsequences(s)
    if S.null(s) then return {""} end
    local inits = S.subsequences(S.init(s))
    local last = S.last(s)
    return inits .. L.map(function(seq) return seq..last end, inits)
end

string.subsequences = S.subsequences

--[[@@@
```lua
S.permutations(s)
s:permutations()
```
> Returns the list of all permutations of the argument.
@@@]]
function S.permutations(s)
    return L.permutations(s:toChars()):map(S.concat)
end

string.permutations = S.permutations

--[[------------------------------------------------------------------------@@@
## Reducing strings (folds)
@@@]]

--[[@@@
```lua
S.foldl(f, z, s)
s:foldl(f, z)
```
> Left-associative fold of a string.
@@@]]
function S.foldl(fzc, z, s)
    return S.toChars(s):foldl(fzc, z)
end

string.foldl = function(s, fzc, z) return S.foldl(fzc, z, s) end

--[[@@@
```lua
S.foldl1(f, s)
s:foldl1(f)
```
> Left-associative fold of a string (the initial value is `s[1]`).
@@@]]
function S.foldl1(fzc, s)
    return S.toChars(s):foldl1(fzc)
end

string.foldl1 = function(xs, fzx) return S.foldl1(fzx, xs) end

--[[@@@
```lua
S.foldr(f, z, s)
s:foldr(f, z)
```
> Right-associative fold of a string.
@@@]]
function S.foldr(fcz, z, s)
    return S.toChars(s):foldr(fcz, z)
end

string.foldr = function(s, fcz, z) return S.foldr(fcz, z, s) end

--[[@@@
```lua
S.foldr1(f, s)
s:foldr1(f)
```
> Right-associative fold of a string (the initial value is `s[#s]`).
@@@]]
function S.foldr1(fcz, s)
    return S.toChars(s):foldr1(fcz)
end

string.foldr1 = function(s, fcz) return S.foldr1(fcz, s) end

--[[------------------------------------------------------------------------@@@
## Special folds
@@@]]

--[[@@@
```lua
S.concat(ss)
```
> The concatenation of all the elements of a container of strings.
@@@]]
function S.concat(ss)
    return table.concat(ss)
end

--[[@@@
```lua
S.any(p, xs)
xs:any(p)
```
> Determines whether any element of the string satisfies the predicate.
@@@]]
function S.any(p, s)
    return S.toChars(s):any(p)
end

string.any = function(s, p) return S.any(p, s) end

--[[@@@
```lua
S.all(p, s)
s:all(p)
```
> Determines whether all elements of the string satisfy the predicate.
@@@]]
function S.all(p, s)
    return S.toChars(s):all(p)
end

string.all = function(s, p) return S.all(p, s) end

--[[@@@
```lua
S.maximum(s)
s:maximum()
```
> The largest element of a non-empty string.
@@@]]
function S.maximum(s)
    return S.toChars(s):maximum()
end

string.maximum = S.maximum

--[[@@@
```lua
S.minimum(s)
s:minimum()
```
> The least element of a non-empty string.
@@@]]
function S.minimum(s)
    return S.toChars(s):minimum()
end

string.minimum = S.minimum

--[[------------------------------------------------------------------------@@@
## Building strings
@@@]]

--[[------------------------------------------------------------------------@@@
### Scans
@@@]]

--[[@@@
```lua
S.scanl(f, z, s)
s:scanl(f, z)
```
> Similar to `foldl` but returns a list of successive reduced values from the left.
@@@]]
function S.scanl(fzc, z, s)
    return S.toChars(s):scanl(fzc, z)
end

string.scanl = function(s, fzc, z) return S.scanl(fzc, z, s) end

--[[@@@
```lua
S.scanl1(f, s)
s:scanl1(f)
```
> Like `scanl` but the initial value is `s[1]`.
@@@]]
function S.scanl1(fzc, s)
    return S.toChars(s):scanl1(fzc)
end

string.scanl1 = function(s, fzc) return S.scanl1(fzc, s) end

--[[@@@
```lua
S.scanr(f, z, s)
s:scanr(f, z)
```
> Similar to `foldr` but returns a list of successive reduced values from the right.
@@@]]
function S.scanr(fcz, z, s)
    return S.toChars(s):scanr(fcz, z)
end

string.scanr = function(s, fzc, z) return S.scanr(fzc, z, s) end

--[[@@@
```lua
S.scanr1(f, s)
s:scanr1(f)
```
> Like `scanr` but the initial value is `s[#s]`.
@@@]]
function S.scanr1(fcz, s)
    return S.toChars(s):scanr1(fcz)
end

string.scanr1 = function(s, fzc) return S.scanr1(fzc, s) end

--[[------------------------------------------------------------------------@@@
### Infinite strings
@@@]]

--[[@@@
```lua
S.replicate(n, c)
c:replicate(n)
```
> Returns a string of length n with x the value of every element.
@@@]]
function S.replicate(n, s)
    return s:rep(n)
end

string.replicate = function(s, n) return S.replicate(n, s) end

--[[------------------------------------------------------------------------@@@
### Unfolding
@@@]]

--[[@@@
```lua
S.unfoldr(f, z)
```
> Builds a string from a seed value (dual of `foldr`).
@@@]]
function S.unfoldr(fz, z)
    return S.concat(L.unfoldr(fz, z))
end

--[[------------------------------------------------------------------------@@@
## Substrings
@@@]]

--[[------------------------------------------------------------------------@@@
### Extracting strings
@@@]]

--[[@@@
```lua
S.take(n, s)
s:take(n)
```
> Returns the prefix of s of length n.
@@@]]
function S.take(n, s)
    if n <= 0 then return "" end
    return s:sub(1, n)
end

string.take = function(s, n) return S.take(n, s) end

--[[@@@
```lua
S.drop(n, s)
s:drop(n)
```
> Returns the suffix of s after the first n elements.
@@@]]
function S.drop(n, s)
    if n <= 0 then return s end
    return s:sub(n+1)
end

string.drop = function(s, n) return S.drop(n, s) end

--[[@@@
```lua
S.splitAt(n, s)
s:splitAt(n)
```
> Returns a tuple where first element is s prefix of length n and second element is the remainder of the list.
@@@]]
function S.splitAt(n, s)
    return S.take(n, s), S.drop(n, s)
end

string.splitAt = function(s, n) return S.splitAt(n, s) end

--[[@@@
```lua
S.takeWhile(p, s)
s:takeWhile(p)
```
> Returns the longest prefix (possibly empty) of s of elements that satisfy p.
@@@]]
function S.takeWhile(p, s)
    return S.concat(S.toChars(s):takeWhile(p))
end

string.takeWhile = function(s, p) return S.takeWhile(p, s) end

--[[@@@
```lua
S.dropWhile(p, s)
s:dropWhile(p)
```
> Returns the suffix remaining after `takeWhile(p, s)`{.lua}.
@@@]]
function S.dropWhile(p, s)
    return S.concat(S.toChars(s):dropWhile(p))
end

string.dropWhile = function(s, p) return S.dropWhile(p, s) end

--[[@@@
```lua
L.dropWhileEnd(p, s)
s:dropWhileEnd(p)
```
> Drops the largest suffix of a list in which the given predicate holds for all elements.
@@@]]
function S.dropWhileEnd(p, s)
    return S.concat(S.toChars(s):dropWhileEnd(p))
end

string.dropWhileEnd = function(s, p) return S.dropWhileEnd(p, s) end

--[[@@@
```lua
L.span(p, s)
s:span(p)
```
> Returns a tuple where first element is longest prefix (possibly empty) of xs of elements that satisfy p and second element is the remainder of the list.
@@@]]
function S.span(p, s)
    local s1, s2 = S.toChars(s):span(p)
    return S.concat(s1), S.concat(s2)
end

string.span = function(s, p) return S.span(p, s) end

--[[@@@
```lua
S.break_(p, s)
s:break_(p)
```
> Returns a tuple where first element is longest prefix (possibly empty) of s of elements that do not satisfy p and second element is the remainder of the list.
@@@]]
function S.break_(p, s)
    local s1, s2 = S.toChars(s):break_(p)
    return S.concat(s1), S.concat(s2)
end

string.break_ = function(s, p) return S.break_(p, s) end

--[[@@@
```lua
S.stripPrefix(prefix, s)
s:stripPrefix(prefix)
```
> Drops the given prefix from a list.
@@@]]
function S.stripPrefix(prefix, s)
    local n = #prefix
    if s:sub(1, n) == prefix then return s:sub(n+1) end
    return nil
end

string.stripPrefix = function(s, prefix) return S.stripPrefix(prefix, s) end

--[[@@@
```lua
L.group(s)
s:group()
```
> Returns a list of strings such that the concatenation of the result is equal to the argument. Moreover, each sublist in the result contains only equal elements.
@@@]]
function S.group(s)
    return S.toChars(s):group():map(S.concat)
end

string.group = S.group

--[[@@@
```lua
S.inits(s)
s:inits()
```
> Returns all initial segments of the argument, shortest first.
@@@]]
function S.inits(s)
    local ss = {}
    for i = 0, #s do
        ss[#ss+1] = s:sub(1, i)
    end
    return L(ss)
end

string.inits = S.inits

--[[@@@
```lua
L.tails(s)
s:tails()
```
> Returns all final segments of the argument, longest first.
@@@]]
function S.tails(s)
    local ss = {}
    for i = 1, #s+1 do
        ss[#ss+1] = s:sub(i)
    end
    return L(ss)
end

string.tails = S.tails

--[[------------------------------------------------------------------------@@@
### Predicates
@@@]]

--[[@@@
```lua
S.isPrefixOf(prefix, s)
prefix:isPrefixOf(s)
```
> Returns `true` iff the first string is a prefix of the second.
@@@]]
function S.isPrefixOf(prefix, s)
    return s:sub(1, #prefix) == prefix
end

string.isPrefixOf = S.isPrefixOf

--[[@@@
```lua
S.isSuffixOf(suffix, s)
suffix:isSuffixOf(s)
```
> Returns `true` iff the first string is a suffix of the second.
@@@]]
function S.isSuffixOf(suffix, s)
    return s:sub(#s-#suffix+1) == suffix
end

string.isSuffixOf = S.isSuffixOf

--[[@@@
```lua
S.isInfixOf(infix, s)
infix:isInfixOf(s)
```
> Returns `true` iff the first string is contained, wholly and intact, anywhere within the second.
@@@]]
function S.isInfixOf(infix, s)
    return s:find(infix) ~= nil
end

string.isInfixOf = S.isInfixOf

--[[@@@
```lua
S.isSubsequenceOf(seq, s)
seq:isSubsequenceOf(s)
```
> Returns `true` if all the elements of the first string occur, in order, in the second. The elements do not have to occur consecutively.
@@@]]
function S.isSubsequenceOf(seq, s)
    return L.isSubsequenceOf(S.toChars(seq), S.toChars(s))
end

string.isSubsequenceOf = S.isSubsequenceOf

--[[------------------------------------------------------------------------@@@
## Searching strings
@@@]]

--[[------------------------------------------------------------------------@@@
### Searching by equality
@@@]]

--[[@@@
```lua
S.elem(x, s)
x:elem(s)
```
> Returns `true` if x occurs in s.
@@@]]
function S.elem(x, s)
    return s:find(x) ~= nil
end

string.elem = function(s, x) return S.elem(x, s) end

--[[@@@
```lua
S.notElem(x, s)
x:notElem(s)
```
> Returns `true` if x does not occur in s.
@@@]]
function S.notElem(x, s)
    return s:find(x) == nil
end

string.notElem = function(s, x) return S.notElem(x, s) end

--[[------------------------------------------------------------------------@@@
### Searching with a predicate
@@@]]

--[[@@@
```lua
S.find(p, s)
s:find(p)
```
> Returns the leftmost element of s matching the predicate p.
@@@]]
function S.find(p, s)
    return S.toChars(s):find(p)
end

-- string.find is already defined and shall not be overriden
--string.find = function(s, p) return S.find(p, s) end

--[[@@@
```lua
S.filter(p, s)
s:filter(p)
```
> Returns the string of those elements that satisfy the predicate.
@@@]]
function S.filter(p, s)
    return S.concat(S.toChars(s):filter(p))
end

string.filter = function(s, p) return S.filter(p, s) end

--[[@@@
```lua
S.partition(p, s)
s:partition(p)
```
> Returns the pair of strings of elements which do and do not satisfy the predicate, respectively.
@@@]]
function S.partition(p, s)
    local s1, s2 = S.toChars(s):partition(p)
    return S.concat(s1), S.concat(s2)
end

string.partition = function(s, p) return S.partition(p, s) end

--[[------------------------------------------------------------------------@@@
## Indexing strings
@@@]]

--[[@@@
```lua
S.elemIndex(x, s)
s:elemIndex(x)
```
> Returns the index of the first element in the given string which is equal to the query element.
@@@]]
function S.elemIndex(x, s)
    return S.toChars(s):elemIndex(x)
end

string.elemIndex = function(s, x) return S.elemIndex(x, s) end

--[[@@@
```lua
S.elemIndices(x, s)
s:elemIndices(x)
```
> Returns the indices of all elements equal to the query element, in ascending order.
@@@]]
function S.elemIndices(x, s)
    return S.toChars(s):elemIndices(x)
end

string.elemIndices = function(s, x) return S.elemIndices(x, s) end

--[[@@@
```lua
S.findIndex(p, s)
s:findIndex(p)
```
> Returns the index of the first element in the string satisfying the predicate.
@@@]]
function S.findIndex(p, s)
    return S.toChars(s):findIndex(p)
end

string.findIndex = function(s, p) return S.findIndex(p, s) end

--[[@@@
```lua
S.findIndices(p, s)
s:findIndices(p)
```
> Returns the indices of all elements satisfying the predicate, in ascending order.
@@@]]
function S.findIndices(p, s)
    return S.toChars(s):findIndices(p)
end

string.findIndices = function(s, p) return S.findIndices(p, s) end

--[[------------------------------------------------------------------------@@@
## Special lists
@@@]]

--[[------------------------------------------------------------------------@@@
### Functions on strings
@@@]]

--[[@@@
```lua
S.split(s, sep, maxsplit, plain)
s:split(sep, maxsplit, plain)
```
> Splits a string `s` around the separator `sep`. `maxsplit` is the maximal number of separators. If `plain` is true then the separator is a plain string instead of a Lua string pattern.
@@@]]

function S.split(s, sep, maxsplit, plain)
    assert(sep and sep ~= "")
    maxsplit = maxsplit or (1/0)
    local items = {}
    if #s > 0 then
        local init = 1
        for _ = 1, maxsplit do
            local m, n = s:find(sep, init, plain)
            if m and m <= n then
                table.insert(items, s:sub(init, m - 1))
                init = n + 1
            else
                break
            end
        end
        table.insert(items, s:sub(init))
    end
    return L(items)
end

string.split = S.split

--[[@@@
```lua
S.lines(s)
s:lines()
```
> Splits the argument into a list of lines stripped of their terminating `\n` characters.
@@@]]
function S.lines(s)
    local lines = s:split('\r?\n\r?')
    if lines[#lines] == "" and s:match('\r?\n\r?$') then table.remove(lines) end
    return L(lines)
end

string.lines = S.lines

--[[@@@
```lua
S.words(s)
s:words()
```
> Breaks a string up into a list of words, which were delimited by white space.
@@@]]
function S.words(s)
    local words = s:split('%s+')
    if words[1] == "" and s:match('^%s+') then table.remove(words, 1) end
    if words[#words] == "" and s:match('%s+$') then table.remove(words) end
    return L(words)
end

string.words = S.words

--[[@@@
```lua
S.unlines(xs)
```
> Appends a `\n` character to each input string, then concatenates the results.
@@@]]
function S.unlines(xs)
    local s = {}
    for i = 1, #xs do
        s[#s+1] = xs[i]
        s[#s+1] = "\n"
    end
    return table.concat(s)
end

--[[@@@
```lua
S.unwords(xs)
```
> Joins words with separating spaces.
@@@]]
function S.unwords(xs)
    return table.concat(xs, " ")
end

--[[@@@
```lua
S.ltrim(s)
s:ltrim()
```
> Removes heading spaces
@@@]]
function S.ltrim(s)
    return (s:match("^%s*(.*)"))
end

string.ltrim = S.ltrim

--[[@@@
```lua
S.rtrim(s)
s:rtrim()
```
> Removes trailing spaces
@@@]]
function S.rtrim(s)
    return (s:match("(.-)%s*$"))
end

string.rtrim = S.rtrim

--[[@@@
```lua
S.trim(s)
s:trim()
```
> Removes heading and trailing spaces
@@@]]
function S.trim(s)
    return (s:match("^%s*(.-)%s*$"))
end

string.trim = S.trim

--[[@@@
```lua
S.cap(s)
s:cap()
```
> Capitalizes a string. The first character is upper case, other are lower case.
@@@]]
function S.cap(s)
    return s:sub(1, 1):upper()..s:sub(2):lower()
end

string.cap = S.cap

--[[------------------------------------------------------------------------@@@
### Set operations
@@@]]

--[[@@@
```lua
S.nub(s)
s:nub()
```
> Removes duplicate elements from a string. In particular, it keeps only the first occurrence of each element.
@@@]]
function S.nub(s)
    return S.concat(S.toChars(s):nub())
end

string.nub = S.nub

--[[@@@
```lua
S.delete(x, s)
s:delete(x)
```
> Removes the first occurrence of x from its string argument.
@@@]]
function S.delete(x, s)
    local i, j = s:find(x)
    if not i then return s end
    return s:sub(1, i-1) .. s:sub(j+1)
end

string.delete = function(s, x) return S.delete(x, s) end

--[[@@@
```lua
S.difference(xs, ys)
xs:difference(ys)
```
> Returns the list difference. In `difference(xs, ys)`{.lua} the first occurrence of each element of ys in turn (if any) has been removed from xs.
@@@]]
function S.difference(xs, ys)
    return S.concat(S.toChars(xs):difference(S.toChars(ys)))
end

string.difference = S.difference

--[[@@@
```lua
S.union(xs, ys)
xs:union(ys)
```
> Returns the list union of the two lists. Duplicates, and elements of the first list, are removed from the the second list, but if the first list contains duplicates, so will the result.
@@@]]
function S.union(xs, ys)
    return S.concat(S.toChars(xs):union(S.toChars(ys)))
end

string.union = S.union

--[[@@@
```lua
S.intersect(xs, ys)
xs:intersect(ys)
```
> Returns the list intersection of two lists. If the first list contains duplicates, so will the result.
@@@]]
function S.intersect(xs, ys)
    return S.concat(S.toChars(xs):intersect(S.toChars(ys)))
end

string.intersect = S.intersect

--[[------------------------------------------------------------------------@@@
### Ordered lists
@@@]]

--[[@@@
```lua
S.sort(xs)
xs:sort(xs)
```
> Sorts xs from lowest to highest.
@@@]]

function S.sort(xs)
    return S.concat(S.toChars(xs):sort())
end

string.sort = S.sort

--[[@@@
```lua
S.sortOn(f, xs)
xs:sortOn(f)
```
> Sorts a list by comparing the results of a key function applied to each element.
@@@]]

function S.sortOn(f, xs)
    return S.concat(S.toChars(xs):sortOn(f))
end

string.sortOn = function (xs, f) return S.sortOn(f, xs) end

--[[@@@
```lua
S.insert(x, xs)
xs:insert(x)
```
> Inserts the element into the list at the first position where it is less than or equal to the next element.
@@@]]

function S.insert(x, xs)
    return S.concat(S.toChars(xs):insert(x))
end

string.insert = function(xs, x) return S.insert(x, xs) end

--[[------------------------------------------------------------------------@@@
## Generalized functions
@@@]]

--[[@@@
```lua
S.nubBy(eq, xs)
xs:nubBy(eq)
```
> like nub, except it uses a user-supplied equality predicate instead of the overloaded == function.
@@@]]
function S.nubBy(eq, xs)
    return S.concat(S.toChars(xs):nubBy(eq))
end

string.nubBy = function(xs, eq) return S.nubBy(eq, xs) end

--[[@@@
```lua
S.deleteBy(eq, x, xs)
xs:deleteBy(eq, x)
```
> like delete, except it uses a user-supplied equality predicate instead of the overloaded == function.
@@@]]
function S.deleteBy(eq, x, xs)
    return S.concat(S.toChars(xs):deleteBy(eq, x))
end

string.deleteBy = function(xs, eq, x) return S.deleteBy(eq, x, xs) end

--[[@@@
```lua
S.differenceBy(eq, xs, ys)
xs:differenceBy(eq, ys)
```
> like difference, except it uses a user-supplied equality predicate instead of the overloaded == function.
@@@]]
function S.differenceBy(eq, xs, ys)
    return S.concat(S.toChars(xs):differenceBy(eq, S.toChars(ys)))
end

string.differenceBy = function(xs, eq, ys) return S.differenceBy(eq, xs, ys) end

--[[@@@
```lua
S.unionBy(eq, xs, ys)
xs:unionBy(eq, ys)
```
> like union, except it uses a user-supplied equality predicate instead of the overloaded == function.
@@@]]
function S.unionBy(eq, xs, ys)
    return S.concat(S.toChars(xs):unionBy(eq, S.toChars(ys)))
end

string.unionBy = function(xs, eq, ys) return S.unionBy(eq, xs, ys) end

--[[@@@
```lua
S.intersectBy(eq, xs, ys)
xs:intersectBy(eq, ys)
```
> like intersect, except it uses a user-supplied equality predicate instead of the overloaded == function.
@@@]]
function S.intersectBy(eq, xs, ys)
    return S.concat(S.toChars(xs):intersectBy(eq, S.toChars(ys)))
end

string.intersectBy = function(xs, eq, ys) return S.intersectBy(eq, xs, ys) end

--[[@@@
```lua
S.groupBy(eq, xs)
xs:groupBy(eq)
```
> like group, except it uses a user-supplied equality predicate instead of the overloaded == function.
@@@]]
function S.groupBy(eq, xs)
    return S.toChars(xs):groupBy(eq):map(S.concat)
end

string.groupBy = function(xs, eq) return S.groupBy(eq, xs) end

--[[@@@
```lua
S.sortBy(le, xs)
xs:sortBy(le)
```
> like sort, except it uses a user-supplied equality predicate instead of the overloaded <= function.
@@@]]
function S.sortBy(le, xs)
    return S.concat(S.toChars(xs):sortBy(le))
end

string.sortBy = function(xs, le) return S.sortBy(le, xs) end

--[[@@@
```lua
S.insertBy(le, x, xs)
xs:insertBy(le, x)
```
> like insert, except it uses a user-supplied equality predicate instead of the overloaded <= function.
@@@]]
function S.insertBy(le, x, xs)
    return S.concat(S.toChars(xs):insertBy(le, x))
end

string.insertBy = function(xs, ls, x) return S.insertBy(ls, x, xs) end

--[[@@@
```lua
S.maximumBy(le, xs)
xs:maximumBy(le)
```
> like maximum, except it uses a user-supplied equality predicate instead of the overloaded <= function.
@@@]]
function S.maximumBy(le, xs)
    return S.toChars(xs):maximumBy(le)
end

string.maximumBy = function(xs, le) return S.maximumBy(le, xs) end

--[[@@@
```lua
S.minimumBy(le, xs)
xs:minimumBy(le)
```
> like minimum, except it uses a user-supplied equality predicate instead of the overloaded <= function.
@@@]]
function S.minimumBy(le, xs)
    return S.toChars(xs):minimumBy(le)
end

string.minimumBy = function(xs, le) return S.minimumBy(le, xs) end

-------------------------------------------------------------------------------
-- String module
-------------------------------------------------------------------------------

return setmetatable(S, {
    __call = function(_, s) return s end, -- to write S"foo":xxx() instead of ("foo"):xxx()
})
