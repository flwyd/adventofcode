import_file("../.iex.exs")
c("day4.exs")
daymod = Day4
exampletxt = "input.example.txt"
actualtxt = "input.actual.txt"
IO.puts("Run on #{exampletxt}: Runner.run(Day4, exampletxt) or Today.run_example")
IO.puts("Run on #{actualtxt}: Runner.run(Day4, actualtxt) or Today.run_actual")

defmodule Today do
  use InteractiveDay, Day4
end
