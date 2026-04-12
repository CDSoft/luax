#include "arch.h"

#include <stdio.h>
#include <string.h>

#define ASK_BUF_SIZE 1024

char *ask(const char *prompt)
{
    (void)fputs(prompt, stdout);
    (void)fflush(stdout);
    char buf[ASK_BUF_SIZE];
    (void)fgets(buf, sizeof(buf), stdin);
    return strdup(buf);
}
