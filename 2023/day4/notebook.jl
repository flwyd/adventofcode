### A Pluto.jl notebook ###
# v0.19.32

using Markdown
using InteractiveUtils

# ╔═╡ dcaa944f-f331-49c0-834a-a953c7bf2387
begin
  import Pkg
  Pkg.activate()
  try
    @eval using Revise
  catch e
    @warn "Need to install Revise?" exception=(e)
  end
  using Day4
  using Runner
  inputexample = "input.example.txt"
  inputactual = "input.actual.txt"
  run() = Runner.run_module(Day4, Runner.inputfiles(); verbose=true)
  println("Day4 ready, just run() or Day4.part1(readlines(inputexample))")
end

# ╔═╡ d6d9f3fb-ae1f-4901-b60c-9369b49515f8
@doc Day4

# ╔═╡ 4cc4eed0-9cb1-4c9f-9c25-dae90d395849
Runner.inputstats();

# ╔═╡ 331b4ad2-9412-4b56-8278-9e50c70336b2
begin
function parseinput(lines)
  #Day4.parseinput(lines)
  map(lines) do line
    #parse(Int, line)
    if (m = match(r"^Card *(\d+): *((?:\d+\s*)+)\| *((?:\d+\s*)+)$", line)) !== nothing
      card, wins, have = m.captures
	  (parse(Int, card), parse.(Int, split(wins)), parse.(Int, split(have)))
	else
		:WTF
    end
  end
end
end;

# ╔═╡ 11e503c7-ba92-474e-b53b-08a81ab820ae
begin # Useful variables
exampleexpected = Runner.expectedfor(inputexample)
examplelines = readlines(inputexample)
input = parseinput(examplelines)
#input = parseinput(readlines(inputactual))
end

# ╔═╡ c98ec821-dcc1-4274-a290-166b13d861ea
scores = map(input) do card
	count = length(intersect(card[2], card[3]))
	count == 0 ? 0 : 2^(count-1)
end

# ╔═╡ 5d147234-df26-4363-8275-a963b72a7461
sum(scores)

# ╔═╡ 70e73793-2c19-4af9-8d47-7178afd7e054
copies = ones(Int, length(input))

# ╔═╡ 8a443aec-647a-4733-8738-9fd00032b79c
for (card, wins, have) in input
	count = length(intersect(wins, have))
	for i = 1:count
		copies[card + i] += copies[card]
	end
end

# ╔═╡ e58c4956-ae5e-499f-94e9-b14ca95aa673
sum(copies)

# ╔═╡ 7df5cfe5-8336-42eb-8748-5a571f2408dd
md"## Results"

# ╔═╡ a8cb9125-468e-4372-a11c-a045509c6eea
Runner.run_module(Day4, [
inputexample,
inputactual,
], verbose=true)

# ╔═╡ Cell order:
# ╟─d6d9f3fb-ae1f-4901-b60c-9369b49515f8
# ╟─dcaa944f-f331-49c0-834a-a953c7bf2387
# ╠═4cc4eed0-9cb1-4c9f-9c25-dae90d395849
# ╠═331b4ad2-9412-4b56-8278-9e50c70336b2
# ╠═11e503c7-ba92-474e-b53b-08a81ab820ae
# ╠═c98ec821-dcc1-4274-a290-166b13d861ea
# ╠═5d147234-df26-4363-8275-a963b72a7461
# ╠═70e73793-2c19-4af9-8d47-7178afd7e054
# ╠═8a443aec-647a-4733-8738-9fd00032b79c
# ╠═e58c4956-ae5e-499f-94e9-b14ca95aa673
# ╟─7df5cfe5-8336-42eb-8748-5a571f2408dd
# ╠═a8cb9125-468e-4372-a11c-a045509c6eea
