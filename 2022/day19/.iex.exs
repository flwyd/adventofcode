import_file("../.iex.exs")
c("day19.exs")
daymod = Day19
exampletxt = "input.example.txt"
actualtxt = "input.actual.txt"
IO.puts("Run on #{exampletxt}: Runner.run(Day19, exampletxt) or Today.run_example")
IO.puts("Run on #{actualtxt}: Runner.run(Day19, actualtxt) or Today.run_actual")

defmodule Today do
  use InteractiveDay, Day19
end
