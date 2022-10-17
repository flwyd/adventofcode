# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# Runner for Elixir Advent of Code solutions.
# Usage: elixir -r runner.ex day0/day0.exs day0/input*.txt

defmodule Runner do
  @doc """
  Reads input from file and passes it to :part1 and :part2 functions in
  daymodule.  Prints results.  Also checks for a companion .expected file and
  prints SUCCESS if the result matches, FAIL if it does not, MAYBE if the
  expected value is not yet set, and TODO if the function returned TODO.
  Returns true if no expected match failed, false otherwise.

  ## Examples

    iex> Runner.run(Day0, "day0/input.example.txt")
  """
  def run(daymodule, file) do
    input =
      File.stream!(file)
      |> Stream.map(&String.trim_trailing(&1, "\n"))
      |> Enum.to_list()

    expected = read_expected(file)

    outcomes =
      for part <- [:part1, :part2] do
        IO.puts("Running #{daymodule} #{part} on #{file}")
        {usec, res} = :timer.tc(daymodule, part, [input])
        IO.inspect(res)

        {got, want} = {to_string(res), Map.get(expected, part, "")}

        {outcome, message} =
          cond do
            got == want -> {true, "SUCCESS"}
            res == :todo -> {true, "TODO implement #{part}"}
            want == "" -> {true, "MAYBE"}
            true -> {false, "FAIL want #{want}"}
          end

        IO.puts(message)
        IO.puts("#{part} took #{usec}μs on #{file}")
        IO.puts(String.duplicate("=", 40))
        outcome
      end

    Enum.all?(outcomes)
  end

  defp read_expected(input_file) do
    file = Path.rootname(input_file, ".txt") <> ".expected"

    # .expected files have lines like "part1: value".  This is valid YAML, but
    # parsing YAML would require an external dependency to read a simple file.
    case File.read(file) do
      {:ok, data} ->
        Regex.scan(~r/(?<part>part\d+):\s*(?<value>.*)/, data, capture: :all_but_first)
        |> Enum.map(&List.to_tuple/1)
        |> Enum.map(fn {part, value} -> {String.to_atom(part), value} end)
        |> Map.new()

      {:error, _err} ->
        %{}
    end
  end
end
