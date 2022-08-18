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

static int ps_sleep(lua_State *L)
{
    double t = luaL_checknumber(L, 1);
    usleep((useconds_t)(t * 1e6));
    return 0;
}

static int ps_time(lua_State *L)
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
    lua_pushnumber(L, t);
    return 1;
}

static const luaL_Reg pslib[] =
{
    {"sleep",       ps_sleep},
    {"time",        ps_time},
    {NULL, NULL}
};

LUAMOD_API int luaopen_ps (lua_State *L)
{
    luaL_newlib(L, pslib);
    return 1;
}
