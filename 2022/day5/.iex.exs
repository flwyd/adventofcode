import_file("../.iex.exs")
c("day5.exs")
daymod = Day5
exampletxt = "input.example.txt"
actualtxt = "input.actual.txt"
IO.puts("Run on #{exampletxt}: Runner.run(Day5, exampletxt) or Today.run_example")
IO.puts("Run on #{actualtxt}: Runner.run(Day5, actualtxt) or Today.run_actual")

defmodule Today do
  use InteractiveDay, Day5
end
