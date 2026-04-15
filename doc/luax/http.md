# Simple HTTP(S) module based on curl

``` lua
local http = require "http"
```

`http` is meant to be a simple replacement of LuaSocket and OpenSSL. It
can issue HTTP(S) requests using `curl`. curl must be installed
separately.

``` lua
http.set_user_agent([user_agent])
```

> Define the default User-Agent header used by HTTP requests. If no
> `user_agent` is given, the default value is used (`LuaX/X.Y`).

``` lua
http.request(method, url, [options])
```

> Issue a generic HTTP(S) request, using the method `method` to the
> target URL `url`. `options` is an optional table:
>
> - `options.headers`: header table (key names are normalized: `_` is
>   replaced by `-` and words are capitalized)
> - `options.body`: body of the request (e.g. for `POST` requests)
> - `options.output_file`: filename where the response data is saved
> - `options.user_agent`: user agent specific to this request
>
> It returns a table with the following fields:
>
> - `ok`: `true` if the requests is successful (i.e. the status is
>   `2XX`)
> - `status`: HTTP status code
> - `status_msg`: HTTP status message (if any)
> - `headers`: response header table with normalized keys (`-` replaced
>   with `_`, all lower case)
>
> In case of errorn it returns `nil` and an error message.

``` lua
http.get(url, [options])
```

> Issue a `GET` requests using `http.request`.

``` lua
http.head(url, [options])
```

> Issue a `HEAD` requests using `http.request`.

``` lua
http.post(url, body, [options])
```

> Issue a `POST` requests using `http.request`.

``` lua
http.put(url, body, [options])
```

> Issue a `PUT` requests using `http.request`.

``` lua
http.delete(url, [options])
```

> Issue a `DELETE` requests using `http.request`.

``` lua
http.connect(url, [options])
```

> Issue a `CONNECT` requests using `http.request`.

``` lua
http.options(url, [options])
```

> Issue a `OPTIONS` requests using `http.request`.

``` lua
http.trace(url, [options])
```

> Issue a `TRACE` requests using `http.request`.

``` lua
http.patch(url, body, [options])
```

> Issue a `PATCH` requests using `http.request`.

``` lua
http.download(url, output_file, [options])
```

> Issue a `GET` requests using `http.request` and store the response
> into `output_file`. It returns `true` if the download is successful.
