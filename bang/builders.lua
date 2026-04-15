-- This file is part of bang.
--
-- bang is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- bang is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with bang.  If not, see <https://www.gnu.org/licenses/>.
--
-- For further information about bang you can visit
-- https://codeberg.org/cdsoft/luax

local F = require "F"
local fs = require "fs"
local sys = require "sys"

local default_options = {
    cmd = "cat",
    flags = {},
    args = "$in > $out",
    ext = "",
}

local builder_keys = F.keys(default_options) .. { "name", "output_prefix" }

local function set_ext(name, ext)
    if (vars%name):lower():has_suffix(ext:lower()) then return name end
    return name..ext
end

local function split_hybrid_table(t)
    local function is_numeric_key(k)
        return math.type(k) == "integer"
    end
    return F.table_partition_with_key(is_numeric_key, t)
end

local rules = setmetatable({}, {
    __index = function(self, builder)
        local new_rule = rule(builder.name) (F.merge{
            {
                description = builder.description or {builder.name, "$out"},
                command = { builder.cmd, builder.flags, builder.args },
            },
            F.without_keys(builder, builder_keys),
        })
        self[builder] = new_rule
        return new_rule
    end
})

local function gen_rule(self)
    return rules[self]
end

local function run(self, output)
    return function(inputs)
        if type(inputs) == "string" then
            inputs = {inputs}
        end
        local input_list, input_vars = split_hybrid_table(inputs)
        output = set_ext(output, self.ext)
        return build(output) (F.merge{
            { rules[self], input_list },
            self.output_prefix and { output_prefix = output:splitext() } or {},
            input_vars,
        })
    end
end

local builder_mt

local builder_definitions = {}

local function new(builder, name)
    if builder_definitions[name] then
        error(name..": document builder redefinition")
    end
    local self = F.merge { builder, {name=name} }
    builder_definitions[name] = self
    return setmetatable(self, builder_mt)
end

builder_mt = {
    __call = run,

    __index = {
        new = new,

        rule = gen_rule,
        build = run,

        set = function(self, name)
            return function(value) self[name] = value; return self end
        end,
        add = function(self, name)
            return function(value) self[name] = self[name]==nil and value or {self[name], value}; return self end
        end,
        insert = function(self, name)
            return function(value) self[name] = self[name]==nil and value or {value, self[name]}; return self end
        end,
    },
}

local cat = new(default_options, "cat")
local cp = new(default_options, "cp")
    : set "cmd" "cp"
    : set "flags" (sys.os=="linux" and "-d --preserve=mode" or {})
    : set "args" "$in $out"

local ypp = new(default_options, "ypp")
    : set "cmd" "ypp"
    : set "args" "$in -o $out"
    : set "flags" "--MF $depfile"
    : set "depfile" "$out.d"

local function ypp_var(name)
    return function(val)
        return ("-e '%s=(%q):read()'"):format(name, F.show(val))
    end
end

local function ypp_vars(t)
    return F.mapk2a(function(k, v) return ("-e '%s=%q'"):format(k, v) end, t)
end

local pandoc = new(default_options, "pandoc")
    : set "cmd" "pandoc"
    : set "args" "$in -o $out"
    : set "flags" {
        "--fail-if-warnings",
    }

local panda = pandoc:new "panda"
    : set "cmd" "panda"
    : add "flags" {
        "-Vpanda_target=$out",
        "-Vpanda_dep_file=$depfile",
    }
    : set "depfile" "$out.d"

local typst = new(default_options, "typst")
    : set "cmd" "typst"
    : set "args" "$in $out"
    : set "flags" "compile"

if sys.os == "windows" then
    cat : set "cmd" "type"
    cp : set "cmd" "copy"
       : set "flags" "/B /Y"
       : set "args" "$in $out"
end

local dot = new(default_options, "dot")
    : set "cmd" "dot"
    : set "args" "-o $out $in"

local PLANTUML = os.getenv "PLANTUML" or fs.findpath "plantuml.jar"

