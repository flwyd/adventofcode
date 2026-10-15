#!/usr/bin/env elixir
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# Generates a directory with Elixir code from a template and empty input files.
# Usage: generate.exs day42

defmodule Generate do
  @template Path.join(__DIR__, "template.exs.eex")
  @iex Path.join(__DIR__, "iex.exs.eex")

  def into(daydir) do
    if !File.exists?(@template), do: abort("#{@template} not found")
    [daynum] = Regex.run(~r/\d+$/, daydir, capture: :first)
    exsfile = Path.join(daydir, "day#{daynum}.exs")
    iexfile = Path.join(daydir, ".iex.exs")
    if File.exists?(exsfile), do: abort("#{exsfile} already exists")
    IO.puts(:stderr, "Generating files in #{daydir}")
    absday = Path.absname(daydir)
    year = Path.dirname(absday)
    langdir = Path.relative_to(Path.relative_to_cwd(__DIR__), daydir, [:force])
    File.mkdir_p!(daydir)
    File.write!(exsfile, EEx.eval_file(@template, day_num: daynum, year: year,
      copy_date: Date.utc_today().year,
      runner_path: Path.join(langdir, "runner.ex")))
    File.chmod!(exsfile, 0o755)
    File.write!(iexfile, EEx.eval_file(@iex, day_num: daynum,
      main_iex: Path.join(langdir, ".iex.exs")))

    inputdir = Path.join(["..", "input", daynum])
    File.mkdir_p!(Path.join(daydir, inputdir))
    for f <- ~w[input.actual.txt input.actual.expected] do
      p = Path.join(daydir, f)
      if !File.exists?(p), do: File.ln_s!(Path.join(inputdir, f), p)
    end
    for base <- ~w[input.example input.actual] do
      txt = Path.join(daydir, base <> ".txt")
      if !File.exists?(txt), do: File.touch!(txt)
      expect = Path.join(daydir, base <> ".expected")
      if !File.exists?(expect), do: File.write!(expect, "part1:\npart2:\n")
    end
  end

  def abort(reason) do
    IO.puts(:stderr, reason)
    exit({:shutdown, 1})
  end
end

if Enum.empty?(System.argv()), do: Generate.abort("Usage: generate.exs day0")
Enum.map(System.argv(), &Generate.into/1)
