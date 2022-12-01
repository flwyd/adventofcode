import_file("../.iex.exs")
c("day1.exs")
daymod = Day1
exampletxt = "input.example.txt"
actualtxt = "input.actual.txt"
IO.puts("Run on #{exampletxt}: Runner.run(Day1, exampletxt)")
IO.puts("Run on #{actualtxt}: Runner.run(Day1, actualtxt)")
