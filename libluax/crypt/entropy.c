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

#include <sys/time.h>
#include <time.h>
#include <unistd.h>

/* Entropy sources for PRNG initialization */

uint64_t entropy(void *ptr)
{
    static uint64_t hash = 0xcbf29ce484222325;
    static const uint64_t prime = 0x100000001b3;

    struct timespec ts;

    register uint64_t h = hash;
    h = (h ^ (uintptr_t)ptr) * prime;         /* Address of a characteristic variable */
    h = (h ^ (uintptr_t)&ts) * prime;         /* Address of a local variable */

    clock_gettime(CLOCK_REALTIME, &ts);
    h = (h ^ (uint64_t)ts.tv_sec) * prime;    /* Time in seconds */
    h = (h ^ (uint64_t)ts.tv_nsec) * prime;   /* ... and nanoseconds */

    h = (h ^ (uint64_t)getpid()) * prime;     /* Process ID */
    hash = h;

    return h;
}
