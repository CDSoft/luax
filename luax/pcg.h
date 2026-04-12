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

#include <stddef.h>
#include <stdint.h>

/* https://www.pcg-random.org */

typedef struct {
    uint64_t state;
    uint64_t increment;
} t_pcg;

#define PCG_RAND_MAX ((uint64_t)(uint32_t)(-1))

/* Low level random functions */

uint32_t pcg_int(t_pcg *prng);
int64_t pcg_int_range(t_pcg *prng, int64_t a, int64_t b);
double pcg_float(t_pcg *prng);
double pcg_float_range(t_pcg *prng, double a, double b);
void pcg_str(t_pcg *prng, size_t size, char *buf);
void pcg_seed(t_pcg *prng, uint64_t state, uint64_t increment);
void pcg_clone(t_pcg *src, t_pcg *dst);
