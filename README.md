# Trevor Stone's Advent of Code Repository

This is a repository containing solutions for [Advent of
Code](https://adventofcode.com/). Each AoC year has its own directory and the
solution for each day is in its own subdirectory.  Each day’s solution is
generally a standalone program which takes input either on standard input
(2020) or one or more input files on the command line (2021, 2022, 2023). 2022
introduced a separate solution runner library rather than including a few dozen
lines of orchestration code in the template, but they still run as standalone
scripts with more spartan output.  The scripts take an optional `-v` or
`--verbose` flag as the first argument to print whether the program matched the
expected output, along with timing information.  There is also a `testday`
script which can run one or more days, compare output with expected, and report
results using the [Test Anything Protocol format](https://testanything.org/).

I generally use Advent of Code as an opportunity to get experience with a
language that I don’t yet know well. You’re welcome to take inspiration from the
way I solved a problem, but please don’t assume that I’ve solved it in the most
idiomatic, efficient, or readable way.

Year           | Language | Thoughts
-------------- | -------- | --------
[2020](./2020) | [Kotlin](https://kotlinlang.org/) | [Blog post](https://flwyd.dreamwidth.org/396527.html)
[2021](./2021) | [Raku](https://raku.org/) plus [Go](https://go.dev/) when Raku was too slow | [Blog post](https://flwyd.dreamwidth.org/400979.html)
[2022](./2022) | [Elixir](https://elixir-lang.org/) | [Blog post](https://flwyd.dreamwidth.org/405717.html)
[2023](./2023) | [Julia](https://julialang.org/) |

This code is made available under an [MIT-style license](./LICENSE). I do not
accept pull requests to this repo, but you’re welcome to point out anything you
think could be done better.

## Directory Structure

Each year’s solutions are in a directory named after the year.  Within that dir
is one directory for each day’s solution, named `day1` through `day25`.
Each day directory has the solution code in one or more languages, a file named
`input.example.txt` with an example taken from the problem description and
`input.example.expected` with two lines (prefixed `part1: ` and `part2: `) with
the expected output when the solution code is run `input.example.txt`.  If the
problem description has multiple examples, they’ll be in `input.example2.txt`
and `input.example2.expected`, etc.

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

There is also a `lang` directory for runner and generator infrastructure for
programming languages which aren’t “the main language” for any year, but which I
sometimes use for fun or because I got stuck on a problem with the main new
language for a year.

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
