# Trevor Stone's Advent of Code Repository

This is a repository containing my solutions for
[Advent of Code](https://adventofcode.com/).  I generally use Advent of Code as
an opportunity to get experience with a language that I don’t yet know well.
You’re welcome to take inspiration from the way I solved a problem, but please
don’t assume that I’ve solved it in the most idiomatic, efficient, or readable
way.

This code is made available under an [MIT-style license](./LICENSE). I do not
accept pull requests to this repo, but you’re welcome to point out anything you
think could be done better.

Year           | Language | Thoughts
-------------- | -------- | --------
[2020](./2020) | [Kotlin](https://kotlinlang.org/) | [Blog post](https://flwyd.dreamwidth.org/396527.html)
[2021](./2021) | [Raku](https://raku.org/) plus [Go](https://go.dev/) when Raku was too slow | [Blog post](https://flwyd.dreamwidth.org/400979.html)
[2022](./2022) | [Elixir](https://elixir-lang.org/) | [Blog post](https://flwyd.dreamwidth.org/405717.html)
[2023](./2023) | [Julia](https://julialang.org/) |
[2024](./2024) | [PostScript](https://en.wikipedia.org/wiki/PostScript) |
[2025](./2025) | Glue languages that might already be installed on your system: [AWK](https://en.wikipedia.org/wiki/AWK), [dc](https://en.wikipedia.org/wiki/Dc_(computer_program)), [gvpr (Graphviz)](https://graphviz.org/docs/cli/gvpr/), [Jsonnet](https://jsonnet.org/), [jq](https://jqlang.org/), [Lua](https://lua.org/about.html), [sed](https://en.wikipedia.org/wiki/Sed), [SQL/MM](https://en.wikipedia.org/wiki/Simple_Features#Spatial), [zsh](https://en.wikipedia.org/wiki/Z_shell) plus [Go](https://go.dev/) and [Ruby](https://ruby-lang.org/) to explore some puzzles | [Blog post](https://flwyd.dreamwidth.org/417936.html)

When solving Advent puzzles as they come out, I also post code and commentary to
u/adventofcode Solutions Megathreads on Reddit.
[See all my solutions comments](https://www.reddit.com/r/adventofcode/search/?q=u%2Fflwyd+solutions&type=comments).

## Directory Structure

Each year has its own directory and the solution for each day is in its own
subdirectory, e.g. `2025/day10`.  Each day’s solution is a standalone program
which solves the puzzle for each input file on the command line, or from
standard input if no file is given.  Each day directory has the solution code
in one or more languages, named with the language’s source file convention,
e.g. `day1.exs` and `Day1.jl`.  Some languages have a symlink to a runner
library or a Makefile.

Each day also has a file named `input.example.txt` with an example taken from
the problem description and `input.example.expected` with two lines (prefixed
`part1: ` and `part2: `) with the expected output when the solution code is run
`input.example.txt`.  If the problem description has multiple examples, they’ll
be in `input.example2.txt` and `input.example2.expected`, etc.  If a solution
needs a little extra help, `run` will look for a `dayXlang` file, e.g.
`day1sed` would pass each file individually to the `day1.sed` script and
perhaps transform the output by adding all the numbers produced by the script.

The `input.actual.txt` and `input.actual.expected` files are symlinks into a
non-public directory with input specific to my AoC account.  If you’d like to
test my code against your personal input, provide the path to your input as a
command line argument: `day1/day1.exs -v path/to/my/input.txt`.  If you’d like
to run a whole suite of solutions against your input, make sure they’re in a
directory with numbered subdirectories, e.g. `1/input.actual.txt` and replace
my `input` directory with a symlink to yours, e.g. `rm 2023/input; ln -s
path/to/my/2023 2023/input` which will cause `runday` and `testday` scripts to
use yours.  Alternatively, substitute the `input` submodule at the base of the
repository, as in the next section.

Except for a few one-off programs, each language has a “runner” library and a
template generator script.  The runner library generally handles reading each
input into an array of strings (one per line) and calling `part1` and `part2`
functions passed by the program.  Runners and generators are in the
[`lang` directory](./lang).  The runner library also looks for a file with
expected results and compares the puzzle solutions to the expected values,
exiting the program with a non-zero status code if the program returned the
wrong value.  With the `-v` (and sometimes `--verbose`) option as the first
argument, the runner also prints start and end messages with input line count,
timing, and an eye-catching line with the program’s outcome.

General-purpose scripts are in the top-level directory.  They were originally
copied with minor modifications into each year’s directory; some are still
lying around.  In addition to running and testing, some scripts automate
day-of-coding activities.

* The [`run`](./run) script ensures the runner library is present, though most
  programs can be run directly, or built by `make -C year/dayX`.
* The [`runday`](./runday) script runs all the solution programs in a directory
  on both the example and actual inputs, teeing output to the `out` subdirectory
  for post hoc debugging.
* The [`watch`](./watch) script calls `runday` every time a substantive file in
  a day directory changes; I run that in a terminal while iterating on a
  solution in a Vim window.
* The [`testday`](./testday) script which can run one or more days, compare
  output with expected, and report results using the
  [Test Anything Protocol format](https://testanything.org/).
* [`fetchinput`](./fetchinput) uses `curl` to download my input file for a
  day’s puzzle, taking care not to call the site before the puzzle is released;
  the `runday` script is responsible for saving the output to a private
  directory (see below) and not requesting it if the file isn’t empty (always
  cache your inputs,
  [be nice to Eric’s servers](https://www.reddit.com/r/adventofcode/wiki/faqs/automation/)!).
  One failure mode of this approach is if there’s an error writing the input
  file, e.g. a symlink pointing to nowhere.  This will likely result in a read
  error being displayed or the solution program crashing, so fix the directory
  structure before `watch` picks up a lot more changes.  The other failure mode
  is expired cookies (stored in `.cookie-jar`).  I’ve found that cookies are
  often rejected well before the expiration date in the initial HTTP response,
  so if `input.actual.txt` has 0 lines after midnight, go to adventofcode.com
  and inspect your request to grab a fresh cookie.
* [`cachepuzzle`](./cachepuzzle) downloads a copy of the puzzle HTML and saves
  it in `dayX/puzzle/puzzle.html` for offline browsing and grepping.  The
  `puzzle` directory is in `.gitignore`:
  [don’t redistribute puzzle text](https://adventofcode.com/2021/about#faq_copying)
* [`extractexamples`](./extractexamples) looks for `<pre>` formatted text in the
  puzzle.html file and saves it to `input.example.txt` (and example2 etc), which
  will be automatically used as test input.  This isn’t a perfect system; there
  are sometimes `<pre>` blocks showing what happens to the input after some
  operation, so delete any input files that aren’t good test cases.
* [`formegathread`](./formegathread) formats the code for a solution appropriate
  for a
  [Solutions Megathread comment](https://www.reddit.com/r/adventofcode/wiki/index/#wiki_archives).
  In particular, this uses four-space markdown indent (not a backtick fence) for
  code formatting and removes imports, comment lines, and boilerplate code.
  It also inserts a title with the language name and a link to the file on
  my GitHub repository.  The resulting file can be used in a text editor to
  compose a solutions comment that’s more likely to be short enough and not
  annoy u/daggerdragon for
  [not following the rules](https://www.reddit.com/r/adventofcode/wiki/solution_megathreads/post_guidelines/).

## Hiding Private Advent of Code Input with Git Submodules

Eric Wastl [asks that you don’t include your personal input in public source
code repositories](https://www.reddit.com/r/adventofcode/wiki/faqs/copyright/inputs/).
If you’d like to use [git submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules)
to keep your input files under source control and available wherever you check
out the repository with your code, follow these steps:

1.  [Create a new GitHub repository](https://github.com/new) and select the
    `Private` radio button.  Give it a name like `adventofcode-input`.
1.  Git submodules don’t work with an empty repository, so make sure to create
    at least one file in this new repository, such as `.gitignore` or
    `README.md`.
1.  In your main Advent of Code repository, add the new repository as a submodule:
    `git submodule add https://github.com/YourUserName/adventofcode-input input`.
    This will check out the new repo into a directory named `input`.
1.  *Pro tip:* To use the same transport (HTTPS or SSH) for the submodule as the
    main repository, [use a relative URL like
    `../adventofcode-input.git`](https://stackoverflow.com/questions/40841882/automatically-access-git-submodules-via-ssh-or-https).
1.  If you run `git status` it will show two new staged entries: `.gitmodules`
    and `input`.  If you run `git diff --staged` you’ll see the content of the
    new `.gitmodules` file (this keeps track of your submodules and their
    remote URL) and the latest git commit in that repo:

    ```
    diff --git a/.gitmodules b/.gitmodules
    new file mode 100644
    index 0000000..7904cad
    --- /dev/null
    +++ b/.gitmodules
    @@ -0,0 +1,3 @@
    +[submodule "input"]
    +       path = input
    +       url = https://github.com/flwyd/adventofcode-input
    diff --git a/input b/input
    new file mode 160000
    index 0000000..7fde85f
    --- /dev/null
    +++ b/input
    @@ -0,0 +1 @@
    +Subproject commit 7fde85fc0dc5d6334645ebd10978e8755aab4de2
    ```

1.  Run `git commit` to add this new submodule to your main repository’s history.
1.  Run `git push origin main` to upload your main repository to GitHub.  Since
    the `input` submodule is private, other people won’t be able to see the
    files inside that directory when they browse github.com or check out your
    public repository.
1.  When you check out your main repository on a different computer, you need to
    initialize the submodule.  The easy way to do this is when cloning:
    `git clone --recurse-submodules https://github.com/YourUserName/adventofcode`
    If it’s already checked out, run `git submodule init && git submodule update`
    Git may prompt you for your GitHub credentials when checking out the submodule
    if [your credentials aren’t cached](https://docs.github.com/en/get-started/getting-started-with-git/caching-your-github-credentials-in-git)
1.  Although the submodule is really a separate git repository, locally it looks
    like a single file tree.  As you work on AoC problems, put your personal
    input files in the submodule, e.g. in `input/2023/1/input.actual.txt`.  Your
    code can read the input files using a relative path, or you can create a
    symlink from your solution directory:
    `cd solutions2023; ln -s ../input/2023/1/input.actual.txt day1/`
1.  When your solution’s done it now takes two steps to upload to GitHub.
    First, commit the input file in your submodule:

    ```sh
    cd input
    git add 2023/1
    git commit -m "2023 day 1 input file"
    git push origin main
    ```

    Then commit the code and other files in your main repository, as well as the
    pointer to the new head commit of your input repository:

    ```sh
    cd ..
    git add input
    git add 2023/day1/*
    git commit -m "Solution to 2023 day 1"
    git push origin main
    ```

1.  If you’d like to check out someone’s Advent of Code solutions repository but
    use your own input files, you can swap out the submodule URL:
    `git config submodule.input.url https://github.com/SomwhereElse/aoc-input`
    and then run `git submodule init && git submodule update`.
