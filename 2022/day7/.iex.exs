import_file("../.iex.exs")
c("day7.exs")
daymod = Day7
exampletxt = "input.example.txt"
actualtxt = "input.actual.txt"
IO.puts("Run on #{exampletxt}: Runner.run(Day7, exampletxt)")
IO.puts("Run on #{actualtxt}: Runner.run(Day7, actualtxt)")