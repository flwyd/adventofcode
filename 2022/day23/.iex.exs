import_file("../.iex.exs")
c("day23.exs")
daymod = Day23
exampletxt = "input.example.txt"
actualtxt = "input.actual.txt"
IO.puts("Run on #{exampletxt}: Runner.run(Day23, exampletxt) or Today.run_example")
IO.puts("Run on #{actualtxt}: Runner.run(Day23, actualtxt) or Today.run_actual")

defmodule Today do
  use InteractiveDay, Day23
end
