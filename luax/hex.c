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

#include "hex.h"

static const char hex_digits[] = "0123456789abcdef";

static const char hex_values[256] =
{
    ['0'] = 0,      ['A'] = 10,     ['a'] = 10,
    ['1'] = 1,      ['B'] = 11,     ['b'] = 11,
    ['2'] = 2,      ['C'] = 12,     ['c'] = 12,
    ['3'] = 3,      ['D'] = 13,     ['d'] = 13,
    ['4'] = 4,      ['E'] = 14,     ['e'] = 14,
    ['5'] = 5,      ['F'] = 15,     ['f'] = 15,
    ['6'] = 6,
    ['7'] = 7,
    ['8'] = 8,
    ['9'] = 9,
};

void raw_to_hex(const char *raw, size_t size, char *hex)
{
    for (size_t i = 0; i < size; i++) {
        const char c = raw[i];
        hex[2*i+0] = hex_digits[(c>>4)&0xF];
        hex[2*i+1] = hex_digits[(c>>0)&0xF];
    }
}

void hex_to_raw(const char *hex, size_t size, char *raw)
{
    for (size_t i = 0; i < size-1; i += 2) {
        const unsigned char d1 = hex[i+0] & 0xFF;
        const unsigned char d2 = hex[i+1] & 0xFF;
        raw[i/2] = (char)((hex_values[d1]<<4) | (hex_values[d2]<<0));
    }
}
