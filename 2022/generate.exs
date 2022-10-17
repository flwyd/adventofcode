#!/usr/bin/env elixir
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# Generates a directory with Elixir code from a template and empty input files.
# Usage: generate.exs day42

defmodule Generate do
  @template Path.dirname(__ENV__.file) |> Path.join("template.exs.eex")

  def into(daydir) do
    if !File.exists?(@template), do: Generate.abort("#{@template} not found")
    [daynum] = Regex.run(~r/\d+$/, daydir, capture: :first)
    exsfile = Path.join(daydir, "day#{daynum}.exs")
    if File.exists?(exsfile), do: abort("#{exsfile} already exists")
    File.mkdir_p!(daydir)
    File.write!(exsfile, EEx.eval_file(@template, day_num: daynum))
    File.chmod!(exsfile, 0o755)

    for base <- ~w[input.example input.actual] do
      for ext <- ~w[.txt .expected] do
        File.touch!(Path.join(daydir, base <> ext))
      end
    end
  end

  def abort(reason) do
    IO.puts(:stderr, reason)
    exit({:shutdown, 1})
  end
end

if Enum.empty?(System.argv()), do: Generate.abort("Usage: generate.exs day0")
Enum.map(System.argv(), &Generate.into/1)
