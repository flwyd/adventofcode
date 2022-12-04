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

[Day 1](#day-1)
[Day 2](#day-2)
[Day 3](#day-3)

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
