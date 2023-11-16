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

#include "lua.h"

#include <complex.h>

#ifdef __clang__
#pragma clang diagnostic ignored "-Wreserved-identifier"
#endif

/* Missing complex functions in the current Zig version ??? */

// Returns: the product of a + ib and c + id

extern double _Complex __muldc3(double a, double b, double c, double d);

double _Complex __muldc3(double a, double b, double c, double d)
{
    double _Complex z;
    __real__(z) = a*c - b*d;
    __imag__(z) = a*d + b*c;
    return z;
}

// Returns: the quotient of (a + ib) / (c + id)

extern double _Complex __divdc3(double a, double b, double c, double d);

double _Complex __divdc3(double a, double b, double c, double d)
{
    double _Complex z;
    const double cc_dd = c*c + d*d;
    __real__(z) = (a*c + b*d) / cc_dd;
    __imag__(z) = (b*c - a*d) / cc_dd;
    return z;
}

/* C module registration function */
LUAMOD_API int luaopen_complex(lua_State *L);
