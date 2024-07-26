"""
    LazyArray(gen::Base.Generator)

Wrapper around Base.Generator that also indexes like an array. This is needed to make ComponentArrays
that hold arrays of ComponentArrays
"""
struct LazyArray{T,N,G} <: AbstractArray{T,N}
    gen::G
    LazyArray{T}(gen) where T = new{T, ndims(gen), typeof(gen)}(gen)
    LazyArray(gen::Base.Generator{A,F}) where {A,F} = new{eltype(A), ndims(gen), typeof(gen)}(gen)
end

const LazyVector{T,G} = LazyArray{T,1,G}
const LazyMatrix{T,G} = LazyArray{T,2,G}

Base.getindex(a::LazyArray, i...) =  _un_iter(getfield(a, :gen), i)

function Base.setindex!(a::LazyArray, val, i...)
    a[i...] .= val
end

_un_iter(iter, idxs) = _un_iter(iter.f, iter.iter, idxs)
_un_iter(f, iter::Base.Generator, idxs) = f(_un_iter(iter.f, iter.iter, idxs))
_un_iter(f, iter::Base.Iterators.ProductIterator, idxs) = f(getindex.(iter.iterators, idxs))
_un_iter(f, iter, idxs) = f(iter[idxs...])

Base.getproperty(a::LazyArray, s::Symbol) = LazyArray(getproperty(item, s) for item in a)

Base.iterate(a::LazyArray) = iterate(getfield(a, :gen))
Base.iterate(a::LazyArray, state...) = iterate(getfield(a, :gen), state...)

Base.collect(a::LazyArray) = collect(getfield(a, :gen))

Base.length(a::LazyArray) = length(getfield(a, :gen))

Base.size(a::LazyArray) = size(getfield(a, :gen))

Base.eltype(::LazyArray{T,N,G}) where {T,N,G} = T

Base.show(io::IO, a::LazyArray) = show(io, collect(a))
function Base.show(io::IO, mime::MIME"text/plain", a::LazyArray)
    arr = collect(a)
    rep = repr(mime, arr)
    return print(replace(rep, r"(\d+-element )?((Vector|Array){(.+)?})" => s"\1LazyArray{\4}"; count=1))
end

Base.copy(a::LazyArray) = collect(a)
Base.deepcopy(a::LazyArray) = copy(a)
