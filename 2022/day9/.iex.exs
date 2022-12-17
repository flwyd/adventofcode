import_file("../.iex.exs")
c("day9.exs")
daymod = Day9
exampletxt = "input.example.txt"
actualtxt = "input.actual.txt"
IO.puts("Run on #{exampletxt}: Runner.run(Day9, exampletxt) or Today.run_example")
IO.puts("Run on #{actualtxt}: Runner.run(Day9, actualtxt) or Today.run_actual")

defmodule Today do
  use InteractiveDay, Day9
end
