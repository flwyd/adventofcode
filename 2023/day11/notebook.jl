### A Pluto.jl notebook ###
# v0.19.32

using Markdown
using InteractiveUtils

# ╔═╡ d6328f3e-a4aa-45ae-950e-5180749a3940
begin
  import Pkg
  Pkg.activate()
  try
    @eval using Revise
  catch e
    @warn "Need to install Revise?" exception=(e)
  end
  using Day11
  using Runner
  inputexample = "input.example.txt"
  inputactual = "input.actual.txt"
  run() = Runner.run_module(Day11, Runner.inputfiles(); verbose=true)
  println("Day11 ready, just run() or Day11.part1(readlines(inputexample))")
end

# ╔═╡ dcc44782-d1f5-4d3e-841c-a3a1442aa2e8
@doc Day11

# ╔═╡ f08133f4-1607-4090-9a7e-e01ce43aa98a
Runner.inputstats();

# ╔═╡ 3b692962-f04b-452f-bc48-3b9dd8cb1a48
begin
	function parseinput(lines)
		reduce(hcat, [collect(line) for line in lines])
		#Day11.parseinput(lines)
		#map(lines) do line
			#parse(Int, line)
			#if (m = match(r"^(\S+) (\S+)$", line)) !== nothing
			#  (foo, bar) = m.captures
			#end
		#end
	end
end;

# ╔═╡ 7ab433c0-00ed-4ef6-bdc8-7a755ad67673
begin # Useful variables
	exampleexpected = Runner.expectedfor(inputexample)
	examplelines = readlines(inputexample)
	actualexpected = Runner.expectedfor(inputactual)
	actuallines = readlines(inputactual)
	input = parseinput(actuallines)
	inpute = parseinput(examplelines)
end

# ╔═╡ 7b8b8189-3617-42c8-9a90-6cb6c763f753
galaxies = findall(==('#'), input)

# ╔═╡ 732de456-a98a-4ddf-910b-f2a1731fe7e5
emptyrows = findall(x -> all(==('.'), x), eachrow(input))

# ╔═╡ eb1539da-d3d5-4b9e-810d-04e91abce637
emptycols = findall(x -> all(==('.'), x), eachcol(input))

# ╔═╡ 3358919d-fd0b-4073-a5aa-c64d9746db50
function dist(a, b)
	arow, acol = Tuple(a)
	brow, bcol = Tuple(b)
	width = abs(bcol - acol) + 1_000_000 * length((min(acol, bcol):max(acol, bcol)) ∩ emptycols)
	height = abs(brow - arow) + 1_000_000 * length((min(arow, brow):max(arow, brow)) ∩ emptyrows)
	width + height
end

# ╔═╡ 5049b867-f338-46e3-81ec-4e22ef06101e
dists = reduce(vcat, map(i -> [dist(galaxies[i], x) for x in galaxies[i+1:end]], eachindex(galaxies)))

# ╔═╡ 8edf92d5-efab-4f44-983e-af59c0940336
sum(dists)

# ╔═╡ 87b11dd5-c2fd-4c64-8b8b-bd48d830adc0
md"## Results"

# ╔═╡ cbadd45d-ae90-45b8-adcb-a6adf729b76e
Runner.run_module(Day11, [
inputexample,
inputactual,
], verbose=true)

# ╔═╡ Cell order:
# ╟─dcc44782-d1f5-4d3e-841c-a3a1442aa2e8
# ╟─d6328f3e-a4aa-45ae-950e-5180749a3940
# ╠═f08133f4-1607-4090-9a7e-e01ce43aa98a
# ╠═3b692962-f04b-452f-bc48-3b9dd8cb1a48
# ╠═7ab433c0-00ed-4ef6-bdc8-7a755ad67673
# ╠═7b8b8189-3617-42c8-9a90-6cb6c763f753
# ╠═732de456-a98a-4ddf-910b-f2a1731fe7e5
# ╠═eb1539da-d3d5-4b9e-810d-04e91abce637
# ╠═3358919d-fd0b-4073-a5aa-c64d9746db50
# ╠═5049b867-f338-46e3-81ec-4e22ef06101e
# ╠═8edf92d5-efab-4f44-983e-af59c0940336
# ╟─87b11dd5-c2fd-4c64-8b8b-bd48d830adc0
# ╠═cbadd45d-ae90-45b8-adcb-a6adf729b76e
