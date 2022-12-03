import_file("../.iex.exs")
c("day3.exs")
daymod = Day3
exampletxt = "input.example.txt"
actualtxt = "input.actual.txt"
IO.puts("Run on #{exampletxt}: Runner.run(Day3, exampletxt)")
IO.puts("Run on #{actualtxt}: Runner.run(Day3, actualtxt)")
