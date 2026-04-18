#include "hello/hello.h"

#include "arch.h"
#include "utils/utils.h"

#include <stdbool.h>
#include <stdlib.h>

int main(void)
{
    while (true) {
        char *name = ask("Your name: ");
        char *stripped_name = strip(name);
        free(name);
        if (stripped_name[0] == '\0') {
            free(stripped_name);
            break;
        }
        char *s = greeting(stripped_name);
        free(stripped_name);
        say(s);
        free(s);
    }
}
