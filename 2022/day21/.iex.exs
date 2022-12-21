import_file("../.iex.exs")
c("day21.exs")
daymod = Day21
exampletxt = "input.example.txt"
actualtxt = "input.actual.txt"
IO.puts("Run on #{exampletxt}: Runner.run(Day21, exampletxt) or Today.run_example")
IO.puts("Run on #{actualtxt}: Runner.run(Day21, actualtxt) or Today.run_actual")

defmodule Today do
  use InteractiveDay, Day21
end
