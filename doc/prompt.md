# prompt: Prompt module

The prompt module is a basic prompt implementation to display a prompt
and get user inputs.

The use of [rlwrap](https://github.com/hanslub42/rlwrap) is highly
recommended for a better user experience on Linux.

``` lua
local prompt = require "prompt"
```

``` lua
s = prompt.read(p)
```

prints `p` and waits for a user input

``` lua
prompt.clear()
```

clears the screen
