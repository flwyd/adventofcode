import_file("../.iex.exs")
c("day25.exs")
daymod = Day25
exampletxt = "input.example.txt"
actualtxt = "input.actual.txt"
IO.puts("Run on #{exampletxt}: Runner.run(Day25, exampletxt) or Today.run_example")
IO.puts("Run on #{actualtxt}: Runner.run(Day25, actualtxt) or Today.run_actual")

defmodule Today do
  use InteractiveDay, Day25
end
