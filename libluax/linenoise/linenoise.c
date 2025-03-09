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
# linenoise: light readline alternative

[linenoise](https://github.com/antirez/linenoise)
is a small self-contained alternative to readline and libedit.

**Warning**: linenoise has not been ported to Windows.
The following functions works on Windows but are stubbed using the Lua `io` module when possible.
The history can not be saved on Windows.
@@@*/

#include "linenoise.h"

#include <stdbool.h>
#include <unistd.h>

#include "lua.h"
#include "lauxlib.h"

#ifdef _WIN32
#define isatty _isatty
#else
#define HAS_LINENOISE
#include "ext/c/linenoise/linenoise.h"
#include "ext/c/linenoise/utf8.h"
#endif

#ifdef HAS_LINENOISE
#define LUAX_HISTORY_LEN    10000
#else
#define LUAX_MAXINPUT       4096
#endif

#ifdef HAS_LINENOISE
static int mask_mode = 0;
#endif

static bool running_in_a_tty;

/*@@@
```lua
linenoise.read(prompt)
```
prints `prompt` and returns the string entered by the user.
@@@*/

static int linenoise_read(lua_State *L)
{
    const char *prompt = luaL_checkstring(L, 1);
#ifdef HAS_LINENOISE
    char *line = linenoise(prompt);
    if (line != NULL)
    {
        lua_pushstring(L, line);
        linenoiseFree(line);
    }
    else
    {
        lua_pushnil(L);
    }
#else
    char line[LUAX_MAXINPUT];
    if (running_in_a_tty) {
        fputs(prompt, stdout);
        fflush(stdout);
    }
    if (fgets(line, LUAX_MAXINPUT, stdin) != NULL)
    {
        lua_pushstring(L, line);
    }
    else
    {
        lua_pushnil(L);
    }
#endif
    return 1;
}

/*@@@
```lua
linenoise.read_mask(prompt)
```
is the same as `linenoise.read(prompt)`
but the characters are not echoed but replaced with `*`.
@@@*/

static int linenoise_read_mask(lua_State *L)
{
#ifdef HAS_LINENOISE
    linenoiseMaskModeEnable();
#endif
    const int n = linenoise_read(L);
#ifdef HAS_LINENOISE
    if (!mask_mode)
    {
        linenoiseMaskModeDisable();
    }
#endif
    return n;
}

/*@@@
```lua
linenoise.add(line)
```
adds `line` to the current history.
@@@*/

static int linenoise_history_add(lua_State *L)
{
#ifdef HAS_LINENOISE
    if (running_in_a_tty)
    {
        if (lua_isstring(L, 1))
        {
            const char *line = luaL_checkstring(L, 1);
            linenoiseHistoryAdd(line);
        }
    }
#else
    (void)L;
#endif
    return 0;
}

/*@@@
```lua
linenoise.set_len(len)
```
sets the maximal history length to `len`.
@@@*/

static int linenoise_history_set_len(lua_State *L)
{
#ifdef HAS_LINENOISE
    const int len = (int)luaL_checkinteger(L, 1);
    linenoiseHistorySetMaxLen(len);
#else
    (void)L;
#endif
    return 0;
}

/*@@@
```lua
linenoise.save(filename)
```
saves the history to the file `filename`.
@@@*/

static int linenoise_history_save(lua_State *L)
{
#ifdef HAS_LINENOISE
    if (running_in_a_tty)
    {
        linenoiseHistorySave(luaL_checkstring(L, 1));
    }
#else
    (void)L;
#endif
    return 0;
}

/*@@@
```lua
linenoise.load(filename)
```
loads the history from the file `filename`.
@@@*/

static int linenoise_history_load(lua_State *L)
{
#ifdef HAS_LINENOISE
    if (running_in_a_tty)
    {
        linenoiseHistoryLoad(luaL_checkstring(L, 1));
    }
#else
    (void)L;
#endif
    return 0;
}

/*@@@
```lua
linenoise.clear()
```
clears the screen.
@@@*/

static int linenoise_clear_screen(lua_State *L __attribute__((unused)))
{
#ifdef HAS_LINENOISE
    linenoiseClearScreen();
#else
    const char *clear = "\x1b[1;1H\x1b[2J";
    write(STDOUT_FILENO, clear, 12);
#endif
    return 0;
}

/*@@@
```lua
linenoise.multi_line(ml)
```
enable/disable the multi line mode (enabled by default).
@@@*/

static int linenoise_set_multi_line(lua_State *L)
{
#ifdef HAS_LINENOISE
    const bool ml = luaL_checkinteger(L, 1);
    linenoiseSetMultiLine(ml);
#else
    (void)L;
#endif
    return 0;
}

/*@@@
```lua
linenoise.mask(b)
```
enable/disable the mask mode.
@@@*/

static int linenoise_mask_mode(lua_State *L)
{
#ifdef HAS_LINENOISE
    mask_mode = (int)luaL_checkinteger(L, 1);
    if (mask_mode)
    {
        linenoiseMaskModeEnable();
    }
    else
    {
        linenoiseMaskModeDisable();
    }
#else
    (void)L;
#endif
    return 0;
}

static const luaL_Reg linenoiselib[] =
{
    {"read",        linenoise_read},
    {"read_mask",   linenoise_read_mask},
    {"add",         linenoise_history_add},
    {"set_len",     linenoise_history_set_len},
    {"save",        linenoise_history_save},
    {"load",        linenoise_history_load},
    {"clear",       linenoise_clear_screen},
    {"multi_line",  linenoise_set_multi_line},
    {"mask",        linenoise_mask_mode},
    {NULL, NULL}
};

static void init_linenoise(void)
{
    running_in_a_tty = isatty(STDIN_FILENO);
#ifdef HAS_LINENOISE
    linenoiseHistorySetMaxLen(LUAX_HISTORY_LEN);
    linenoiseSetMultiLine(true);
    linenoiseSetEncodingFunctions(linenoiseUtf8PrevCharLen, linenoiseUtf8NextCharLen, linenoiseUtf8ReadCode);
#endif
}

LUAMOD_API int luaopen_linenoise (lua_State *L)
{
    init_linenoise();
    luaL_newlib(L, linenoiselib);
    return 1;
}
