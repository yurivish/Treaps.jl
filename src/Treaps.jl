module Treaps

import Base: show, isempty, minimum, maximum, length, in

export Treap, TreapNode, show, isempty, add!, remove!, minimum, maximum, left, right, key, root

typealias PriorityT Float32

type TreapNode{K}
	priority::PriorityT
	key::K
	left::TreapNode{K}
	right::TreapNode{K}
	TreapNode(key, priority, left, right) = new(priority, key, left, right)
	TreapNode() = new(inf(PriorityT))
end
show(io::IO, t::TreapNode) = show(io, "Key: $(t.key), Priority: $(t.priority)")
isempty(t::TreapNode) = t.priority == inf(PriorityT)

key(t::TreapNode) = t.key
left(t::TreapNode) = t.left
right(t::TreapNode) = t.right

type Treap{K}
	root::TreapNode{K}
	pool::Vector{TreapNode{K}}
	poolsize::Int
	function Treap()
		pool = Array(TreapNode{K}, 2000)
		new(TreapNode{K}(), pool, 0)
	end
end

function newnode{K}(treap::Treap{K})
	if treap.poolsize > 0
		node = treap.pool[treap.poolsize]
		node.priority = inf(PriorityT)
		treap.poolsize -= 1
		node
	else
		TreapNode{K}()
	end
end

function add!{K}(treap::Treap, t::TreapNode{K}, key::K)
	if isempty(t)
		t.key = key
		t.priority = rand(PriorityT)
		t.left = newnode(treap)  # TreapNode{K}()
		t.right = newnode(treap) # TreapNode{K}()
		return t
	end

	if key < t.key
		t.left = add!(treap, t.left, key)
		t.left.priority < t.priority ? rotate_right!(t) : t
	else
		@assert t.key < key "A treap may not contain duplicate keys: $key, $(t.key)"
		t.right = add!(treap, t.right, key)
		t.right.priority < t.priority ? rotate_left!(t) : t
	end
end

function merge!{K}(left::TreapNode{K}, right::TreapNode{K})
	isempty(left)  && return right
	isempty(right) && return left
	if left.priority < right.priority
		result = left
		result.right = merge!(result.right, right)
	else
		result = right
		result.left = merge!(left, result.left)
	end
	result
end

function remove!{K}(treap::Treap, t::TreapNode{K}, key::K)
	isempty(t) && throw(KeyError(key))
	if key == t.key
		# push!(treap.pool, t)
		treap.poolsize += 1
		if treap.poolsize > length(treap.pool)
			resize!(treap.pool, treap.poolsize * 2)
		end
		treap.pool[treap.poolsize] = t
		merge!(t.left, t.right)
	elseif key < t.key
		t.left = remove!(treap, t.left, key)
		t.left.priority < t.priority ? rotate_right!(t) : t
	else
		t.right = remove!(treap, t.right, key)
		t.right.priority < t.priority ? rotate_left!(t) : t
	end
end

function in{K}(key::K, t::TreapNode{K})
	isempty(t) && return false
	if key == t.key
		true
	elseif key < t.key
		in(key, t.left)
	else
		in(key, t.right)
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

### --- ###

add!{K}(t::Treap{K}, key::K) = t.root = add!(t, t.root, key)
remove!{K}(t::Treap{K}, key::K) = t.root = remove!(t, t.root, key)
show(io::IO, t::Treap) = show(io, t.root)
isempty(t::Treap) = isempty(t.root)
length(t::Treap) = length(t.root)
minimum(t::Treap) = minimum(t.root)
maximum(t::Treap) = maximum(t.root)
left(t::Treap) = left(t.root)
right(t::Treap) = right(t.root)
key(t::Treap) = key(t.root)
root(t::Treap) = t.root
in{K}(key::K, t::Treap{K}) = in(key, t.root)

include("nearest.jl")

end # module

