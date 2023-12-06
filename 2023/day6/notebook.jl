### A Pluto.jl notebook ###
# v0.19.32

using Markdown
using InteractiveUtils

# ╔═╡ 32ee4f20-769c-4327-bb7e-7553226b612c
begin
  import Pkg
  Pkg.activate()
  try
    @eval using Revise
  catch e
    @warn "Need to install Revise?" exception=(e)
  end
  using Day6
  using Runner
  inputexample = "input.example.txt"
  inputactual = "input.actual.txt"
  run() = Runner.run_module(Day6, Runner.inputfiles(); verbose=true)
  println("Day6 ready, just run() or Day6.part1(readlines(inputexample))")
end

# ╔═╡ b5b1fe65-ea27-4f52-9b66-50ef75c6a8eb
@doc Day6

# ╔═╡ e3fdf101-5625-4d87-b403-be6664822486
Runner.inputstats();

# ╔═╡ 7f7d292c-c423-4282-84f1-2ea971f65224
begin
	function parseinput(lines)
		times = parse.(Int, split(chopprefix(lines[1], "Time:")))
		dists = parse.(Int, split(chopprefix(lines[2], "Distance:")))
		(times, dists)
		#Day6.parseinput(lines)
		#map(lines) do line
			#parse(Int, line)
			#if (m = match(r"^(\S+) (\S+)$", line)) !== nothing
			#  (foo, bar) = m.captures
			#end
		#end
	end

	function winning_moves(time, dist)
		1:time-1 |> filter(i -> (time-i)*i > dist)
	end
end;

# ╔═╡ 7b52dca3-4742-4520-b0d3-82c2ee0b669b
begin # Useful variables
	exampleexpected = Runner.expectedfor(inputexample)
	examplelines = readlines(inputexample)
	actualexpected = Runner.expectedfor(inputactual)
	actuallines = readlines(inputactual)
	inputa = parseinput(actuallines)
	input = parseinput(examplelines)
	times, dists = input
end

# ╔═╡ 4d927a1b-3ded-4e4a-a93e-f20559157298
prod([winning_moves.(x, y) |> length for (x, y) in zip(times, dists)])

# ╔═╡ 06b6dfa5-8778-45c9-908d-965f424513ed
bigtime, bigdist = parse(Int, join(times, "")), parse(Int, join(dists, ""))

# ╔═╡ e3b0b3a4-230a-4858-a349-c26751cb25c5
length(winning_moves(bigtime, bigdist))

# ╔═╡ a0311d37-1a8e-41ac-8a18-0973bc610432
md"## Results"

# ╔═╡ 042d9107-1a2c-43ad-ad9b-a162a6d0a56b
Runner.run_module(Day6, [
inputexample,
inputactual,
], verbose=true)

# ╔═╡ Cell order:
# ╟─b5b1fe65-ea27-4f52-9b66-50ef75c6a8eb
# ╟─32ee4f20-769c-4327-bb7e-7553226b612c
# ╠═e3fdf101-5625-4d87-b403-be6664822486
# ╠═7f7d292c-c423-4282-84f1-2ea971f65224
# ╠═7b52dca3-4742-4520-b0d3-82c2ee0b669b
# ╠═4d927a1b-3ded-4e4a-a93e-f20559157298
# ╠═06b6dfa5-8778-45c9-908d-965f424513ed
# ╠═e3b0b3a4-230a-4858-a349-c26751cb25c5
# ╟─a0311d37-1a8e-41ac-8a18-0973bc610432
# ╠═042d9107-1a2c-43ad-ad9b-a162a6d0a56b
