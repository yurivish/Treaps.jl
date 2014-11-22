using Treaps
using Base.Test

# write your own tests here
@test 1 == 1

function test_treap()
	n = 10000
	a = shuffle([i for i in 1:n])
	t = Treap{Int}()

	for i in 1:n
		add!(t, a[i])
	end
	sort!(a)

	@assert !isempty(t)
	@assert maximum(t) == maximum(a)
	@assert minimum(t) == minimum(a)

	for v in a
		remove!(t, v)
	end

	@assert isempty(t)

	println("Treap: Test succeeded.")

end


test_treap()

using LowDimNearestNeighbors

immutable Vec3{T}
	x::T
	y::T
	z::T
end
Base.getindex(v::Vec3, n::Int) = n == 1 ? v.x : n == 2 ? v.y : n == 3 ? v.z : throw("Vec3 indexing error.")
Base.length(v::Vec3) = 3
Base.rand{T}(::Type{Vec3{T}}) = Vec3(rand(T), rand(T), rand(T))
<(a::Vec3, b::Vec3) = shuffless(a, b)

function benchmark_treap(numelements, numqueries)
	const check_correctness = true

	for i in 1:10
		arr = unique([rand(Vec3{Uint8}) for i in 1:numelements])
		t = Treap{Vec3{Uint8}}()
		for v in arr
			add!(t, v)
		end

		queries = [rand(Vec3{Uint8}) for i in 1:numqueries]

		check_correctness && preprocess!(arr)
		@time for q in queries
			result = nearest(t, q)
			if check_correctness
				result_sqdist = LowDimNearestNeighbors.sqdist(q, result)

				correct_result = nearest(arr, q)
				correct_sqdist = LowDimNearestNeighbors.sqdist(q, correct_result)

				if result_sqdist != correct_sqdist
					result_dist = sqrt(result_sqdist)
					correct_dist = sqrt(correct_sqdist)
					println("Mismatch when searching for ", q, ":")
					println("\t Result: ", result, "\t", result_dist)
					println("\tCorrect: ", correct_result, "\t", correct_dist)
					println("\t% error: ", 100 * (1 - correct_dist / result_dist), "%")
					println()
				end
			end
		end
	end
end

benchmark_treap(100000, 100000)
