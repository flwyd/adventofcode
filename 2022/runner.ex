# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# Runner for Elixir Advent of Code solutions.
# Usage: elixir -r runner.ex day0/day0.exs day0/input*.txt

defmodule Runner do
  defmodule Result do
    defstruct outcome: :unknown, got: "", want: "", time_usec: 0

    def ok?(%Result{outcome: :fail}), do: false
    def ok?(%Result{}), do: true

    @outcome_colors %{
      success: :light_green_background,
      fail: :light_red_background,
      unknown: :light_yellow_background,
      todo: :cyan_background
    }
    @outcome_signs %{success: "✅", fail: "❌", unknown: "❓", todo: "❗"}
    def message(result) do
      outcome = Atom.to_string(result.outcome) |> String.upcase()
      sign = @outcome_signs[result.outcome]
      background = @outcome_colors[result.outcome]

      msg =
        case result do
          %Result{outcome: :success, got: got} -> "got #{got}"
          %Result{outcome: :fail, got: got, want: want} -> "got #{got}, want #{want}"
          %Result{outcome: :unknown, got: got} -> "got #{got}"
          %Result{outcome: :todo, want: ""} -> "implement it"
          %Result{outcome: :todo, want: want} -> "implement it, want #{want}"
        end

      IO.ANSI.format([sign, " ", background, :black, outcome, :reset, " ", msg])
    end
  end

  @doc """
  Parses argv as a command line and runs part1 and part2 of daymodule on each
  file in argv, or standard input if no files are given or any file is "-".
  Returns true if all parts  match their expected values for all files,
  otherwise returns false.  If `--verbose` or `-v` is present in argv,
  additional information like filenames, expected values, and timing will be
  printed to standard error.

  ## Examples:

    # Run against multiple files, print extra output
    iex> Runner.main(Day0, ~w[--verbose input.example.txt input.actual.txt])
    # Run against standard input, no extra output
    iex> Runner.main(Day0, [])
  """
  @spec main(module, [String.t()]) :: boolean
  def main(daymodule, argv) do
    {args, files} = OptionParser.parse!(argv, strict: [verbose: :boolean], aliases: [v: :verbose])
    verbose = Keyword.get(args, :verbose, false)
    files = if Enum.empty?(files), do: ["-"], else: files
    Enum.all?(Enum.map(files, &run(daymodule, &1, verbose)))
  end

  @doc """
  Reads input from file and passes it to :part1 and :part2 functions in
  daymodule.  Prints results.  Also checks for a companion .expected file and
  prints "SUCCESS" if the result matches, FAIL if it does not, "UNKNOWN" if the
  expected value is not yet set, and "TODO" if the function returned :todo.
  Returns true if no expected match failed, false otherwise.

  ## Examples

    iex> Runner.run(Day0, "day0/input.example.txt")
  """
  @spec run(module, String.t(), boolean) :: boolean
  def run(daymodule, file, verbose \\ true) do
    input = read_lines(file)
    expected = read_expected(file)

    outcomes =
      for part <- [:part1, :part2] do
        if verbose, do: IO.puts(:stderr, "Running #{daymodule} #{part} on #{file}")
        res = run_part(daymodule, part, input, Map.get(expected, part, ""))

        try do
          IO.puts("#{part}: #{res.got}")
        rescue
          Protocol.UndefinedError -> IO.inspect(res, label: part)
        end

        if verbose do
          IO.puts(:stderr, Result.message(res))
          IO.puts(:stderr, "#{part} took #{format_usec(res.time_usec)} on #{file}")
          IO.puts(:stderr, String.duplicate("=", 40))
        end

        Result.ok?(res)
      end

    Enum.all?(outcomes)
  end

  @doc """
  Runs function part of daymodule with the given iput and returns a
  Runner.Result based on the function's output and whether it matches want.

  ## Examples
      iex> Runner.run_part(Day0, :part1, ["123", "foo"], "42")
  """
  @spec run_part(module, atom, [String.t()], String.t()) :: Result.t()
  def run_part(daymodule, part, input, want) do
    {usec, got} = :timer.tc(daymodule, part, [input])

    outcome =
      cond do
        to_string(got) == to_string(want) -> :success
        got == :todo -> :todo
        want == "" -> :unknown
        true -> :fail
      end

    %Result{outcome: outcome, got: got, want: want, time_usec: usec}
  end

  @doc """
  Reads a file and splits it into a list of lines without trailing line breaks.
  If file is "-" reads from stdio.
  """
  @spec read_lines(String.t()) :: [String.t()]
  def read_lines(file) do
    case file do
      "" -> raise ArgumentError, "empty filename"
      "-" -> IO.stream()
      _ -> File.stream!(file)
    end
    |> Stream.map(&String.trim_trailing(&1, "\n"))
    |> Enum.to_list()
  end

  def read_expected(input_file) do
    file = Path.rootname(input_file, ".txt") <> ".expected"

    if File.exists?(file) do
      for line <- read_lines(file), String.starts_with?(line, "part") do
        [part, value] = String.split(line, ~r/:\s*/, parts: 2)
        {String.to_atom(part), value}
      end
      |> Map.new()
    else
      %{}
    end
  end

  defp format_usec(0), do: "0μs"
  defp format_usec(usec) when usec < 1000, do: "#{usec}μs"
  defp format_usec(usec) when usec < 1_000_000, do: "#{usec / 1000}ms"
  defp format_usec(usec) when usec < 60_000_000, do: "#{Float.round(usec / 1_000_000, 3)}s"
  defp format_usec(usec), do: "#{div(usec, 60_000_000)}:#{rem(div(usec, 1_000_000), 60)}"
end
