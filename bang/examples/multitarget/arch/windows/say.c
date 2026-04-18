#include "arch.h"

#include <stdio.h>

void say(const char *msg)
{
    (void)fprintf(stdout, "%s\n", msg);
}
