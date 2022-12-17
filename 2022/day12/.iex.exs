import_file("../.iex.exs")
c("day12.exs")
daymod = Day12
exampletxt = "input.example.txt"
actualtxt = "input.actual.txt"
IO.puts("Run on #{exampletxt}: Runner.run(Day12, exampletxt) or Today.run_example")
IO.puts("Run on #{actualtxt}: Runner.run(Day12, actualtxt) or Today.run_actual")

defmodule Today do
  use InteractiveDay, Day12
end
