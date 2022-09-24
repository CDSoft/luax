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
 * http://cdelord.fr/luax
 */

#pragma once

#include "lua.h"

#include <stdint.h>
#include <stdlib.h>

/* C module registration function */
LUAMOD_API int luaopen_crypt(lua_State *L);

/* RC4 algorithm exported to be used by run.c to decrypt the payload */
const char *rc4_runtime(const char *input, size_t input_len, char **output, size_t *output_len);

/* AES algorithm exported to be used by run.c to decrypt the payload */
const char *aes_encrypt_runtime(const uint8_t *plaintext, const size_t plaintext_len, uint8_t **encrypted, size_t *encrypted_len);
const char *aes_decrypt_runtime(const uint8_t *encrypted, const size_t encrypted_len, uint8_t **decrypted_buffer, uint8_t **decrypted, size_t *decrypted_len);
