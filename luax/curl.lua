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
# Simple curl interface

```lua
local curl = require "curl"
```

`curl` provides functions to execute curl.
curl must be installed separately.

@@@]]

local curl = {
    http = {},
}

local F = require "F"
local sh = require "sh"

--[[------------------------------------------------------------------------@@@
## curl command line
@@@]]

local errs = {
    [  0] = "Success. The operation completed successfully according to the instructions.",
    [  1] = "Unsupported protocol. This build of curl has no support for this protocol.",
    [  2] = "Failed to initialize.",
    [  3] = "URL malformed. The syntax was not correct.",
    [  4] = "A feature or option that was needed to perform the desired request was not enabled or was explicitly disabled at build-time. To make curl able to do this, you probably need another build of libcurl.",
    [  5] = "Could not resolve proxy. The given proxy host could not be resolved.",
    [  6] = "Could not resolve host. The given remote host could not be resolved.",
    [  7] = "Failed to connect to host.",
    [  8] = "Weird server reply. The server sent data curl could not parse.",
    [  9] = "FTP access denied. The server denied login or denied access to the particular resource or directory you wanted to reach. Most often you tried to change to a directory that does not exist on the server.",
    [ 10] = "FTP accept failed. While waiting for the server to connect back when an active FTP session is used, an error code was sent over the control connection or similar.",
    [ 11] = "FTP weird PASS reply. Curl could not parse the reply sent to the PASS request.",
    [ 12] = "During an active FTP session while waiting for the server to connect back to curl, the timeout expired.",
    [ 13] = "FTP weird PASV reply, Curl could not parse the reply sent to the PASV request.",
    [ 14] = "FTP weird 227 format. Curl could not parse the 227-line the server sent.",
    [ 15] = "FTP cannot use host. Could not resolve the host IP we got in the 227-line.",
    [ 16] = "HTTP/2 error. A problem was detected in the HTTP2 framing layer. This is somewhat generic and can be one out of several problems, see the error message for details.",
    [ 17] = "FTP could not set binary. Could not change transfer method to binary.",
    [ 18] = "Partial file. Only a part of the file was transferred.",
    [ 19] = "FTP could not download/access the given file, the RETR (or similar) command failed.",
    [ 21] = "FTP quote error. A quote command returned error from the server.",
    [ 22] = "HTTP page not retrieved. The requested URL was not found or returned another error with the HTTP error code being 400 or above. This return code only appears if -f, --fail is used.",
    [ 23] = "Write error. Curl could not write data to a local filesystem or similar.",
    [ 25] = "Failed starting the upload. For FTP, the server typically denied the STOR command.",
    [ 26] = "Read error. Various reading problems.",
    [ 27] = "Out of memory. A memory allocation request failed.",
    [ 28] = "Operation timeout. The specified time-out period was reached according to the conditions.",
    [ 30] = "FTP PORT failed. The PORT command failed. Not all FTP servers support the PORT command, try doing a transfer using PASV instead.",
    [ 31] = "FTP could not use REST. The REST command failed. This command is used for resumed FTP transfers.",
    [ 33] = "HTTP range error. The range \"command\" did not work.",
    [ 34] = "HTTP post error. Internal post-request generation error.",
    [ 35] = "SSL connect error. The SSL handshaking failed.",
    [ 36] = "Bad download resume. Could not continue an earlier aborted download.",
    [ 37] = "FILE could not read file. Failed to open the file. Permissions?",
    [ 38] = "LDAP cannot bind. LDAP bind operation failed.",
    [ 39] = "LDAP search failed.",
    [ 41] = "Function not found. A required LDAP function was not found.",
    [ 42] = "Aborted by callback. An application told curl to abort the operation.",
    [ 43] = "Internal error. A function was called with a bad parameter.",
    [ 45] = "Interface error. A specified outgoing interface could not be used.",
    [ 47] = "Too many redirects. When following redirects, curl hit the maximum amount.",
    [ 48] = "Unknown option specified to libcurl. This indicates that you passed a weird option to curl that was passed on to libcurl and rejected. Read up in the manual!",
    [ 49] = "Malformed telnet option.",
    [ 52] = "The server did not reply anything, which here is considered an error.",
    [ 53] = "SSL crypto engine not found.",
    [ 54] = "Cannot set SSL crypto engine as default.",
    [ 55] = "Failed sending network data.",
    [ 56] = "Failure in receiving network data.",
    [ 58] = "Problem with the local certificate.",
    [ 59] = "Could not use specified SSL cipher.",
    [ 60] = "Peer certificate cannot be authenticated with known CA certificates.",
    [ 61] = "Unrecognized transfer encoding.",
    [ 63] = "Maximum file size exceeded.",
    [ 64] = "Requested FTP SSL level failed.",
    [ 65] = "Sending the data requires a rewind that failed.",
    [ 66] = "Failed to initialize SSL Engine.",
    [ 67] = "The username, password, or similar was not accepted and curl failed to log in.",
    [ 68] = "File not found on TFTP server.",
    [ 69] = "Permission problem on TFTP server.",
    [ 70] = "Out of disk space on TFTP server.",
    [ 71] = "Illegal TFTP operation.",
    [ 72] = "Unknown TFTP transfer ID.",
    [ 73] = "File already exists (TFTP).",
    [ 74] = "No such user (TFTP).",
    [ 77] = "Problem reading the SSL CA cert (path? access rights?).",
    [ 78] = "The resource referenced in the URL does not exist.",
    [ 79] = "An unspecified error occurred during the SSH session.",
    [ 80] = "Failed to shut down the SSL connection.",
    [ 82] = "Could not load CRL file, missing or wrong format.",
    [ 83] = "Issuer check failed.",
    [ 84] = "The FTP PRET command failed.",
    [ 85] = "Mismatch of RTSP CSeq numbers.",
    [ 86] = "Mismatch of RTSP Session Identifiers.",
    [ 87] = "Unable to parse FTP file list.",
    [ 88] = "FTP chunk callback reported error.",
    [ 89] = "No connection available, the session is queued.",
    [ 90] = "SSL public key does not matched pinned public key.",
    [ 91] = "Invalid SSL certificate status.",
    [ 92] = "Stream error in HTTP/2 framing layer.",
    [ 93] = "An API function was called from inside a callback.",
    [ 94] = "An authentication function returned an error.",
    [ 95] = "A problem was detected in the HTTP/3 layer. This is somewhat generic and can be one out of several problems, see the error message for details.",
    [ 96] = "QUIC connection error. This error may be caused by an SSL library error. QUIC is the protocol used for HTTP/3 transfers.",
    [ 97] = "Proxy handshake error.",
    [ 98] = "A client-side certificate is required to complete the TLS handshake.",
    [ 99] = "Poll or select returned fatal error.",
    [100] = "A value or data field grew larger than allowed.",

    -- This error is returned by the shell, not curl
    [127] = "curl: command not found",
}

