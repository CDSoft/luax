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
https://codeberg.org/cdsoft/luax
--]]

--[[@@@
* `image(render, ext)(source)`: use the command `render` to produce an image from the source `source` with the format `ext` (`"svg"`, `"png"` or `"pdf"`).
  `image` returns the name of the image (e.g. to point to the image once deployed) and the actual file path (e.g. to embed the image in the final document).

The `render` parameter is a string that defines the command to execute to generate the image.
It contains some parameters:

- `%i` is replaced by the name of the input document (temporary file containing `source`).
- `%o` is replaced by the name of the output image file (generated from a hash of `source`).

Images are generated in a directory given by:

- the directory name given by the `--img` option
- the environment variable `YPP_IMG` if it is defined
- the directory name of the output file if the `-o` option is given
- the `img` directory in the current directory

If `source` starts with a `@` (e.g. `@q'"@filename"'`) then the actual image source is read from the file `filename`.

The image link in the output document may have to be different than the
actual path in the file system. This happens when the documents are not
generated in the same path than the source document. Brackets can be used to
specify the part of the path that belongs to the generated image but not to the
link in the output document in `YPP_IMG`.
E.g. if `YPP_IMG=[prefix]path` then images will be generated in `prefix/path`
and the link used in the output document will be `path`.

The file format (extension) must be in `render`, after the `%o` tag (e.g.: `%o.png`).

To avoid useless regenerations, a `.meta` file is created in the same directory than the image.
This file contains image information (source of the image, ypp parameters...).
The image is regenerated only if this information changes.
The `--meta` option can be used to save meta files in a different directory.

If the program requires a specific input file extension, it can be specified in `render`,
after the `%i` tag (e.g.: `%i.xyz`).

Some render commands are predefined.
For each render `X` (which produces images in the default format)
there are 3 other render commands `X.svg`, `X.png` and `X.pdf` which explicitely specify the image format.
They can be used similaryly to `image`: `X(source)`.

An optional table can be given before `source` to set some options:

* `X {name="output_name"} (source)` renders `source` and save the image to a file named `output_name`.
  This can help distributing documents with user friendly image names.

* `X {pp=func} (source)` renders `func(source)` instead of `source`.
  E.g.: if `func` is `ypp` then `source` is preprocessed by `ypp` before being rendered.

@@[===[
    local engine = {
        circo = "Graphviz",
        dot = "Graphviz",
        fdp = "Graphviz",
        neato = "Graphviz",
        osage = "Graphviz",
        patchwork = "Graphviz",
        sfdp = "Graphviz",
        twopi = "Graphviz",
        actdiag = "Blockdiag",
        blockdiag = "Blockdiag",
        nwdiag = "Blockdiag",
        packetdiag = "Blockdiag",
        rackdiag = "Blockdiag",
        seqdiag = "Blockdiag",
        mmdc = "Mermaid",
        asy = "Asymptote",
        plantuml = "PlantUML",
        ditaa = "ditaa",
        gnuplot = "gnuplot",
        lsvg = "lsvg",
        octave = "octave",
    }
    local function cmp(x, y)
        assert(engine[x], x.." engine unknown")
        assert(engine[y], y.." engine unknown")
        if engine[x] == engine[y] then return x < y end
        return engine[x] < engine[y]
    end
    return F{
        "Image engine | ypp function | Example",
        "-------------|--------------|--------",
    }
    ..
    F.keys(image):sort(cmp):map(function(x)
        return ("[%s] | `%s` | `image.%s(source)`"):format(engine[x], x, x)
    end)
]===]

Example:

@q[=====[
``` markdown
![ypp image generation example](@image.dot [===[
digraph {
    rankdir=LR;
    input -> ypp -> output
    ypp -> image
}
]===])
```
]=====]

is rendered as

@@image.set_meta_path(BUILD/"tmp/doc/ypp")
![ypp image generation example](img/@image.dot {name="image"} [===[
digraph {
    rankdir=LR;
    input -> ypp -> output
    ypp -> image
}
]===] : basename())

@@@]]

local F = require "F"
local fs = require "fs"
local sh = require "sh"

local output_path   -- actual directory where images are saved
local link_path     -- directory added to image filenames
local img_path      -- default path for generated images
local meta_path     -- default path for meta image files

local function parse_output_path(path)
    local prefix, link = path : match "^%[(.-)%](.*)"
    if prefix then
        output_path = fs.join(prefix, link)
        link_path = link
    else
        output_path = path
        link_path = path
    end
end

local function get_input_ext(s)
    return s:match("%%i(%.%w+)") or ""
end

local function get_ext(s, t)
    return s:match("%%o(%.%w+)") or t:match("%%o(%.%w+)") or ""
end

local function make_diagram_cmd(src, out, render)
    return render:gsub("%%i", src):gsub("%%o", out)
end

local function render_diagram(cmd)
    if cmd:match "^asy " then
        -- for asymptote, the -o option is the output name without its extension
        cmd = cmd:gsub("(-o )(%S+)", function(opt, name)
            return opt..name:splitext()
        end)
    end
    -- stdout shall be discarded otherwise ypp can not be used in a pipe
    if not sh.read(cmd) then ypp.error "diagram error" end
end

local output_file -- filename given by the -o option

local function default_image_output()
    if not output_path then
        local env = os.getenv "YPP_IMG"
        parse_output_path(
            img_path
            or (env and env ~= "" and env)
            or (output_file and fs.join(fs.dirname(output_file), "img"))
            or "img")
    end
