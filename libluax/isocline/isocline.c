/* This file is part of luax.
 *
 * luax is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * luax is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with luax.  If not, see <https://www.gnu.org/licenses/>.
 *
 * For further information about luax you can visit
 * https://github.com/cdsoft/luax
 */

/***************************************************************************@@@
# isocline: light readline alternative

[Isocline](https://github.com/daanx/isocline)
is a portable GNU readline alternative.

See <https://daanx.github.io/isocline> for furter details.
@@@*/

#include "isocline.h"

#include <stdbool.h>
#include <stdlib.h>
#include <unistd.h>

#include "lua.h"
#include "lauxlib.h"

#include "ext/c/isocline/include/isocline.h"

static bool running_in_a_tty;

/*@@@
```lua
isocline.readline(prompt_text)
```
Read input from the user using rich editing abilities.
The prompt text, can be `nil` for the default ("").
The displayed prompt becomes `prompt_text` followed by the `prompt_marker` ("> ").
@@@*/

static int isocline_readline(lua_State *L)
{
    const char *prompt_text = lua_isstring(L, 1) ? luaL_checkstring(L, 1) : NULL;
    char *line = ic_readline(prompt_text);
    if (line != NULL) {
        lua_pushstring(L, line);
        ic_free(line);
    } else {
        lua_pushnil(L);
    }
    return 1;
}

//--------------------------------------------------------------
// Formatted Text
//--------------------------------------------------------------

/*@@@
```lua
isocline.print(s)
```
Print to the terminal while respection bbcode markup.
@@@*/

static int isocline_print(lua_State *L)
{
    const char *s = luaL_checkstring(L, 1);
    ic_print(s);
    return 0;
}

/*@@@
```lua
isocline.println(s)
```
Print with bbcode markup ending with a newline.
@@@*/

static int isocline_println(lua_State *L)
{
    const char *s = luaL_checkstring(L, 1);
    ic_println(s);
    return 0;
}

/*@@@
```lua
isocline.printf(fmt, ...)
```
Print formatted with bbcode markup.
@@@*/

/* implemented in isocline.lua */

/*@@@
```lua
isocline.style_def(style_name, fmt)
```
Define or redefine a style.
@@@*/

static int isocline_style_def(lua_State *L)
{
    const char *style_name = luaL_checkstring(L, 1);
    const char *fmt = luaL_checkstring(L, 2);
    ic_style_def(style_name, fmt);
    return 0;
}

/*@@@
```lua
isocline.style_open(fmt)
```
Start a global style that is only reset when calling a matching ic_style_close().
@@@*/

static int isocline_style_open(lua_State *L)
{
    const char *fmt = luaL_checkstring(L, 1);
    ic_style_open(fmt);
    return 0;
}

/*@@@
```lua
isocline.style_close()
```
End a global style.
@@@*/

static int isocline_style_close(lua_State *L)
{
    (void)L;
    ic_style_close();
    return 0;
}

//--------------------------------------------------------------
// History
//--------------------------------------------------------------

/*@@@
```lua
isocline.set_history(fname, max_entries)
```
Enable history.
Use a `nil` filename to not persist the history. Use `-1` or `nil` for max_entries to get the default (1000).
@@@*/

static int isocline_set_history(lua_State *L)
{
    const char *fname = lua_isstring(L, 1) ? luaL_checkstring(L, 1) : NULL;
    const long max_entries = lua_isinteger(L, 2) ? (long)luaL_checkinteger(L, 2) : -1;
    ic_set_history(fname, max_entries);
    return 0;
}

/*@@@
```lua
isocline.history_remove_last()
```
Remove the last entry in the history.
@@@*/

static int isocline_history_remove_last(lua_State *L)
{
    (void)L;
    ic_history_remove_last();
    return 0;
}

/*@@@
```lua
isocline.history_clear()
```
Clear the history.
@@@*/

static int isocline_history_clear(lua_State *L)
{
    (void)L;
    ic_history_clear();
    return 0;
}

/*@@@
```lua
isocline.history_add(entry)
```
Add an entry to the history
@@@*/

static int isocline_history_add(lua_State *L)
{
    const char *entry = luaL_checkstring(L, 1);
    ic_history_add(entry);
    return 0;
}

//--------------------------------------------------------------
// Options
//--------------------------------------------------------------

/*@@@
```lua
isocline.set_prompt_marker(prompt_marker, continuation_prompt_marker)
```
Set a prompt marker and a potential marker for extra lines with multiline input.
Pass `nil` for the `prompt_marker` for the default marker (`"> "`).
Pass `nil` for continuation prompt marker to make it equal to the `prompt_marker`.
@@@*/

static int isocline_set_prompt_marker(lua_State *L)
{
    const char *prompt_marker = lua_isstring(L, 1) ? luaL_checkstring(L, 1) : NULL;
const char *continuation_prompt_marker = lua_isstring(L, 2) ? luaL_checkstring(L, 2) : NULL;
    ic_set_prompt_marker(prompt_marker, continuation_prompt_marker);
    return 0;
}

