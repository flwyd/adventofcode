# Load runner library if it wasn't already
if !function_exported?(Runner, :__info__, 1) do
  c(Enum.find(~w[runner.ex ../runner.ex], &File.exists?/1))
end

# IEx convenience functions, implemented by Today modules.
defmodule InteractiveDay do
  defmacro __using__(daymod) do
    quote do
      def all_files() do
        case Path.wildcard("*.txt") do
          [] -> tap([], fn _ -> IO.puts(:stderr, "No .txt files in current directoy") end)
          ["input.actual.txt" = actual | rest] -> rest ++ [actual]
          files -> files
        end
      end

      def reload(), do: r(unquote(daymod))

      def run(files \\ all_files()) do
        Enum.map(files, fn f -> Runner.run(unquote(daymod), f) end)
      end

      def run_actual(), do: run(["input.actual.txt"])
      def run_example(), do: run(["input.example.txt"])

      def run_part(part, files \\ all_files()) do
        p = if is_atom(part), do: part, else: String.to_atom("part#{part}")

        for f <- List.wrap(files) do
          expect = Map.get(Runner.read_expected(f), p, "")
          res = Runner.run_part(unquote(daymod), p, Runner.read_lines(f), expect)
          IO.puts("#{Runner.Result.message(res)} on #{f}")
          res
        end
      end

      def part1(files \\ all_files()), do: run_part(:part1, files)
      def part2(files \\ all_files()), do: run_part(:part2, files)

      def lines(file), do: Runner.read_lines(file)

      def actual_lines(), do: lines("input.actual.txt")
      def example_lines(), do: lines("input.example.txt")

      def cat(file), do: Enum.map(lines(file), &IO.puts(:stderr, &1)) |> Enum.count()

      def lengths(files \\ Path.wildcard("*.txt")),
        do: Enum.map(files, fn f -> {f, Enum.count(Runner.read_lines(f))} end) |> Map.new()
    end
  end
end
