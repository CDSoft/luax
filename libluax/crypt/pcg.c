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

#include "pcg.h"

/* https://www.pcg-random.org */

/* Low level random functions */

static const uint64_t default_pcg_state = 0x4d595df4d0f33173;
static const uint64_t pcg_multiplier = 6364136223846793005ULL;
static const uint64_t default_pcg_increment = 1442695040888963407ULL;

static inline void pcg_advance(t_pcg *prng)
{
    // Advance internal state
    prng->state = prng->state*pcg_multiplier + prng->increment;
}

static inline uint32_t xsh_rr(uint64_t state)
{
    // Calculate output function (XSH RR)
    const uint32_t xorshifted = (uint32_t)(((state >> 18u) ^ state) >> 27u);
    const uint32_t rot = state >> 59u;
    return (xorshifted >> rot) | (xorshifted << ((-rot) & 31));
}

uint32_t pcg_int(t_pcg *prng)
{
    const uint64_t oldstate = prng->state;
    // Advance internal state
    pcg_advance(prng);
    // Calculate output function (XSH RR), uses old state for max ILP
    return xsh_rr(oldstate);
}

int64_t pcg_int_range(t_pcg *prng, int64_t a, int64_t b)
{
    const uint64_t n = pcg_int(prng);
    return (int64_t)(n % ((uint64_t)(b-a)+1)) + a;
}

double pcg_float(t_pcg *prng)
{
    const uint32_t x = pcg_int(prng);
    return (double)x / (PCG_RAND_MAX+1);
}

double pcg_float_range(t_pcg *prng, double a, double b)
{
    const double x = pcg_float(prng);
    return x*(b-a) + a;
}

void pcg_str(t_pcg *prng, size_t size, char *buf)
{
    for (size_t i = 0; i < size; i+=4) {
        const uint32_t r = pcg_int(prng);
        buf[i+0] = (char)(r>>(0*8));
        buf[i+1] = (char)(r>>(1*8));
        buf[i+2] = (char)(r>>(2*8));
        buf[i+3] = (char)(r>>(3*8));
    }
}

static inline uint64_t optional(uint64_t value, uint64_t def)
{
    return value == (uint64_t)(-1) ? def : value;
}

void pcg_seed(t_pcg *prng, uint64_t state, uint64_t increment)
{
    prng->state = optional(state, default_pcg_state);
    prng->increment = optional(increment, default_pcg_increment) | 1;
    /* drop the first values */
    pcg_advance(prng);
    pcg_advance(prng);
}

void pcg_clone(t_pcg *src, t_pcg *dst)
{
    dst->state = src->state;
    dst->increment = src->increment;
}
