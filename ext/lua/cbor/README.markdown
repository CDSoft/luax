Lua-CBOR
========

Lua-CBOR is a (mostly) pure Lua implementation of the
[CBOR](http://cbor.io/), a compact data serialization format,
defined in [RFC 7049](http://tools.ietf.org/html/rfc7049).
It supports Lua 5.1 until 5.4 and will utilize struct packing
and bitwise operations if available.

Installing
----------

Lua-CBOR can be installed using [LuaRocks](https://luarocks.org/):

    luarocks install lua-cbor

Sources are available from <https://code.zash.se/lua-cbor/>.

### Optional dependencies

-   Struct library compatible with [`string.pack` and `string.unpack`
    from Lua 5.3](http://www.lua.org/manual/5.3/manual.html#6.4.2), such
    as <http://www.inf.puc-rio.br/~roberto/struct/>.
-   Bitwise operators compatible with
    [those in LuaJIT](http://bitop.luajit.org/) or
    [Lua 5.2](https://luarocks.org/modules/siffiejoe/bit32).

API
---

Lua-CBOR has a similar API to many other serialization libraries, like
Lua-CJSON.

### `cbor.encode(object[, options])`

`cbor.encode` encodes `object` into its CBOR representation and returns
that as a string.

Optionally, a table `options` may be supplied, containing a mapping of
metatables to custom encoder functions for tables and userdata. Such
functions should return an encoded CBOR data string.

### `cbor.decode(string[, options])`

`cbor.decode` decodes CBOR encoded data from `string` and returns a Lua
value.

The optional table `options` may contain callbacks for semantic types
and simple values encountered during decoding. Simple values use the
field `simple` and semantic tagged types use integer indices.

### `cbor.decode_file(file[, options)`

`cbor.decode_file` behaves like `cbor.decode` but reads from a Lua file
handle instead of a string. It can also read from anything that behaves
like a file handle, i.e. exposes an `:read(bytes)` method.

### `cbor.simple(value, name, [cbor])`

`cbor.simple` creates an object representing a ["simple" value][simple],
which are small (up to 255) named integers.

Two such values are pre-defined:

* `cbor.null` is used to represent the null value.
* `cbor.undefined` is used to represent the undefined value.

[simple]: http://tools.ietf.org/html/rfc7049#section-2.3

### `cbor.tagged(tag, value)`

`cbor.tagged` creates an object representing a ["tagged" value][tagged],
which is an integer attached to a value, which can be any value.

[tagged]: http://tools.ietf.org/html/rfc7049#section-2.4

### `cbor.type_encoders`

A table containing functions for serializing each Lua type, and a few
without direct Lua equivalents.

`number`
:   Encodes as `integer` or `float` depending on the value.

`integer`
:   Encodes an integer.

`float`
:   Encodes a IEEE 754 Double-Precision Float, the default Lua number type until 5.3.

`string`
:   Encodes a Lua string as a CBOR byte string, or an UTF-8 string if it
    appars as such to the Lua 5.3 function `utf8.len`.

`boolean`
:   Encodes a boolean value.

`table`
:   Encodes a Lua table either as a CBOR array or map. If it sees
    succesive integer keys when iterating using `pairs`, it will return an array,
    otherwise a map.

`array`
:   Encodes a Lua table as a CBOR array. Uses `ipairs` internally so the
    resulting array will end at the first `nil`.

`map`
:   Encodes a Lua table as a CBOR map, without guessing if it should be an array.

`ordered_map`
:   Encodes a Lua table as a CBOR map, with ordered keys. Order can be
    specified by listing them with incrementing integer keys, otherwise
    the default sort order is used.

Custom serialization
--------------------

Tables and userdata types that have a metatable may invoke custom
serialization, either by placing a callback in the optional `options`
argument, or via a `__tocbor` metatable field.

This can be composed from fields in `cbor.type_encoders`.

Some examples::

```lua
-- using options:

local array_mt = { __name = "array" }

local myarray = setmetatable({1, 2, 3, nil, foo= "bar" }, array_mt);
local options = {
    [array_mt] = cbor.type_encoders.array
}

cbor.encode(myarray, options);

-- or using a __tocbor metatable field

local array_mt = { __tocbor = cbor.type_encoders.array }

cbor.encode(setmetatable({1, 2, 3, nil, foo= "bar" }, array_mt));

local ordered_map_mt = { __tocbor = cbor.type_encoders.ordered_map }

cbor.encode(setmetatable({ foo = "hello", bar = "world", "foo", "bar" }, array_mt));
```

Bignum support
--------------

Lua-CBOR has optional support for bignums, using
[luaossl](http://www.25thandclement.com/~william/projects/luaossl.html).

```lua
local cbor = require"cbor";
local bignum = require"openssl.bignum";
require"cbor.bignum";

io.write(cbor.encode(bignum.new("9000")));
```
