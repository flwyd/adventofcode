### A Pluto.jl notebook ###
# v0.19.32

using Markdown
using InteractiveUtils

# ╔═╡ 8dde9b21-6dbb-400b-85ea-4c519724476a
begin
  import Pkg
  Pkg.activate()
  try
    @eval using Revise
  catch e
    @warn "Need to install Revise?" exception=(e)
  end
  using Day9
  using Runner
  inputexample = "input.example.txt"
  inputactual = "input.actual.txt"
  run() = Runner.run_module(Day9, Runner.inputfiles(); verbose=true)
  println("Day9 ready, just run() or Day9.part1(readlines(inputexample))")
end

# ╔═╡ 5adbb715-16b6-4786-b42c-f7792ba9639e
@doc Day9

# ╔═╡ 643c4a2c-70c4-447c-95b8-0d0c09d7fbf8
Runner.inputstats();

# ╔═╡ 00b95ce7-ede3-40a0-addc-bbc8abb60b4f
begin
	function parseinput(lines)
		#Day9.parseinput(lines)
		map(lines) do line
			parse.(Int, split(line))
			#if (m = match(r"^(\S+) (\S+)$", line)) !== nothing
			#  (foo, bar) = m.captures
			#end
		end
	end
end;

# ╔═╡ 342bff06-ddbc-4d42-a258-14746d8ae11a
	function nextnums(nums)
		if all(==(nums[1]), nums)
			nums[1] #, [nums[1]]
		else
			nums[end] + nextnums(nums[2:end] - nums[1:end-1])
			#nums[end] + next, push!(chain, nums[end] + next)
		end
	end

# ╔═╡ 717c5cce-aad3-4f68-b6ad-f47a8eb06494
begin # Useful variables
	exampleexpected = Runner.expectedfor(inputexample)
	examplelines = readlines(inputexample)
	actualexpected = Runner.expectedfor(inputactual)
	actuallines = readlines(inputactual)
	inputa = parseinput(actuallines)
	input = parseinput(examplelines)
end

# ╔═╡ fd63c1e6-e1c1-4108-9de5-66a73cfb2c86
map(nextnums, inputa) |> sum

# ╔═╡ b9de6478-792f-4648-a6c6-3c621ec8bab7
	function prevnums(nums)
		if all(==(nums[1]), nums)
			nums[1] #, [nums[1]]
		else
			nums[1] - prevnums(nums[2:end] - nums[1:end-1])
			#nums[end] + next, push!(chain, nums[end] + next)
		end
	end

# ╔═╡ abee6d1d-e8db-4177-8926-296942d4b32d
map(prevnums, inputa) |> sum

# ╔═╡ bdd2b602-e329-48a7-9fb9-3e693fe8058f
md"## Results"

# ╔═╡ ea296a8c-c45a-458c-9b70-007e1670d4f9
Runner.run_module(Day9, [
inputexample,
inputactual,
], verbose=true)

# ╔═╡ Cell order:
# ╟─5adbb715-16b6-4786-b42c-f7792ba9639e
# ╟─8dde9b21-6dbb-400b-85ea-4c519724476a
# ╠═643c4a2c-70c4-447c-95b8-0d0c09d7fbf8
# ╠═00b95ce7-ede3-40a0-addc-bbc8abb60b4f
# ╠═342bff06-ddbc-4d42-a258-14746d8ae11a
# ╠═717c5cce-aad3-4f68-b6ad-f47a8eb06494
# ╠═fd63c1e6-e1c1-4108-9de5-66a73cfb2c86
# ╠═b9de6478-792f-4648-a6c6-3c621ec8bab7
# ╠═abee6d1d-e8db-4177-8926-296942d4b32d
# ╟─bdd2b602-e329-48a7-9fb9-3e693fe8058f
# ╠═ea296a8c-c45a-458c-9b70-007e1670d4f9
