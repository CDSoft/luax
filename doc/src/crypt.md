# crypt: cryptography module

```lua
local crypt = require "crypt"
```

**`crypt.hex_encode(data)`** encodes `data` in hexa.

**`crypt.hex_decode(data)`** decodes the hexa `data`.

**`crypt.base64_encode(data)`** encodes `data` in base64.

**`crypt.base64_decode(data)`** decodes the base64 `data`.

**`crypt.base64url_encode(data)`** encodes `data` in base64url.

**`crypt.base64url_decode(data)`** decodes the base64url `data`.

**`crypt.crc32(data)`** computes the CRC32 of `data`.

**`crypt.crc64(data)`** computes the CRC64 of `data`.

**`crypt.rc4(data, key, [drop])`** encrypts/decrypts `data` using the RC4Drop
algorithm and the encryption key `key` (drops the first `drop` encryption
steps, the default value of `drop` is 768).

**`crypt.srand(seed)`** sets the random seed.

**`crypt.rand()`** returns a random integral number between `0` and `crypt.RAND_MAX`.

**`crypt.rand(bytes)`** returns a string with `bytes` random bytes.

**`crypt.frand()`** returns a random floating point number between `0.0` and `1.0`.

**`crypt.prng(seed)`** returns a random number generator starting from the
optional seed `seed`. This object has three methods: `srand(seed)`,
`rand([bytes])` and `frand()`.

`crypt` also exports functions from
[TinyCrypt](https://github.com/intel/tinycrypt):

**`crypt.sha256(data)`** returns the SHA256 digest of `data`.

**`crypt.hmac(data, key)`** returns the HMAC-SHA256 digest of `data` using `key`
as a key.

**`crypt.hmac_prng(personalization)`** returns a HMAC PRNG initialized with
`personalization` (32 bytes of more) and some OS dependant entropy. This object
has three methods: `srand(seed)`, `rand([bytes])` and `frand()`.

**`crypt.ctr_prng(personalization)`** returns a CTR PRNG initialized with
`personalization` (32 bytes of more) and some OS dependant entropy. This object
has three methods: `srand(seed)`, `rand([bytes])` and `frand()`.

**`crypt.aes_encrypt(data, key)`** encrypts `data` using the AES-128-CBC
algorithm and the encryption key `key`.

**`crypt.aes_decrypt(data, key)`** decrypts `data` using the AES-128-CBC
algorithm and the encryption key `key`.

Some functions of the `crypt` package are added to the string module:

**`s:hex_encode()`** is `crypt.hex_encode(s)`.

**`s:hex_decode()`** is `crypt.hex_decode(s)`.

**`s:base64_encode()`** is `crypt.base64_encode(s)`.

**`s:base64_decode()`** is `crypt.base64_decode(s)`.

**`s:base64url_encode()`** is `crypt.base64url_encode(s)`.

**`s:base64url_decode()`** is `crypt.base64url_decode(s)`.

**`s:crc32()`** is `crypt.crc32(s)`.

**`s:crc64()`** is `crypt.crc64(s)`.

**`s:rc4(key, drop)`** is `crypt.crc64(s, key, drop)`.

**`s:sha256()`** is `crypt.sha256(s)`.

**`s:hmac(key)`** is `crypt.hmac(s, key)`.

**`s:aes_encrypt(key)`** is `crypt.aes_encrypt(s, key)`.

**`s:aes_decrypt(key)`** is `crypt.aes_decrypt(s, key)`.
