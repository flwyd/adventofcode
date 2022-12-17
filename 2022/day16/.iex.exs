import_file("../.iex.exs")
c("day16.exs")
daymod = Day16
exampletxt = "input.example.txt"
actualtxt = "input.actual.txt"
IO.puts("Run on #{exampletxt}: Runner.run(Day16, exampletxt) or Today.run_example")
IO.puts("Run on #{actualtxt}: Runner.run(Day16, actualtxt) or Today.run_actual")

defmodule Today do
  use InteractiveDay, Day16
end