/*@@@
```lua
isocline.get_prompt_marker()
```
Get the current prompt marker.
@@@*/

static int isocline_get_prompt_marker(lua_State *L)
{
    lua_pushstring(L, ic_get_prompt_marker());
return 1;
}
/*@@@
```lua
isocline.get_continuation_prompt_marker()
```
Get the current continuation prompt marker.
@@@*/

static int isocline_get_continuation_prompt_marker(lua_State *L)
{
    lua_pushstring(L, ic_get_continuation_prompt_marker());
    return 1;
}

/*@@@
```lua
isocline.enable_multiline(enable)
```
Disable or enable multi-line input (enabled by default).
Returns the previous setting.
@@@*/

static int isocline_enable_multiline(lua_State *L)
{
    const bool enable = lua_isboolean(L, 1)? lua_toboolean(L, 1) : true;
    lua_pushboolean(L, ic_enable_multiline(enable));
    return 1;
}

/*@@@
```lua
isocline.enable_beep(enable)
```
Disable or enable sound (enabled by default).
A beep is used when tab cannot find any completion for example.
Returns the previous setting.
@@@*/

static int isocline_enable_beep(lua_State *L)
{
    const bool enable = lua_isboolean(L, 1) ? lua_toboolean(L, 1) : true;
    lua_pushboolean(L, ic_enable_beep(enable));
    return 1;
}

/*@@@
```lua
isocline.enable_color(enable)
```
Disable or enable color output (enabled by default).
Returns the previous setting.
@@@*/

static int isocline_enable_color(lua_State *L)
{
    const bool enable = lua_isboolean(L, 1) ? lua_toboolean(L, 1) : true;
    lua_pushboolean(L, ic_enable_color(enable));
    return 1;
}

/*@@@
```lua
isocline.enable_history_duplicates(enable)
```
Disable or enable duplicate entries in the history (disabled by default).
Returns the previous setting.
@@@*/

static int isocline_enable_history_duplicates(lua_State *L)
{
    const bool enable = lua_isboolean(L, 1) ? lua_toboolean(L, 1) : true;
    lua_pushboolean(L, ic_enable_history_duplicates(enable));
    return 1;
}

/*@@@
```lua
isocline.enable_auto_tab(enable)
```
Disable or enable automatic tab completion after a completion
to expand as far as possible if the completions are unique. (disabled by default).
Returns the previous setting.
@@@*/

static int isocline_enable_auto_tab(lua_State *L)
{
    const bool enable = lua_isboolean(L, 1)? lua_toboolean(L, 1) : true;
    lua_pushboolean(L, ic_enable_auto_tab(enable));
    return 1;
}

/*@@@
```lua
isocline.enable_completion_preview(enable)
```
Disable or enable preview of a completion selection (enabled by default)
Returns the previous setting.
@@@*/

static int isocline_enable_completion_preview(lua_State *L)
{
    const bool enable = lua_isboolean(L, 1) ? lua_toboolean(L, 1) : true;
    lua_pushboolean(L, ic_enable_completion_preview(enable));
    return 1;
}

/*@@@
```lua
isocline.enable_multiline_indent(enable)
```
Disable or enable automatic identation of continuation lines in multiline
input so it aligns with the initial prompt.
Returns the previous setting.
@@@*/

static int isocline_enable_multiline_indent(lua_State *L)
{
    const bool enable = lua_isboolean(L, 1) ? lua_toboolean(L, 1) : true;
    lua_pushboolean(L, ic_enable_multiline_indent(enable));
    return 1;
}

/*@@@
```lua
isocline.enable_inline_help(enable)
```
Disable or enable display of short help messages for history search etc.
(full help is always dispayed when pressing F1 regardless of this setting)
Returns the previous setting.
@@@*/

static int isocline_enable_inline_help(lua_State *L)
{
    const bool enable = lua_isboolean(L, 1) ? lua_toboolean(L, 1) : true;
    lua_pushboolean(L, ic_enable_inline_help(enable));
    return 1;
}

/*@@@
```lua
isocline.enable_hint(enable)
```
Disable or enable hinting (enabled by default)
Shows a hint inline when there is a single possible completion.
Returns the previous setting.
@@@*/

static int isocline_enable_hint(lua_State *L)
{
    const bool enable = lua_isboolean(L, 1) ? lua_toboolean(L, 1) : true;
    lua_pushboolean(L, ic_enable_hint(enable));
    return 1;
}

/*@@@
```lua
isocline.set_hint_delay(delay_ms)
```
Set millisecond delay before a hint is displayed. Can be zero. (500ms by default).
@@@*/

static int isocline_set_hint_delay(lua_State *L)
{
    const long delay_ms = (long)luaL_checkinteger(L, 1);
    lua_pushinteger(L, ic_set_hint_delay(delay_ms));
    return 1;
}

