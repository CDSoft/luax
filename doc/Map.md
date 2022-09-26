# List

`Map` is a module inspired by the Haskell module
[`Data.Map`](https://hackage.haskell.org/package/containers-0.6.6/docs/Data-Map.html).

Note: contrary to the original Haskell modules, all these functions are
evaluated strictly (i.e. no lazy evaluation, no infinite table, …).

``` lua
local M = require "Map"
```

## Construction

``` lua
M.clone(t)
t:clone()
```

> Clone a table

``` lua
t1 .. t2
```

> Merge two tables

``` lua
M.empty()
```

> The empty map

``` lua
M.singleton(k, v)
```

> A map with a single element.

``` lua
M.fromSet(f, ks)
```

> Build a map from a set of keys and a function which for each key
> computes its value.

``` lua
M.fromList(kvs)
```

> Build a map from a list of key/value pairs.

## Deletion / Update

``` lua
M.delete(k, t)
t:delete(k)
```

> Delete a key and its value from the map.

``` lua
M.adjust(f, k, t)
t:adjust(f, k)
```

> Update a value at a specific key with the result of the provided
> function. When the key is not a member of the map, the original map is
> returned.

``` lua
M.adjustWithKey(f, k, t)
t:adjustWithKey(f, k)
```

> Adjust a value at a specific key. When the key is not a member of the
> map, the original map is returned.

``` lua
M.update(f, k, t)
t:update(f, k)
```

> Updates the value x at k (if it is in the map). If f(x) is nil, the
> element is deleted. Otherwise the key k is bound to the value f(x).

``` lua
M.updateWithKey(f, k, t)
t:updateWithKey(f, k)
```

> Updates the value x at k (if it is in the map). If f(k, x) is nil, the
> element is deleted. Otherwise the key k is bound to the value f(k, x).

``` lua
M.updateLookupWithKey(f, k, t)
t:updateLookupWithKey(f, k)
```

> Lookup and update. See also updateWithKey. The function returns
> changed value, if it is updated. Returns the original key value if the
> map entry is deleted.

``` lua
M.alter(f, k, t)
t:alter(f, k)
```

> The expression alter(f, k, t) alters the value x at k, or absence
> thereof. alter can be used to insert, delete, or update a value in a
> Map.

``` lua
M.alterWithKey(f, k, t)
t:alterWithKey(f, k)
```

> The expression alterWithKey(f, k, t) alters the value x at k, or
> absence thereof. alterWithKey can be used to insert, delete, or update
> a value in a Map.

## Query

### Lookup

``` lua
M.lookup(k, t)
t:lookup(k)
```

> Lookup the value at a key in the map.

``` lua
M.findWithDefault(def, k, t)
t:findWithDefault(def, k)
```

> Returns the value at key k or returns default value def when the key
> is not in the map.

``` lua
M.member(k, t)
t:member(k)
```

> Lookup the value at a key in the map.

``` lua
M.notMember(k, t)
t:notMember(k)
```

> Lookup the value at a key in the map.

``` lua
M.lookupLT(k, t)
t:lookupLT(k)
```

> Find largest key smaller than the given one and return the
> corresponding (key, value) pair.

``` lua
M.lookupGT(k, t)
t:lookupGT(k)
```

> Find smallest key greater than the given one and return the
> corresponding (key, value) pair.

``` lua
M.lookupLE(k, t)
t:lookupLE(k)
```

> Find largest key smaller or equal to the given one and return the
> corresponding (key, value) pair.

``` lua
M.lookupGE(k, t)
t:lookupGE(k)
```

> Find smallest key greater or equal to the given one and return the
> corresponding (key, value) pair.

### Size

``` lua
M.null(t)
t:null()
```

> Is the map empty?

``` lua
M.size(t)
t:size()
```

> The number of elements in the map.

## Combine

### Union

``` lua
M.union(t1, t2)
t1:union(t2)
```

> Left-biased union of t1 and t2. It prefers t1 when duplicate keys are
> encountered.

``` lua
M.unionWith(f, t1, t2)
t1:unionWith(f, t2)
```

> Union with a combining function.

``` lua
M.unionWithKey(f, t1, t2)
t1:unionWithKey(f, t2)
```

> Union with a combining function.

``` lua
M.unions(ts)
ts:unions()
```

> The union of a list of maps.

``` lua
M.unionsWith(f, ts)
ts:unionsWith(f)
```

> The union of a list of maps, with a combining operation.

``` lua
M.unionsWithKey(f, ts)
ts:unionsWithKey(f)
```

> The union of a list of maps, with a combining operation.

### Difference

``` lua
M.difference(t1, t2)
t1:difference(t2)
```

> Difference of two maps. Return elements of the first map not existing
> in the second map.

``` lua
M.differenceWith(f, t1, t2)
t1:differenceWith(f, t2)
```

> Difference with a combining function. When two equal keys are
> encountered, the combining function is applied to the values of these
> keys.

``` lua
M.differenceWithKey(f, t1, t2)
t1:differenceWithKey(f, t2)
```

> Union with a combining function.

### Intersection

``` lua
M.intersection(t1, t2)
t1:intersection(t2)
```

> Intersection of two maps. Return data in the first map for the keys
> existing in both maps.

``` lua
M.intersectionWith(f, t1, t2)
t1:intersectionWith(f, t2)
```

> Difference with a combining function. When two equal keys are
> encountered, the combining function is applied to the values of these
> keys.

``` lua
M.intersectionWithKey(f, t1, t2)
t1:intersectionWithKey(f, t2)
```

> Union with a combining function.

### Disjoint

``` lua
M.disjoint(t1, t2)
t1:disjoint(t2)
```

> Intersection of two maps. Return data in the first map for the keys
> existing in both maps.

### Compose

``` lua
M.compose(t1, t2)
t1:compose(t2)
```

> Relate the keys of one map to the values of the other, by using the
> values of the former as keys for lookups in the latter.

## Traversal

### Map

``` lua
M.map(f, t)
t:map(f)
```

> Map a function over all values in the map.

``` lua
M.mapWithKey(f, t)
t:mapWithKey(f)
```

> Map a function over all values in the map.

## Folds

``` lua
M.foldr(f, b, t)
t:foldr(f, b)
```

> Fold the values in the map using the given right-associative binary
> operator.

``` lua
M.foldl(f, b, t)
t:foldl(f, b)
```

> Fold the values in the map using the given right-associative binary
> operator.

``` lua
M.foldrWithKey(f, b, t)
t:foldrWithKey(f, b)
```

> Fold the keys and values in the map using the given right-associative
> binary operator.

``` lua
M.foldlWithKey(f, b, t)
t:foldlWithKey(f, b)
```

> Fold the keys and values in the map using the given left-associative
> binary operator.

## Conversion

``` lua
M.elems(t)
t:elems()
M.values(t)
t:values()
```

> Return all elements of the map in the ascending order of their keys
> (values is an alias for elems).

``` lua
M.keys(t)
t:keys()
```

> Return all keys of the map in ascending order.

``` lua
M.assocs(t)
t:assocs()
```

> Return all key/value pairs in the map in ascending key order.

``` lua
P.pairs(t)
t:pairs()
```

> Like Lua pairs function but iterating on ascending keys

### Lists

``` lua
M.toList(t)
t:toList()
```

> Convert the map to a list of key/value pairs.

### Ordered lists

``` lua
M.toAscList(t)
t:toAscList()
```

> Convert the map to a list of key/value pairs where the keys are in
> ascending order.

``` lua
M.toDescList(t)
t:toDescList()
```

> Convert the map to a list of key/value pairs where the keys are in
> descending order.

## Filter

``` lua
M.filter(p, t)
t:filter(p)
```

> Filter all values that satisfy the predicate.

``` lua
M.filterWithKey(p, t)
t:filterWithKey(p)
```

> Filter all values that satisfy the predicate.

``` lua
M.restrictKeys(t, ks)
t:restrictKeys(ks)
```

> Restrict a map to only those keys found in a list.

``` lua
M.withoutKeys(t, ks)
t:withoutKeys(ks)
```

> Restrict a map to only those keys found in a list.

``` lua
M.partition(p, t)
t:partition(p)
```

> Partition the map according to a predicate. The first map contains all
> elements that satisfy the predicate, the second all elements that fail
> the predicate.

``` lua
M.partitionWithKey(p, t)
t:partitionWithKey(p)
```

> Partition the map according to a predicate. The first map contains all
> elements that satisfy the predicate, the second all elements that fail
> the predicate.

``` lua
M.mapEither(f, t)
t:mapEither(f)
```

> Map values and separate the left and right results.

``` lua
M.mapEitherWithKey(f, t)
t:mapEitherWithKey(f)
```

> Map keys/values and separate the left and right results.

``` lua
M.split(k, t)
t:split(k)
```

> pair (map1,map2) where the keys in map1 are smaller than k and the
> keys in map2 larger than k. Any key equal to k is found in neither
> map1 nor map2.

``` lua
M.splitLookup(k, t)
t:splitLookup(k)
```

> splits a map just like split but also returns lookup(k, t).

## Submap

``` lua
M.isSubmapOf(t1, t2)
t1:isSubmapOf(t2)
```

> returns true if all keys in t1 are in t2.

``` lua
M.isSubmapOfBy(f, t1, t2)
t1:isSubmapOfBy(f, t2)
```

> returns true if all keys in t1 are in t2, and when f returns frue when
> applied to their respective values.

``` lua
M.isProperSubmapOf(t1, t2)
t1:isProperSubmapOf(t2)
```

> returns true if all keys in t1 are in t2 and t1 keys and t2 keys are
> different.

``` lua
M.isProperSubmapOfBy(f, t1, t2)
t1:isProperSubmapOfBy(f, t2)
```

> returns true when t1 and t2 keys are not equal, all keys in t1 are in
> t2, and when f returns true when applied to their respective values.

## Min/Max

``` lua
M.lookupMin(t)
t:lookupMin()
```

> The minimal key of the map and its value.

``` lua
M.lookupMax(t)
t:lookupMax()
```

> The maximal key of the map and its value.

``` lua
M.deleteMin(t)
t:deleteMin()
```

> Delete the minimal key. Returns an empty map if the map is empty.

``` lua
M.deleteMax(t)
t:deleteMax()
```

> Delete the maximal key. Returns an empty map if the map is empty.

``` lua
M.deleteFindMin(t)
t:deleteFindMin()
```

> Delete and find the minimal element.

``` lua
M.deleteFindMax(t)
t:deleteFindMax()
```

> Delete and find the maximal element.

``` lua
M.updateMin(f, t)
t:updateMin(f)
```

> Update the value at the minimal key.

``` lua
M.updateMax(f, t)
t:updateMax(f)
```

> Update the value at the maximal key.

``` lua
M.updateMinWithKey(f, t)
t:updateMinWithKey(f)
```

> Update the value at the minimal key.

``` lua
M.updateMaxWithKey(f, t)
t:updateMaxWithKey(f)
```

> Update the value at the maximal key.

``` lua
M.minView(t)
t:minView()
```

> Retrieves the value associated with minimal key of the map, and the
> map stripped of that element, or nil if passed an empty map.

``` lua
M.maxView(t)
t:maxView()
```

> Retrieves the value associated with maximal key of the map, and the
> map stripped of that element, or nil if passed an empty map.

``` lua
M.minViewWithKey(t)
t:minViewWithKey()
```

> Retrieves the minimal (key,value) pair of the map, and the map
> stripped of that element, or Nothing if passed an empty map.

``` lua
M.maxViewWithKey(t)
t:maxViewWithKey()
```

> Retrieves the maximal (key,value) pair of the map, and the map
> stripped of that element, or Nothing if passed an empty map.
