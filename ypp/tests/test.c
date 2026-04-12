/*
This file is part of ypp.

ypp is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

ypp is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with ypp.  If not, see <https://www.gnu.org/licenses/>.

For further information about ypp you can visit
https://codeberg.org/cdsoft/luax
*/

/*@@@
**`answer`** takes any question
and returns the most relevant answer.

Example:
``` c
    const char *meaning
        = answer("What's the meaning of life?");
```

The code is:
``` c
@include.raw "test.c" {pattern="//".."===%s*(.-)%s*$"}
```
@@@*/

//===
const char *answer(const char *question)
{
    return "42";
}

