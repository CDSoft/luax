# Terminal

`term` provides some functions to deal with the terminal in a quite
portable way. It is heavily inspired by:

- [lua-term](https://github.com/hoelzro/lua-term/): Terminal operations
  for Lua
- [nocurses](https://github.com/osch/lua-nocurses/): A terminal screen
  manipulation library

``` lua
local term = require "term"
```

## Colors

The table `term.colors` contain objects that can be used to build
colorized string with ANSI sequences.

An object `term.color.X` can be used:

- as a string
- as a function
- in combination with other color attributes

``` lua
-- change colors in a string
" ... " .. term.color.X .. " ... "

-- change colors for a string and reset colors at the end of the string
term.color.X("...")

-- build a complex color with attributes
local c = term.color.red + term.color.italic + term.color.oncyan
```

| `term.color` field | Description                         |
|:-------------------|:------------------------------------|
| reset              | reset the colors                    |
| clear              | same as reset                       |
| default            | same as reset                       |
| bright             | bold or more intense                |
| bold               | same as bold                        |
| dim                | thiner or less intense              |
| italic             | italic (sometimes inverse or blink) |
| underline          | underlined                          |
| blink              | slow blinking (less than 150 bpm)   |
| fast               | fast blinking (more than 150 bpm)   |
| reverse            | swap foreground and background      |
| hidden             | hidden text                         |
| strike             | strike or crossed-out               |
| black              | black foreground                    |
| red                | red foreground                      |
| green              | green foreground                    |
| yellow             | yellow foreground                   |
| blue               | blue foreground                     |
| magenta            | magenta foreground                  |
| cyan               | cyan foreground                     |
| white              | white foreground                    |
| onblack            | black background                    |
| onred              | red background                      |
| ongreen            | green background                    |
| onyellow           | yellow background                   |
| onblue             | blue background                     |
| onmagenta          | magenta background                  |
| oncyan             | cyan background                     |
| onwhite            | white background                    |

## Cursor

The table `term.cursor` contains functions to change the shape of the
cursor:

``` lua
-- turns the cursor into a blinking vertical thin bar
term.cursor.bar_blink()
```

| `term.cursor` field | Description                |
|:--------------------|:---------------------------|
| reset               | reset to the initial shape |
| block_blink         | blinking block cursor      |
| block               | fixed block cursor         |
| underline_blink     | blinking underline cursor  |
| underline           | fixed underline cursor     |
| bar_blink           | blinking bar cursor        |
| bar                 | fixed bar cursor           |

## Terminal

``` lua
term.reset()
```

resets the colors and the cursor shape.

``` lua
term.clear()
term.clearline()
term.cleareol()
term.clearend()
```

clears the terminal, the current line, the end of the current line or
from the cursor to the end of the terminal.

``` lua
term.pos(row, col)
```

moves the cursor to the line `row` and the column `col`.

``` lua
term.save_pos()
term.restore_pos()
```

saves and restores the position of the cursor.

``` lua
term.up([n])
term.down([n])
term.right([n])
term.left([n])
```

moves the cursor by `n` characters up, down, right or left.

## Prompt

The prompt function is a basic prompt implementation to display a prompt
and get user inputs.

The use of [rlwrap](https://github.com/hanslub42/rlwrap) is highly
recommended for a better user experience on Linux.

``` lua
s = term.prompt(p)
```

prints `p` and waits for a user input

``` lua
term.isatty([fileno])
```

returns `true` if `fileno` is a tty. The default file descriptor is
`stdin` (`0`).

``` lua
term.size([fileno])
```

returns a table with the number of rows (field `rows`) and columns
(field `cols`) of the terminal attached to `fileno`. The default file
descriptor is `stdout` (`0`).
