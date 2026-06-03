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

#include "strbuf.h"

#include <stdarg.h>
#include <string.h>

void str_init(t_str *str, char *mem, size_t capacity)
{
    str->capacity = capacity;
    str->s = mem;
    str_reset(str);
}

void str_reset(t_str *str)
{
    str->len = 0;
    str->overflow = false;
    str->s[0] = '\0';
}

void str_add(t_str *str, const char *s, size_t len)
{
    const size_t new_len = str->len + len;
    if (new_len >= str->capacity) {
        str->overflow = true;
        return;
    }
    memcpy(&str->s[str->len], s, len);
    str->s[new_len] = '\0';
    str->len = new_len;
}

bool str_ok(t_str *str)
{
    return !str->overflow;
}
