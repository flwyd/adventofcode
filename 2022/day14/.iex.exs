import_file("../.iex.exs")
c("day14.exs")
daymod = Day14
exampletxt = "input.example.txt"
actualtxt = "input.actual.txt"
IO.puts("Run on #{exampletxt}: Runner.run(Day14, exampletxt) or Today.run_example")
IO.puts("Run on #{actualtxt}: Runner.run(Day14, actualtxt) or Today.run_actual")

defmodule Today do
  use InteractiveDay, Day14
end