end

local function diagram(exe, render, default_ext)
    local template
    if type(render) == "table" then
        render, template = F.unpack(render)
    else
        template = "%s"
    end
    render = render
        : gsub("%%exe", exe or "%0")
        : gsub("%%ext", default_ext or "%0")
        : gsub("%%o", default_ext and ("%%o."..default_ext) or "%0")
    template = template
        : gsub("%%ext", default_ext or "%0")
        : gsub("%%o", default_ext and ("%%o."..default_ext) or "%0")
    render = F.I{ext=default_ext}(render)
    local render_image = function(contents, opts)
        local filename = contents:match("^@([^\n\r]+)$")
        if filename then
            contents = tostring(include.raw(filename))
        end
        contents = (opts.pp or F.id)(contents)
        local input_ext = get_input_ext(render)
        local ext = get_ext(render, template)
        local hash = crypt.hash(render..contents)
        default_image_output()
        fs.mkdirs(output_path)
        local img_name = opts.name or hash
        local out = fs.join(output_path, img_name)
        local link = fs.join(link_path, fs.basename(out))
        local meta = (meta_path and meta_path/img_name or out)..ext..".meta"
        local meta_content = F.unlines {
            "hash: "..hash,
            "render: "..render,
            "out: "..out,
            "link: "..link,
            "",
            (template : gsub("%%s", contents)),
        }
        local old_meta = fs.read(meta) or ""
        if not fs.is_file(out..ext) or meta_content ~= old_meta then
            fs.with_tmpdir(function(tmpdir)
                fs.mkdirs(fs.dirname(out))
                local name = fs.join(tmpdir, "diagram")
                local name_ext = name..input_ext
                local templated_contents = template
                    : gsub("%%o", out)
                    : gsub("%%s", contents)
                if not fs.write(name_ext, templated_contents) then ypp.error("can not create %s", name_ext) end
                if not fs.write(meta, meta_content) then ypp.error("can not create %s", meta) end
                local render_cmd = make_diagram_cmd(name, out, render)
                render_diagram(render_cmd)
            end)
        end
        return link..ext, out..ext
    end
    return function(param)
        if type(param) == "table" then
            local opts = param
            return function(contents)
                return render_image(contents, opts)
            end
        else
            local contents = param
            return render_image(contents, {})
        end
    end
end

local default_ext = "svg"

local PLANTUML = _G["PLANTUML"] or os.getenv "PLANTUML" or fs.join(fs.dirname(arg[0]), "plantuml.jar")
local DITAA = _G["DITAA"] or os.getenv "DITAA" or fs.join(fs.dirname(arg[0]), "ditaa.jar")

local graphviz = "%exe -T%ext -o %o %i"
local plantuml = "java -jar "..PLANTUML.." -pipe -charset UTF-8 -t%ext < %i > %o"
local asymptote = "%exe -f %ext -o %o %i"
local mermaid = "%exe --pdfFit -i %i -o %o"
local blockdiag = "%exe -a -T%ext -o %o %i"
local ditaa = "java -jar "..DITAA.." $(ext=='svg' and '--svg' or '') -o -e UTF-8 %i %o"
local gnuplot = "%exe -e 'set terminal %ext' -e 'set output \"%o\"' -c %i"
local lsvg = "%exe %i.lua -o %o"
local octave = { "octave --silent --no-gui %i", 'figure("visible", "off")\n\n%s\nprint %o;' }

local function define(t)
    local self = {}
    local mt = {}
    for k, v in pairs(t) do
        if k:match "^__" then
            mt[k] = v
        else
            self[k] = v
        end
    end
    return setmetatable(self, mt)
end

local function instantiate(exe, render)
    return define {
        __call = function(_, ...) return diagram(exe, render, default_ext)(...) end,
        svg = diagram(exe, render, "svg"),
        png = diagram(exe, render, "png"),
        pdf = diagram(exe, render, "pdf"),
    }
end

return define {
    dot         = instantiate("dot", graphviz),
    neato       = instantiate("neato", graphviz),
    twopi       = instantiate("twopi", graphviz),
    circo       = instantiate("circo", graphviz),
    fdp         = instantiate("fdp", graphviz),
    sfdp        = instantiate("sfdp", graphviz),
    patchwork   = instantiate("patchwork", graphviz),
    osage       = instantiate("osage", graphviz),
    plantuml    = instantiate("plantuml", plantuml),
    asy         = instantiate("asy", asymptote),
    mmdc        = instantiate("mmdc", mermaid),
    actdiag     = instantiate("actdiag", blockdiag),
    blockdiag   = instantiate("blockdiag", blockdiag),
    nwdiag      = instantiate("nwdiag", blockdiag),
    packetdiag  = instantiate("packetdiag", blockdiag),
    rackdiag    = instantiate("rackdiag", blockdiag),
    seqdiag     = instantiate("seqdiag", blockdiag),
    ditaa       = instantiate("ditaa", ditaa),
    gnuplot     = instantiate("gnuplot", gnuplot),
    lsvg        = instantiate("lsvg", lsvg),
    octave      = instantiate("octave", octave),
    __call = function(_, render, ext) return diagram(nil, render, ext) end,
    __index = {
        format = function(fmt) default_ext = fmt end,
        output = function(path) output_file = path end,
        set_img_path = function(path) img_path = path end,
        set_meta_path = function(path) meta_path = path end,
    },
}
