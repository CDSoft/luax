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
# readline: read lines from a user with editing

[The GNU Readline library](https://tiswww.case.edu/php/chet/readline/rltop.html)
provides a set of functions for use by applications that allow users to edit command lines as they are typed in.

**Warning**: the LuaX readline module tries to dynamically load libreadline.
If it fails, it uses basic functions with no editing and history capabilities.
@@@*/

#include "readline.h"

#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#ifndef _WIN32
#include <dlfcn.h>
#endif

#include "lua.h"
#include "lauxlib.h"

#define LUAX_HISTORY_LEN    10000
#define LUAX_MAXINPUT       4096

static bool running_in_a_tty;

/* readline functions */

typedef char * (*t_readline_func)(const char *);
typedef void (*t_add_history_func)(const char *);
typedef int (*t_read_history_func)(const char *);
typedef int (*t_write_history_func)(const char *);
typedef void (*t_stifle_history_func)(int);

static char *noreadline(const char *prompt)
{
    static char line[LUAX_MAXINPUT];
    if (running_in_a_tty) {
        fputs(prompt, stdout);
        fflush(stdout);
    }
    if (fgets(line, LUAX_MAXINPUT, stdin) == NULL) { return NULL; }
    line[strcspn(line, "\n")] = '\0';
    return strdup(line);
}

static void noreadline_add_history(const char *line)
{
    (void)line;
}

static int noreadline_read_history(const char *filename)
{
    (void)filename;
    return 0;
}

static int noreadline_write_history(const char *filename)
{
    (void)filename;
    return 0;
}

static void noreadline_stifle_history(int size)
{
    (void)size;
}

static t_readline_func       readline       = noreadline;
static t_add_history_func    add_history    = noreadline_add_history;
static t_read_history_func   read_history   = noreadline_read_history;
static t_write_history_func  write_history  = noreadline_write_history;
static t_stifle_history_func stifle_history = noreadline_stifle_history;

#ifndef _WIN32
static void load_readline(void)
{
    void *handle = dlopen("libreadline.so", RTLD_LAZY);
    if (handle != NULL) {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wpedantic"
        readline       = (t_readline_func)      dlsym(handle, "readline");
        add_history    = (t_add_history_func)   dlsym(handle, "add_history");
        read_history   = (t_read_history_func)  dlsym(handle, "read_history");
        write_history  = (t_write_history_func) dlsym(handle, "write_history");
        stifle_history = (t_stifle_history_func)dlsym(handle, "stifle_history");
#pragma GCC diagnostic pop
    }
    if (readline       == NULL) { readline       = noreadline; }
    if (add_history    == NULL) { add_history    = noreadline_add_history; }
    if (read_history   == NULL) { read_history   = noreadline_read_history; }
    if (write_history  == NULL) { write_history  = noreadline_write_history; }
    if (stifle_history == NULL) { stifle_history = noreadline_stifle_history; }
}
#endif

/*@@@
```lua
readline.read(prompt)
```
prints `prompt` and returns the string entered by the user.
@@@*/

static int readline_read(lua_State *L)
{
    const char *prompt = luaL_checkstring(L, 1);
    char *line = readline(prompt);
    if (line == NULL) {
        lua_pushnil(L);
    } else {
        lua_pushstring(L, line);
        free(line);
    }
    return 1;
}

/*@@@
```lua
readline.add(line)
```
adds `line` to the current history.
@@@*/

static int readline_history_add(lua_State *L)
{
    if (running_in_a_tty) {
        if (lua_isstring(L, 1)) {
            const char *line = luaL_checkstring(L, 1);
            add_history(line);
        }
    }
    return 0;
}

/*@@@
```lua
readline.set_len(len)
```
sets the maximal history length to `len`.
@@@*/

static int readline_history_set_len(lua_State *L)
{
    stifle_history((int)luaL_checkinteger(L, 1));
    return 0;
}

/*@@@
```lua
readline.save(filename)
```
saves the history to the file `filename`.
@@@*/

static int readline_history_save(lua_State *L)
{
    if (running_in_a_tty) {
        write_history(luaL_checkstring(L, 1));
    }
    return 0;
}

/*@@@
```lua
readline.load(filename)
```
loads the history from the file `filename`.
@@@*/

static int readline_history_load(lua_State *L)
{
    if (running_in_a_tty) {
        read_history(luaL_checkstring(L, 1));
    }
    return 0;
}

static const luaL_Reg readlinelib[] =
{
    {"read",        readline_read},
    {"add",         readline_history_add},
    {"set_len",     readline_history_set_len},
    {"save",        readline_history_save},
    {"load",        readline_history_load},
    {NULL, NULL}
};

LUAMOD_API int luaopen_readline (lua_State *L)
{
    running_in_a_tty = isatty(STDIN_FILENO);
#ifndef _WIN32
    if (running_in_a_tty) {
        load_readline();
    }
#endif
    luaL_newlib(L, readlinelib);
    return 1;
}
