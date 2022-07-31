# Makefile for Lua library

LUA_TOPDIR= /usr/local
LUA_INCDIR= $(LUA_TOPDIR)/include
LUA_BINDIR= $(LUA_TOPDIR)/bin
    LIBDIR= $(LUA_TOPDIR)/lib/lua/5.3
       LUA= $(LUA_BINDIR)/lua

CC= gcc -std=c99
CFLAGS= -Wall -Wextra -Wfatal-errors -O2
MYCFLAGS= $(CFLAGS) -I$(LUA_INCDIR) -Isrc

MYNAME= qmath
MYLIBS= src/imath.o src/imrat.o
MYFILE= l$(MYNAME).c
MYMOD= $(MYNAME).$(LIBEXT)

all:	so test

so:
	@$(MAKE) `uname`

test:
	$(LUA) test.lua

install:
	cp $(MYMOD) $(LIBDIR)

clean:
	rm -f *.o *.so src/*.o src/*.a

doc:
	@echo "$(MYNAME) library:"
	@fgrep '/**' $(MYFILE) | cut -f2 -d/ | tr -d '* ' | sort | column

Linux:
	$(MAKE) -C src PIC=-fPIC
	$(CC) $(MYCFLAGS) -o $(MYMOD) -shared -fPIC $(MYFILE) $(MYLIBS)

Darwin:
	$(MAKE) -C src
	$(CC) $(MYCFLAGS) -o $(MYMOD) -bundle -undefined dynamic_lookup $(MYFILE) $(MYLIBS)

build:
	$(MAKE) -C src CC="$(CC)" CFLAGS="$(CFLAGS)"
	$(CC) $(MYCFLAGS) -o $(MYMOD) $(LIBFLAG) $(MYFILE) $(MYLIBS)

LIBFLAG= -shared -fPIC
LIBEXT= so

.PHONY: all so test install clean doc Linux Darwin build
