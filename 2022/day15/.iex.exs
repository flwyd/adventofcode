import_file("../.iex.exs")
c("day15.exs")
daymod = Day15
exampletxt = "input.example.txt"
actualtxt = "input.actual.txt"
IO.puts("Run on #{exampletxt}: Runner.run(Day15, exampletxt) or Today.run_example")
IO.puts("Run on #{actualtxt}: Runner.run(Day15, actualtxt) or Today.run_actual")

defmodule Today do
  use InteractiveDay, Day15
end
