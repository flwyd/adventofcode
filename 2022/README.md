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

_Elixir thoughts coming soon._

## Day 9

[Code](day9/day9.exs) - [Problem description](https://adventofcode.com/2022/day/9)

The elves are throwing a TGIF party with a beer bong made out of one of those
[expandable plastic
tubes](https://webstore.cdlusa.net/content/images/thumbs/0002247_clear-flexible-vacuum-hoses_550.jpeg).
At first it's a really short path from the funnel, but then you pull on the
hose and discover that it's pretty long. The elves wander around the room with
the funnel, and you need to keep up. What path do you follow?

_Elixir thoughts coming soon._

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
iex> %Day10.Raster{rows: rows} = Day10.part2(Runner.read_lines("input.example.txt”))
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
