import_file("../.iex.exs")
c("day3.exs")
daymod = Day3
exampletxt = "input.example.txt"
actualtxt = "input.actual.txt"
IO.puts("Run on #{exampletxt}: Runner.run(Day3, exampletxt) or Today.run_example")
IO.puts("Run on #{actualtxt}: Runner.run(Day3, actualtxt) or Today.run_actual")

defmodule Today do
  use InteractiveDay, Day3
end
