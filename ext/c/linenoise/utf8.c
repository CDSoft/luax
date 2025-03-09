/* encoding/utf8.c -- VERSION 1.0
 *
 * Guerrilla line editing library against the idea that a line editing lib
 * needs to be 20,000 lines of C code.
 *
 * You can find the latest source code at:
 *
 *   http://github.com/antirez/linenoise
 *
 * Does a number of crazy assumptions that happen to be true in 99.9999% of
 * the 2010 UNIX computers around.
 *
 * ------------------------------------------------------------------------
 *
 * Copyright (c) 2010-2014, Salvatore Sanfilippo <antirez at gmail dot com>
 * Copyright (c) 2010-2013, Pieter Noordhuis <pcnoordhuis at gmail dot com>
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *  *  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *
 *  *  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "utf8.h"

#include <unistd.h>
#include <stdio.h>

#define UNUSED(x) (void)(x)

/* ============================ UTF8 utilities ============================== */

static unsigned long wideCharTable[][2] = {
#include "wide_char_table.inc"
};

static size_t wideCharTableSize = sizeof(wideCharTable) / sizeof(wideCharTable[0]);

static unsigned long combiningCharTable[] = {
#include "combining_char_table.inc"
};

static unsigned long combiningCharTableSize = sizeof(combiningCharTable) / sizeof(combiningCharTable[0]);

/* Check if the code is a wide character
 */
static int isWideChar(unsigned long cp) {
    size_t i;
    for (i = 0; i < wideCharTableSize; i++)
        if (wideCharTable[i][0] <= cp && cp <= wideCharTable[i][1]) return 1;
    return 0;
}

/* Check if the code is a combining character
 */
static int isCombiningChar(unsigned long cp) {
    size_t i;
    for (i = 0; i < combiningCharTableSize; i++)
        if (combiningCharTable[i] == cp) return 1;
    return 0;
}

/* Get length of previous UTF8 character
 */
static size_t prevUtf8CharLen(const char* buf, int pos) {
    int end = pos--;
    while (pos >= 0 && ((unsigned char)buf[pos] & 0xC0) == 0x80)
        pos--;
    return end - pos;
}

/* Convert UTF8 to Unicode code point
 */
static size_t utf8BytesToCodePoint(const char* buf, size_t len, int* cp) {
    if (len) {
        unsigned char byte = buf[0];
        if ((byte & 0x80) == 0) {
            *cp = byte;
            return 1;
        } else if ((byte & 0xE0) == 0xC0) {
            if (len >= 2) {
                *cp = (((unsigned long)(buf[0] & 0x1F)) << 6) |
                       ((unsigned long)(buf[1] & 0x3F));
                return 2;
            }
        } else if ((byte & 0xF0) == 0xE0) {
            if (len >= 3) {
                *cp = (((unsigned long)(buf[0] & 0x0F)) << 12) |
                      (((unsigned long)(buf[1] & 0x3F)) << 6) |
                       ((unsigned long)(buf[2] & 0x3F));
                return 3;
            }
        } else if ((byte & 0xF8) == 0xF0) {
            if (len >= 4) {
                *cp = (((unsigned long)(buf[0] & 0x07)) << 18) |
                      (((unsigned long)(buf[1] & 0x3F)) << 12) |
                      (((unsigned long)(buf[2] & 0x3F)) << 6) |
                       ((unsigned long)(buf[3] & 0x3F));
                return 4;
            }
        }
    }
    return 0;
}

/* Get length of next grapheme
 */
size_t linenoiseUtf8NextCharLen(const char* buf, size_t buf_len, size_t pos, size_t *col_len) {
    size_t beg = pos;
    int cp;
    size_t len = utf8BytesToCodePoint(buf + pos, buf_len - pos, &cp);
    if (isCombiningChar(cp)) {
        /* NOTREACHED */
        return 0;
    }
    if (col_len != NULL) *col_len = isWideChar(cp) ? 2 : 1;
    pos += len;
    while (pos < buf_len) {
        int cp;
        len = utf8BytesToCodePoint(buf + pos, buf_len - pos, &cp);
        if (!isCombiningChar(cp)) return pos - beg;
        pos += len;
    }
    return pos - beg;
}

/* Get length of previous grapheme
 */
size_t linenoiseUtf8PrevCharLen(const char* buf, size_t buf_len, size_t pos, size_t *col_len) {
    UNUSED(buf_len);
    size_t end = pos;
    while (pos > 0) {
        size_t len = prevUtf8CharLen(buf, pos);
        pos -= len;
        int cp;
        utf8BytesToCodePoint(buf + pos, len, &cp);
        if (!isCombiningChar(cp)) {
            if (col_len != NULL) *col_len = isWideChar(cp) ? 2 : 1;
            return end - pos;
        }
    }
    /* NOTREACHED */
    return 0;
}

/* Read a Unicode from file.
 */
size_t linenoiseUtf8ReadCode(int fd, char* buf, size_t buf_len, int* cp) {
    if (buf_len < 1) return -1;
    size_t nread = read(fd,&buf[0],1);
    if (nread <= 0) return nread;

    unsigned char byte = buf[0];
    if ((byte & 0x80) == 0) {
        ;
    } else if ((byte & 0xE0) == 0xC0) {
        if (buf_len < 2) return -1;
        nread = read(fd,&buf[1],1);
        if (nread <= 0) return nread;
    } else if ((byte & 0xF0) == 0xE0) {
        if (buf_len < 3) return -1;
        nread = read(fd,&buf[1],2);
        if (nread <= 0) return nread;
    } else if ((byte & 0xF8) == 0xF0) {
        if (buf_len < 3) return -1;
        nread = read(fd,&buf[1],3);
        if (nread <= 0) return nread;
    } else {
        return -1;
    }

    return utf8BytesToCodePoint(buf, buf_len, cp);
}
