/*@@@

# Example of *reversed* literate programming

@@@*/

//---
/* This portion should be discarded. */
#include <assert.h>
//---

/*@@@
## Fibonacci sequence

Native implementation:
@@@*/

int fib(int n) {
    if (n <= 1) return 1;       /* fib(0) == fib(1) == 1         */
    return fib(n-1) + fib(n-2); /* fib(n) == fib(n-1) + fib(n-2) */
}

/*@@@
## Tests

@@@*/

int main(void) {
    assert(fib(0) == 1);
    assert(fib(1) == 1);
    assert(fib(10) == 89);
}
