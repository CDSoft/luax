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

/***************************************************************************@@@
# ps: Process management module

```lua
local ps = require "ps"
```
@@@*/

#include "ps.h"

#include "tools.h"

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <math.h>
#include <stdint.h>
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
#include "lualib.h"

/*@@@
```lua
ps.sleep(n)
```
sleeps for `n` seconds.
@@@*/

static int ps_sleep(lua_State *L)
{
    double t = luaL_checknumber(L, 1);
    usleep((useconds_t)(t * 1e6));
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
    clock_gettime(CLOCK_MONOTONIC_RAW, &ts);
    const uint64_t sec_in_nsec = (uint64_t)ts.tv_sec * 1000000000;
    const uint64_t nsec = (uint64_t)ts.tv_nsec;
    const lua_Number t = (double)(sec_in_nsec + nsec) / 1e9;
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
ps.profile(func)
```
executes `func` and returns its execution time in seconds.
@@@*/

static int ps_profile(lua_State *L)
{
    if (lua_gettop(L) == 1 && lua_isfunction(L, 1))
    {
        const lua_Number t0 = gettime();
        const int status = lua_pcall(L, 0, 0, 0);
        const lua_Number t1 = gettime();
        if (status == LUA_OK)
        {
            lua_pushnumber(L, t1 - t0);
            return 1;
        }
        else
        {
            return bl_pusherror(L, "ps.profile argument shall be callable (?)");
        }
    }
    else
    {
        return bl_pusherror(L, "ps.profile argument shall be callable");
    }
}

static const luaL_Reg pslib[] =
{
    {"sleep",       ps_sleep},
    {"time",        ps_time},
    {"profile",     ps_profile},
    {NULL, NULL}
};

LUAMOD_API int luaopen_ps (lua_State *L)
{
    luaL_newlib(L, pslib);
    return 1;
}
