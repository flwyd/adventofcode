import_file("../.iex.exs")
c("day18.exs")
daymod = Day18
exampletxt = "input.example.txt"
actualtxt = "input.actual.txt"
IO.puts("Run on #{exampletxt}: Runner.run(Day18, exampletxt) or Today.run_example")
IO.puts("Run on #{actualtxt}: Runner.run(Day18, actualtxt) or Today.run_actual")

defmodule Today do
  use InteractiveDay, Day18
end
