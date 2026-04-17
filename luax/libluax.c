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

#include "libluax.h"

#include "lauxlib.h"

#include "complex.h"
#include "crypt.h"
#include "fs.h"
#include "imath.h"
#include "readline.h"
#include "linenoise.h"
#include "lpeg.h"
#include "lz4.h"
#include "lzip.h"
#include "mathx.h"
#include "ps.h"
#include "qmath.h"
#include "luasocket.h"
#include "sys.h"
#include "term.h"

static const luaL_Reg lrun_libs[] = {
    {"_complex",    luaopen_complex},
    {"_crypt",      luaopen_crypt},
    {"_fs",         luaopen_fs},
    {"_imath",      luaopen_imath},
    {"_readline",   luaopen_readline},
    {"_linenoise",  luaopen_linenoise},
    {"lpeg",        luaopen_lpeg},
    {"_lz4",        luaopen_lz4},
    {"_lzip",       luaopen_lzip},
    {"_mathx",      luaopen_mathx},
    {"_ps",         luaopen_ps},
    {"_qmath",      luaopen_qmath},
    {"socket",      luaopen_luasocket},
    {"_sys",        luaopen_sys},
    {"_term",       luaopen_term},
    {NULL, NULL},
};

LUAMOD_API int luaopen_libluax(lua_State *L)
{
    for (const luaL_Reg *lib = lrun_libs; lib->func != NULL; lib++) {
        luaL_requiref(L, lib->name, lib->func, 0);
        lua_pop(L, 1);
    }

    return 1;
}
