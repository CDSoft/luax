# Makefile for building imath library
# imath is available at https://github.com/creachadair/imath
# The code here is from https://github.com/creachadair/imath/archive/v1.32.tar.gz

CC= gcc -std=c99
CFLAGS= -pedantic -Wall -Wextra -Wno-unused-parameter $(PIC)
MYCFLAGS= $(CFLAGS) -O3 -funroll-loops -finline-functions
L= imath.o

all:	$L

imath.o: imath.c imath.h
	$(CC) $(MYCFLAGS) -c imath.c

clean:
	-rm -f *.o *.a $T
