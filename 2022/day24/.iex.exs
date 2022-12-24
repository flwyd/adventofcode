import_file("../.iex.exs")
c("day24.exs")
daymod = Day24
exampletxt = "input.example.txt"
actualtxt = "input.actual.txt"
IO.puts("Run on #{exampletxt}: Runner.run(Day24, exampletxt) or Today.run_example")
IO.puts("Run on #{actualtxt}: Runner.run(Day24, actualtxt) or Today.run_actual")

defmodule Today do
  use InteractiveDay, Day24
end
