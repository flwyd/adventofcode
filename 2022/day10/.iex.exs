import_file("../.iex.exs")
c("day10.exs")
daymod = Day10
exampletxt = "input.example.txt"
actualtxt = "input.actual.txt"
IO.puts("Run on #{exampletxt}: Runner.run(Day10, exampletxt) or Today.run_example")
IO.puts("Run on #{actualtxt}: Runner.run(Day10, actualtxt) or Today.run_actual")

defmodule Today do
  use InteractiveDay, Day10
end
