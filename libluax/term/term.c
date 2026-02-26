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

#include "tools.h"

#include <stdio.h>

#ifdef _WIN32
#include <io.h>
#include <windows.h>
#else
#include <sys/ioctl.h>
#include <unistd.h>
#endif

#include "lua.h"
#include "lauxlib.h"

#include "term.h"

/***************************************************************************@@@
## Terminal characterization

@@@*/

static bool get_file_descriptor(lua_State *L, int default_fd, int *fd)
{
    switch (lua_type(L, 1))
    {
        case LUA_TNIL:
        case LUA_TNONE:     *fd = default_fd; break;
        case LUA_TNUMBER:   *fd = (int)luaL_checkinteger(L, 1); break;
        case LUA_TUSERDATA: *fd = fileno(*(FILE**)luaL_checkudata(L, 1, LUA_FILEHANDLE)); break;
        default: return false;
    }
    return true;
}

#ifdef _WIN32
static bool get_file_handle(lua_State *L, int default_fd, DWORD *fh)
{
    int fd;
    if (!get_file_descriptor(L, default_fd, &fd)) {
        return false;
    }
    switch (fd) {
        case STDIN_FILENO:  *fh = STD_INPUT_HANDLE; break;
        case STDOUT_FILENO: *fh = STD_OUTPUT_HANDLE; break;
        case STDERR_FILENO: *fh = STD_ERROR_HANDLE; break;
        default: return false;
    }
    return true;
}
#endif

/*@@@
```lua
term.isatty([fileno])
```
returns `true` if `fileno` is a tty.
The default file descriptor is `stdin` (`0`).
@@@*/

static int term_isatty(lua_State *L)
{
    int fd;
    if (!get_file_descriptor(L, STDIN_FILENO, &fd)) {
        return luax_pusherror(L, "isatty: bad file descriptor");
    }
    lua_pushboolean(L, isatty(fd));
    return 1;
}

/*@@@
```lua
term.size([fileno])
```
returns a table with the number of rows (field `rows`) and columns (field `cols`) of the terminal attached to `fileno`.
The default file descriptor is `stdout` (`1`).
@@@*/

static inline void set_integer(lua_State *L, const char *name, lua_Integer val)
{
    lua_pushinteger(L, val);
    lua_setfield(L, -2, name);
}

static int term_size(lua_State *L)
{
#ifdef _WIN32
    DWORD fh;
    if (!get_file_handle(L, STDOUT_FILENO, &fh)) {
        return luax_pusherror(L, "size: bad file descriptor");
    }
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    if (!GetConsoleScreenBufferInfo(GetStdHandle(fh), &csbi)) {
        return luax_pusherror(L, "size: bad file descriptor");
    }
    const int cols = csbi.srWindow.Right - csbi.srWindow.Left + 1;
    const int rows = csbi.srWindow.Bottom - csbi.srWindow.Top + 1;
#else
    int fd;
    if (!get_file_descriptor(L, STDOUT_FILENO, &fd)) {
        return luax_pusherror(L, "size: bad file descriptor");
    }
    struct winsize win;
    if (ioctl(fd, TIOCGWINSZ, &win) == -1) {
        return luax_pusherror(L, "size: bad file descriptor");
    }
    const int cols = win.ws_col;
    const int rows = win.ws_row;
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
