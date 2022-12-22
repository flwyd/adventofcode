import_file("../.iex.exs")
c("day22.exs")
daymod = Day22
exampletxt = "input.example.txt"
actualtxt = "input.actual.txt"
IO.puts("Run on #{exampletxt}: Runner.run(Day22, exampletxt) or Today.run_example")
IO.puts("Run on #{actualtxt}: Runner.run(Day22, actualtxt) or Today.run_actual")

defmodule Today do
  use InteractiveDay, Day22
end
