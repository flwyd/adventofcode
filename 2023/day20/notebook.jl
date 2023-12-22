### A Pluto.jl notebook ###
# v0.19.32

using Markdown
using InteractiveUtils

# ╔═╡ 417659b7-ea90-44d6-851e-03b109d31cb0
begin
  import Pkg
  Pkg.activate()
  try
    @eval using Revise
  catch e
    @warn "Need to install Revise?" exception=(e)
  end
  using Day20
  using Runner
  inputexample = "input.example.txt"
  inputactual = "input.actual.txt"
  run() = Runner.run_module(Day20, Runner.inputfiles(); verbose=true)
  println("Day20 ready, just run() or Day20.part1(readlines(inputexample))")
end

# ╔═╡ fda6936e-cf1a-4cd0-bed0-529a4b210654
@doc Day20

# ╔═╡ 54ab5e88-e0dc-4a5e-a449-2e51de40fde8
Runner.inputstats();

# ╔═╡ 7eb86c5a-fb8b-4b66-ae84-46d23e0fc0a7
begin
mutable struct FlipFlop
	name::AbstractString
	high::Bool
	outputs::Vector{AbstractString}
end
mutable struct Conjunction
	name::AbstractString
	inputs::Dict{AbstractString, Bool}
	outputs::Vector{AbstractString}
end
mutable struct Broadcaster
	name::AbstractString
	outputs::Vector{AbstractString}
end
struct Pulse
	high::Bool
	source::AbstractString
	dest::AbstractString
end
end

# ╔═╡ 1831da28-489c-4db3-a5f2-8c6d018c07e3
begin
	function receive(gate::Broadcaster, pulse::Pulse, gates::Dict, pending::Vector{Pulse})
		for out in gate.outputs
			push!(pending, Pulse(pulse.high, gate.name, out))
		end
	end
	
	function receive(gate::FlipFlop, pulse::Pulse, gates::Dict, pending::Vector{Pulse})
		gate.high = !gate.high
		for out in gate.outputs
			push!(pending, Pulse(gate.high, gate.name, out))
		end
	end

	function receive(gate::Conjunction, pulse::Pulse, gates::Dict, pending::Vector{Pulse})
		gate.inputs[pulse.source] = pulse.high
		high = !all(values(gate.inputs))
			for out in gate.outputs
				push!(pending, Pulse(high, gate.name, out))
			end
		
	end
end

# ╔═╡ 0eb2a96a-4936-4f66-b115-37279e44f892
begin
	function parseinput(lines)
		outputs = Dict{AbstractString, Vector{AbstractString}}()
		inputs = Dict{AbstractString, Vector{AbstractString}}()
		flipflops = Set{AbstractString}()
		conjunctions = Set{AbstractString}()
		broadcasters = Set{AbstractString}()
		for line in lines
			gate, outs = split(line, " -> ")
			name = gate
			if startswith(gate, '%')
				name = gate[2:end]
				push!(flipflops, name)
			elseif startswith(gate, '&')
				name = gate[2:end]
				push!(conjunctions, name)
			else
				push!(broadcasters, name)
			end
			outputs[name] = split(outs, ", ")
			for o in outputs[name]
				if !haskey(inputs, o)
					inputs[o] = AbstractString[]
				end
				push!(inputs[o], name)
			end
		end
		for name in keys(inputs)
			if !haskey(outputs, name)
				outputs[name] = AbstractString[]
				push!(broadcasters, name)
			end
		end
		gates = Dict()
		for name in flipflops
			gates[name] = FlipFlop(name, false, outputs[name])
		end
		for name in conjunctions
			gates[name] = Conjunction(name, Dict(i => false for i in inputs[name]), outputs[name])
		end
		for name in broadcasters
			gates[name] = Broadcaster(name, outputs[name])
		end
		println(join(sort(["$k <- $(join(v, ", "))" for (k, v) in pairs(inputs)]), "\n"))
		gates
		#Day20.parseinput(lines)
		#map(lines) do line
			#parse(Int, line)
			#if (m = match(r"^(\S+) (\S+)$", line)) !== nothing
			#  (foo, bar) = m.captures
			#end
		#end
	end
end;

# ╔═╡ ac426bce-13d5-4c58-9c4d-ad7a3caf1c8c
begin # Useful variables
	exampleexpected = Runner.expectedfor(inputexample)
	examplelines = readlines(inputexample)
	example2expected = Runner.expectedfor("input.example2.txt")
	example2lines = readlines("input.example2.txt")
	actualexpected = Runner.expectedfor(inputactual)
	actuallines = readlines(inputactual)
	inputa = parseinput(actuallines)
	input2 = parseinput(example2lines)
	input = parseinput(examplelines)
end

# ╔═╡ b2124667-3181-4143-bd18-0680d0f931fb
function push_the_button(gates)
	pending = [Pulse(false, "", "broadcaster")]
	highs, lows = 0, 0
	while !isempty(pending)
		pulse = popfirst!(pending)
		pulse.high ? highs += 1 : lows += 1
		receive(gates[pulse.dest], pulse, gates, pending)
	end
	highs, lows
end

# ╔═╡ 63a6114d-9747-4059-a12b-08256224be54
#begin
#	gates = parseinput(examplelines)
#push_the_button(gates)
#end

# ╔═╡ 0ccbe14a-5969-4559-b9f6-29427633f563
function printgate(gates, name, depth; seen=Set{String}())
	gate = gates[name]
	prefix = if gate isa FlipFlop
		"%"
	elseif gate isa Conjunction
		"&"
	else
		"_"
	end
	outs = sort(gate.outputs)
	println(string(repeat(" ", depth), prefix, name, " -> ", join(outs, ", ")))
	if name ∈ seen
		return
	end
	push!(seen, name)
	for g in outs
		printgate(gates, g, depth+1, seen=seen)
	end
end

# ╔═╡ 64e09dd7-1dbc-4019-9c4a-381f21c7383f
printgate(parseinput(actuallines), "broadcaster", 0)

# ╔═╡ 2ab1998f-74ac-4f68-b52b-89e70ef84f00
md"## Results"

# ╔═╡ 80b68148-091f-4c4f-841a-1c8f691025b7
Runner.run_module(Day20, [
inputexample,
inputactual,
], verbose=true)

# ╔═╡ Cell order:
# ╟─fda6936e-cf1a-4cd0-bed0-529a4b210654
# ╟─417659b7-ea90-44d6-851e-03b109d31cb0
# ╠═54ab5e88-e0dc-4a5e-a449-2e51de40fde8
# ╠═7eb86c5a-fb8b-4b66-ae84-46d23e0fc0a7
# ╠═1831da28-489c-4db3-a5f2-8c6d018c07e3
# ╠═0eb2a96a-4936-4f66-b115-37279e44f892
# ╠═ac426bce-13d5-4c58-9c4d-ad7a3caf1c8c
# ╠═b2124667-3181-4143-bd18-0680d0f931fb
# ╠═63a6114d-9747-4059-a12b-08256224be54
# ╠═0ccbe14a-5969-4559-b9f6-29427633f563
# ╠═64e09dd7-1dbc-4019-9c4a-381f21c7383f
# ╟─2ab1998f-74ac-4f68-b52b-89e70ef84f00
# ╠═80b68148-091f-4c4f-841a-1c8f691025b7
