# ypp tests

## Variables defined on the command line

VAR1 = <42>      
VAR2 = <43>      
VAR3 = <44>      
VAR4 = <val4>      
VAR5 = <>      
VAR6 = <>      

## Basic text substitution

$1 + 2 = 3$



$$ \sum_{n=1}^{100} = 5050 $$

- Line 1
- Line 2
- Line 3
- Line 4
- Line 5
- Line 6
- Line 7
- Line 8
- Line 9
- Line 10


nil in an expression = @(nil)

nil in a statement = 



weird = bizarre string )) => ) unbalanced ())

malformed expression: @[===========[ foo bar ]=====]
malformed chunk: @@[===========[ foo bar ]=====]

function call: 90.0
chaining methods: 55
chaining methods: WORLD! <- HELLO
chaining methods: OLLEH -< !DLROW
chaining methods: WORLD! <- HELLO : reverse()
uncomplete chains: a-b-c: this colon is not part of the previous macro

escaping: `@F.range(1, 10):sum()`

Strings can not contain newline characters:
cool! 'this is not
a string'
but this is a
multiline single quoted string

### pattern_1

1+1 = 2
1+1 = 2

### pattern_2

1+1 = 2
1+1 = 2
1+1 = 2
1+1 = 2

### pattern_3



pi = 3.1415926535898
math.max(2, 3) = 3
F.maximum{2, 3, 1} = 3
func(1, 2)[[three]] = three = 1 + 2
functb{1, 2}[[three]] = three = 1 + 2
string.upper[=[ Hello World! ]=] = HELLO WORLD!
t.u[1].x = x
t.u[10-9].x = x
t.u[10-9].f(10) = 100
t.u[10-9]:g(10) = 1000

ignored pattern: someone@example.com
undefined variable: @undefined

### Special syntax for assignments


$golden\_ratio = 1.6$



vrai = true, faux = false


a = 14


b = {x=1, y=2}


c = a long string



d = 1, 4, 9, 16, 25, 36, 49, 64, 81, 100








t = {nil, 2, {...}, 4, x="x", y="y", z="z"}

 597
 66

 3.1416
 3.1416
 3.1416

## File inclusion



Macro char is <!> now in this file but not in the included files.



foo = bar
foo = @foo

### Included from another file

This paragraph has been included.

Caller:

- `input_file(1)`: `./ypp/tests/test.md`
- `input_path(1)`: `./ypp/tests`

Callee:

- `input_file()`: `./ypp/tests/test_inc.md`
- `input_path()`: `./ypp/tests`

This part is not included:

This part is also not included:


foo = bar
foo = @foo

Using a special character with ypp.macro:
     ^ => bar     
     $ => bar     
     % => bar     
     . => bar   
     * => bar     
     + => bar     
     - => bar     
     ? => bar     



Macro char <@> is back.

foo = !foo
foo = bar

lines: 28

## Comments





## Conditional




Texte français conservé (lang=fr)

## Documentation extraction

### Doc blocks only

**`answer`** takes any question and returns the most relevant answer.

Example:

``` c
    const char *meaning
        = answer("What's the meaning of life?");
```

The code is:

``` c
const char *answer(const char *question)
{
    return "42";
}
```


### Doc blocks and code in code blocks


#### Example of *reversed* literate programming

##### Fibonacci sequence

Native implementation:

``` c
int fib(int n) {
    if (n <= 1) return 1;       /* fib(0) == fib(1) == 1         */
    return fib(n-1) + fib(n-2); /* fib(n) == fib(n-1) + fib(n-2) */
}
```

##### Tests

``` c
int main(void) {
    assert(fib(0) == 1);
    assert(fib(1) == 1);
    assert(fib(10) == 89);
}
```


## Scripts

### Custom language

- 1+1 = 2
- 2+2 = 4

### Predefined language

- 3+3 = 6
- 4+4 = 8

### Formatting script output

#### Explicit conversion

  X   Y   Z
  --- --- ---
  a   b   c
  d   e   f


#### Implicit conversion

  X   Y   Z
  --- --- ---
  a   b   c
  d   e   f


## Images



### Images with the default format (SVG)

- ypp_images/b49087009670ddd6.svg
- .build/tests/ypp/ypp_images/b49087009670ddd6.svg


### Images with a specific format (e.g. PNG)

- ypp_images/20cdbe6a97b8872c.png
- .build/tests/ypp/ypp_images/20cdbe6a97b8872c.png


### Images with a custom command

- ypp_images/b49087009670ddd6.svg
- .build/tests/ypp/ypp_images/b49087009670ddd6.svg


### Images generated with Asymptote

ypp_images/test-asy.svg

### Images generated with Octave

ypp_images/test-octave.svg

ypp_images/9b81cc265bda8ae9.svg

### Images from an external file

ypp_images/test-dot.svg

ypp_images/a6ae6726874bd0b6.svg

### Images preprocessed with ypp


ypp_images/hello.svg

## Scripts loaded on the command line

`test_loaded` = `true`

`mod1_loaded` = `true`      `mod1.name` = `Mod1`
`mod2_loaded` = `true`      `mod2.name` = `@mod2.name`  `mymod.name` = `Mod2`
`mod3_loaded` = `true`      `mod3.name` = `@mod3.name`

## Scripts loaded by test.md



`test_2_loaded` = `true`



`test3.test_3_loaded` = `true`

## File creation




check .build/tests/ypp/test-file.txt

## Deferred evaluation

### Table of content

1. Chapter 1
2. Chapter 2


nbch = 2

### Chapter 1

nbch = 2

### Chapter 2

nbch = 2

### Accumulation in a table



lines:
one
two
three
four
five
6
42










words: un deux trois





## End of the document

This text shall not be forgotten.
