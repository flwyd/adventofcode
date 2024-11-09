# Cob, a PostScript library

Cob is a library of [PostScript](https://en.wikipedia.org/wiki/PostScript)
functions and utilities that one might have liked to see in the PostScript
standard library.  These functions are non-graphical, intended for use in
programs run from the command line on a computer rather than programs sent to a
printer with limited resources.

So far Cob is only tested on [Ghostscript](https://ghostscript.com/) and might
produce errors on other PostScript interpreters.  Please report any
incompatibilities.

## How to use Cob

In 2024 Cob isn’t ready to be an independent repository, so you’ll need to `git
clone https://github.com/flwyd/adventofcode` or otherwise extract this
directory.   When you run your PostScript program, ensure either the parent of
the `cob` directory or the directory itself (which contains a `cob` symlink to
itself) is in the library path, and that the PostScript environment is allowed
to perform file I/O (the `NOSAFER` Ghostscript property).  For example, `gsnd
-q -dNOSAFER -Iadventofcode/2024 -- myprogram.ps` Inside your program, run the
bootstrap file and then `cob.require` the libraries used by your program:

```postscript
%!PS
(cob/bootstrap.ps) runlibfile
(cob/core.ps) cob.require
(cob/string.ps) cob.require

% Check if all words in the string have odd length.
(hello/world) (/) split { length 2 mod 1 eq } all?
```

### Unit testing

`cob/testing.ps` provides an xUnit-style test framework with
[Test Anything Protocol](https://testanything.org/) output.  Test files use
Cob to run their library dependencies, then set up a test suite and test cases.
To run a test file, `gsnd -q -Ipath/to/cob -- path/to/cob/foo_test.ps`
You can run multiple tests and feed the results to a TAP consumer like
[tapview](https://gitlab.com/esr/tapview):
`gsnd -q -dBATCH -I. *_test.ps | tapview -s`

## Why Cob?

I was inspired to use a stack-based language for the 2024 season of
[Advent of Code](https://adventofcode.com/), and PostScript’s syntax and naming
conventions were easier to wrap my mind around than the Forth-derived ones.
The language’s standard library is fairly spartan, particularly for working
with strings, and I didn’t fancy spending a late night implementing “join an
array to a string” from scratch, so wrote some core library functions that I
expect to use in any significant AoC problem.  Since Cob is the first
PostScript code I’ve written, there is probably plenty of room for improvement.
Please leave a comment if you see something that could be done better.

## Why “cob”?

[Cob](https://en.wikipedia.org/wiki/Cob_(material)) is a simple natural
building material that’s used for building walls and other structures.  It has
similar characteristics to adobe bricks.  It’s also short enough to type
frequently in a program.

## License and other details

This library is open source under an MIT-style license.  For more details about
use and contributions,
[see my Advent of Code README](https://github.com/flwyd/adventofcode).
