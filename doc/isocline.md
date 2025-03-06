# isocline: light readline alternative

[Isocline](https://github.com/daanx/isocline) is a portable GNU readline
alternative.

See <https://daanx.github.io/isocline> for furter details.

``` lua
isocline.readline(prompt_text)
```

Read input from the user using rich editing abilities. The prompt text,
can be `nil` for the default (““). The displayed prompt becomes
`prompt_text` followed by the `prompt_marker` (”\> “).

``` lua
isocline.print(s)
```

Print to the terminal while respection bbcode markup.

``` lua
isocline.println(s)
```

Print with bbcode markup ending with a newline.

``` lua
isocline.printf(fmt, ...)
```

Print formatted with bbcode markup.

``` lua
isocline.style_def(style_name, fmt)
```

Define or redefine a style.

``` lua
isocline.style_open(fmt)
```

Start a global style that is only reset when calling a matching
ic_style_close().

``` lua
isocline.style_close()
```

End a global style.

``` lua
isocline.set_history(fname, max_entries)
```

Enable history. Use a `nil` filename to not persist the history. Use
`-1` or `nil` for max_entries to get the default (1000).

``` lua
isocline.history_remove_last()
```

Remove the last entry in the history.

``` lua
isocline.history_clear()
```

Clear the history.

``` lua
isocline.history_add(entry)
```

Add an entry to the history

``` lua
isocline.set_prompt_marker(prompt_marker, continuation_prompt_marker)
```

Set a prompt marker and a potential marker for extra lines with
multiline input. Pass `nil` for the `prompt_marker` for the default
marker (`"> "`). Pass `nil` for continuation prompt marker to make it
equal to the `prompt_marker`.

``` lua
isocline.get_prompt_marker()
```

Get the current prompt marker.

``` lua
isocline.get_continuation_prompt_marker()
```

Get the current continuation prompt marker.

``` lua
isocline.enable_multiline(enable)
```

Disable or enable multi-line input (enabled by default). Returns the
previous setting.

``` lua
isocline.enable_beep(enable)
```

Disable or enable sound (enabled by default). A beep is used when tab
cannot find any completion for example. Returns the previous setting.

``` lua
isocline.enable_color(enable)
```

Disable or enable color output (enabled by default). Returns the
previous setting.

``` lua
isocline.enable_history_duplicates(enable)
```

Disable or enable duplicate entries in the history (disabled by
default). Returns the previous setting.

``` lua
isocline.enable_auto_tab(enable)
```

Disable or enable automatic tab completion after a completion to expand
as far as possible if the completions are unique. (disabled by default).
Returns the previous setting.

``` lua
isocline.enable_completion_preview(enable)
```

Disable or enable preview of a completion selection (enabled by default)
Returns the previous setting.

``` lua
isocline.enable_multiline_indent(enable)
```

Disable or enable automatic identation of continuation lines in
multiline input so it aligns with the initial prompt. Returns the
previous setting.

``` lua
isocline.enable_inline_help(enable)
```

Disable or enable display of short help messages for history search etc.
(full help is always dispayed when pressing F1 regardless of this
setting) Returns the previous setting.

``` lua
isocline.enable_hint(enable)
```

Disable or enable hinting (enabled by default) Shows a hint inline when
there is a single possible completion. Returns the previous setting.

``` lua
isocline.set_hint_delay(delay_ms)
```

Set millisecond delay before a hint is displayed. Can be zero. (500ms by
default).

``` lua
isocline.enable_highlight(enable)
```

Disable or enable syntax highlighting (enabled by default). This applies
regardless whether a syntax highlighter callback was set
(`ic_set_highlighter`) Returns the previous setting.

``` lua
isocline.set_tty_esc_delay(initial_delay_ms, followup_delay_ms)
```

Set millisecond delay for reading escape sequences in order to
distinguish a lone ESC from the start of a escape sequence. The defaults
are 100ms and 10ms, but it may be increased if working with very slow
terminals.

``` lua
isocline.enable_brace_matching(enable)
```

Enable highlighting of matching braces (and error highlight unmatched
braces).

``` lua
isocline.set_matching_braces(brace_pairs)
```

Set matching brace pairs. Pass `nil` for the default `"()[]{}"`.

``` lua
isocline.enable_brace_insertion(enable)
```

Enable automatic brace insertion (enabled by default).

``` lua
isocline.set_insertion_braces(brace_pairs)
```

Set matching brace pairs for automatic insertion. Pass `nil` for the
default `()[]{}\"\"''`
