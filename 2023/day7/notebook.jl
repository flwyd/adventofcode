### A Pluto.jl notebook ###
# v0.19.32

using Markdown
using InteractiveUtils

# ╔═╡ b7cfc1a8-e1f5-41bb-bf6a-92455880a64c
begin
  import Pkg
  Pkg.activate()
  try
    @eval using Revise
  catch e
    @warn "Need to install Revise?" exception=(e)
  end
  using Day7
  using Runner
  inputexample = "input.example.txt"
  inputactual = "input.actual.txt"
  run() = Runner.run_module(Day7, Runner.inputfiles(); verbose=true)
  println("Day7 ready, just run() or Day7.part1(readlines(inputexample))")
end

# ╔═╡ e7c966af-df5a-432b-9e68-de26e6f922b3
@doc Day7

# ╔═╡ ce38d3f7-4ff2-427a-a11c-c2a8b5bf23a6
Runner.inputstats();

# ╔═╡ 882640ce-e523-485e-8c0e-77dfb401beb7
begin
	#primitive type Card <: Char 32 end
	struct Card
		value::Char
	end

	const ORDER = "AKQJT98765432"
	function Base.isless(a::Card, b::Card)
		less(findfirst(a.value, ORDER), findfirst(b.value, ORDER))
	end
	
	struct Hand
		cards::Vector{Card}
		bid::Int
	end

	function handtype(h::Hand)
		sort([count(==(i), h.cards) for i in unique(h.cards)]; rev=true) |> filter(!=(1))
	end

	function Base.isless(a::Hand, b::Hand)
    haa = handtype(a)
    hab = handtype(b)
    if haa == hab
      a.cards < b.cards
    else
      handtype(a) < handtype(b)
    end
	end
	
	function parseinput(lines)
		#Day7.parseinput(lines)
		map(lines) do line
			cards, bid = split(line)	
			Hand([Card(c) for c in cards], parse(Int, bid))
			#parse(Int, line)
			#if (m = match(r"^(\S+) (\S+)$", line)) !== nothing
			#  (foo, bar) = m.captures
			#end
		end
	end
end;

# ╔═╡ 9169dacb-f863-4391-9c99-6aab4d0ff2cd
begin # Useful variables
	exampleexpected = Runner.expectedfor(inputexample)
	examplelines = readlines(inputexample)
	actualexpected = Runner.expectedfor(inputactual)
	actuallines = readlines(inputactual)
	inputa = parseinput(actuallines)
	input = parseinput(examplelines)
end

# ╔═╡ ceaa6626-ed11-4238-9638-d942f0572949
sortedhands = sort(input)

# ╔═╡ 49d8dc47-0788-4575-811e-240dc05a746c
sum(map(ib -> first(ib) * last(ib),  enumerate(map(h -> h.bid, sort(input)))))

# ╔═╡ 0cc923a9-6a9c-4cd8-b69e-b513f56d2b34


# ╔═╡ 78cdc828-c051-4ab9-a7f2-1cdfd6124b90
map(handtype, input)

# ╔═╡ d31bf92b-d5f8-48dd-b8b5-ac0206488239
md"## Results"

# ╔═╡ 0ec76517-fd06-4de4-9354-01184f0db03d
Runner.run_module(Day7, [
inputexample,
inputactual,
], verbose=true)

# ╔═╡ Cell order:
# ╟─e7c966af-df5a-432b-9e68-de26e6f922b3
# ╟─b7cfc1a8-e1f5-41bb-bf6a-92455880a64c
# ╠═ce38d3f7-4ff2-427a-a11c-c2a8b5bf23a6
# ╠═882640ce-e523-485e-8c0e-77dfb401beb7
# ╠═9169dacb-f863-4391-9c99-6aab4d0ff2cd
# ╠═ceaa6626-ed11-4238-9638-d942f0572949
# ╠═49d8dc47-0788-4575-811e-240dc05a746c
# ╠═0cc923a9-6a9c-4cd8-b69e-b513f56d2b34
# ╠═78cdc828-c051-4ab9-a7f2-1cdfd6124b90
# ╟─d31bf92b-d5f8-48dd-b8b5-ac0206488239
# ╠═0ec76517-fd06-4de4-9354-01184f0db03d
