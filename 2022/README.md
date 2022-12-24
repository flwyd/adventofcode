# Advent of Code 2022 in Elixir

I am using [Advent of Code 2022](https://adventofcode.com/”) to learn
[Elixir](https://elixir-lang.org/), a functional and concurrent style language
built on the Erlang virtual machine.  An elixir,
[as Wikipedia says](https://en.wikipedia.org/wiki/Elixir) “is a sweet liquid
used for medical purposes, to be taken orally and intended to cure one's
illness”.  I broaden that sense a little and think of an elixir as a brewed or
concocted beverage with ingredients intended to have an effect on the body.
This thus treats beer and spirits as, at least poetically, elixirs.

This page presents recasts each day’s Advent of Code problem as an elixir (the
beverage) and shares some insights into Elixir (the language) as used in my
solution for the day.  **WARNING: Spoilers below.**

## Table of Contents

* [Day 1](#day-1)
* [Day 2](#day-2)
* [Day 3](#day-3)
* [Day 4](#day-4)
* [Day 5](#day-5)
* [Day 6](#day-6)
* [Day 7](#day-7)
* [Day 8](#day-8)
* [Day 9](#day-9)
* [Day 10](#day-10)
* [Day 11](#day-11)
* [Day 12](#day-12)
* [Day 13](#day-13)
* [Day 14](#day-14)
* [Day 15](#day-15)
* [Day 16](#day-16)
* [Day 17](#day-17)
* [Day 18](#day-18)
* [Day 19](#day-19)
* [Day 20](#day-20)
* [Day 21](#day-21)
* [Day 22](#day-22)
* [Day 23](#day-23)
* [Day 24](#day-24)

## Day 1
[Code](day1/day1.exs) - [Problem description](https://adventofcode.com/2022/day/1)

The elixir is [boba tea](https://en.wikipedia.org/wiki/Bubble_tea), a tea- or
fruit-based drink, served in many east Asian restaurants, with tapioca balls
(the boba) at the bottom of the cup, sucked through a wide straw.
The input for Day 1 is a list of the number of tapioca grains in a cluster,
several lines in a row (delimited by a blank line) indicate clusters which are
bound together in a boba ball.  Part 1 requires finding the largest tapioca
pearl so you can make sure the straw is big enough.  Part 2 asks for the sum of
the three largest pearls, since we all know you’re going to have at least one
boba get stuck on the pointy end of your straw.

I set up my [Elixir Advent of Code template](template.exs.eex) to take a list
of strings, one per line, with [the runner](runner.ex) parsing each file into
lines.  My [2020 AoC experience](../2020) found this to be a useful approach,
since most problems have a one-value-per-line input structure.  I also knew
that there were occasional “paragraph” inputs where distinct pieces of the input
were separated by blank lines.  I expected to encounter at least one paragraph
input in 2022, but didn’t expect it to be day 1.  Since the list-of-lines input
doesn’t have a `string.split("\n\n")` option I needed to figure out how to split
a list into smaller lists based on a property of the delimiting list elements.
[`Enum.chunk_while`](https://hexdocs.pm/elixir/Enum.html#chunk_while/4) is a
good way to do this, and let me get practice with accumulator-based enumeration
functions.  `chunk_while` takes an accumulator for an initial value (an empty
list in this case), a chunk function which gets called, with the accumulator,
for each element in the enumerable, and an after function which is called with
the accumulator after all elements have been visited so you can handle the final
chunk.  Both functions return a struct; the first element is either `:cont` or
`:halt` to continue or stop iteration.  The final struct element is the
accumulator, either the one that’s built up for the chunk so far or an empty
accumulator if it’s time to start a new chunk.  When starting a new chunk the
functions return the chunked value as the second parameter.  In my solution the
accumulator is a list of integers and the chunk values are the sum of those
integers.  I could’ve also used `0` as the initial accumulator value and added
each number to the sum as it came in, saving memory space.  To avoid
implementing separate functions, my “after function” was the same as my
“chunk function” with an empty string (implied blank line) curried as the first
argument.

```elixir
defp sum_chunks(input), do: Enum.chunk_while(input, [], &chunk_lines/2, &(chunk_lines("", &1)))
defp chunk_lines("", []), do: {:cont, []} # ignore excess blanks, just in case
defp chunk_lines("", acc), do: {:cont, Enum.sum(acc), []}
defp chunk_lines(number, acc), do: {:cont, [String.to_integer(number) | acc]}
```

## Day 2
[Code](day2/day2.exs) - [Problem description](https://adventofcode.com/2022/day/2)

The elixir is some potion we’re brewing from fruits and herbs.  Bitter herbs
counteract the sweet sugars in fruits, sour acidic fruits make the bitters
palatable, and sweets keep the sours from puckering up our face.  There are two
cooks in the kitchen; we’ve sneaked a copy of the first cook’s recipe and have
a plan to concoct the elixir to our liking (the other cook likes things a little
too strong) without winning each step and revealing that we stole their secret
recipe.  In part 1, the second column of input represents the ingredient we add
to the pot, in part 2 the second column represents whether we want to counteract
the other cook’s ingredient, match their ingredient, or let theirs counteract
ours.

Since I learned [Perl](https://perl.org/) as a teenager, my instinct for the
input for this type of problem is `split(line, " ")`.  But there’s no need to
use regular expressions to pull the first and last letter from a three-character
string, so I used Elixir’s [binary (string) matching capability](https://elixir-lang.org/getting-started/binaries-strings-and-char-lists.html#Binaries)
to extract variables from an expected string format.  I also took advantage of
the ASCII-ordering of the input text to do modular arithmetic on letters.
I also discovered that Elixir has two modulus functions: `Kernel.rem(a, b)`
keeps the sign of `a` while `Integer.mod(c, d)` keeps the sign of `d`, allowing
`Integer.mod(mine - theirs, 3)` to represent ties as `0`, wins as `1`, and
losses as `2`.  (I realized from someone else’s solution that
`Integer.mod(mine - theirs + 1, 3) * 3` would compute the score more concisely
than my `case` lookup table.)

```elixir
input
|> Enum.map(fn <<theirs, " ", mine>> -> {theirs - ?A, mine - ?X} end)
|> Enum.map(&score/1)
|> Enum.sum()
defp score({theirs, mine}) do
  mine + 1 + case Integer.mod(mine - theirs, 3) do
      0 -> 3
      1 -> 6
      2 -> 0
    end
end
```

## Day 3

[Code](day3/day3.exs) - [Problem description](https://adventofcode.com/2022/day/3)

There’s a bartender making ridiculously complicated cocktails.  They serve you
two drinks and you need to sip both and identify the one ingredient that’s
present in both elixirs.  In part 2, the bartender gives one drink to three
people and they need to figure out which one ingredient is in all the drinks.

I implemented part 1 with the simple but repetitive
`MapSet.intersection(MapSet.new(String.to_charlist(first)), MapSet.new(String.to_charlist(second)))`.
With the second part operating on three sets I decided to convert this to a
recursive set intersection function, with the base case returning all elements
from a set while the recursive case intersects the elements in the head of
the list with the intersection of the tail.  I don’t think this inmplementation
is properly [tail-recursive](https://en.wikipedia.org/wiki/Tail_call) because
it needs to pass the recursion result to another function, along with the
calculated head value.  Reading another solution on the Reddit megathread I
realized this could be simplified as
`Enum.map(&MapSet.new/1) |> Enum.reduce(&MapSet.intersection/2)`.

```elixir
defp common([solo]), do: MapSet.new(solo)
defp common([head | tail]), do: MapSet.new(head) |> MapSet.intersection(common(tail))
```

## Day 4

[Code](day4/day4.exs) - [Problem description](https://adventofcode.com/2022/day/4)

It’s Saturday night, so it’s time for sake bombs.  Part 1 wants to know if the
shot of sake is completely contained in the glass of beer (or if a very small
glass of beer ended up entirely within a cup of sake).  Part 2 wants to know if
any of the sake got in the beer, or vice versa.

Elixir’s [Range](https://hexdocs.pm/elixir/Range.html) API is pretty anemic;
it doesn’t have anything like `contains?`.  So I first solved part 1 using
`MapSet.subset?` while part 2 got to use `Range.disjoint?`.  Enumerating an
two entire ranges just to find out if one is a subset of the other seemed
wasteful, so I implemented `range_subset?` to compare the endpoints.  I thought
that a natural sort of Range values would let me do a single comparison, but
discovered that misses cases where the first have the same value, since `4..6`
sorts less than `4..8`.

```elixir
defp range_subset?({first, second}) do
  # sort by Range start, ties go to the longer range
  [a, b] = sort_by([first, second], fn lo .. hi -> {lo, -hi} end)
  a.last >= b.last
end
```

## Day 5

[Code](day5/day5.exs) - [Problem description](https://adventofcode.com/2022/day/5)

We planned ahead for smoothies by chopping and freezing delicious fruits in the
summer.  As winter approaches we pull out our frozen fruit cubes and put them in
glasses.  We allow the fruit to melt a little into the cups while we follow a
recipe that looks like a shell game, moving pieces of fruit from the top of one
cup onto another cup.  The first round moves each fruit cube individually; on
the second round we just pick up a whole stack and move it over.

This was the first program where my stroll through the official Elixir tutorial
and Advent infrastructure coding exercise from October left me missing important
language semantics.  This problem leads itself to iterative updates to a data
structure.  I knew that Elixir’s data structures were all immutable, but local
variables can be reassigned.  So I started with code like

```elixir
stack_indices = … # 1 through max stack, parsed from input
stacks = Map.new(stack_indices, fn i -> {i, []}) # each stack starts empty
for line <- header |> Enum.reverse() do
  for i <- stack_indices do
    crate = String.at(line, (i - 1)*4 + 1) # character in stack i
    if crate != nil && crate != " " do
      cur = stacks[i]
      stacks = Map.put(stacks, i, [c | cur])
    end
  end
end
```

but at the end my `stacks` map was always empty.  I think what’s happening is
the `do/end` blocks in `for` and `if` are turned into closures (anonymous
functions) which cannot modify the variable in the “outer” scope.  But instead
of an error about trying to clobber an outer-scope variable, Elixir just creates
a new variable within the “block scope” that shadows the outer one.

I therefore had to convert this imperative-style programming to rely heavily on
`Enum.reduce` and accumulators.

```elixir
stacks = Map.new(stack_indices, fn i -> {i, parse_stack(stack_header, i)} end)
defp parse_stack(lines, index) do
  for line <- lines do
    String.at(line, (index - 1)*4 + 1)
  end |> Enum.filter(&(&1 != nil && &1 != " "))
end
```

One interesting mental effect is that this switched parsing from line-oriented
to column-oriented: I iterate through all the lines for each stack rather than
iterating through each stack on each line, because the output is a map of
index to stack.

After copy/pasting part 1 to part 2 with a slight change I set about
refactoring.  On the first pass, input parsing was about half of my code.

```elixir
{header, moves} = Enum.split_while(input, &(&1 != ""))
moves = tl(moves)
stack_indices = List.last(header) |> String.trim() |> String.split(~r/ +/) |> map(&to_integer/1)
stack_header = Enum.take(header, Enum.count(header) - 1)
stacks = Map.new(stack_indices, fn i -> {i, parse_stack(stack_header, i)} end)
stacks = Enum.reduce(moves, stacks, fn line, stacks ->
  ["move", n, "from", first, "to", second] = String.split(line, " ", trim: true)
… end)
```

This has the Advent benefit of being fairly quick to implement, but I wasn’t
fond of the fact that I was flipping lists around, pulling things off the head
and tail, and iterating through them several times.  I decided to create an
`Input` struct that would be parsed as a single scan of the input.  This turned
out to be mentally tricky to get everything right, but I think is closer to the
functional programming spirit.  Using string prefix for function signature
matching was interesting, though I’m not satisfied with it as a general parsing
solution, since it can’t handle something like a variable-length number as the
first value.  The other thing I lost in this parsing switch was accumulating a
list by inserting at the head, then reversing it at the end.  I’m not sure if
Elixir has some optimization to make list concatenation (`++`) efficient.

I’m aware that an [`Agent` or `GenServer`](https://elixir-lang.org/getting-started/mix-otp/agent.html)
would make my iterative map updating a lot smoother.  I figured I would
implement it without any concurrency today so that I really internalize the
awkward way of doing it, so that I will appreciate concurrent state abstraction
in Elixir that much more.

## Day 6

[Code](day6/day6.exs) - [Problem description](https://adventofcode.com/2022/day/6)

We’re making whiskey with a trombone for a still.  Our mash has all sorts of
wonderful grains in it: barley, rye, wheat, corn, sorghum, rice, millet…
We boil four (then fourteen) grains of mash at a time.  Each time we move our
trombone’s slide (used as the condenser in the still) one position forward.
When vapor from four (fourteen) distinct types of grain emerge from the
trombone’s horn we’ve found the sweet spot for our whiskey distillation process
and we mark it on the slide.

To test my Elixir Advent of Code infrastructure I’d done an implementation of
[2021 day 1](https://adventofcode.com/2021/day/1) using
`List.zip([tl(tl(input)), tl(input), input])` to iterate through the list three
at a time.  I solved part 1 with a similar approach, converting the input string
to a charlist, Erlang’s representation of a string as a list of integers.

```elixir
chars = to_charlist(List.first(input))
List.zip([chars, tl(chars), tl(tl(chars)), tl(tl(tl(chars)))])
|> Enum.find_index(fn list -> Enum.uniq(Tuple.to_list(list)) |> Enum.count() == 4 end)
|> then(&(&1 + 4))
```

This worked well, and quickly found the answer.  In part 2 I didn’t want to
write `tl(tl(tl(tl(tl(tl(tl(tl(tl(tl(tl(tl(tl(tl(chars))))))))))))))` and its
13 younger siblings so I tried to generate that list programmatically,
generating a 14-element list by repeatedly calling `Enum.drop`.  Unfortunately
I neglected to wrap that result in `Enum.zip` so I was just iterating through
the first 14 characters of the string, which never yielded a successful result.
A working solution for that approach is interesting.

```elixir
chars = to_charlist(str)
Enum.zip(Enum.reduce(0..13, [], fn x, acc -> acc ++ [Enum.drop(chars, x)] end))
|> Enum.find_index(fn sub -> Enum.uniq(Tuple.to_list(sub)) |> Enum.count == 14 end)
|> IO.inspect
|> then(&(&1 + 14))
```

Since I couldn’t find my bug, I implemented a second solution using `Stream`,
calling `String.slice` at each step.  This code is not particularly beautiful,
and feels more awkward than an imperative language which would just return
from within a for loop when the result was found.  `Stream.with_index(14)` to
avoid adding the offset at the end was kind of clever, though.

```elixir
Stream.map(0..(String.length(str) - 1), fn i ->
  String.slice(str, i, 14) |> to_charlist |> Enum.uniq() |> Enum.count()
end)
|> Stream.with_index(14)
|> Stream.filter(fn {len, _i} -> len == 14 end)
|> Stream.take(1)
|> Enum.to_list()
|> List.first()
|> elem(1)
```

Once I submitted the answer from the Stream solution I implemented a recursive
solution which is both much more elegant and is also 100 times faster(!) than
the streams-and-substrings solution, and twice as fast as the `zip` one.
This again relies on charlists being a `[char | tail]` list of characters,
just waiting for recursion.

```elixir
def solve(length, {i, chars}) do
  prefix = Enum.take(chars, length)
  if Enum.uniq(prefix) |> Enum.count == length, do: i, else: solve(length, {i + 1, tl(chars)})
end
```

## Day 7

[Code](day7/day7.exs) - [Problem description](https://adventofcode.com/2022/day/7)

We’re mixing a [coco loco](https://tipsybartender.com/recipe/coco-loco/).  But
we’re not just pouring coconut milk and spirits into a coconut shell, adding a
straw, and calling it done.  We start with half a coconut shell and put half a
cored pineapple inside.  Inside the pineapple goes a passion fruit and inside
_that_ goes a lychee.  Think of it as a tropical turducken smoothie.  To make
sure none of the fruits tip over we’ll pack more nested fruit in the empty
spaces: kumquats inside apples, grapes inside kiwis, starfruit in a mango in a
papaya.  In the first part we need to find all the fruit clusters that have
room anywhere inside them for 10 drams of spirits.  In the second part we
realized we’ve got too much fruit to serve a full-strength drink so we need to
find the size of the smallest sub-turducken that will let us fit 7000 drams
anywhere within the coconut concoction.

Since Elixir is a functional language and directory hierarchies are usually
represented as trees, this problem screams “recursion!”  My tired brain found
the recursive bookkeeping to be a little challenging, since we need to keep
track of both the current working directory and the whole filesystem state.
I got flustered when I realized that I needed to handle `$ cd ..` to return back
to the parent directory but couldn’t just return subdirectories from recursive
functions because the input doesn’t move all the way up to the root.  Instead of
representing the filesystem as a recursive tree I realized the structure could
just be embedded in absolute file paths in a map of path to file size.  Rather
than computing a recursive total size I could just filter the whole filesystem
by path prefix and sum the matching sizes.

Since each type of line can be distinguished by a fixed-length prefix, parsing
is clean and easy to follow.  I like how it highlights how the `$ ls` command
doesn’t affect the current working directory or the files, just returning the
`FileSys` accumulator.

```elixir
  defp parse_files(input),
    do: input |> Enum.reduce(%FileSys{}, &process_line/2) |> Map.get(:files)

  defp process_line(<<"$ cd /">>, %FileSys{} = sys), do: Map.put(sys, :pwd, [])

  defp process_line(<<"$ cd ..">>, %FileSys{pwd: pwd} = sys),
    do: Map.put(sys, :pwd, Enum.drop(pwd, -1))

  defp process_line(<<"$ cd ", dir::binary>>, %FileSys{pwd: pwd} = sys),
    do: Map.put(sys, :pwd, Enum.concat(pwd, [dir]))

  defp process_line(<<"$ ls">>, %FileSys{} = sys), do: sys

  defp process_line(<<"dir ", dir::binary>>, %FileSys{pwd: pwd} = sys),
    do: Map.update!(sys, :files, &Map.put(&1, Enum.concat(pwd, [dir]), 0))

  defp process_line(line, %FileSys{pwd: pwd} = sys) do
    [size, name] = String.split(line, " ")
    Map.update!(sys, :files, &Map.put(&1, Enum.concat(pwd, [name]), String.to_integer(size)))
  end
```

I originally used string keys for the files map.  Switching to lists of
directories (skipping `Enum.join(pwd, "/")` and `name <> "/"`) saved about 30%
on runtime.  Elixir string operations are definitely not as cheap as working
directly with lists!

## Day 8

[Code](day8/day8.exs) - [Problem description](https://adventofcode.com/2022/day/8)

9801 glasses of various elixirs are arranged in a 99-by-99 grid.  The glasses
are of differing heights.  In part 1 we compute the number of glasses we can see
in a straight line from outside the grid.  In part 2 we multiply the number of
glasses visible in each direction together and pick the glass with the highest
score.

Each year, Advent of Code has a few problems about traversing a two-dimensional
grid.  Many people instinctively model these as a 2D array, but I prefer to use
a map with pairs of integers as keys.  This avoids the need to get the endpoints
right for bounds checks; you can just check `Map.member?(grid, {row, column})`.
To find whether a tree in the grid is visible from the edges is easy by
iterating through four ranges of pair values.

```elixir
defp visible?({row, col}, maxrow, maxcol, grid) do
  value = grid[{row, col}]
  Enum.any?([
    Enum.all?(0..(row - 1)//1, fn r -> grid[{r, col}] < value end),
    Enum.all?(0..(col - 1)//1, fn c -> grid[{row, c}] < value end),
    Enum.all?((row + 1)..maxrow//1, fn r -> grid[{r, col}] < value end),
    Enum.all?((col + 1)..maxcol//1, fn c -> grid[{row, c}] < value end)
  ])
end
```

## Day 9

[Code](day9/day9.exs) - [Problem description](https://adventofcode.com/2022/day/9)

The elves are throwing a TGIF party with a beer bong made out of one of those
[expandable plastic
tubes](https://webstore.cdlusa.net/content/images/thumbs/0002247_clear-flexible-vacuum-hoses_550.jpeg).
At first it's a really short path from the funnel, but then you pull on the
hose and discover that it's pretty long. The elves wander around the room with
the funnel, and you need to keep up. What path do you follow?

Part 2 requires tracking nine tail components, starting at the `{0, 0}` origin.
At first I generated a list of 9 element by mapping over a range but ignoring
the value: `Enum.map(1..9, fn _ -> {0, 0} end)`.  Then I found `List.duplicate`
which is a lot nicer to read.  I also used this to turn moves like `L 5` into
five steps that reduce the X coordinate by one.

```elixir
@origin {0, 0}
defp record_path(input, num_tails) do
  tails = List.duplicate(@origin, num_tails)
  moves = Enum.map(input, &expand_line/1) |> List.flatten()
  Enum.reduce(moves, {@origin, tails, MapSet.new([@origin])}, fn move, {head, tail, acc} ->
    newhead = move_head(move, head)
    newtail = move_chain(newhead, tail)
    {newhead, newtail, MapSet.put(acc, List.last(newtail))}
  end)
end

defp expand_line(<<dir, " ", amount::binary>>) do
  List.duplicate(
    case dir do
      ?U -> {-1, 0}
      ?D -> {1, 0}
      ?L -> {0, -1}
      ?R -> {0, 1}
    end,
    String.to_integer(amount))
end
```

## Day 10

[Code](day10/day10.exs) - [Problem description](https://adventofcode.com/2022/day/10)

We've got nearly 100 tea bags. It takes about two minutes for the flavor of a
tea bag to steep into the hot water. The
[camellia](https://en.wikipedia.org/wiki/Camellia_sinensis) bags add a varying
level of bitterness: black teas are strong, green a little less bitter, the
white teas are very delicate. The herbal
[tisanes](https://en.wikipedia.org/wiki/Tisane) cut that bitterness. Sometimes
we remove the bag and just let the tea sit for a minute. Over the course of
four hours, while we swap these tea bags, we sip the mug once a minute and make
a mark on graph paper if the bitterness level is just right or close enough.

The output is an ASCII [raster](https://en.wikipedia.org/wiki/Raster_graphics),
pixelated in the example with `#` and `.`.  The coder is then meant to squint
at the output and identify a series of letters to submit to the Advent of Code
website.  I was able to visually parse this just fine, but it presented a
challenge for my runner infrastructure.  For each input file (example and
actual) I save the desired output in a `.example` file with `part1: ` and
`part2: ` prefixes.  Ideally I would like to store my program output, `EGLHBLFJ`
in the `.expected` file, but the example output doesn’t form any letters that I
recognize.  I opted to enhance my [runner program](./runner.exs) and
[test harness](./testday) to replace `\n` in the expected output with real
newlines.  That way the runner will print the ASCII raster on multiple lines
while still doing simple equality checking to see if I got the values right.
This let me learn how
[Elixir protocols work](https://elixir-lang.org/getting-started/protocols.html)
so that `to_string(result)` would print it as expected.

```elixir
defmodule Raster do
  defstruct rows: [], on: ?#, off: ?.

  def new(rows, {on, off} \\ {?#, ?.}),
    do: %Raster{rows: rows, on: on, off: off}
end

defimpl String.Chars, for: Raster do
  def to_string(%Raster{rows: rows, on: on, off: off}) do
    rows
    |> Enum.map(fn row -> Enum.map(row, &if(&1, do: on, else: off)) end)
    |> Enum.join("\n")
  end
end
```

The `on` and `off` members of the struct let me play around with different
display options in an interactive REPL session.  The `tl(rows)` strip the
initial blank list which is used to force a newline when printing output.

```
iex> %Day10.Raster{rows: rows} = Day10.part2(Runner.read_lines("input.example.txt"))
iex> IO.puts(Day10.Raster.new(tl(rows), {?@, ?\s})
@@  @@  @@  @@  @@  @@  @@  @@  @@  @@
@@@   @@@   @@@   @@@   @@@   @@@   @@@
@@@@    @@@@    @@@@    @@@@    @@@@
@@@@@     @@@@@     @@@@@     @@@@@
@@@@@@      @@@@@@      @@@@@@      @@@@
@@@@@@@       @@@@@@@       @@@@@@@
# Thematic emoji:
iex> %Day10.Raster{rows: rows} = Day10.part2(Runner.read_lines("input.actual.txt”))
iex> IO.puts(Day10.Raster.new(tl(rows), {127876, 127775})
🎄🎄🎄🎄🌟🌟🎄🎄🌟🌟🎄🌟🌟🌟🌟🎄🌟🌟🎄🌟🎄🎄🎄🌟🌟🎄🌟🌟🌟🌟🎄🎄🎄🎄🌟🌟🌟🎄🎄🌟
🎄🌟🌟🌟🌟🎄🌟🌟🎄🌟🎄🌟🌟🌟🌟🎄🌟🌟🎄🌟🎄🌟🌟🎄🌟🎄🌟🌟🌟🌟🎄🌟🌟🌟🌟🌟🌟🌟🎄🌟
🎄🎄🎄🌟🌟🎄🌟🌟🌟🌟🎄🌟🌟🌟🌟🎄🎄🎄🎄🌟🎄🎄🎄🌟🌟🎄🌟🌟🌟🌟🎄🎄🎄🌟🌟🌟🌟🌟🎄🌟
🎄🌟🌟🌟🌟🎄🌟🎄🎄🌟🎄🌟🌟🌟🌟🎄🌟🌟🎄🌟🎄🌟🌟🎄🌟🎄🌟🌟🌟🌟🎄🌟🌟🌟🌟🌟🌟🌟🎄🌟
🎄🌟🌟🌟🌟🎄🌟🌟🎄🌟🎄🌟🌟🌟🌟🎄🌟🌟🎄🌟🎄🌟🌟🎄🌟🎄🌟🌟🌟🌟🎄🌟🌟🌟🌟🎄🌟🌟🎄🌟
🎄🎄🎄🎄🌟🌟🎄🎄🎄🌟🎄🎄🎄🎄🌟🎄🌟🌟🎄🌟🎄🎄🎄🌟🌟🎄🎄🎄🎄🌟🎄🌟🌟🌟🌟🌟🎄🎄🌟🌟
# Try it out: this uses ANSI color escapes to print solid magenta blocks.
iex> IO.puts(Day10.Raster.new(tl(rows),
  {IO.ANSI.format([:magenta_background, :magenta, ?#]), ?\s}))
```

If I had more time it might be fun to write a letter parser using the Raster as
input so I could just copy and paste the letters.

## Day 11

[Code](day11/day11.exs) - [Problem description](https://adventofcode.com/2022/day/11)

An assembly line is making a smoothie with blueberries, pomegranate pips, oats,
peanuts, chia seeds, and other tasty ingredients.  Each chef either adds more
ingredients or multiplies the ingredients already in the cup, then passes it to
another chef based on the number of goodies in the cup, then puts an ice cube in
their blender.  They’re sloppy, so two thirds of the goodies fall out of the cup
on each pass.  After 20 rounds of each chef taking a turn we multiply the number
of ice cubes in the two fullest blenders.  In the second part the cooks are no
longer sloppy and we realize we’ve used nearly ¾ million ice cubes.

I modeled the -chefs- monkeys in this problem as a tuple of structs, rather than
a list or map, because I knew I’d be repeatedly cycling through them in order.
Although Elixir doesn’t have a lot of utility functions for operating on tuples,
“updating” it in a reduce method wasn’t too bad.  I also learned about the
[`struct!` function](https://hexdocs.pm/elixir/Kernel.html#struct!/2) which
looks a lot nicer than what I was going to do with `Map.update!`.

```elixir
def play_turn(who, monkeys, worry_fun) do
  Enum.reduce(elem(monkeys, who).items, monkeys, fn item, acc ->
    m = elem(acc, who)
    level = worry_fun.(m.op.(item))
    next = if rem(level, m.divisor) == 0, do: m.yes, else: m.no
    next_m = elem(acc, next)

    put_elem(
      put_elem(acc, next, struct!(next_m, items: next_m.items ++ [level])),
      who,
      struct!(m, times: m.times + 1, items: tl(m.items))
    )
  end)
end
```

## Day 12

[Code](day12/day12.exs) - [Problem description](https://adventofcode.com/2022/day/12)

We’re making a
[champagne tower](https://richfulness.com/wp-content/uploads/2021/09/Champagne_tower.jpg)
but instead of pouring from the top we’re pumping the bubbly up from the bottom.
To make things even trickier, the glasses are different height.  We want to see
how many glasses the elixir needs to climb or splash down to, starting from a
specific glass on the table, to reach the top.  Then we want to know the fewest
steps it takes from any glass sitting on the table.

I’ve written breadth-first search in imperative languages many times, including
for Advent of Code problems.  I think this is the first time I’ve implemented
it recursively, though I have a foggy memory of talking about recursive BFS in
an artificial intelligence course 20 years ago.  The implementation took a
little more careful work than I’m used to, since I can quickly dash off an
imperative BFS implementation:

```
queue = [start]
visited = {start}
while queue is not empty:
  cur = queue.shift
  return cur.moves if cur.coord == target
  for next in valid_moves(cur):
    if next not in visited:
      visited.add(next)
      queue.push(next)
```

The recursive version ended up fairly short:

```elixir
defp bfs([], _grid, _target, _visited), do: :not_found
defp bfs([{coord, moves} | _tail], _grid, coord, _visited), do: moves

defp bfs([{coord, moves} | tail], grid, target, visited) do
  next =
    valid_moves(coord, grid)
    |> Enum.filter(&(!MapSet.member?(visited, &1)))
    |> Enum.map(&{&1, moves + 1})
  queue = tail ++ next
  bfs(queue, grid, target,
    MapSet.union(visited, MapSet.new(next |> Enum.map(&elem(&1, 0)))))
end
```

The downside is that `queue = tail ++ next` is an O(n) operation in Elixir
(which follows functional languages back to Lisp in using singly linked
[cons lists](https://en.wikipedia.org/wiki/Cons)).  Runtime on my personal input
file is about one and a half seconds, the slowest solution in the first dozen
days of AoC 2022.  I implemented a partial
[array-based deque](https://en.wikipedia.org/wiki/Double-ended_queue#Implementations)
to see if using dynamically resized tuples would be more efficient.  (I should
also try it with Erlang’s
[array module](https://www.erlang.org/doc/man/array.html).)  The refactored
code, which lost the nice structural matching of the `bfs` function above, did
not work when first introduced, so I’ll come back to that after a good night’s
sleep.

_Update, after sleep:_ It turns out that Erlang has an efficient
[queue module](https://www.erlang.org/doc/man/queue.html).  Switching to that
was actually a few milliseconds slower than the list-based approach.  But when I
also switched from “find the path to end from all lowest-level start positions”
to “do a single BFS path with lowest-level start positions as the initial queue”
the overall time dropped from about a second and a half to a little over 20 milliseconds.  The Erlang queue led to a roughly 15% performance improvement in part
2 with the optimized algorithm.  Moving backwards from end to any valid start
would probably be faster still, but require function structure changes.

## Day 13

[Code](day13/day13.exs) - [Problem description](https://adventofcode.com/2022/day/13)

We’ve got a recipe for brewing beer, but the instructions are all out of order.
It simply would not do to put the Irish moss in the water for 2 minutes, then
grind ten pounds of malt barley, then pitch the yeast, then heat the water to
150° F.  In the first part we figure out which pairs of instructions are in the
right order between themselves-don’t sparge before you add the specialty
grains to the pot-and add the positions of the well-ordered pairs.  In the second part we sort the whole list so it becomes a viable recipe.  We notice that the
recipe left out hops, so we add some 2% alpha acid Hersbruck for bittering and
some 6% AA Santiam for aroma.  Then multiply the hop positions together.

This problem felt tailor-made for Elixir.  I used `Code.eval_string` to parse
the lines into lists, since they were already valid Elixir syntax.  (This is
dangerous, though: if someone slipped in a different input file they could
delete everything on my disk or other nefarious tactics.  I’ll write a proper
parser later.)  I still managed to add a bug to almost every line I wrote, but
the end result is pretty elegant: every line is either an `Enum` operation or
a pattern-matching function.

```elixir
defp compare_pair(l, r) when is_integer(l) and is_integer(r) and l < r, do: :correct
defp compare_pair(l, r) when is_integer(l) and is_integer(r) and l > r, do: :wrong
defp compare_pair(l, r) when is_integer(l) and is_integer(r) and l == r, do: :continue
defp compare_pair(left, right) when is_integer(left), do: compare_pair([left], right)
defp compare_pair(left, right) when is_integer(right), do: compare_pair(left, [right])
defp compare_pair(left, right) when is_list(left) and is_list(right) do
  Enum.zip_reduce(Stream.concat(left, [:stop]), Stream.concat(right, [:stop]), :continue, fn
    _, _, :wrong -> :wrong
    _, _, :correct -> :correct
    :stop, :stop, _acc -> :continue
    :stop, _, _acc -> :correct
    _, :stop, _acc -> :wrong
    l, r, :continue -> compare_pair(l, r)
  end)
end
```

## Day 14

[Code](day14/day14.exs) - [Problem description](https://adventofcode.com/2022/day/14)

We’re sitting patiently while [ice water drips over a sugar cube, through the
slotted spoon, and into our glass of absinthe](https://en.wikipedia.org/wiki/Absinthe#Preparation).
The absinthe compounds are oddly firm, and the water has unusually high tension.
Each drop of sugar water stacks on the absinthe molecules and the bottom of the
glass, forming a pyramid of absinthe at its
[triple point](https://en.wikipedia.org/wiki/Triple_point).  In the first part
we want to know how many drops it takes until the water hits the sides of the
glass; in the second part we want to know when the absinthe rises up to the
spoon.

This problem provides a good example for a mix of `reduce` and recursion in
Elixir.  Where an imperative language would use a `while` loop, breaking once
the end condition is reached, Elixir can use `Enum.reduce_while` over a
`Stream.cycle`, passing the state of the absinthe and water molecules to each
subsequent step of the reduction, until `:halt` signals a stop.  This also
illustrates that the `:cont` and `:halt` options from the reducer don’t need to
return the same type: `{:cont, {newgrid, count + 1}}` keeps the two-part
accumulator going, but we only need to return `{:halt, count}` at the end, since
the state of the grid doesn’t matter to the answer.

```elixir
Enum.reduce_while(
  Stream.cycle([{500, 0}]),
  {start_grid, 0},
  fn start, {grid, count} ->
    if MapSet.member?(grid, start) do
      {:halt, count}
    else
      {landed, newgrid} = drop(start, grid, max_y, part)
      if landed, do: {:cont, {newgrid, count + 1}}, else: {:halt, count}
    end
  end
)

defp drop({_x, y}, grid, max_y, 1 = _part) when y > max_y, do: {false, grid}
defp drop({x, y}, grid, max_y, 2 = _part) when y > max_y, do: {true, MapSet.put(grid, {x, y})}

defp drop({x, y} = point, grid, max_y, part) do
  case possible_moves(point, grid) do
    [] -> {true, MapSet.put(grid, {x, y})}
    [first | _] -> drop(first, grid, max_y, part)
  end
end
```

## Day 15

[Code](day15/day15.exs) - [Problem description](https://adventofcode.com/2022/day/15)

Oh no, we spilled tray of elixirs on the floor!  Each potion spreads in a circle
until it encounters the nearest ice cube, then suddenly freezes solid.  But
there’s one ice cube which isn’t touched by any liquid.  In the first part we
figure out which positions along one board of the floor couldn’t have an ice
cube because the center of the elixir drop is closer to that spot than to the
ice cube it encountered.  In part 2 we find the untouched ice cube in the one
spot in a large square area of floor.

My initial brute force solution to the first problem was fairly simple,
creating a list of all points along the given row which are within
`distance(sensor, beacon) - distance(sensor, {sensor_x, row})` to the left or
right of the sensor, then rejecting the position of any sensors or beacons on
that row to get the count right.  This worked, but was pretty slow: 25 seconds
for the millions-wide input file.  The efficient version merges ranges without
expanding them and just adds the size, but looks uglier, at least after
`mix format` is done with it.

I made it all the way to day 15 before pulling out
[Regex](https://hexdocs.pm/elixir/Regex.html).  This has mostly been because I’m
an old hand at regular expressions, so playing with other forms of parsing has
been a fun exercise.  Pulling four numbers out of a fixed-format sentence is
easy with a regular expression and tedious with the prefix-matching code I’ve
been writing.  The ability to include all the groups in a structured list result
(which also means you get a clear error if you don’t get the expected number of
groups) is petty nice.  Compare

```elixir
@pattern ~r/Sensor at x=(-?\d+), y=(-?\d+): closest beacon is at x=(-?\d+), y=(-?\d+)/
defp parse_line(line) do
  [_, sx, sy, bx, by] = Regex.run(@pattern, line)
  {{to_integer(sx), to_integer(sy)}, {to_integer(bx), to_integer(by)}}
end
```

to

```elixir
defp parse_line(line) do
  ["Sensor at x", sx, " y", sy, " closest beacon is at x", bx, " y", by]
    = String.split(line, [",", ":", "="], trim: true)
  {{to_integer(sx), to_integer(sy)}, {to_integer(bx), to_integer(by)}}
end
```

The second may run slightly faster, though.

## Day 16

[Code](day16/day16.exs) - [Problem description](https://adventofcode.com/2022/day/16)

Our brewery has several
[lauter tuns](https://en.wikipedia.org/wiki/Lautering#Lauter_tun) spaced around
a large warehouse.  We have a map of the floor with the rate that
[wort](https://en.wikipedia.org/wiki/Wort) can flow out of each tun when the
spigot is open.  Traveling from one tun to another takes one minute; each tun is
linked to a few other tuns, and some of the tuns are empty.  In part 1 we want
to know the total amount of wort that could flow in a 30-minute period as we
walk around opening spigots.  In part 2, we spend 4 minutes training a friend to
open the lauter spigots and spend 26 minutes opening the tuns.

The number of possible spigot opening sequences in this problem is huge; even
after compacting the graph to take several steps past empty tuns there are over
one trillion permissions.  Fortunately, a lot of the smaller portions of the
permutations will be the same, so runtime becomes reasonable when using a cache.
Caches, by nature, keep and mutate state, which is difficult with Elixir’s
immutable-only data structures.  To manage this sort of state, Elixir offers
[Agents](https://elixir-lang.org/getting-started/mix-otp/agent.html) which run
in a separate light-weight process that sends and receives messages and uses
recursive calls to transition to the next state.

I started with an Agent which contained a Map; at the end of each recursive
`find_best_score` call I put the computed value into the cache like
`Agent.update(cache, fn cur -> Map.put(cur, key, value) end)`.  I discovered
that Agent calls have a timeout, which defaults to five seconds.  As the cache
got into millions of items, each with a couple lists and structs as key, the
process took several gigabytes of RAM and the O(log n) cost of updates to the
map, combined with garbage collection, created trouble.

I switched the cache to use Erlang’s
[ETS](https://elixir-lang.org/getting-started/mix-otp/ets.html) module which
provides a mutable key-value store with O(1) performance.  In-memory caches are
exactly the sort of thing this module is built for, and it improved the
performance of my search by quite a bit, though I haven’t yet run a comparison
with the final solution with optimized heuristics.  It’s also got a nice feature
to increment and decrement counters without needing to fetch the current value
first; I used this to periodically print the number of cache hits and misses as
a simple way to see progress.  My part 2 solution ended up with a cache of
roughly 8.5 million entries and got nearly 20 million cache hits (cache hits
above the bottom of the tree save more than one step of work, so even a 2:1 hit
to miss ratio saves an immense amount of work).

```elixir
cache = :ets.new(:cache, [:set])
cache_stats = :ets.new(:cache_stats, [:set])
value = find_best_score(flows, compact, initial, cache, cache_stats)
[hits, misses] = Enum.map([:hits, :misses], fn key -> Keyword.fetch!(:ets.lookup(cache_stats, key), key) end)
IO.puts(:stderr, "Cache hits: #{hits} misses: #{misses}")
:ets.delete(cache)
:ets.delete(cache_stats)

defp find_best_score(flows, graph, state, cache, stats) do
  case :ets.lookup(cache, state) do
    [{_, cached}] ->
      :ets.update_counter(stats, :hits, 1, {:hits, 0})
      cached
    [] ->
      :ets.update_counter(stats, :misses, 1, {:misses, 0})
      best =
        valid_move_groups(flows, graph, state, 0, 0)
        |> Enum.map(fn {move, value} ->
          value + find_best_score(flows, graph, State.normalize(move), cache, stats)
        end)
        |> Enum.max(fn -> 0 end)
      :ets.insert(cache, {state, best})
      best
  end
end
```

## Day 17

[Code](day17/day17.exs) - [Problem description](https://adventofcode.com/2022/day/17)

We’ve made 2,022 ice cubes using five custom molds filled with five flavors of
spa water.  The ice machine has a predictable pattern of how the cubes tumble
out, so they slot into our (very tall) glass at different positions.  How tall
is the stack of ice in our glass?  In part two, we dispense one trillion ice
cubes (that’s two thirds of a cubic kilometer) and measure the height.
Assuming one centimeter per ice cube segment, the glass would stretch 10% of
the distance to the sun.

Learning about `ets` in day 16 came in handy.  Elixir/Erlang define comparison
and equality for all data types, so a cache key of “two integers and the top
several lines of a stack of symbols” was super easy.

Today’s solution illustrates one of the benefits of immutable data structures
and change-by-copy.  I represented rocks (ice cubes) as lists of pairs of
integers representing position above (negative y value) or below (positive y
value) the top of the stack.  At each step of the “blow sideways, then fall
down” the `move(rock, {dx, dy})` function uses `Enum.map` to create a new list
of positions, and the result is assigned to a new local variable.  The
`allowed?` predicate is then checked, and we revert back to the original local
variable if it’s not a valid move.  Once the rock has stopped moving,
`place_rock` creates a new stack with the rock’s resting place merged with the
top few rows of the stack, but since a list is just a series of `[head | tail]`
pairs, only the first few items need to be changed, the final one of which is
pointing to the unchanged tail that might be a few thousand rows long,
resulting in an algorithm that has a constant upper bound on memory allocation
for each loop (assuming there isn’t a super-deep hole that a vertical bar rock
can fall into).

```elixir
defp move(rock, {dx, dy}), do: Enum.map(rock, fn {x, y} -> {x + dx, y + dy} end)

defp place_rock(rock, height, stack) do
  get_y = &elem(&1, 1)
  min_y = Enum.map(rock, get_y) |> Enum.min()
  min_y_or_zero = min(min_y, 0)
  new_rows = List.duplicate(List.duplicate(:clear, 7), -1 * min_y_or_zero)
  new_stack =
    Enum.reduce(rock, new_rows ++ stack, fn {x, y}, st ->
      List.update_at(st, y - min_y_or_zero, fn list -> List.replace_at(list, x, :blocked) end)
    end)
  {height - min_y_or_zero, new_stack}
end

@down {0, 1}
defp drop_rock(rock, height, stack, jets) do
  {moved, jets} =
    Enum.reduce_while(Stream.cycle([nil]), {rock, jets}, fn nil, {rock, jets} ->
      {jets, move} = Jetstream.next_move(jets)
      shifted = move(rock, move)
      r = if allowed?(shifted, height, stack), do: shifted, else: rock
      down = move(r, @down)
      if allowed?(down, height, stack), do: {:cont, {down, jets}}, else: {:halt, {r, jets}}
    end)
  {height, stack} = place_rock(moved, height, stack)
  {height, stack, jets}
end
```

## Day 18

[Code](day18/day18.exs) - [Problem description](https://adventofcode.com/2022/day/18)

When fermenting alcohol it’s important to minimize the surface area exposed to
air.  Yeast ferment in an anaerobic environment, and air has a bunch of
microbes that you don’t want reproducing in your brew.  But before the yeast
can start fermenting they need lots of oxygen immersed in the wort (for beer)
or must (for wine) so they can reproduce.  Pitch the yeast, then aerate, then
put the airlock on your fermenter.  In today’s problem we have an oddly shaped
fermenter (no [carboys](https://en.wikipedia.org/wiki/Carboy) in this jungle
cave full of elephants) with lots of air pockets.  In part one we want to know
the total surface area of wort exposed to air.  In the second part we ignore
the internal air pockets (the yeast will need those to reproduce) and focus on
the exterior surface of the brew.

Several previous days showed multiple functions with the same name and argument
types but different structural values, which is one of Elixir/Erlang’s distinct
features.  Just a few days ago I realized that anonymous functions defined with
`fn` can provide multiple structural variants, too.  So in a sense, `case` is
shorthand for calling a one-argument anonymous function with several structural
variants.  Maybe that’s even how the macro is implemented.

```elixir
Enum.reduce_while(Stream.cycle([nil]), {0, [min_point], MapSet.new([min_point])}, fn
  nil, {count, [], _} -> {:halt, count}

  nil, {count, [head | queue], visited} ->
    interesting = neighbors(head) |> Enum.filter(in_range)

    {:cont,
      Enum.reduce(interesting, {count, queue, visited}, fn n, {count, queue, visited} ->
        case {MapSet.member?(pts, n), MapSet.member?(visited, n), in_range.(n)} do
          {true, false, true} -> {count + 1, queue, visited}
          {false, false, true} -> {count, [n | queue], MapSet.put(visited, n)}
          {false, true, true} -> {count, queue, visited}
          {false, false, false} -> {count, queue, visited}
        end
      end)}
end)
```

## Day 19

[Code](day19/day19.exs) - [Problem description](https://adventofcode.com/2022/day/19)

We're distilling rum.  Rum requires water and molasses.  To make molasses you
need sugar cane and water.  To grow sugar cane you need water.  You can also use
water to drill a well and get more water to flow.  We're evaluating several
contractors, each can do one thing a day: drill a well, plant a field of cane,
build a sugar refinery, or build a still.  Each day, each well produces one
[acre-foot](https://en.wikipedia.org/wiki/Acre-foot) of water, each cane field produces a
[hundredweight](https://en.wikipedia.org/wiki/Hundredweight) of sugar, each refinery
produces a [hogshead](https://en.wikipedia.org/wiki/Hogshead) of molasses, and
each still produces a barrel of rum.  Each contractor requires different amounts
of each resource to produce each type of equipment.  We want to know the most
barrels of rum each contractor could produce in a 24-day period (part 1) or a
30-day period (part 2).

Caching via `ets` came in handy in much the same way it did in [day 16](#day-16)
but with different decisions to make in order to reduce the number of states
explored at each step.  Transitioning from one state to another consists of
deciding what (if anything) to build and then producing resources.  This is easy
to model with maps: building adds one to one entry in the `robots` map while
subtracting each of the `resources` costs.  Producing adds the values from the
blueprint map to the state map.

```elixir
defmodule State do
  defstruct robots: %{ore: 1, clay: 0, obsidian: 0, geode: 0},
            resources: %{ore: 0, clay: 0, obsidian: 0, geode: 0}

  def build(state, type, cost) do
    struct!(state,
      robots: Map.update!(state.robots, type, &(&1 + 1)),
      resources: Map.merge(state.resources, cost, fn _k, v1, v2 -> v1 - v2 end)
    )
  end

  def can_build?(state, cost), do: Enum.all?(cost, fn {k, v} -> v <= state.resources[k] end)

  def add_resources(state, res),
    do: struct!(state, resources: Map.merge(state.resources, res, fn _k, v1, v2 -> v1 + v2 end))
end
```

## Day 20

[Code](day20/day20.exs) - [Problem description](https://adventofcode.com/2022/day/20)

We've pitched the yeast and it's time to aerate the wort, but we don't have any
mixing implements.  So we decide to mix it up by putting all of the wort in a
siphon tube with both ends connected, assigning a number to each drop of liquid,
and individually moving each droplet forward or backward through the circular
tube.  It is very important that we do not consider the droplet's old position
as a step when moving a droplet more than a full cycle through the tube.
In part one we do this mixing maneuver once, then add the numbers assigned to
the 1-, 2-, and 3000th droplets past the droplet with value 0.  In part 2 each
droplet value is multiplied by nearly one billion and then the mix process is
run ten times to ensure the yeast get plenty of oxygen for the aerobic phase.

This is the first problem where Elixir's lack of mutable data structures has
presented a problem.  Previously, the only mutation was modifying a cache, which
`ets` handled well.  Rather than lean on `ets` again I implemented a linked list
structure where each node was held by an
[Agent](https://elixir-lang.org/getting-started/mix-otp/agent.html).  Agents
keep state in a separate coroutine and respond to messages like `get` and
`update` by applying a caller-provided function, changing the state within that
coroutine, and sending a reply back with the result.  The code mostly looks a
lot like linked list code in a language with mutable data structures, but with
`Agent.get` and `Agent.update` wrappers.

The input file has 5,000, including many with absolute value greater than 5,000
but the total steps per iteration is reduced by taking the remainder, so assume
an average of 2,500 nodes are traversed times 5,000 traversals = 12,500,000
`Agent.get` calls spent on traversal.  (Updating a node takes a few more Agent
operations, but is only done 5,000 times.)  My solution takes roughly a minute
to run on part 1, which is a rate of about 200 node traversals per microsecond.
By contrast, I implemented this problem in Go with a mutable linked list
`type Node struct` and the whole of part 1 runs in about 23 milliseconds, over
half a million nodes per ms.  This is a significant overhead when processing a
lot of data represented as a lot of small agents!  I wonder if it would be
faster to skip the agents and recreate the whole linked list each time.

The recursive circular linked list structure is pretty simple.

```elixir
defmodule Node do
  defstruct value: nil, prev: nil, next: nil

  def new(value, prev, next) do
    {:ok, pid} = Agent.start_link(fn -> %Node{value: value, prev: prev, next: next} end)
    pid
  end

  def get(agent), do: Agent.get(agent, &Function.identity/1)

  def find(agent, 0), do: agent
  def find(agent, steps) when steps < 0, do: find(get(agent).prev, steps + 1)
  def find(agent, steps) when steps > 0, do: find(get(agent).next, steps - 1)

  def find_value(agent, val) do
    node = get(agent)
    if node.value === val, do: agent, else: find_value(node.next, val)
  end

  def set_prev(agent, prev), do: Agent.update(agent, fn node -> struct!(node, prev: prev) end)

  def set_next(agent, next), do: Agent.update(agent, fn node -> struct!(node, next: next) end)

  def insert(agent, left, right) do
    node = Node.get(agent)
    set_next(left, agent)
    set_prev(right, agent)
    set_next(agent, right)
    set_prev(agent, left)
    :ok
  end
end
```

## Day 21

[Code](day21/day21.exs) - [Problem description](https://adventofcode.com/2022/day/21)

We’re mixing a potion in a cauldron.  We’ve got a recipe with a lot of strange
ingredient names, but fortunately the gig economy spell prep delivery company
sent us nicely labeled packages of herbs.  The labels also say to stir
[widdershins or deosil](https://en.wikipedia.org/wiki/Widdershins), or increase
or decrease the rate of stirring.  In part 1 we count the total amount of
progress we’ve made in a sunwise direction.  In part 2 we figure out what the
stir count is for the satchel labeled “humn” so that we’ll make an equal number
of clockwise and counterclockwise turns, ensuring that the sun will return its
climb through the sky after this winter solstice day.

I initially implemented part 1 by having `parse_line` assign an anonymous
function to the `eval` property of a struct, with either the literal value or
a Kernel function reference combined with a lookup:

```elixir
func = case op do
  ?+ -> &+/2
  ?- -> &-/2
  ?* -> &*/2
  ?/ -> &div/2
end
%Op{name: name, eval: fn ctx -> func.(ctx[left], ctx[right]) end}
```

This doesn’t work for the second part because we need to inspect the expression
tree in order to solve for the unknown variable and the anonymous function hides
any information about what it’s using to make a computation.  Instead I switched
the `Op` struct to store the operation and two operands or the numeric value and
write an `evaluate` method that pattern matches on the operation, in the same
sort of way that an object-oriented language would have each Operation subclass
implement an `evaluate` method.

```elixir
defmodule Op do
  defstruct name: "", left: "", right: "", value: 0, operation: ?!

  def get_value(name, ctx), do: evaluate(ctx[name], ctx)

  def evaluate(%Op{operation: ?!, value: val}, _ctx), do: val
  def evaluate(%Op{operation: ?+} = op, ctx), do: binary_op(op, &+/2, ctx)
  def evaluate(%Op{operation: ?-} = op, ctx), do: binary_op(op, &-/2, ctx)
  def evaluate(%Op{operation: ?*} = op, ctx), do: binary_op(op, &*/2, ctx)
  def evaluate(%Op{operation: ?/} = op, ctx), do: binary_op(op, &div/2, ctx)

  defp binary_op(%Op{left: left, right: right}, func, ctx),
    do: func.(get_value(left, ctx), get_value(right, ctx))
end
```

## Day 22

[Code](day22/day22.exs) - [Problem description](https://adventofcode.com/2022/day/22)

We’ve made a barrel of our elixir, but our equipment wasn’t properly sanitized
so the batch is bad.  Rather than pouring it down the drain we decide to have
some fun with it.  We’ve got six
[tilt mazes](https://codepen.io/HunorMarton/pen/VwKwgxX) connected together
without walls around the edges so we decide to pour our work on the maze and see
where we can get it to flow.  In part one, when the liquid leaves a side of a
maze that’s not adjacent to another maze it wraps around horizontally or
vertically as if we were playing Pac-Man.  In part two, we form the six mazes
into a cube and the water flows as we turn the cube in 3D.  But we still need to
keep track of the 2D coordinates!

Solving this problem required repeatedly mapping 2D geometry into 3D while
running on three weeks of not enough sleep.  My cognitive style is somewhere
between [spatial visualizer and verbalizer](https://www.nmr.mgh.harvard.edu/mkozhevnlab/?page_id=639)
and I’m not a very effective object visualizer.  I can visualize geographic maps
and the complex links in a computation graph, but it takes me a lot of effort to
think about what happens when you move around a specific 3D obect.  I cut out
strips of sticky notes and affixed them to the faces of a Rubik’s Cube, each
with a number written on it.  I wrote the numbers out in a text file matching
the arrangement in the input file (which annoyingly isn’t the same arrangement
as the sample input) and then figured out which cube face, side, and direction
one would travel after moving off the edge of another face.
[I took a photo of the cube](https://photos.app.goo.gl/PCbuA7KC3diWJULz5) and
the text file follows.

```
    222 111
    222 111
    222 111

    333
    333
    333

555 444
555 444
555 444

666
666
666
```

I’m sure there’s a clever way to do the math to map to the matching side and
orientation, but I was also sure that I wouldn’t be able to to correctly derive
and implement it after three weeks of late nights.  So I decided to hard-code
the edge links, for both the example configuration and the actual one.  This
provided an opportunity to learn about [Enum.into](https://hexdocs.pm/elixir/Enum.html#into/2).
I’d read about it, but the reason to use `Enum.map(something) |> Enum.into(%{}`
instead of something like `Enum.map(something) |> Map.new` wasn’t clear.  The
advantage of `into` is that it adds to the existing structure without needing
to write an `Enum.reduce` which passes the in-progress map as an accumulator.

```elixir
wraps = %{}
# side 1 going right goes to 6 going left
wraps =
  Enum.map(1..4, fn row -> {{{row, 13}, @right}, {{13 - row, 16}, @left}} end) |> Enum.into(wraps)
# side 1 going up goes to 2 going down
wraps =
  Enum.map(9..12, fn col -> {{{0, col}, @up}, {{5, col - 5}, @down}} end) |> Enum.into(wraps)
# side 1 going left goes to 3 going down
wraps =
  Enum.map(1..4, fn row -> {{{row, 8}, @left}, {{5, 4 + row}, @down}} end) |> Enum.into(wraps)
```

This isn’t particularly elegant, but it made it easy to find the right thing to
change when I noticed the path drawn on a grid didn’t match expectations.  (Pro
tip: if the side of a cube face in your output doesn’t have any inbound arrows,
its matching edge is probably pointed at the wrong thing.)

## Day 23

[Code](day23/day23.exs) - [Problem description](https://adventofcode.com/2023/day/23)

The Kwik-E-Mart is out of [Skittlebrau](https://www.youtube.com/watch?v=tnHF11NsVFw)
so we’ll need to make our own.  We dump a bag of skittles into a pitcher of
American lager and notice that they all float at the top, clustered together.
As time passes, they move away from each other (positively charged candy!).
The way in which they spread has some surprising emergent properties: if the
spaces toward the bar are clear they head that direction.  If not, they might
head toward the pool table.  If not that, they head for the stage, or maybe the
exit.  But every second they seem to switch their preference order, swirling
around at the top of the pitcher.  In the first part we measure the area that’s
head foam, not occupied by Skittles.  In the second part we count the number of
seconds until the skittles stabilize.  This bug’s for you.

In the second part we need to perform an operation until reaching a stopping
condition, and count the number of times that happens.  In a typical imperative
language, that can easily be done with a loop counter:

```java
int countRounds() {
  State state = …;
  for (int round = 1; ; round++) {
    runRound(state);
    if (shouldStop(state)) { return round; }
  }
}
```

Earlier in the month I’ve done plenty of iterating through ranges when the
number of steps is known, as in part 1.

```elixir
points = Enum.reduce(1..10, points, fn round, points -> run_round(…) end)
```

And I’ve written recursive functions which increment a counter, like today’s
input parser.

```elixir
defp parse_input([line | rest], row, acc) do
  acc = String.to_charlist(line) |> Enum.with_index()
    |> Enum.filter(fn {c, _i} -> c == ?# end)
    |> Enum.map(fn {_, col} -> {row, col} end)
    |> Enum.into(acc)
  parse_input(rest, row + 1, acc)
end
```

And run a reduce function that didn’t care about a counter like
`Enum.reduce(Stream.cycle([nil]), acc, fn _, acc -> whatever(acc) end)`.
But I’m amused that it took until day 23 to need to figure out how to easily
count the number of times a loop runs.  The
[Stream.iterate](https://hexdocs.pm/elixir/Stream.html#iterate/2) function can
run any function repeatedly, taking the previous value as input.  Helpfully, the
example in the documentation is a counter that increments by one.

```elixir
Enum.reduce_while(Stream.iterate(1, &(&1 + 1)), points, fn round, points ->
  next = run_round(points, round_prefs(round, pref_cycle))
  if MapSet.equal?(points, next), do: {:halt, round}, else: {:cont, next}
end)
```

## Day 24
[Code](day24/day24.exs) - [Problem description](https://adventofcode.com/2022/day/24)

A jar of [kombucha](https://en.wikipedia.org/wiki/Kombucha) sits happily on the
counter with a thick [SCOBY](https://en.wikipedia.org/wiki/SCOBY) on top.
Clumps of bacteria and yeast are moving in straight lines, then quickly wrapping
around the jar, and moving along the same line again.  We drop a small tea leaf
at the edge and want to see how long it will take to get to the other side.  The
leaf can move through the liquid ‘booch but it’s blocked by the pellicle.  In
part 2 we want to know how long it takes to make one and a half round trips.

After realizing that my depth-first-search and naive breadth-first-search
implementations were generating lots of unhelpful states and unlikely to
terminate, I decided to implement a priority queue so I could use
[Dijkstra’s algorithm](https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm).
Elixir’s standard library doesn’t have a priority queue, so I decided to make
one from a Map, with keys as integer priorities (distance to the goal plus turn)
and values as a list of `{position, turn}` states with that priority.  I’d read
that Maps don’t have a defined order, but I’d also read that equality was based
on comparison and operations are O(log n), so I figured they were like a
`TreeMap` in Java and would iterate in sorted order.  So I implemented
`shift_next` (get an item from the queue with the lowest priority) using
`Enum.take(1)` to get the lowest priority item.  I then removed the item from
the list at that priority, or deleted the list entirely if it’s now empty.

```elixir
case Enum.take(pq, 1) do
  [{priority, [value]}] -> {priority, value, Map.delete(pq, priority)}
  [{priority, [value | rest]}] -> {priority, value, Map.put(pq, priority, rest)}
end
```

This worked, and I got the correct answer.  I then reasoned that I could
simplify it by using a MapSet of `{priority, value}` since Elixir sorts tuples
in order of their elements.

```elixir
[{priority, value} = first] = Enum.take(pq, 1)
{priority, value, MapSet.delete(pq, first)
```

But this got the wrong answer on the example and got stuck on the actual input.
The reason is because Elixir (via Erlang) Maps (and thus MapSets) are only
sorted [if they have 32 or fewer items](https://stackoverflow.com/questions/40392012/is-ordering-of-keys-and-values-preserved-in-elixir-when-you-operate-on-a-map).
When the structure grows larger, a different internal data structure is used to
be more efficient.  My Map-based priority queue had worked because the horizon
doesn’t expand very far during search: at each step it can only insert
priorities at most two greater than the current priority (one for the turn and
one for moving away from the target).  So the total number of items in the queue
could be in the thousands, but they’e all slotted away in lists for just a few
keys.  When I switched to a MapSet, this structure flattened out and Erlang
switched to a non-sorted data structure.

The solution is pretty simple, though: `Enum.min` still runs fast enough on a
small set of keys.

```elixir
case Enum.min(pq) do
  {priority, [value]} -> {priority, value, Map.delete(pq, priority)}
  {priority, [value | rest]} -> {priority, value, Map.put(pq, priority, rest)}
end
```
