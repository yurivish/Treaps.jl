# Nearest-neighbor search on a BST containing unique
# elements in shuffle order. Assumes the tree implements
# key, left, right, isempty, minimum, and maximum.
# The code follows the shape of the array version in LowDimNearestNeighbors.

if Pkg.installed("LowDimNearestNeighbors") != nothing
	import LowDimNearestNeighbors: shuffless, shuffmore, nearest, nearest_result, Result, sqdist, sqdist_to_quadtree_box
	export nearest, nearest_result

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

	nearest{P, Q}(t::Treap{P}, q::Q, ε=0.0) = nearest(root(t), q, ε)

	function nearest_result{P, Q}(t::TreapNode{P}, q::Q, ε=0.0)
		@assert !isempty(t) "Searching for the nearest in an empty treap"
		nearest(t, q, Result{P, Q}(key(t)), ε)
	end

	nearest_result{P, Q}(t::Treap{P}, q::Q, ε=0.0) = nearest_result(root(t), q, ε)
end
