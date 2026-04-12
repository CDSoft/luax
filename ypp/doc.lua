--[[
This file is part of ypp.

ypp is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

ypp is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with ypp.  If not, see <https://www.gnu.org/licenses/>.

For further information about ypp you can visit
https://codeberg.org/cdsoft/ypp
--]]

local F = require "F"
local flex = require "flex"
local convert = require "convert"

--[[@@@
* `doc(filename, [opts])`: extract documentation fragments from the file `filename` (all fragments are concatenated).

    - `opts.pattern` is the Lua pattern used to identify the documentation fragments. The default pattern is `@("@".."@@(.-)@@".."@")`.
    - `opts.from` is the format of the documentation fragments (e.g. `"markdown"`, `"rst"`, ...). The default format is Markdown.
    - `opts.to` is the destination format of the documentation (e.g. `"markdown"`, `"rst"`, ...). The default format is Markdown.
    - `opts.shift` is the offset applied to the header levels. The default offset is `0`.
    - `opts.code` extract code (i.e. everything but documentation fragments) in code blocks.
      The code language is given by the filename (if `opts.code==true`) or by `opts.code` if it is a string.
    - `opts.hide` is a Lua pattern used to identify portions of documentations or code to exclude.

@q[=====[
The `doc` macro can also be called as a curried function (arguments can be swapped). E.g.:

    @doc "file.c" {pattern="///(.-)///"}

]=====]
@@@]]

local function default_pattern()
    local tag = ("@"):rep(3)
    return tag.."(.-)"..tag
end

local langs = {
  -- General programming
  ["lua"] = "lua",
  ["py"] = "python",
  ["pyw"] = "python",
  ["java"] = "java",
  ["c"] = "c",
  ["h"] = "c",
  ["cpp"] = "cpp",
  ["cc"] = "cpp",
  ["cxx"] = "cpp",
  ["hpp"] = "cpp",
  ["hxx"] = "cpp",
  ["cs"] = "csharp",
  ["go"] = "go",
  ["rs"] = "rust",
  ["swift"] = "swift",
  ["kt"] = "kotlin",
  ["kts"] = "kotlin",

  -- JavaScript/TypeScript
  ["js"] = "javascript",
  ["mjs"] = "javascript",
  ["cjs"] = "javascript",
  ["jsx"] = "javascript",
  ["ts"] = "typescript",
  ["tsx"] = "typescript",

  -- Web
  ["html"] = "html",
  ["htm"] = "html",
  ["css"] = "css",
  ["scss"] = "scss",
  ["sass"] = "sass",
  ["less"] = "less",
  ["xml"] = "xml",
  ["svg"] = "xml",
  ["json"] = "json",
  ["yaml"] = "yaml",
  ["yml"] = "yaml",
  ["toml"] = "toml",

  -- Scripts
  ["sh"] = "bash",
  ["bash"] = "bash",
  ["zsh"] = "bash",
  ["fish"] = "fish",
  ["ps1"] = "powershell",
  ["psm1"] = "powershell",
  ["bat"] = "batch",
  ["cmd"] = "batch",
  ["awk"] = "awk",

  -- PHP and other web languages
  ["php"] = "php",
  ["php3"] = "php",
  ["php4"] = "php",
  ["php5"] = "php",
  ["rb"] = "ruby",
  ["pl"] = "perl",
  ["pm"] = "perl",

  -- Databases
  ["sql"] = "sql",

  -- Scientific languages
  ["r"] = "r",
  ["m"] = "matlab",
  ["jl"] = "julia",
  ["f"] = "fortran",
  ["f90"] = "fortran",
  ["f95"] = "fortran",

  -- Markup and documentation
  ["md"] = "markdown",
  ["markdown"] = "markdown",
  ["tex"] = "latex",
  ["latex"] = "latex",
  ["rst"] = "rst",
  ["asciidoc"] = "asciidoc",
  ["adoc"] = "asciidoc",

  -- Configuration and build
  ["dockerfile"] = "dockerfile",
  ["makefile"] = "makefile",
  ["mk"] = "makefile",
  ["cmakelists"] = "cmake",
  ["cmake"] = "cmake",
  ["vim"] = "vim",
  ["diff"] = "diff",
  ["patch"] = "diff",

  -- Other languages
  ["hs"] = "haskell",
  ["lhs"] = "haskell",
  ["scala"] = "scala",
  ["sc"] = "scala",
  ["erl"] = "erlang",
  ["ex"] = "elixir",
  ["exs"] = "elixir",
  ["clj"] = "clojure",
  ["cljs"] = "clojure",
  ["nim"] = "nim",
  ["d"] = "d",
  ["v"] = "verilog",
  ["vhd"] = "vhdl",
  ["vhdl"] = "vhdl",
  ["asm"] = "assembly",
  ["s"] = "assembly",

  -- Data formats
  ["ini"] = "ini",
  ["cfg"] = "ini",
  ["conf"] = "conf",
  ["properties"] = "properties",

  -- JVM languages
  ["groovy"] = "groovy",
  ["gradle"] = "groovy",
}

return flex.str(function(filename, opts)
    opts = opts or {}
    local pattern = opts.pattern or default_pattern()
    local content = ypp.with_inputfile(filename, function(full_filepath)
        local s = ypp.read_file(full_filepath)
        if opts.hide then s = s:gsub(opts.hide, "") end
        local code
        if opts.code then
            local lang
            local name, ext = filename:splitext()
            name = name:lower()
            ext = ext and ext:gsub("^%.", ""):lower()
            if opts.code == true then
                lang = langs[ext] or langs[name:basename()]
            else
                lang = langs[opts.code:gsub("^%.", "")] or opts.code
            end
            local fence = ("~"):rep(32)
            while s:find(fence, 1, true) do
                fence = fence .. "~~"
            end
            local start = lang and ("%s{.%s}"):format(fence, lang) or fence
            local stop = fence
            code = function(src)
                src = src : lines()
                    : drop_while(string.null)
                    : drop_while_end(string.null)
                if #src == 0 then return nil end
                local block = F.unlines { start, src:unlines(), stop }
                return convert.if_required(block, {to = opts.from})
            end
        else
            code = F.const(nil)
        end
        local output = F{}
        local i = 1
        while i <= #s do
            local i1, i2, doc = s:find(pattern, i)
            if not i1 then
                output[#output+1] = code(s:sub(i, #s))
                break
            end
            output[#output+1] = code(s:sub(i, i1-1))
            output[#output+1] = ypp(doc)
            i = i2+1
        end
        return output:unlines()
    end)
    content = convert.if_required(content, opts)
    return content
end)
