#include "hello.h"

#include "arch.h"

#include <stdio.h>
#include <string.h>

#define HELLO_BUF_SIZE 2048

char *greeting(const char *name)
{
    const char *arch = get_arch();
    char buf[HELLO_BUF_SIZE];
    (void)snprintf(buf, sizeof(buf), "%s says: « Hello, %s! »", arch, name);
    return strdup(buf);
}
