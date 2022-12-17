import_file("../.iex.exs")
c("day1.exs")
daymod = Day1
exampletxt = "input.example.txt"
actualtxt = "input.actual.txt"
IO.puts("Run on #{exampletxt}: Runner.run(Day1, exampletxt) or Today.run_example")
IO.puts("Run on #{actualtxt}: Runner.run(Day1, actualtxt) or Today.run_actual")

defmodule Today do
  use InteractiveDay, Day1
end
