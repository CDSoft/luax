#include "hello/hello.h"

#include "arch.h"

#include <stdlib.h>

int main(int argc, const char *argv[])
{
    switch (argc) {
        case 1: {
            say("Please tell me your name.");
            break;
        }
        case 2: {
            char *s = greeting(argv[1]);
            say(s);
            free(s);
            break;
        }
        default: {
            say("Too many arguments...");
            break;
        }
    }
}
