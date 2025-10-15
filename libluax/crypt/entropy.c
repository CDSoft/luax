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

#include "entropy.h"

#include "fnv1a_64.h"

#include <time.h>
#include <sys/time.h>
#include <unistd.h>

/* Entropy sources for PRNG initialization */
uint64_t entropy(void *ptr)
{
    static t_fnv1a_64 hash = 0xcbf29ce484222325;    /* Start with the previous value */
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    const uint32_t random[] = {
        (uint32_t)ts.tv_sec,        /* Time in seconds */
        (uint32_t)ts.tv_nsec,       /* and nanoseconds */
        (uint32_t)getpid(),         /* Process ID */
        (uint32_t)(uintptr_t)ptr,   /* Address of a characteristic variable */
        (uint32_t)(uintptr_t)&ts,   /* Address of a local variable */
    };
    fnv1a_64_update(&hash, &random, sizeof(random));
    return hash;
}