local plantuml = new(default_options, "plantuml")
    : set "cmd" { "java -jar", PLANTUML }
    : set "flags" { "-pipe", "charset UTF-8" }
    : set "args" "< $in > $out"

local DITAA = os.getenv "DITAA" or fs.findpath "ditaa.jar"

local ditaa = new(default_options, "ditaa")
    : set "cmd" { "java -jar", DITAA }
    : set "flags" { "-o", "-e UTF-8" }
    : set "args" "$in $out"

local asymptote = new(default_options, "asymptote")
    : set "cmd" "asy"
    : set "args" "-o $output_prefix $in"
    : set "output_prefix" (true)

local mermaid = new(default_options, "mermaid")
    : set "cmd" "mmdc"
    : set "flags" "--pdfFit"
    : set "args" "-i $in -o $out"

local blockdiag = new(default_options, "blockdiag")
    : set "cmd" "blockdiag"
    : set "flags" "-a"
    : set "args" "-o $out $in"

local gnuplot = new(default_options, "gnuplot")
    : set "cmd" "gnuplot"
    : set "args" { "-e 'set output \"$out\"'", "-c $in" }

local lsvg = new(default_options, "lsvg")
    : set "cmd" "lsvg"
    : set "flags" { "--MF $depfile" }
    : set "depfile" "$out.d"
    : set "args" "$in -o $out -- $args"

local octave = new(default_options, "octave")
    : set "cmd" "octave"
    : set "flags" {
        "--silent",
        "--no-gui",
        "--eval 'figure(\"visible\",\"off\");'",
    }
    : set "args" {
        "--eval 'run(\"$in\");'";
        "--eval 'print $out;'",
    }

