import_file("../.iex.exs")
c("day6.exs")
daymod = Day6
exampletxt = "input.example.txt"
actualtxt = "input.actual.txt"
IO.puts("Run on #{exampletxt}: Runner.run(Day6, exampletxt) or Today.run_example")
IO.puts("Run on #{actualtxt}: Runner.run(Day6, actualtxt) or Today.run_actual")

defmodule Today do
  use InteractiveDay, Day6
end
