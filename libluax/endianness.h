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

#if defined(__linux__)

#include <endian.h>

#else

#include <stdint.h>

static uint32_t le32toh(uint32_t little_endian_32bits)
{
    return (uint32_t) ( ((uint8_t*)&little_endian_32bits)[0] << (8*0)
                      | ((uint8_t*)&little_endian_32bits)[1] << (8*1)
                      | ((uint8_t*)&little_endian_32bits)[2] << (8*2)
                      | ((uint8_t*)&little_endian_32bits)[3] << (8*3)
                      );
}

#endif
