# linenoise: light readline alternative

**WARNING**: This module is deprecated. Use `readline` instead.

[linenoise](https://github.com/antirez/linenoise) is a small
self-contained alternative to readline and libedit.

**Warning**: linenoise has not been ported to Windows. The following
functions works on Windows but are stubbed using the Lua `io` module
when possible. The history can not be saved on Windows.

``` lua
linenoise.read(prompt)
```

prints `prompt` and returns the string entered by the user.

``` lua
linenoise.read_mask(prompt)
```

is the same as `linenoise.read(prompt)` but the characters are not
echoed but replaced with `*`.

``` lua
linenoise.add(line)
```

adds `line` to the current history.

``` lua
linenoise.set_len(len)
```

sets the maximal history length to `len`.

``` lua
linenoise.save(filename)
```

saves the history to the file `filename`.

``` lua
linenoise.load(filename)
```

loads the history from the file `filename`.

``` lua
linenoise.clear()
```

clears the screen.

``` lua
linenoise.multi_line(ml)
```

enable/disable the multi line mode (enabled by default).

``` lua
linenoise.mask(b)
```

enable/disable the mask mode.
