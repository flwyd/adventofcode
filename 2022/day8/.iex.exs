import_file("../.iex.exs")
c("day8.exs")
daymod = Day8
exampletxt = "input.example.txt"
actualtxt = "input.actual.txt"
IO.puts("Run on #{exampletxt}: Runner.run(Day8, exampletxt) or Today.run_example")
IO.puts("Run on #{actualtxt}: Runner.run(Day8, actualtxt) or Today.run_actual")

defmodule Today do
  use InteractiveDay, Day8
end
