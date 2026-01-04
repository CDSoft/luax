# readline: read lines from a user with editing

[The GNU Readline
library](https://tiswww.case.edu/php/chet/readline/rltop.html) provides
a set of functions for use by applications that allow users to edit
command lines as they are typed in.

**Warning**: the LuaX readline module tries to dynamically load
libreadline. If it fails, it uses basic functions with no editing and
history capabilities.

``` lua
readline.name(appname)
```

sets a unique application name. This name allows conditional parsing of
the inputrc file.

``` lua
readline.read(prompt)
```

prints `prompt` and returns the string entered by the user.

``` lua
readline.add(line)
```

adds `line` to the current history.

The history is cleaned on the fly:

- empty lines are ignored
- duplicates are removed, only the last entry is kept

``` lua
readline.set_len(len)
```

sets the maximal history length to `len`.

``` lua
readline.save(filename)
```

saves the history to the file `filename` (unless the history has not
been modified).

``` lua
readline.load(filename)
```

loads the history from the file `filename`.
