# ypp tests

## Variables defined on the command line

VAR1 = <@VAR1>      @@ assert(type(VAR1) == "number")
VAR2 = <@VAR2>      @@ assert(type(VAR2) == "string")
VAR3 = <@VAR3>      @@ assert(type(VAR3) == "string")
VAR4 = <@VAR4>      @@ assert(type(VAR4) == "string")
VAR5 = <@VAR5>      @@ assert(type(VAR5) == "string")
VAR6 = <@VAR6>      @@ assert(type(VAR6) == "string")

## Basic text substitution

$1 + 2 = @(1 + 2)$

@@(
    function sum(a, b)
        return F.range(a, b):sum()
    end
)

$$ \sum_{n=1}^{100} = @(sum(1, 100)) $$

@(F.range(10):map(F.prefix"- Line "))

nil in an expression = @(nil)

nil in a statement = @@(return nil)

@@[===[
-- large block with unbalanced parentheses )))
weird = ") unbalanced ())"
]===]

weird = @[[ "bizarre string )) => " .. weird ]]

malformed expression: @[===========[ foo bar ]=====]
malformed chunk: @@[===========[ foo bar ]=====]

function call: @math.deg(math.pi/2)
chaining methods: @F.range(1, 10):sum()
chaining methods: @string.words[==[ hello world! ]==] : map(string.upper) : reverse() : str(" <- ")
chaining methods: @string.words[==[ hello world! ]==] : map(string.upper) : reverse() : str(" <- ") : reverse()
chaining methods: @(string.words[==[ hello world! ]==] : map(string.upper) : reverse() : str(" <- ")) : reverse()
uncomplete chains: @string.words"a b c":str"-": this colon is not part of the previous macro

escaping: `@q"@F.range(1, 10):sum()"`

Strings can not contain newline characters:
@string.lower "COOL!" 'this is not
a string'
@string.lower 'BUT THIS IS A\
MULTILINE SINGLE QUOTED STRING'

### pattern_1

1+1 = @(1+1)
1+1 = @@(return 1+1)

### pattern_2

1+1 = @[[1+1]]
1+1 = @[==[1+1]==]
1+1 = @@[[return 1+1]]
1+1 = @@[==[return 1+1]==]

### pattern_3

@@[===[
    function func(x, y)
        return function(s)
            return s.." = "..x.." + "..y
        end
    end
    function functb(xs)
        return function(s)
            return s.." = "..F.str(xs, " + ")
        end
    end
    t = {
        u = {
            {
                x = "x",
                f = function(x) return 10*x end,
                g = function(self, x) return 100*x end,
            },
        },
    }
]===]

pi = @math.pi
math.max(2, 3) = @math.max(2, 3)
F.maximum{2, 3, 1} = @F.maximum{2, 3, 1}
func(1, 2)[[three]] = @func(1, 2)[[three]]
functb{1, 2}[[three]] = @functb{1, 2}[[three]]
string.upper[=[ Hello World! ]=] = @string.upper[=[Hello World!]=]
t.u[1].x = @t.u[1].x
t.u[10-9].x = @t.u[10-9].x
t.u[10-9].f(10) = @t.u[10-9].f(10)
t.u[10-9]:g(10) = @t.u[10-9]:g(10)

ignored pattern: someone@example.com
undefined variable: @undefined

### Special syntax for assignments

@@ golden_ratio = 16e-1
$golden\_ratio = @golden_ratio$

@@ vrai = true
@@ faux = false
vrai = @vrai, faux = @false

@@ a = (2*(3+4))
a = @a

@@ b = {
    x = 1,
    y = 2
}
b = @F.show(b)

@@ c = [===[
a long string
]===]
c = @c

@@ d = F.range(10)
        : map(function(x) return x*x end)
        : str(", ")
d = @d

@@ t = {}
@@ t.x = "x"
@@ t[2] = 2
@@ t[3] = t
@@ t[3][4] = 4
@@ t[3].y = "y"
@@ t[3][3].z = "z"
t = @F.show(t)

@@ x = 0x255 @x
@@ x = 0X42 @x

@@ x = 3.1416 @x
@@ x = 314.16e-2 @x
@@ x = 0.31416E1 @x

## File inclusion

@@ypp.macro "!"

Macro char is <!> now in this file but not in the included files.

!! foo = "bar"

foo = !foo
foo = @foo

!include "test_inc.md" {
    pattern = "===(.-)===",
    exclude = "ignored%s*%b{}",
    shift = 2,
}

foo = !foo
foo = @foo

Using a special character with ypp.macro:
!!ypp.macro "^"     ^ => ^foo     ^ypp.macro "!"
!!ypp.macro "$"     $ => $foo     $ypp.macro "!"
!!ypp.macro "%"     % => %foo     %ypp.macro "!"
!!ypp.macro "."     . => .(foo)   .ypp.macro "!"
!!ypp.macro "*"     * => *foo     *ypp.macro "!"
!!ypp.macro "+"     + => +foo     +ypp.macro "!"
!!ypp.macro "-"     - => -foo     -ypp.macro "!"
!!ypp.macro "?"     ? => ?foo     ?ypp.macro "!"

!!ypp.macro "@"

