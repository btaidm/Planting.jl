immutable OffsetArray{T,N} <: AbstractArray{T,N}
    data::Array{T,N}
    startOffset::Dims{N}
end

Base.eltype(A::OffsetArray) = eltype(A.data)
Base.indices(A::OffsetArray) = map((x,y)->(x-1)+y, A.startOffset, indices(A.data))

@inline Base.getindex(A::OffsetArray, idxs...) = A.data[map((x,y) -> (x-y+1),idxs,A.startOffset)...]
@inline Base.setindex!(A::OffsetArray, X, idxs...) = A.data[map((x,y) -> (x-y+1),idxs,A.startOffset)...] = X

OffsetArray{T}(::Type{T},startOffset::Dims,dims::Dims) = OffsetArray(Array{T}(dims),startOffset)
OffsetArray{T}(::Type{T},startOffset::Dims,dims::Integer...) = OffsetArray(Array{T}(dims...),startOffset)
OffsetArray(startOffset::Dims,dims::Dims) = OffsetArray(Float64,startOffset,dims)
OffsetArray(startOffset::Dims,dims::Integer...) = OffsetArray(Float64,startOffset,dims...)
offsetarray_fill{N}(v,startOffset::Dims{N},dims::Dims{N}) = OffsetArray(fill(v,dims),startOffset)


offsetarray_fill{N}(v::AbstractArray,startOffset::Dims{N},dims::Dims{N}) = OffsetArray(map(x->copy(v), zeros(Bool,dims)),startOffset)
offsetarray_fill{N}(v::AbstractArray,startOffset::Dims{N},dims::Integer...) = OffsetArray(map(x->copy(v), zeros(Bool,dims...)),startOffset)

offsetarray_zeros{T,N}(t::Type{T},startOffset::Dims{N},dims::Dims{N}) = OffsetArray(zeros(t,dims),startOffset)
offsetarray_ones{T,N}(t::Type{T},startOffset::Dims{N},dims::Integer...) = OffsetArray(ones(t,dims...),startOffset)
offsetarray_zeros{N}(startOffset::Dims{N},dims::Dims{N}) = OffsetArray(zeros(dims),startOffset)
offsetarray_ones{N}(startOffset::Dims{N},dims::Integer...) = OffsetArray(ones(dims...),startOffset)

immutable AccelGrid{T,N}
    gridSize::Float64
    data::OffsetArray{T,N}
end


@inline Base.getindex(A::AccelGrid,idxs...) = A.data[map((x,y)->clamp(round(Int,x/A.gridSize),minimum(y),maximum(y)),idxs,indices(A.data))...]
@inline Base.setindex!(A::AccelGrid,X,idxs...) = A.data[map((x,y)->clamp(round(Int,x/A.gridSize),minimum(y),maximum(y)),idxs,indices(A.data))...] = X
Base.eltype(A::AccelGrid) = eltype(A.data)


function AccelGrid{T,N}(::Type{T}, gridSize::Real,lowerBound::NTuple{N,Real}, upperBound::NTuple{N,Real})
    startBound = map(x->floor(Int,x/gridSize),lowerBound)
    endBound = map(x->ceil(Int,x/gridSize),upperBound)

    if T <: AbstractArray
        eT = eltype(T)
        data = offsetarray_fill(eT[],startBound,map(-,endBound,startBound))
    elseif T <: Real
        data = offsetarray_zeros(T,startBound,map(-,endBound,startBound))
    else
        data = offsetarray_fill(Nullable{T}(),startBound,map(-,endBound,startBound))
    end
    AccelGrid(convert(Float64,gridSize),data)
end

AccelGrid{N}(gridSize::Real,lowerBound::NTuple{N,Real}, upperBound::NTuple{N,Real}) = AccelGrid(Float64,gridSize,lowerBound,upperBound)

# function Base.display(a::AccelGrid)
#   bold = "\x1b[1m"; default = "\x1b[0m";
#   println("$(bold)AccelGrid:")
#   println("\tgrid size: ", a.gridSize)
#   print("\tdata: $(default)")
#   display(a.data)
# end
