module Planting


# package code goes here

include("utils.jl")
include("geometry.jl")



abstract AbstractObject



immutable SimpleObject <: AbstractObject
    radius::Float64
end

radius(o::SimpleObject) = o.radius


function randomneighbor{T <: AbstractPoint}(p::T, o::AbstractObject)
    r² = radius(o)^2
    R = 2 * r²
    θ = 2π*rand()
    r = √(rand() * R + r²)
    T(x(p) + (r * cos(θ)), y(p) + (r * sin(θ)))
end

function nearbyCells(accelGrid::AccelGrid, radius::Real, p::AbstractPoint)
    xs = (x(p) - 2*radius):accelGrid.gridSize:(x(p) + 2*radius)
    ys = (y(p) - 2*radius):accelGrid.gridSize:(y(p) + 2*radius)
    return (xs, ys)
end

function nearbyItems(p::AbstractPoint, radius::Real, accel::AccelGrid)
    result = eltype(accel)[]
    (xs, ys) = nearbyCells(accel, radius, p)
    # for x in xs, y in ys
    for item in accel[xs, ys]
        if !(item in result)
            push!(result, item)
        end
    end
    return result
end

immutable RejectionPoissonDisk
    N::Int
end



function plant(m::RejectionPoissonDisk, poly::AbstractObject, o::AbstractObject; callback::Dict{String,Function} = Dict{String,Function}(), seed = Dates.datetime2epochms(now()))
    srand(seed)
    (lb, ub) = boundingbox(poly)
    grid = AccelGrid(Int,radius(o)/√(2),(lb...), (ub...))
    final_list = eltype(poly)[]
    done = false
    while !done
        i = 0
        while i < m.N
            i += 1
            np = rand(poly)
            neighborhood = nearbyItems(np,radius(o),grid)
            points = final_list[filter!(x->x!=0,neighborhood)]
        end
end



immutable FastPoissonDisk
    k::Int
end

function plant(m::FastPoissonDisk, poly::AbstractPolygon, o::AbstractObject; callback::Dict{String,Function} = Dict{String,Function}(), seed = Dates.datetime2epochms(now()))
# http://www.cs.ubc.ca/~rbridson/docs/bridson-siggraph07-poissondisk.pdf

    srand(seed)
    (lb, ub) = boundingbox(poly)
    println(radius(o)/√(2))
    grid = AccelGrid(Int,radius(o)/√(2),(lb...), (ub...))

    active_list = eltype(poly)[]
    final_list = eltype(poly)[]

    x₀ = rand(poly)
    push!(active_list,x₀)
    push!(final_list,x₀)
    grid[x₀...] = length(final_list)

    haskey(callback, "init") && callback["init"](poly,o,active_list, final_list, grid)

    genPoint = function (p)
        for i in 1:m.k
            np = randomneighbor(p,o)
            if np in poly
                neighborhood = nearbyItems(np,radius(o),grid)

                points = final_list[filter!(x->x!=0,neighborhood)]

                haskey(callback, "test") && callback["test"](p, np, points,active_list,final_list,grid)

                nearby = any(map(points) do point
                    norm(Line(np,point)) <= radius(o)
                end)

                if !nearby
                    return (true,np)
                end
            end
        end
        return (false,nothing)
    end

    while !isempty(active_list)
        randIdx = rand(1:length(active_list))
        point = active_list[randIdx]
        deleteat!(active_list, randIdx)
        (found,newPoint) = genPoint(point)
        if found
            push!(active_list,point)
            push!(active_list,newPoint)
            push!(final_list,newPoint)
            grid[newPoint...] = length(final_list)
        end
        haskey(callback, "step") && callback["step"](active_list, final_list, grid)
    end

    return final_list
end



export AbstractPoint, Point, AbstractPolygon, Polygon, SimplePolygon, AbstractObject, SimpleObject, x, y, radius, RejectionPoissonDisk, FastPoissonDisk
export plant, Line

# if Pkg.installed("Plots") != nothing
# include("plot.jl")
# end


end # module
