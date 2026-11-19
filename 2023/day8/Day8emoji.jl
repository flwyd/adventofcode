#!/usr/bin/env julia
# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

"""# Advent of Code 2023 day 8
[Read the puzzle](https://adventofcode.com/2023/day/8)

Variation of Day8.jl where all identifiers under my control are emoji.
This meets the [Reddit day 8 solutions megathread ALLEZ CUISINE
challenge](https://www.reddit.com/r/adventofcode/comments/18df7px/2023_day_8_solutions/).
"""
module Day8

function part1(📜)
  # exaample3 doesn't have AAA/ZZZ
  🆗 = any(startswith("AAA ="), 📜)
  🖥(📜, ==(🆗 ? "AAA" : "11A"), ==(🆗 ? "ZZZ" : "11Z"))
end

part2(📜) = 🖥(📜, endswith('A'), endswith('Z'))

function 🖥(📜, ▶️, ⏹️)
  🦶, 🗺 = 🍴(📜)
  📏 = length(📜[1])
  🪣 = collect(keys(🗺) |> filter(▶️))
  🛞 = zeros(Int, length(🪣))
  🧮 = 0
  for 🤝 in 🦶
    if 🧮 % 📏 == 0
      for (👁, ⛳) in enumerate(🛞)
        if ⛳ == 0 && ⏹️(🪣[👁])
          🛞[👁] = 🧮
        end
      end
      all(>(0), 🛞) && return lcm(🛞)
    end
    🧮 += 1
    🪣 = [🗺[🚪][🤝 == 'L' ? 1 : 2] for 🚪 in 🪣]
  end
end

function 🍴(📜)
  🦶 = Iterators.cycle([🤝 for 🤝 in 📜[1]])
  🗺 = Dict{AbstractString, Tuple{String, String}}()
  map(📜) do ✏
    if (🔱 = match(r"^(\w+) = \((\w+), (\w+)\)$", ✏)) !== nothing
      🤲, 🫲, 🫱 = 🔱.captures
      🗺[🤲] = (🫲, 🫱)
    end
  end
  🦶, 🗺
end

push!(Base.LOAD_PATH, joinpath(dirname(PROGRAM_FILE), "../../lang/julia"))
using Runner
@Runner.run_if_main
end
