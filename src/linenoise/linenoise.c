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

#include "linenoise.h"

#include "tools.h"

#include <unistd.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#ifdef _WIN32
#else
#define HAS_LINENOISE
#include "linenoise/linenoise.h"
#endif

#define LUAX_HISTORY_LEN    10000

#ifdef HAS_LINENOISE
static int mask_mode = 0;
static bool running_in_a_tty = true;
#endif

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
    /* io.write(prompt) */
    lua_getglobal(L, "io");         /* push io */
    lua_getfield(L, -1, "write");   /* push io.write */
    lua_remove(L, -2);              /* remove io */
    lua_pushstring(L, prompt);      /* push prompt */
    lua_call(L, 1, 0);              /* call io.write(prompt) */
    /* io.flush() */
    lua_getglobal(L, "io");         /* push io */
    lua_getfield(L, -1, "flush");   /* push io.write */
    lua_remove(L, -2);              /* remove io */
    lua_call(L, 0, 0);              /* call io.write(prompt) */
    /* return io.read "*l" */
    lua_getglobal(L, "io");         /* push io */
    lua_getfield(L, -1, "read");    /* push io.read */
    lua_remove(L, -2);              /* remove io */
    lua_pushstring(L, "*l");        /* push "*l" */
    lua_call(L, 1, 1);              /* call io.read("*l") */
#endif
    return 1;
}

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

static int linenoise_prin_key_codes(lua_State *L __attribute__((unused)))
{
#ifdef HAS_LINENOISE
    linenoisePrintKeyCodes();
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
    {"key_codes",   linenoise_prin_key_codes},
    {NULL, NULL}
};

LUAMOD_API int luaopen_linenoise (lua_State *L)
{
    luaL_newlib(L, linenoiselib);
#ifdef HAS_LINENOISE
    running_in_a_tty = isatty(STDIN_FILENO);
    linenoiseHistorySetMaxLen(LUAX_HISTORY_LEN);
    linenoiseSetMultiLine(false);
#else
    (void)LUAX_HISTORY_LEN;
#endif
    return 1;
}
