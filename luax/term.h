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
 * Software freedom is inseparable from freedom of thought. Fascism -
 * in all its forms - is incompatible with the values this project stands
 * on, even though the GPL itself cannot and does not restrict who may
 * use this software. See FREEDOM.md.
 *
 * You should have received a copy of the GNU General Public License
 * along with luax.  If not, see <https://www.gnu.org/licenses/>.
 *
 * For further information about luax you can visit
 * https://codeberg.org/cdsoft/luax
 */

#pragma once

#include "lua.h"

/* C module registration function */
LUAMOD_API int luaopen_term(lua_State *L);
