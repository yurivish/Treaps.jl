module Treaps

import Base: show, isempty, minimum, maximum, in

export Treap, TreapNode, show, isempty, add!, remove!, minimum, maximum, left, right, key, root

typealias PriorityT Float32

type TreapNode{K}
	priority::PriorityT
	key::K
	left::TreapNode{K}
	right::TreapNode{K}
	TreapNode(key, priority, left, right) = new(priority, key, left, right)
	TreapNode() = new(convert(PriorityT, Inf))
end
show(io::IO, t::TreapNode) = show(io, "Key: $(t.key), Priority: $(t.priority)")
isempty(t::TreapNode) = t.priority == convert(PriorityT, Inf)

key(t::TreapNode) = t.key
left(t::TreapNode) = t.left
right(t::TreapNode) = t.right

function add!{K}(t::TreapNode{K}, key::K)
	if isempty(t)
		t.key = key
		t.priority = rand(PriorityT)
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
		result.right = merge!(result.right, right)
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

type Treap{K}
	root::TreapNode{K}
	Treap() = new(TreapNode{K}())
end
add!{K}(t::Treap{K}, key::K) = t.root = add!(t.root, key)
remove!{K}(t::Treap{K}, key::K) = t.root = remove!(t.root, key)
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

