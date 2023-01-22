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

#include "runtime.h"

#include <string.h>
#include <unistd.h>
#include <libgen.h>

#ifdef _WIN32
#include <windows.h>
#endif

#include "tools.h"

static void get_exe(const char *arg0, char *name, size_t name_size)
{
#ifdef _WIN32
    const DWORD n = GetModuleFileName(NULL, name, name_size);
    if (n == 0) error(arg0, "Can not be found");
#else
    const ssize_t n = readlink("/proc/self/exe", name, name_size);
    if (n < 0) perror(arg0);
#endif
    name[n] = '\0';
}

int main(int argc, const char *argv[])
{
    char exe[1024];
    get_exe(argv[0], exe, sizeof(exe));

    lua_State *L = luax_newstate(argc, argv);

#if RUNTIME == 1

    return luax_run(L, exe, argv);

#else

    /* Lua script execution (bootstrap interpreter with no LuaX runtime and payload) */

    if (argc == 3 && strcmp(argv[1], "-e") == 0)
    {
        if (luaL_dostring(L, argv[2]) != LUA_OK)
        {
            error(argv[0], lua_tostring(L, -1));
        }
    }
    else if (argc > 1)
    {
        luaL_dostring(L, "arg[0] = arg[1]; table.remove(arg, 1)");
        if (luaL_dofile(L, argv[1]) != LUA_OK)
        {
            error(argv[0], lua_tostring(L, -1));
        }
    }
    else
    {
        const char *name = basename(exe);
        fprintf(stderr, "usage:\n"
                        "\t%s -e 'Lua expression'\n"
                        "\t%s script.lua\n",
                        name, name);
        exit(EXIT_FAILURE);
    }

    return EXIT_SUCCESS;

#endif

}
