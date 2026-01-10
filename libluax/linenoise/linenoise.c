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
 * https://codeberg.org/cdsoft/luax
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
/* No linenoise on Windows */
#else
#define HAS_LINENOISE
#include "ext/c/linenoise/linenoise.h"
#endif

#ifdef HAS_LINENOISE
#define LUAX_HISTORY_LEN    1000
#else
#define LUAX_MAXINPUT       4096
#endif

static bool running_in_a_tty;

#ifdef HAS_LINENOISE
static bool dirty_history = false;
#endif

static bool initialized = false;

static void init_linenoise(void)
{
    if (initialized) { return; }
    initialized = true;

    running_in_a_tty = isatty(STDIN_FILENO);
#ifdef HAS_LINENOISE
    linenoiseHistorySetMaxLen(LUAX_HISTORY_LEN);
    linenoiseSetMultiLine(true);
#endif
}

/*@@@
```lua
linenoise.read(prompt)
```
prints `prompt` and returns the string entered by the user.
@@@*/

int linenoise_read(lua_State *L)
{
    init_linenoise();
    const char *prompt = luaL_checkstring(L, 1);
#ifdef HAS_LINENOISE
    char *line = linenoise(prompt);
    lua_pushstring(L, line);
    linenoiseFree(line);
#else
    char line[LUAX_MAXINPUT];
    if (running_in_a_tty) {
        fputs(prompt, stdout);
        fflush(stdout);
    }
    if (fgets(line, sizeof(line), stdin) != NULL) {
        lua_pushlstring(L, line, strcspn(line, "\n"));
    } else {
        lua_pushnil(L);
    }
#endif
    return 1;
}

/*@@@
```lua
linenoise.add(line)
```
adds `line` to the current history.
@@@*/

int linenoise_history_add(lua_State *L)
{
#ifdef HAS_LINENOISE
    init_linenoise();
    if (running_in_a_tty && lua_isstring(L, 1)) {
        const char *line = luaL_checkstring(L, 1);
        linenoiseHistoryAdd(line);
        dirty_history = true;
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

int linenoise_history_set_len(lua_State *L)
{
#ifdef HAS_LINENOISE
    init_linenoise();
    linenoiseHistorySetMaxLen((int)luaL_checkinteger(L, 1));
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

int linenoise_history_save(lua_State *L)
{
#ifdef HAS_LINENOISE
    init_linenoise();
    if (running_in_a_tty && dirty_history) {
        linenoiseHistorySave(luaL_checkstring(L, 1));
        dirty_history = false;
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

int linenoise_history_load(lua_State *L)
{
#ifdef HAS_LINENOISE
    init_linenoise();
    if (running_in_a_tty) {
        linenoiseHistoryLoad(luaL_checkstring(L, 1));
        dirty_history = false;
    }
#else
    (void)L;
#endif
    return 0;
}

static const luaL_Reg linenoiselib[] =
{
    {"read",        linenoise_read},
    {"add",         linenoise_history_add},
    {"set_len",     linenoise_history_set_len},
    {"save",        linenoise_history_save},
    {"load",        linenoise_history_load},
    {NULL, NULL}
};

LUAMOD_API int luaopen_linenoise (lua_State *L)
{
    luaL_newlib(L, linenoiselib);
    return 1;
}
