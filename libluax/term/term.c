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
 * http://cdelord.fr/luax
 */


#include "tools.h"

#include <stdio.h>

#ifdef _WIN32
#include <io.h>
#include <windows.h>
#else
#include <sys/ioctl.h>
#include <termios.h>
#include <unistd.h>
#endif

#include "lua.h"
#include "lauxlib.h"

#include "term.h"

/*@@@
```lua
term.isatty([fileno])
```
returns `true` if `fileno` is a tty.
@@@*/

static int term_isatty(lua_State *L)
{
    int n;
    switch (lua_type(L, 1))
    {
        case LUA_TNIL:
        case LUA_TNONE:     n = 0; break;
        case LUA_TNUMBER:   n = (int)luaL_checkinteger(L, 1); break;
        case LUA_TUSERDATA: n = fileno(*(FILE**)luaL_checkudata(L, 1, LUA_FILEHANDLE)); break;
        default: return luax_pusherror(L, "invalud argument to isatty");
    }
#ifdef _WIN32
    lua_pushboolean(L, _isatty(n));
#else
    lua_pushboolean(L, isatty(n));
#endif
    return 1;
}

/*@@@
```lua
term.size()
```
returns a table with the number of rows (field `rows`) and lines (field `lines`).
@@@*/

static inline void set_integer(lua_State *L, const char *name, lua_Integer val)
{
    lua_pushinteger(L, val);
    lua_setfield(L, -2, name);
}

static int term_size(lua_State *L)
{
    int cols;
    int rows;
#ifdef _WIN32
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE), &csbi);
    cols = csbi.srWindow.Right - csbi.srWindow.Left + 1;
    rows = csbi.srWindow.Bottom - csbi.srWindow.Top + 1;
#else
    struct winsize win;
    ioctl(STDOUT_FILENO, TIOCGWINSZ, &win);
    cols = win.ws_col;
    rows = win.ws_row;
#endif
    lua_newtable(L);
    set_integer(L, "rows", rows);
    set_integer(L, "cols", cols);
    return 1;
}

static const luaL_Reg termlib[] =
{
    {"isatty",              term_isatty},
    {"size",                term_size},
    {NULL, NULL}
};

LUAMOD_API int luaopen_term (lua_State *L)
{
    luaL_newlib(L, termlib);
    return 1;
}
