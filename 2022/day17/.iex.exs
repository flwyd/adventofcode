import_file("../.iex.exs")
c("day17.exs")
daymod = Day17
exampletxt = "input.example.txt"
actualtxt = "input.actual.txt"
IO.puts("Run on #{exampletxt}: Runner.run(Day17, exampletxt) or Today.run_example")
IO.puts("Run on #{actualtxt}: Runner.run(Day17, actualtxt) or Today.run_actual")

defmodule Today do
  use InteractiveDay, Day17
end
