import_file("../.iex.exs")
c("day2.exs")
daymod = Day2
exampletxt = "input.example.txt"
actualtxt = "input.actual.txt"
IO.puts("Run on #{exampletxt}: Runner.run(Day2, exampletxt) or Today.run_example")
IO.puts("Run on #{actualtxt}: Runner.run(Day2, actualtxt) or Today.run_actual")

defmodule Today do
  use InteractiveDay, Day2
end
