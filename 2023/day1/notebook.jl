### A Pluto.jl notebook ###
# v0.19.32

using Markdown
using InteractiveUtils

# ╔═╡ 0d3d6ef6-e0aa-4598-88db-b75be049b2cc
begin
  import Pkg
  Pkg.activate()
  try
    @eval using Revise
  catch e
    @warn "Need to install Revise?" exception=(e)
  end
  using Day1
  using Runner
  inputexample = "input.example.txt"
  inputactual = "input.actual.txt"
  run() = Runner.run_module(Day1, Runner.inputfiles(); verbose=true)
  println("Day1 ready, just run() or Day1.part1(readlines(inputexample))")
end

# ╔═╡ 5c30aead-7028-4fbd-bcb2-3da548678a43
@doc Day1

# ╔═╡ 1e71de92-fe9c-4d48-aae0-0bb2aa9e19e4
Runner.inputstats();

# ╔═╡ 52fe8e4f-23e5-454b-8970-ab6b55c8ccd5
begin
function parseinput(lines)
  map(lines) do line
    s = filter(isdigit, line)
    isempty(s) ? 0 : parse(Int, string(first(s), last(s)))
  end
end

function parseinput2(lines)
	map(lines) do line
	r = replace(line,  "one" => "1",
	  "two" => "2",
	  "three" => "3",
	  "four" => "4",
	  "five" => "5",
	  "six" => "6",
	  "seven" => "7",
	  "eight" => "8",
	  "nine" => "9")
    s = filter(isdigit, r)
	parse(Int, string(first(s), last(s)))
  end
end

end;

# ╔═╡ 3f26a036-515e-4710-9d75-1df1c52be234
begin # Useful variables
inputexample2 = "input.example2.txt"
exampleexpected = Runner.expectedfor(inputexample)
example2expected = Runner.expectedfor(inputexample2)
examplelines = readlines(inputexample)
example2lines = readlines(inputexample2)
actuallines = readlines(inputactual)
input = parseinput(examplelines)
input2 = parseinput2(example2lines)
end

# ╔═╡ eefdea8e-434c-4e36-abfd-2b8c75bdacce
[sum(parseinput(x)) for x in (examplelines, example2lines, actuallines)]

# ╔═╡ 8969c633-a7ee-4b3a-bf40-5a3713ad63b9
[sum(parseinput2(x)) for x in (examplelines, example2lines, actuallines)]

# ╔═╡ 00d6ae54-cf1f-4361-ab4a-b451f16f11f9
md"## Results"

# ╔═╡ 72cd8fb4-1ecb-45d7-9a66-f5f26a852843
Runner.run_module(Day1, [
inputexample,
inputexample2,
inputactual,
], verbose=true)

# ╔═╡ Cell order:
# ╟─5c30aead-7028-4fbd-bcb2-3da548678a43
# ╟─0d3d6ef6-e0aa-4598-88db-b75be049b2cc
# ╠═1e71de92-fe9c-4d48-aae0-0bb2aa9e19e4
# ╠═52fe8e4f-23e5-454b-8970-ab6b55c8ccd5
# ╠═3f26a036-515e-4710-9d75-1df1c52be234
# ╠═eefdea8e-434c-4e36-abfd-2b8c75bdacce
# ╠═8969c633-a7ee-4b3a-bf40-5a3713ad63b9
# ╟─00d6ae54-cf1f-4361-ab4a-b451f16f11f9
# ╠═72cd8fb4-1ecb-45d7-9a66-f5f26a852843