--[[@@@
```lua
curl.request(...)
```
> Execute `curl` with arguments `...` and returns the output of `curl` (`stdout`).
> Arguments can be a nested list (it will be flattened).
> In case of error, `curl` returns `nil`, an error message and an error code
> (see [curl man page](https://curl.se/docs/manpage.html)).

@@@]]

function curl.request(...)
    local res, _, err = sh("curl", ...)
    if not res then return nil, errs[tonumber(err)] or "curl: unknown error", err end
    return res
end

--[[@@@
```lua
curl(...)
```
> Like `curl.request(...)` with some default options:
>
> - `--silent`: silent mode
> - `--show-error`: show an error message if it fails
> - `--location`: follow redirections

@@@]]

local default_curl_options = {
    "-s",   --silent
    "-S",   --show-error
    "-L",   --location (follow redirections)
}

setmetatable(curl, { __call = function(_, ...) return curl.request(default_curl_options, ...) end })

--[[------------------------------------------------------------------------@@@
## curl HTTP requests

`curl.http` is meant to be a simple replacement of LuaSocket/LuaSec and OpenSSL.
It can issue HTTP(S) requests using `curl`.

@@@]]

local DEFAULT_USER_AGENT = "LuaX/"..require"luax-version".version
local global_user_agent = DEFAULT_USER_AGENT

--[[@@@
```lua
curl.http.set_user_agent([user_agent])
```
> Define the default User-Agent header used by HTTP requests.
> If no `user_agent` is given, the default value is used (`LuaX/X.Y`).
@@@]]
function curl.http.set_user_agent(ua)
    global_user_agent = ua or DEFAULT_USER_AGENT
end

--[[@@@
```lua
curl.http.request(method, url, [options])
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

function curl.http.request(method, url, options)
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
        "-L",                           --location
        "-s",                           --silent
        "-i",                           --show-headers
        "-X", method:upper(), url,      --request
        F.mapk2a(function(k, v)
            return { "-H", q(('%s: %s'):format(k, v)) } --header
        end, headers),
        body and { "-d", q(body) } or {},               --data
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
curl.http.get(url, [options])
```
> Issue a `GET` requests using `http.request`.
@@@]]
function curl.http.get(url, options)
    return curl.http.request("GET", url, options)
end

--[[@@@
```lua
curl.http.head(url, [options])
```
> Issue a `HEAD` requests using `http.request`.
@@@]]
function curl.http.head(url, options)
    return curl.http.request("HEAD", url, options)
end

--[[@@@
```lua
curl.http.post(url, body, [options])
```
> Issue a `POST` requests using `http.request`.
@@@]]
function curl.http.post(url, body, options)
    return curl.http.request("POST", url, F.merge{options or {}, {body=body}})
end

--[[@@@
```lua
curl.http.put(url, body, [options])
```
> Issue a `PUT` requests using `http.request`.
@@@]]
function curl.http.put(url, body, options)
    return curl.http.request("PUT", url, F.merge{options or {}, {body=body}})
end

--[[@@@
```lua
curl.http.delete(url, [options])
```
> Issue a `DELETE` requests using `http.request`.
@@@]]
function curl.http.delete(url, options)
    return curl.http.request("DELETE", url, options)
end

--[[@@@
```lua
curl.http.connect(url, [options])
```
> Issue a `CONNECT` requests using `http.request`.
@@@]]
function curl.http.connect(url, options)
    return curl.http.request("CONNECT", url, options)
end

--[[@@@
```lua
http.options(url, [options])
```
> Issue a `OPTIONS` requests using `http.request`.
@@@]]
function curl.http.options(url, options)
    return curl.http.request("OPTIONS", url, options)
end

--[[@@@
```lua
curl.http.trace(url, [options])
```
> Issue a `TRACE` requests using `http.request`.
@@@]]
function curl.http.trace(url, options)
    return curl.http.request("TRACE", url, options)
end

--[[@@@
```lua
curl.http.patch(url, body, [options])
```
> Issue a `PATCH` requests using `http.request`.
@@@]]
function curl.http.patch(url, body, options)
    return curl.http.request("PATCH", url, F.merge{options or {}, {body=body}})
end

--[[@@@
```lua
curl.http.download(url, output_file, [options])
```
> Issue a `GET` requests using `http.request` and store the response into `output_file`.
> It returns `true` if the download is successful.
@@@]]
function curl.http.download(url, output_file, options)
    local response, err = curl.http.request("GET", url, F.merge{options or {}, {output_file=output_file}})
    if not response then return nil, err end
    if not http_ok(response.status) then return nil, response.status_msg end
    return true
end

--[[@@@
```lua
curl(...)
```
> Shortcut to `curl.request(...)`.
@@@]]

setmetatable(curl.http, { __call = function(self, ...) return self.request(...) end })

return curl
