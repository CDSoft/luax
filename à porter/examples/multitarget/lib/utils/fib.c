#include "fib.h"

int fib(int n)
{
    int a = 1;
    int b = 1;
    for (int i = 0; i < n; i++)
    {
        int c = b + a;
        a = b;
        b = c;
    }
    return a;
}
