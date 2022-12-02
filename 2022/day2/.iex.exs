import_file("../.iex.exs")
c("day2.exs")
daymod = Day2
exampletxt = "input.example.txt"
actualtxt = "input.actual.txt"
IO.puts("Run on #{exampletxt}: Runner.run(Day2, exampletxt)")
IO.puts("Run on #{actualtxt}: Runner.run(Day2, actualtxt)")
