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

#pragma once

#include <stdbool.h>
#include <stdlib.h>

typedef struct {
    char *s;
    size_t capacity;
    size_t len;
    bool overflow;
} t_str;

void str_init(t_str *str, char *mem, size_t capacity);
void str_reset(t_str *str);
void str_add(t_str *str, const char *s, size_t len);
bool str_ok(t_str *str);
