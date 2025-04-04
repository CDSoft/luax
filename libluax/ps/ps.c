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
# ps: Process management module

```lua
local ps = require "ps"
```
@@@*/

#include "ps.h"

#include "tools.h"

#include <dirent.h>
#include <fcntl.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>
#include <utime.h>

#ifdef _WIN32
#include <windows.h>
#endif

#include "lua.h"
#include "lauxlib.h"

/*@@@
```lua
ps.sleep(n)
```
sleeps for `n` seconds.
@@@*/

static int ps_sleep(lua_State *L)
{
    const double t = luaL_checknumber(L, 1);
#ifdef __WIN32
    usleep((useconds_t)(t * 1e6));
#else
    double sec;
    double nsec = modf(t, &sec);
    const struct timespec ts = {
        .tv_sec = (typeof(ts.tv_sec))sec,
        .tv_nsec = (typeof(ts.tv_nsec))(nsec*1e9),
    };
    nanosleep(&ts, NULL);
#endif
    return 0;
}

/*@@@
```lua
ps.time()
```
returns the current time in seconds (the resolution is OS dependant).
@@@*/

static inline lua_Number gettime(void)
{
#ifdef _WIN32
    __int64 wintime;
    GetSystemTimeAsFileTime((FILETIME*)&wintime);
    wintime -= 116444736000000000ULL;  /* 1jan1601 to 1jan1970 */
    const lua_Number t = (double)wintime / 1e7;
#else
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    const lua_Number t = (double)ts.tv_sec + (double)(ts.tv_nsec) / 1e9;
#endif
    return t;
}

static int ps_time(lua_State *L)
{
    lua_pushnumber(L, gettime());
    return 1;
}

/*@@@
```lua
ps.clock()
```
returns an approximation of the amount in seconds of CPU time used by the program,
as returned by the underlying ISO C function `clock`.
@@@*/

static inline lua_Number getclock(void)
{
    const clock_t t = clock();
    return (lua_Number)t/(lua_Number)CLOCKS_PER_SEC;
}

static int ps_clock(lua_State *L)
{
    lua_pushnumber(L, getclock());
    return 1;
}

/*@@@
```lua
ps.profile(func)
```
executes `func` and returns its execution time in seconds (using `ps.clock`).
@@@*/

static int ps_profile(lua_State *L)
{
    if (lua_gettop(L) == 1 && lua_isfunction(L, 1))
    {
        const lua_Number t0 = getclock();
        const int status = lua_pcall(L, 0, 0, 0);
        const lua_Number t1 = getclock();
        if (status == LUA_OK)
        {
            lua_pushnumber(L, t1 - t0);
            return 1;
        }
        else
        {
            return luax_pusherror(L, "ps.profile argument failed");
        }
    }
    else
    {
        return luax_pusherror(L, "ps.profile argument shall be callable");
    }
}

static const luaL_Reg pslib[] =
{
    {"sleep",       ps_sleep},
    {"time",        ps_time},
    {"clock",       ps_clock},
    {"profile",     ps_profile},
    {NULL, NULL}
};

LUAMOD_API int luaopen_ps (lua_State *L)
{
    luaL_newlib(L, pslib);
    return 1;
}