Macro char <@> is back.

foo = !foo
foo = @foo

lines: @include "test_inc.md" : lines() : map(F.const(1)) : sum()

## Comments

@@(--[===[
This comment is ignored
]===])

@comment[=[
This comment is also ignored
]=]

## Conditional

@@(lang = "fr")

@when(lang=="en") [[English text discarded (lang=@(lang))]]
@when(lang=="fr") [[Texte français conservé (lang=@(lang))]]

## Documentation extraction

### Doc blocks only

@doc "test.c" {pattern="@@@(.-)@@@", shift=3}

### Doc blocks and code in code blocks

@@ codedoc = doc {
    pattern = "/%*@@@(.-)@@@%*/",
    code = true,
    hide = "//%-%-%-[%-]*.-//%-%-%-[%-]*",
}
@codedoc "test2.c" {shift=3}

## Scripts

### Custom language

- 1+1 = @script("python") [[print(1+1)]]
- 2+2 = @script("python %s") [[print(2+2)]]

### Predefined language

- 3+3 = @script.python [[print(3+3)]]
- 4+4 = @script.sh [[echo $((4+4))]]

### Formatting script output

#### Explicit conversion

@convert {from="csv"} (script.python [===[
print("X, Y, Z")
print("a, b, c")
print("d, e, f")
]===])

#### Implicit conversion

@script.python {from="csv"} [===[
print("X, Y, Z")
print("a, b, c")
print("d, e, f")
]===]

## Images

@@ example = [===[
digraph {
    A -> B
}
]===]

### Images with the default format (SVG)

@F.map(F.prefix "- ", {image.dot (example)})

### Images with a specific format (e.g. PNG)

@F.map(F.prefix "- ", {image.dot.png (example)})

### Images with a custom command

@F.map(F.prefix "- ", {image("dot -T%ext -o %o %i", "svg") (example)})

### Images generated with Asymptote

@image.asy {name="test-asy"} "dot(0);"

### Images generated with Octave

@image.octave {name="test-octave"} [===[
x = 0:0.01:3;
plot (x, erf (x));
hold on;
plot (x, x, "r");
axis ([0, 3, 0, 1]);
text (0.65, 0.6175, ...
      ['$\displaystyle\leftarrow x = {2 \over \sqrt{\pi}}' ...
       '\int_{0}^{x} e^{-t^2} dt = 0.6175$'],
      "interpreter", "latex");
xlabel ("x");
ylabel ("erf (x)");
title ("erf (x) with text annotation");
]===]

@image.octave [===[
x = 0:0.01:3;
plot (x, erf (x));
hold on;
plot (x, x, "r");
axis ([0, 3, 0, 1]);
text (0.65, 0.6175, ...
      ['$\displaystyle\leftarrow x = {2 \over \sqrt{\pi}}' ...
       '\int_{0}^{x} e^{-t^2} dt = 0.6175$'],
      "interpreter", "latex");
xlabel ("x");
ylabel ("erf (x)");
title ("erf (x) with text annotation");
]===]

### Images from an external file

@image.dot {name="test-dot"} "@ypp/tests/test.dot"

@image.dot "@ypp/tests/test.dot"

### Images preprocessed with ypp

@@ name = "World"
@image.dot {pp=ypp, name="hello"} [===[
digraph {
    "Hello" -> "@name!"
}
]===]

## Scripts loaded on the command line

`test_loaded` = `@test_loaded`

`mod1_loaded` = `@mod1_loaded`      `mod1.name` = `@mod1.name`
`mod2_loaded` = `@mod2_loaded`      `mod2.name` = `@mod2.name`  `mymod.name` = `@mymod.name`
`mod3_loaded` = `@mod3_loaded`      `mod3.name` = `@mod3.name`

## Scripts loaded by test.md

@@require "ypp/tests/test2"

`test_2_loaded` = `@test_2_loaded`

@@ test3 = require "import" "ypp/tests/test3.lua"

`test3.test_3_loaded` = `@test3.test_3_loaded`

## File creation

@@ f = file(ypp.output_file():splitext().."-file.txt")
@@ f [[
first line : 1 + 2 = @(1+2)
]]
@@ f:ypp [[
second line : 1 + 2 = @(1+2)
]]
check @f.name

## Deferred evaluation

### Table of content

@@(
    local toc = {}
    function chapter(title)
        toc[#toc+1] = string.format("%d. %s", #toc+1, title)
        return "### "..title
    end
    nbch = defer(F.length, toc)
    return defer(toc)
)

nbch = @nbch

@chapter "Chapter 1"

nbch = @nbch

@chapter "Chapter 2"

nbch = @nbch

### Accumulation in a table

@@ lines = {}

lines:
@defer(lines)

@@ lines[#lines+1] = "one"
@@ lines[#lines+1] = "two"
@@ lines[#lines+1] = "three"
@@ lines[#lines+1] = { "four", "five", 6 }
@@ lines[#lines+1] = 42

@@ words = {}

words: @defer(F.unwords, words)

@@ words[#words+1] = "un"
@@ words[#words+1] = "deux"
@@ words[#words+1] = "trois"

## End of the document

This text shall not be forgotten.
