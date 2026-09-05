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

/* Just a dummy program to check 64-bit Linux can run a 32-bit binary.
 * Used to enable 32-bit tests on 64-bit Linux OS.
 */

#include <stdint.h>

#if UINTPTR_MAX != UINT32_MAX
#error "This program must be compiled for a 32-bit target"
#endif

int main(void) { }