/*@@@
```lua
isocline.enable_highlight(enable)
```
Disable or enable syntax highlighting (enabled by default).
This applies regardless whether a syntax highlighter callback was set (`ic_set_highlighter`)
Returns the previous setting.
@@@*/

static int isocline_enable_highlight(lua_State *L)
{
    const bool enable = lua_isboolean(L, 1) ? lua_toboolean(L, 1) : true;
    lua_pushboolean(L, ic_enable_highlight(enable));
    return 1;
}

/*@@@
```lua
isocline.set_tty_esc_delay(initial_delay_ms, followup_delay_ms)
```
Set millisecond delay for reading escape sequences in order to distinguish
a lone ESC from the start of a escape sequence. The defaults are 100ms and 10ms,
but it may be increased if working with very slow terminals.
@@@*/

static int isocline_set_tty_esc_delay(lua_State *L)
{
    const long initial_delay_ms = (long)luaL_checkinteger(L, 1);
    const long followup_delay_ms = (long)luaL_checkinteger(L, 2);
    ic_set_tty_esc_delay(initial_delay_ms, followup_delay_ms);
    return 0;
}

/*@@@
```lua
isocline.enable_brace_matching(enable)
```
Enable highlighting of matching braces (and error highlight unmatched braces).
@@@*/

static int isocline_enable_brace_matching(lua_State *L)
{
    const bool enable = lua_isboolean(L, 1) ? lua_toboolean(L, 1) : true;
    lua_pushboolean(L, ic_enable_brace_matching(enable));
    return 1;
}

/*@@@
```lua
isocline.set_matching_braces(brace_pairs)
```
Set matching brace pairs.
Pass `nil` for the default `"()[]{}"`.
@@@*/

static int isocline_set_matching_braces(lua_State *L)
{
    const char *brace_pairs = lua_isstring(L, 1) ? luaL_checkstring(L, 1) : NULL;
    ic_set_matching_braces(brace_pairs);
    return 0;
}

/*@@@
```lua
isocline.enable_brace_insertion(enable)
```
Enable automatic brace insertion (enabled by default).
@@@*/

static int isocline_enable_brace_insertion(lua_State *L)
{
    const bool enable = lua_isboolean(L, 1)? lua_toboolean(L, 1) : true;
    lua_pushboolean(L, ic_enable_brace_insertion(enable));
    return 1;
}

/*@@@
```lua
isocline.set_insertion_braces(brace_pairs)
```
Set matching brace pairs for automatic insertion.
Pass `nil` for the default `()[]{}\"\"''`
@@@*/

static int isocline_set_insertion_braces(lua_State *L)
{
    const char *brace_pairs = lua_isstring(L, 1) ? luaL_checkstring(L, 1) : NULL;
    ic_set_insertion_braces(brace_pairs);
    return 0;
}

//--------------------------------------------------------------
// Lua module
//--------------------------------------------------------------

static const luaL_Reg isoclinelib[] =
{
    {"readline",                        isocline_readline},
    {"print",                           isocline_print},
    {"println",                         isocline_println},
    {"style_def",                       isocline_style_def},
    {"style_open",                      isocline_style_open},
    {"style_close",                     isocline_style_close},
    {"set_history",                     isocline_set_history},
    {"history_remove_last",             isocline_history_remove_last},
    {"history_clear",                   isocline_history_clear},
    {"history_add",                     isocline_history_add},
    {"set_prompt_marker",               isocline_set_prompt_marker},
    {"get_prompt_marker",               isocline_get_prompt_marker},
    {"get_continuation_prompt_marker",  isocline_get_continuation_prompt_marker},
    {"enable_multiline",                isocline_enable_multiline},
    {"enable_beep",                     isocline_enable_beep},
    {"enable_color",                    isocline_enable_color},
    {"enable_history_duplicates",       isocline_enable_history_duplicates},
    {"enable_auto_tab",                 isocline_enable_auto_tab},
    {"enable_completion_preview",       isocline_enable_completion_preview},
    {"enable_multiline_indent",         isocline_enable_multiline_indent},
    {"enable_inline_help",              isocline_enable_inline_help},
    {"enable_hint",                     isocline_enable_hint},
    {"set_hint_delay",                  isocline_set_hint_delay},
    {"enable_highlight",                isocline_enable_highlight},
    {"set_tty_esc_delay",               isocline_set_tty_esc_delay},
    {"enable_brace_matching",           isocline_enable_brace_matching},
    {"set_matching_braces",             isocline_set_matching_braces},
    {"enable_brace_insertion",          isocline_enable_brace_insertion},
    {"set_insertion_braces",            isocline_set_insertion_braces},
    {NULL, NULL}
};

LUAMOD_API int luaopen_isocline (lua_State *L)
{
    luaL_newlib(L, isoclinelib);
    running_in_a_tty = isatty(STDIN_FILENO);
    return 1;
}