return setmetatable({
    cat = cat,
    cp = cp,
    ypp = ypp, ypp_var = ypp_var, ypp_vars = ypp_vars,
    ypp_pandoc = ypp:new "ypp_pandoc" : set "cmd" "ypp-pandoc.lua",
    panda = panda,
    panda_gfm = panda:new "panda_gfm" : add "flags" "-t gfm",
    pandoc = pandoc,
    pandoc_gfm = pandoc:new "pandoc_gfm" : add "flags" "-t gfm",
    typst = typst,
    graphviz = {
        dot = {
            svg = dot:new "dot.svg" : add "flags" "-Tsvg" : set "ext" ".svg",
            png = dot:new "dot.png" : add "flags" "-Tpng" : set "ext" ".png",
            jpg = dot:new "dot.jpg" : add "flags" "-Tjpg" : set "ext" ".jpg",
            pdf = dot:new "dot.pdf" : add "flags" "-Tpdf" : set "ext" ".pdf",
        },
        neato = {
            svg = dot:new "neato.svg" : set "cmd" "neato" : add "flags" "-Tsvg" : set "ext" ".svg",
            png = dot:new "neato.png" : set "cmd" "neato" : add "flags" "-Tpng" : set "ext" ".png",
            jpg = dot:new "neato.jpg" : set "cmd" "neato" : add "flags" "-Tjpg" : set "ext" ".jpg",
            pdf = dot:new "neato.pdf" : set "cmd" "neato" : add "flags" "-Tpdf" : set "ext" ".pdf",
        },
        twopi = {
            svg = dot:new "twopi.svg" : set "cmd" "twopi" : add "flags" "-Tsvg" : set "ext" ".svg",
            png = dot:new "twopi.png" : set "cmd" "twopi" : add "flags" "-Tpng" : set "ext" ".png",
            jpg = dot:new "twopi.jpg" : set "cmd" "twopi" : add "flags" "-Tjpg" : set "ext" ".jpg",
            pdf = dot:new "twopi.pdf" : set "cmd" "twopi" : add "flags" "-Tpdf" : set "ext" ".pdf",
        },
        circo = {
            svg = dot:new "circo.svg" : set "cmd" "circo" : add "flags" "-Tsvg" : set "ext" ".svg",
            png = dot:new "circo.png" : set "cmd" "circo" : add "flags" "-Tpng" : set "ext" ".png",
            jpg = dot:new "circo.jpg" : set "cmd" "circo" : add "flags" "-Tjpg" : set "ext" ".jpg",
            pdf = dot:new "circo.pdf" : set "cmd" "circo" : add "flags" "-Tpdf" : set "ext" ".pdf",
        },
        fdp = {
            svg = dot:new "fdp.svg" : set "cmd" "fdp" : add "flags" "-Tsvg" : set "ext" ".svg",
            png = dot:new "fdp.png" : set "cmd" "fdp" : add "flags" "-Tpng" : set "ext" ".png",
            jpg = dot:new "fdp.jpg" : set "cmd" "fdp" : add "flags" "-Tjpg" : set "ext" ".jpg",
            pdf = dot:new "fdp.pdf" : set "cmd" "fdp" : add "flags" "-Tpdf" : set "ext" ".pdf",
        },
        sfdp = {
            svg = dot:new "sfdp.svg" : set "cmd" "sfdp" : add "flags" "-Tsvg" : set "ext" ".svg",
            png = dot:new "sfdp.png" : set "cmd" "sfdp" : add "flags" "-Tpng" : set "ext" ".png",
            jpg = dot:new "sfdp.jpg" : set "cmd" "sfdp" : add "flags" "-Tjpg" : set "ext" ".jpg",
            pdf = dot:new "sfdp.pdf" : set "cmd" "sfdp" : add "flags" "-Tpdf" : set "ext" ".pdf",
        },
        patchwork = {
            svg = dot:new "patchwork.svg" : set "cmd" "patchwork" : add "flags" "-Tsvg" : set "ext" ".svg",
            png = dot:new "patchwork.png" : set "cmd" "patchwork" : add "flags" "-Tpng" : set "ext" ".png",
            jpg = dot:new "patchwork.jpg" : set "cmd" "patchwork" : add "flags" "-Tjpg" : set "ext" ".jpg",
            pdf = dot:new "patchwork.pdf" : set "cmd" "patchwork" : add "flags" "-Tpdf" : set "ext" ".pdf",
        },
        osage = {
            svg = dot:new "osage.svg" : set "cmd" "osage" : add "flags" "-Tsvg" : set "ext" ".svg",
            png = dot:new "osage.png" : set "cmd" "osage" : add "flags" "-Tpng" : set "ext" ".png",
            jpg = dot:new "osage.jpg" : set "cmd" "osage" : add "flags" "-Tjpg" : set "ext" ".jpg",
            pdf = dot:new "osage.pdf" : set "cmd" "osage" : add "flags" "-Tpdf" : set "ext" ".pdf",
        },
    },
    plantuml = {
        svg = plantuml:new "plantuml.svg" : add "flags" "-tsvg" : set "ext" ".svg",
        png = plantuml:new "plantuml.png" : add "flags" "-tpng" : set "ext" ".png",
        pdf = plantuml:new "plantuml.pdf" : add "flags" "-tpdf" : set "ext" ".pdf",
    },
    ditaa = {
        svg = ditaa:new "ditaa.svg" : add "flags" "--svg" : set "ext" ".svg",
        png = ditaa:new "ditaa.png" : set "ext" ".png",
        pdf = ditaa:new "ditaa.pdf" : set "ext" ".pdf",
    },
    asymptote = {
        svg = asymptote:new "asymptote.svg" : add "flags" "-f svg" : set "ext" ".svg",
        png = asymptote:new "asymptote.png" : add "flags" "-f png" : set "ext" ".png",
        jpg = asymptote:new "asymptote.jpg" : add "flags" "-f jpg" : set "ext" ".jpg",
        pdf = asymptote:new "asymptote.pdf" : add "flags" "-f pdf" : set "ext" ".pdf",
    },
    mermaid = {
        svg = mermaid:new "mermaid.svg" : add "flags" "-e svg" : set "ext" ".svg",
        png = mermaid:new "mermaid.png" : add "flags" "-e png" : set "ext" ".png",
        pdf = mermaid:new "mermaid.pdf" : add "flags" "-e pdf" : set "ext" ".pdf",
    },
    blockdiag = {
        svg = blockdiag:new "blockdiag.svg" : add "flags" "-Tsvg" : set "ext" ".svg",
        png = blockdiag:new "blockdiag.png" : add "flags" "-Tpng" : set "ext" ".png",
        pdf = blockdiag:new "blockdiag.pdf" : add "flags" "-Tpdf" : set "ext" ".pdf",
        activity = {
            svg = blockdiag:new "actdiag.svg" : set "cmd" "actdiag" : add "flags" "-Tsvg" : set "ext" ".svg",
            png = blockdiag:new "actdiag.png" : set "cmd" "actdiag" : add "flags" "-Tpng" : set "ext" ".png",
            pdf = blockdiag:new "actdiag.pdf" : set "cmd" "actdiag" : add "flags" "-Tpdf" : set "ext" ".pdf",
        },
        network = {
            svg = blockdiag:new "nwdiag.svg" : set "cmd" "nwdiag" : add "flags" "-Tsvg" : set "ext" ".svg",
            png = blockdiag:new "nwdiag.png" : set "cmd" "nwdiag" : add "flags" "-Tpng" : set "ext" ".png",
            pdf = blockdiag:new "nwdiag.pdf" : set "cmd" "nwdiag" : add "flags" "-Tpdf" : set "ext" ".pdf",
        },
        packet = {
            svg = blockdiag:new "packetdiag.svg" : set "cmd" "packetdiag" : add "flags" "-Tsvg" : set "ext" ".svg",
            png = blockdiag:new "packetdiag.png" : set "cmd" "packetdiag" : add "flags" "-Tpng" : set "ext" ".png",
            pdf = blockdiag:new "packetdiag.pdf" : set "cmd" "packetdiag" : add "flags" "-Tpdf" : set "ext" ".pdf",
        },
        rack = {
            svg = blockdiag:new "rackdiag.svg" : set "cmd" "rackdiag" : add "flags" "-Tsvg" : set "ext" ".svg",
            png = blockdiag:new "rackdiag.png" : set "cmd" "rackdiag" : add "flags" "-Tpng" : set "ext" ".png",
            pdf = blockdiag:new "rackdiag.pdf" : set "cmd" "rackdiag" : add "flags" "-Tpdf" : set "ext" ".pdf",
        },
        sequence = {
            svg = blockdiag:new "seqdiag.svg" : set "cmd" "seqdiag" : add "flags" "-Tsvg" : set "ext" ".svg",
            png = blockdiag:new "seqdiag.png" : set "cmd" "seqdiag" : add "flags" "-Tpng" : set "ext" ".png",
            pdf = blockdiag:new "seqdiag.pdf" : set "cmd" "seqdiag" : add "flags" "-Tpdf" : set "ext" ".pdf",
        },
    },
    gnuplot = {
        svg = gnuplot:new "gnuplot.svg" : add "flags" { "-e 'set terminal svg'" }     : set "ext" ".svg",
        png = gnuplot:new "gnuplot.png" : add "flags" { "-e 'set terminal png'" }     : set "ext" ".png",
        jpg = gnuplot:new "gnuplot.jpg" : add "flags" { "-e 'set terminal jpeg'" }    : set "ext" ".jpg",
        pdf = gnuplot:new "gnuplot.pdf" : add "flags" { "-e 'set terminal context'" } : set "ext" ".pdf",
    },
    lsvg = {
        svg = lsvg:new "lsvg.svg" : set "ext" ".svg",
        png = lsvg:new "lsvg.png" : set "ext" ".png",
        jpg = lsvg:new "lsvg.jpg" : set "ext" ".jpg",
        pdf = lsvg:new "lsvg.pdf" : set "ext" ".pdf",
    },
    octave = {
        svg = octave:new "octave.svg" : set "ext" ".svg",
        png = octave:new "octave.png" : set "ext" ".png",
        jpg = octave:new "octave.jpg" : set "ext" ".jpg",
        pdf = octave:new "octave.pdf" : set "ext" ".pdf",
    },
}, {
    __index = {
        new = function(_, name) return cat:new(name) end,
    }
})
