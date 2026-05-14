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

#if defined (_WIN32)
#include <windows.h>
#include <bcrypt.h>
#endif
#if defined(__linux__) || defined(__APPLE__)
#include <sys/random.h>
#endif

/* Entropy for PRNG initialization */

uint64_t entropy(void)
{
    uint64_t random;
#if defined(__linux__)
    getrandom(&random, sizeof(random), 0);
#endif
#if defined(__APPLE__)
    getentropy(&random, sizeof(random));
#endif
#if defined(_WIN32)
    BCryptGenRandom(NULL, (PUCHAR)&random, (ULONG)sizeof(random), BCRYPT_USE_SYSTEM_PREFERRED_RNG);
#endif

    return random;
}
