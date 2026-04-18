#include "utils.h"

#include <ctype.h>
#include <string.h>

char *strip(const char *s)
{
    unsigned long i = 0;
    while (isspace(s[i])) { i++; }
    unsigned long j = strlen(s) - 1;
    while (j > i && isspace(s[j])) { j--; }
    char *p = strdup(&s[i]);
    p[j-i+1] = '\0';
    return p;
}
