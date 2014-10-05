module Treaps


import Base: show, isempty, minimum, maximum

export Treap, TreapNode, show, isempty, add!, remove!, minimum, maximum, left, right, key, root

type TreapNode{K}
	priority::Float64
	key::K
	left::TreapNode{K}
	right::TreapNode{K}
	TreapNode(key, priority, left, right) = new(priority, key, left, right)
	TreapNode(key) = new(rand(), key, TreapNode{K}(), TreapNode{K}())
	TreapNode() = new(Inf)
end
show(io::IO, t::TreapNode) = show(io, "Key: $(t.key), Priority: $(t.priority)")
isempty(t::TreapNode) = t.priority == Inf

key(t::TreapNode) = t.key
left(t::TreapNode) = t.left
right(t::TreapNode) = t.right

function add!{K}(t::TreapNode{K}, key::K)
	if isempty(t)
		t.key = key
		t.priority = rand()
		t.left = TreapNode{K}()
		t.right = TreapNode{K}()
		return t
	end

	if key < t.key
		t.left = add!(t.left, key)
		t.left.priority < t.priority ? rotate_right!(t) : t
	else
		@assert t.key < key "A treap may not contain duplicate keys: $key, $(t.key)"
		t.right = add!(t.right, key)
		t.right.priority < t.priority ? rotate_left!(t) : t
	end
end

function merge!{K}(left::TreapNode{K}, right::TreapNode{K})
	isempty(left)  && return right
	isempty(right) && return left
	if left.priority < right.priority
		result = left
		result.right = merge!(left.right, right)
	else
		result = right
		result.left = merge!(left, result.left)
	end
	result
end

function remove!{K}(t::TreapNode{K}, key::K)
	isempty(t) && throw(KeyError(key))
	if key == t.key
		merge!(t.left, t.right)
	elseif key < t.key
		t.left = remove!(t.left, key)
		t.left.priority < t.priority ? rotate_right!(t) : t
	else
		t.right = remove!(t.right, key)
		t.right.priority < t.priority ? rotate_left!(t) : t
	end
end

function minimum(t::TreapNode)
	isempty(t) && error("An empty treap has no minimum.")
	while !isempty(t.left) t = t.left end
	t.key
end

function maximum(t::TreapNode)
	isempty(t) && error("An empty treap has no maximum.")
	while !isempty(t.right) t = t.right end
	t.key
end
function rotate_right!(root::TreapNode)
	@assert !isempty(root)
	newroot = root.left
	root.left, newroot.right = newroot.right, root
	newroot
end

function rotate_left!(root::TreapNode)
	@assert !isempty(root)
	newroot = root.right
	root.right, newroot.left = newroot.left, root
	newroot
end

type Treap{K}
	root::TreapNode{K}
	Treap() = new(TreapNode{K}())
end
show(io::IO, t::Treap) = show(io, t.root)
isempty(t::Treap) = isempty(t.root)
add!{K}(t::Treap{K}, key::K) = t.root = add!(t.root, key)
remove!{K}(t::Treap{K}, key::K) = t.root = remove!(t.root, key)
length(t::Treap) = length(t.root)
getindex(t::Treap, n::Int) = getindex(t.root, n)
minimum(t::Treap) = minimum(t.root)
maximum(t::Treap) = maximum(t.root)
left(t::Treap) = left(t.root)
right(t::Treap) = right(t.root)
key(t::Treap) = key(t.root)
root(t::Treap) = t.root

end # module

using Treaps

import LowDimNearestNeighbors: shuffless, shuffmore, nearest, Result, sqdist, sqdist_to_quadtree_box

# Nearest-neighbor search on a binary search tree containing unique
# elements in shuffle order. Assumes the tree implements key,
# left, right, isempty, minimum, and maximum.
# The code follows the shape of the array version.
function nearest{P, Q}(t::TreapNode{P}, q::Q, R::Result{P, Q}, ε::Float64)
	isempty(t) && return R

	min, cur, max = minimum(t), key(t), maximum(t)

	r_sq = sqdist(cur, q)
	r_sq < R.r_sq && (R = Result{P, Q}(cur, r_sq, q))

	if min == max || sqdist_to_quadtree_box(q, min, max) * (1.0 + ε)^2 >= R.r_sq
		return R
	end

	if shuffless(q, cur)
		R = nearest(left(t), q, R, ε)
		shuffmore(R.bbox_hi, cur) && (R = nearest(right(t), q, R, ε))
	else
		R = nearest(right(t), q, R, ε)
		shuffless(R.bbox_lo, cur) && (R = nearest(left(t), q, R, ε))
	end

	R
end

function nearest{P, Q}(t::TreapNode{P}, q::Q, ε=0.0)
	@assert !isempty(t) "Searching for the nearest in an empty treap"
	nearest(t, q, Result{P, Q}(key(t)), ε).point
end

nearest{P, Q}(t::Treap{P}, q::Q, ε=0.0) = nearest(root(t), q, ε)

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
	for i in 1:10
		arr = unique([rand(Vec3{Uint8}) for i in 1:numelements])
		t = Treap{Vec3{Uint8}}()
		for v in arr
			add!(t, v)
		end

		queries = [rand(Vec3{Uint8}) for i in 1:numqueries]

		@time for q in queries
			result = nearest(t, q)
			# result_sqdist = LowDimNearestNeighbors.sqdist(q, result)

			# correct_result = nearest(arr, q)
			# correct_sqdist = LowDimNearestNeighbors.sqdist(q, correct_result)

			# if result_sqdist != correct_sqdist
			# 	result_dist = sqrt(result_sqdist)
			# 	correct_dist = sqrt(correct_sqdist)
			# 	println("Mismatch when searching for ", q, ":")
			# 	println("\t Result: ", result, "\t", result_dist)
			# 	println("\tCorrect: ", correct_result, "\t", correct_dist)
			# 	println("\t% error: ", 100 * (1 - correct_dist / result_dist), "%")
			# 	println()
			# end
		end
	end
end

benchmark_treap(100000, 100000)

