# Simple curl interface

``` lua
local curl = require "curl"
```

`curl` provides functions to execute curl. curl must be installed
separately.

``` lua
curl.request(...)
```

> Execute `curl` with arguments `...` and returns the output of `curl`
> (`stdout`). Arguments can be a nested list (it will be flattened). In
> case of error, `curl` returns `nil`, an error message and an error
> code (see [curl man page](https://curl.se/docs/manpage.html)).

``` lua
curl(...)
```

> Like `curl.request(...)` with some default options:
>
> - `--silent`: silent mode
> - `--show-error`: show an error message if it fails
> - `--location`: follow redirections
