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

#define LUAX_MAXINPUT       4096
#define LUAX_APPNAME_LEN    64

static bool running_in_a_tty;

/* readline functions */

typedef const char ** t_readline_name;
typedef char *      (*t_readline_func)      (const char *);
typedef void        (*t_add_history_func)   (const char *);
typedef int         (*t_read_history_func)  (const char *);
typedef int         (*t_write_history_func) (const char *);
typedef void        (*t_stifle_history_func)(int);

static const char *         *rl_readline_name  = NULL;
static t_readline_func       rl_readline       = NULL;
static t_add_history_func    rl_add_history    = NULL;
static t_read_history_func   rl_read_history   = NULL;
static t_write_history_func  rl_write_history  = NULL;
static t_stifle_history_func rl_stifle_history = NULL;

#ifndef _WIN32
static void load_readline(void)
{
    void *handle = dlopen("libreadline.so", RTLD_NOW | RTLD_LOCAL);
    if (handle == NULL) { return ; }
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wpedantic"
    rl_readline_name  = (t_readline_name)      dlsym(handle, "rl_readline_name");
    rl_readline       = (t_readline_func)      dlsym(handle, "readline");
    rl_add_history    = (t_add_history_func)   dlsym(handle, "add_history");
    rl_read_history   = (t_read_history_func)  dlsym(handle, "read_history");
    rl_write_history  = (t_write_history_func) dlsym(handle, "write_history");
    rl_stifle_history = (t_stifle_history_func)dlsym(handle, "stifle_history");
#pragma GCC diagnostic pop
}
#endif

/*@@@
``` lua
readline.name(appname)
```
sets a unique application name.
This name allows conditional parsing of the inputrc file.
@@@*/

static int readline_name(lua_State *L)
{
    if (rl_readline_name != NULL) {
        static char rl_appname[LUAX_APPNAME_LEN];
        strncpy(rl_appname, luaL_checkstring(L, 1), sizeof(rl_appname)-1);
        *rl_readline_name = rl_appname;
    }
    return 0;
}

/*@@@
```lua
readline.read(prompt)
```
prints `prompt` and returns the string entered by the user.
@@@*/

static int readline_read(lua_State *L)
{
    const char *prompt = luaL_checkstring(L, 1);
    if (rl_readline != NULL) {
        char *line = rl_readline(prompt);
        lua_pushstring(L, line);
        free(line);
    } else {
        static char line[LUAX_MAXINPUT];
        if (running_in_a_tty) {
            fputs(prompt, stdout);
            fflush(stdout);
        }
        if (fgets(line, sizeof(line), stdin) != NULL) {
            lua_pushlstring(L, line, strcspn(line, "\n"));
        } else {
            lua_pushnil(L);
        }
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
    if (rl_add_history != NULL && lua_isstring(L, 1)) {
        rl_add_history(luaL_checkstring(L, 1));
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
    if (rl_stifle_history != NULL) {
        rl_stifle_history((int)luaL_checkinteger(L, 1));
    }
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
    if (rl_write_history != NULL) {
        rl_write_history(luaL_checkstring(L, 1));
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
    if (rl_read_history != NULL) {
        rl_read_history(luaL_checkstring(L, 1));
    }
    return 0;
}

static const luaL_Reg readlinelib[] =
{
    {"name",        readline_name},
    {"read",        readline_read},
    {"add",         readline_history_add},
    {"set_len",     readline_history_set_len},
    {"save",        readline_history_save},
    {"load",        readline_history_load},
    {NULL, NULL}
};

LUAMOD_API int luaopen_readline(lua_State *L)
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
