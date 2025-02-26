# Simple wget interface

``` lua
local wget = require "wget"
```

`wget` provides functions to execute wget. wget must be installed
separately.

``` lua
wget.request(...)
```

> Execute `wget` with arguments `...` and returns the output of `wget`
> (`stdout`). Arguments can be a nested list (it will be flattened). In
> case of error, `wget` returns `nil`, an error message and an error
> code (see [wget man
> page](https://www.gnu.org/software/wget/manual/html_node/Exit-Status.html)).

``` lua
wget(...)
```

> Like `wget(...)` with some default options:
>
> - `--quiet`: quiet mode
