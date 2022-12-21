#!/bin/bash

while [ -n "$1" ]
do

    ORIGIN=$(dirname "$1")
    PLATFORM=$(basename "$1" | sed 's/^[^-]*-//')

    IFS=:
    for path in $(patchelf --print-rpath "$1" 2>/dev/null)
    do
        path="$(echo "$path" | sed "s#\$ORIGIN#$ORIGIN#")"
        lib="$path/libluaxruntime-$PLATFORM.so"
        test -f "$lib" && echo "$lib"
    done
    IFS="\n"

    shift

done
