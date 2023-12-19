### A Pluto.jl notebook ###
# v0.19.32

using Markdown
using InteractiveUtils

# ╔═╡ bdde2b35-6e47-449a-9869-589616828358
begin
  import Pkg
  Pkg.activate()
  try
    @eval using Revise
  catch e
    @warn "Need to install Revise?" exception=(e)
  end
  using Day19
  using Runner
  inputexample = "input.example.txt"
  inputactual = "input.actual.txt"
  run() = Runner.run_module(Day19, Runner.inputfiles(); verbose=true)
  println("Day19 ready, just run() or Day19.part1(readlines(inputexample))")
end

# ╔═╡ 2d83895d-e07c-49e6-b8c1-280643e42928
@doc Day19

# ╔═╡ 61d8598a-1edb-497e-99d3-40d42a314195
Runner.inputstats();

# ╔═╡ 93e6c848-6e8c-43ad-a5c5-7fb818da0270
struct Part
	x::Int
	m::Int
	a::Int
	s::Int
end

# ╔═╡ 49aefa1a-bb17-4ca8-80d1-eceeac9c6107
struct Workflow
	steps::Vector{Pair{Function,String}}
end

# ╔═╡ 3aee481f-cc77-4752-9284-2960494742d0
begin
	function parseinput(lines)
		values = String[]
		alwaystrue = _ -> true
		workflowlines = Iterators.takewhile(!isempty, lines)
		workflows = Dict(map(workflowlines) do line
			name, content = split(line, ['{', '}']; keepempty=false)
			name => Workflow(map(split(content, ",")) do chunk
				if ':' ∉ chunk
					alwaystrue => chunk
				else
					cond, dest = split(chunk, ':')
					varstr, opstr, valstr = match(r"([xmas])([<>])(\d+)", cond).captures
					var = Symbol(varstr)
					val = parse(Int, valstr)
					push!(values, "$varstr:$val")
					op = opstr == "<" ? <(val) : >(val)
					(p -> op(getproperty(p, var))) => dest
				end
			end)
		end)
		@show allunique(values)
		partlines = Iterators.dropwhile(!startswith("{"), lines)
		parts = map(partlines) do line
			x, m, a, s = parse.(Int, match(r"x=(\d+),m=(\d+),a=(\d+),s=(\d+)", line).captures)
			Part(x, m, a, s)
		end
		(workflows, parts)
		#Day19.parseinput(lines)
		#map(lines) do line
			#parse(Int, line)
			#if (m = match(r"^(\S+) (\S+)$", line)) !== nothing
			#  (foo, bar) = m.captures
			#end
		#end
	end
end;

# ╔═╡ f2cdc177-f754-4424-a5b5-952b532f2924
function evaluate(flows, p::Part)
	name = "in"
	while true
		#@show (name, p)
		if name == "A"
			return true
		end
		if name == "R"
			return false
		end
		for (predicate, dest) in flows[name].steps
			if predicate(p)
				name = dest
				break
			end
		end
	end
end

# ╔═╡ 991f8ff8-ef54-4a06-9c86-e0c7f6673d72
score(p::Part) = p.x + p.m + p.a + p.s

# ╔═╡ b92df61d-b2a9-455b-9354-6555e7c417fa
begin # Useful variables
	exampleexpected = Runner.expectedfor(inputexample)
	examplelines = readlines(inputexample)
	actualexpected = Runner.expectedfor(inputactual)
	actuallines = readlines(inputactual)
	inputa = parseinput(actuallines)
	input = parseinput(examplelines)
end

# ╔═╡ a1304fb6-0c2c-404c-8f70-581d3312cc65
(workflows, parts) = inputa

# ╔═╡ 973414d5-20ce-478b-900b-55fa93f1d645
typeof(workflows)

# ╔═╡ b7408874-1d24-42f1-94fe-d323bce559c5
evaluate(workflows, first(parts))

# ╔═╡ 346100c2-f9e9-4fd2-902f-c27cc2fef4d6
map(p -> evaluate(workflows, p) ? score(p) : 0, parts) |> sum

# ╔═╡ 3f144730-b915-4d8b-9fc3-2936e3ce88ac
length(workflows)

# ╔═╡ 4973b5f3-aa20-4488-b8fd-ae914bf9ed2d
md"## Results"

# ╔═╡ 378bfabd-f75d-4e20-864f-410d1e759042
Runner.run_module(Day19, [
inputexample,
inputactual,
], verbose=true)

# ╔═╡ Cell order:
# ╟─2d83895d-e07c-49e6-b8c1-280643e42928
# ╟─bdde2b35-6e47-449a-9869-589616828358
# ╠═61d8598a-1edb-497e-99d3-40d42a314195
# ╠═93e6c848-6e8c-43ad-a5c5-7fb818da0270
# ╠═49aefa1a-bb17-4ca8-80d1-eceeac9c6107
# ╠═3aee481f-cc77-4752-9284-2960494742d0
# ╠═f2cdc177-f754-4424-a5b5-952b532f2924
# ╠═991f8ff8-ef54-4a06-9c86-e0c7f6673d72
# ╠═b92df61d-b2a9-455b-9354-6555e7c417fa
# ╠═a1304fb6-0c2c-404c-8f70-581d3312cc65
# ╠═973414d5-20ce-478b-900b-55fa93f1d645
# ╠═b7408874-1d24-42f1-94fe-d323bce559c5
# ╠═346100c2-f9e9-4fd2-902f-c27cc2fef4d6
# ╠═3f144730-b915-4d8b-9fc3-2936e3ce88ac
# ╟─4973b5f3-aa20-4488-b8fd-ae914bf9ed2d
# ╠═378bfabd-f75d-4e20-864f-410d1e759042
