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
https://codeberg.org/cdsoft/luax
--]]

--@LIB

--[[------------------------------------------------------------------------@@@
# Simple HTTP(S) module based on curl

```lua
local http = require "http"
```

`http` is meant to be a simple replacement of LuaSocket and OpenSSL.
It can issue HTTP(S) requests using `curl`.
curl must be installed separately.

@@@]]

local http = {}

local DEFAULT_USER_AGENT = "LuaX/"..require"luax-version".version
local global_user_agent = DEFAULT_USER_AGENT

local F = require "F"
local curl = require "curl"

--[[@@@
```lua
http.set_user_agent([user_agent])
```
> Define the default User-Agent header used by HTTP requests.
> If no `user_agent` is given, the default value is used (`LuaX/X.Y`).
@@@]]
function http.set_user_agent(ua)
    global_user_agent = ua or DEFAULT_USER_AGENT
end

--[[@@@
```lua
http.request(method, url, [options])
```
> Issue a generic HTTP(S) request, using the method `method` to the target URL `url`.
> `options` is an optional table:
>
> - `options.headers`: header table (key names are normalized: `_` is replaced by `-` and words are capitalized)
> - `options.body`: body of the request (e.g. for `POST` requests)
> - `options.output_file`: filename where the response data is saved
> - `options.user_agent`: user agent specific to this request
>
> It returns a table with the following fields:
>
> - `ok`: `true` if the requests is successful (i.e. the status is `2XX`)
> - `status`: HTTP status code
> - `status_msg`: HTTP status message (if any)
> - `headers`: response header table with normalized keys (`-` replaced with `_`, all lower case)
>
> In case of errorn it returns `nil` and an error message.
@@@]]

local function http_ok(code) return code >= 200 and code < 300 end

local function q(s)
    s = ("%q"):format(s) -- escape special chars
    s = s:gsub("%$", "\\$") -- escape $ to avoid unwanted interpolations
    return s
end

function http.request(method, url, options)
    options = options or {}
    local headers = options.headers or {}
    local body = options.body
    local output_file = options.output_file
    local user_agent = options.user_agent or global_user_agent

    headers = F.mapk2a(function(k, v)
        return {k : gsub("_", "-") : split "%-" : map(string.cap) : str "-", v}
    end, headers) : map2t(F.unpack)

    headers["User-Agent"] = headers["User-Agent"] or user_agent

    local response, error_message = curl.request {
        "--location", "--silent", "--show-headers",
        "--request", method:upper(), url,
        F.mapk2a(function(k, v)
            return { "--header", q(('%s: %s'):format(k, v)) }
        end, headers),
        body and { "--data", q(body) } or {},
    }
    if not response then return nil, error_message end

    local status_line, headers_str, response_body = response:match("^(.-)\r\n(.-)\r\n\r\n(.*)$")
    if not status_line then return nil, "curl: Unexpected reply format" end

    local _, status_code, status_msg = status_line:split(" ", 2):unpack() -- HTTP/X.Y 200 msg...
    status_code = tonumber(status_code)

    local response_headers = {}
    for line in headers_str:gmatch("([^\r\n]+)") do
        local k, v = line : split(":", 1) : map(string.trim) : unpack()
        if k and v then
            k = k : gsub("%-", "_") : lower()
            response_headers[k] = v
        end
    end
    response_headers.content_length = tonumber(response_headers.content_length)

    local ok = http_ok(status_code)

    if output_file and ok then
        local write_ok, errmsg = fs.write_bin(output_file, response_body)
        if not write_ok then return nil, errmsg end
    end

    return {
        ok = ok,
        status = status_code,
        status_msg = #status_msg > 0 and status_msg or status_code,
        headers = response_headers,
        body = response_body
    }
end

--[[@@@
```lua
http.get(url, [options])
```
> Issue a `GET` requests using `http.request`.
@@@]]
function http.get(url, options)
    return http.request("GET", url, options)
end

--[[@@@
```lua
http.head(url, [options])
```
> Issue a `HEAD` requests using `http.request`.
@@@]]
function http.head(url, options)
    return http.request("HEAD", url, options)
end

--[[@@@
```lua
http.post(url, body, [options])
```
> Issue a `POST` requests using `http.request`.
@@@]]
function http.post(url, body, options)
    return http.request("POST", url, F.merge{options or {}, {body=body}})
end

--[[@@@
```lua
http.put(url, body, [options])
```
> Issue a `PUT` requests using `http.request`.
@@@]]
function http.put(url, body, options)
    return http.request("PUT", url, F.merge{options or {}, {body=body}})
end

--[[@@@
```lua
http.delete(url, [options])
```
> Issue a `DELETE` requests using `http.request`.
@@@]]
function http.delete(url, options)
    return http.request("DELETE", url, options)
end

--[[@@@
```lua
http.connect(url, [options])
```
> Issue a `CONNECT` requests using `http.request`.
@@@]]
function http.connect(url, options)
    return http.request("CONNECT", url, options)
end

--[[@@@
```lua
http.options(url, [options])
```
> Issue a `OPTIONS` requests using `http.request`.
@@@]]
function http.options(url, options)
    return http.request("OPTIONS", url, options)
end

--[[@@@
```lua
http.trace(url, [options])
```
> Issue a `TRACE` requests using `http.request`.
@@@]]
function http.trace(url, options)
    return http.request("TRACE", url, options)
end

--[[@@@
```lua
http.patch(url, body, [options])
```
> Issue a `PATCH` requests using `http.request`.
@@@]]
function http.patch(url, body, options)
    return http.request("PATCH", url, F.merge{options or {}, {body=body}})
end

--[[@@@
```lua
http.download(url, output_file, [options])
```
> Issue a `GET` requests using `http.request` and store the response into `output_file`.
> It returns `true` if the download is successful.
@@@]]
function http.download(url, output_file, options)
    local response, err = http.request("GET", url, F.merge{options or {}, {output_file=output_file}})
    if not response then return nil, err end
    if not http_ok(response.status) then return nil, response.status_msg end
    return true
end

return setmetatable(http, {
    __call = function(self, method, url, options)
        return self.request(method, url, options)
    end,
})
