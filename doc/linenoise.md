# linenoise: light readline alternative

**linenoise.read(prompt)** prints `prompt` and returns the string
entered by the user.

**linenoise.read_mask(prompt)** is the same as
**linenoise.read(prompt)** the the characters are not echoed but
replaced with `*`.

**linenoise.add(line)** adds `line` to the current history.

**linenoise.set_len(len)** sets the maximal history length to `len`.

**linenoise.save(filename)** saves the history to the file `filename`.

**linenoise.load(filename)** loads the history from the file `filename`.

**linenoise.clear()** clears the screen.

**linenoise.multi_line(ml)** enable/disable the multi line mode.

**linenoise.mask(b)** enable/disable the mask mode.
