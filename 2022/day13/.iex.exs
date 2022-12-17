import_file("../.iex.exs")
c("day13.exs")
daymod = Day13
exampletxt = "input.example.txt"
actualtxt = "input.actual.txt"
IO.puts("Run on #{exampletxt}: Runner.run(Day13, exampletxt) or Today.run_example")
IO.puts("Run on #{actualtxt}: Runner.run(Day13, actualtxt) or Today.run_actual")

defmodule Today do
  use InteractiveDay, Day13
end
