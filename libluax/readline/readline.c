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

#include "linenoise/linenoise.h"
#include "tools.h"

#include <ctype.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#ifndef _WIN32
#include <dlfcn.h>
#endif

#include "lua.h"
#include "lauxlib.h"

#define LUAX_HISTORY_LEN    1000
#define LUAX_MAXINPUT       4096
#define LUAX_APPNAME_LEN    64
#define MAX_HISTORY_SEARCH  1000

static bool running_in_a_tty;
static bool dirty_history = false;
static bool has_readline = false;
static bool has_name = false;
static bool has_history = false;
static bool has_history_set_len = false;
static bool has_history_clean = false;

/* readline functions */

typedef struct {
    char *line;
    char *timestamp;
    void *data;
} HIST_ENTRY;

typedef const char *  *t_readline_name;
typedef int           *t_history_base;
typedef int           *t_history_length;
typedef char *       (*t_readline)          (const char *);
typedef void         (*t_add_history)       (const char *);
typedef int          (*t_read_history)      (const char *);
typedef int          (*t_write_history)     (const char *);
typedef void         (*t_stifle_history)    (int);
typedef HIST_ENTRY * (*t_history_get)       (int);
typedef HIST_ENTRY * (*t_remove_history)    (int);
typedef void *       (*t_free_history_entry)(HIST_ENTRY *);

static t_readline_name      rl_readline_name      = NULL;
static t_history_base       rl_history_base       = NULL;
static t_history_length     rl_history_length     = NULL;
static t_readline           rl_readline           = NULL;
static t_add_history        rl_add_history        = NULL;
static t_read_history       rl_read_history       = NULL;
static t_write_history      rl_write_history      = NULL;
static t_stifle_history     rl_stifle_history     = NULL;
static t_history_get        rl_history_get        = NULL;
static t_remove_history     rl_remove_history     = NULL;
static t_free_history_entry rl_free_history_entry = NULL;

static void load_readline(void)
{
    running_in_a_tty = isatty(STDIN_FILENO);
    if (!running_in_a_tty) { return; }

#ifndef _WIN32

    void *handle = dlopen("libreadline.so", RTLD_NOW | RTLD_LOCAL);
    if (handle == NULL) { return ; }

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wpedantic"

    rl_readline           = (t_readline)          dlsym(handle, "readline");

    has_readline = rl_readline!=NULL;
    if (!has_readline) {
        dlclose(handle);
        return;
    }

    rl_readline_name      = (t_readline_name)     dlsym(handle, "rl_readline_name");

    has_name = rl_readline_name!=NULL;

    rl_add_history        = (t_add_history)       dlsym(handle, "add_history");
    rl_read_history       = (t_read_history)      dlsym(handle, "read_history");
    rl_write_history      = (t_write_history)     dlsym(handle, "write_history");

    has_history = rl_add_history!=NULL && rl_read_history!=NULL && rl_write_history!=NULL;

    rl_stifle_history     = (t_stifle_history)    dlsym(handle, "stifle_history");

    has_history_set_len = has_history && rl_stifle_history!=NULL;

    rl_history_base       = (t_history_base)      dlsym(handle, "history_base");
    rl_history_length     = (t_history_length)    dlsym(handle, "history_length");
    rl_history_get        = (t_history_get)       dlsym(handle, "history_get");
    rl_remove_history     = (t_remove_history)    dlsym(handle, "remove_history");
    rl_free_history_entry = (t_free_history_entry)dlsym(handle, "free_history_entry");

    has_history_clean = has_history
                     && rl_history_base!=NULL && rl_history_length!=NULL
                     && rl_history_get!=NULL && rl_remove_history!=NULL && rl_free_history_entry!=NULL;

#pragma GCC diagnostic pop

    if (has_history_set_len) {
        rl_stifle_history(LUAX_HISTORY_LEN);
    }

#endif
}

/*@@@
``` lua
readline.name(appname)
```
sets a unique application name.
This name allows conditional parsing of the inputrc file.
@@@*/

static int readline_name(lua_State *L)
{
    if (has_name) {
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
    if (!has_readline) { return linenoise_read(L); }
    const char *prompt = luaL_checkstring(L, 1);
    char *line = rl_readline(prompt);
    lua_pushstring(L, line);
    free(line);
    return 1;
}

/*@@@
```lua
readline.add(line)
```
adds `line` to the current history.

The history is cleaned on the fly:

- empty lines are ignored
- duplicates are removed, only the last entry is kept
@@@*/

static int readline_history_add(lua_State *L)
{
    if (!has_readline) { return linenoise_history_add(L); }
    if (has_history && running_in_a_tty && lua_isstring(L, 1)) {
        const char *line = luaL_checkstring(L, 1);
        bool empty = true;
        for (const char *c = line; *c != '\0'; c++) {
            if (!isspace((unsigned char)*c)) { empty = false; }
        }
        if (empty) { goto done; }
        if (has_history_clean) {
            const int latest = *rl_history_length - 1;
            const int oldest = imax(0, latest - MAX_HISTORY_SEARCH);
            for (int i = latest; i > oldest; i--) {
                const HIST_ENTRY *entry = rl_history_get(*rl_history_base + i);
                if (entry != NULL && strcmp(entry->line, line) == 0) {
                    HIST_ENTRY *removed = rl_remove_history(i);
                    rl_free_history_entry(removed);
                }
            }
        }
        dirty_history = true;
        rl_add_history(luaL_checkstring(L, 1));
    }
done:
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
    if (!has_readline) { return linenoise_history_set_len(L); }
    if (has_history_set_len) {
        rl_stifle_history((int)luaL_checkinteger(L, 1));
    }
    return 0;
}

/*@@@
```lua
readline.save(filename)
```
saves the history to the file `filename`
(unless the history has not been modified).
@@@*/

static int readline_history_save(lua_State *L)
{
    if (!has_readline) { return linenoise_history_save(L); }
    if (has_history && running_in_a_tty && dirty_history) {
        rl_write_history(luaL_checkstring(L, 1));
        dirty_history = false;
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
    if (!has_readline) { return linenoise_history_load(L); }
    if (has_history && running_in_a_tty) {
        rl_read_history(luaL_checkstring(L, 1));
        dirty_history = false;
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
    load_readline();
    luaL_newlib(L, readlinelib);
    return 1;
}
