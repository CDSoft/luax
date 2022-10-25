---
title: Lua eXtended
author: Christophe Delord
---

# ps: Process management module

```lua
local ps = require "ps"
```

**`ps.sleep(n)`** sleeps for `n` seconds.

**`ps.time()`** returns the current time in seconds (the resolution is OS dependant).

**`ps.profile(func)`** executes `func` and returns its execution time in seconds.
