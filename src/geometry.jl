
abstract AbstractPoint{T <: Real}


immutable Point{T} <: AbstractPoint
	x::T
	y::T
end

x(p::Point) = p.x
y(p::Point) = p.y
Base.eltype{T}(::Type{Point{T}}) = T


Base.start(p::Point) = 1
Base.next(p::Point, state) = (getfield(p,fieldname(Point,state)), state + 1)
Base.done(p::Point, state) = state > nfields(Point)
Base.length(p::Point) = nfields(Point)
Base.size(p::Point) = (nfields(Point),)

Base.getindex(p::Point,i) = getfield(p,fieldname(Point,i))
Base.endof(p::Point)  = length(p)


immutable Line{T <: AbstractPoint}
	p1::T
	p2::T
end

function perpendicular(l1::Line, l2::Line)
	m1 = (y(l1.p2) - y(l1.p1)) / (x(l1.p2) - x(l1.p1))
	m2 = (y(l2.p2) - y(l2.p1)) / (x(l2.p2) - x(l2.p1))

	return isapprox(m1,-(1/m2))
end

⟂(l1,l2) = perpendicular(l1,l2)

isleft(p::AbstractPoint, l::Line) = ((x(l.p2) - x(l.p1)) * (y(p) - y(l.p1) ) - (x(p) - x(l.p1)) * (y(l.p2) - y(l.p1)))

Base.norm(l::Line) = norm([x(l.p2) - x(l.p1), y(l.p2) - y(l.p1)])


abstract AbstractPolygon{T <: AbstractPoint}

immutable Polygon{T} <: AbstractPolygon{T}
	vertexs::Vector{T}
	function Polygon(v::Vector)
		if v[end] != v[1]
			push!(v,v[1])
		end
		return new(v)
	end
end

Polygon{T}(v::Vector{T}) = Polygon{T}(v)

Base.start(p::Polygon) = start(p.vertexs)
Base.next(p::Polygon, state) = next(p.vertexs, state)
Base.done(p::Polygon, state) = done(p.vertexs, state)
Base.length(p::Polygon) = length(p.vertexs)
Base.size(p::Polygon) = size(p.vertexs)

Base.getindex(p::Polygon,i) = p.vertexs[i]
Base.endof(p::Polygon)  = endof(p.vertexs)
Base.eltype(p::Polygon) = eltype(p.vertexs)


function boundingbox(poly::AbstractPolygon)
	minx = mapreduce(x,min,poly.vertexs)
	miny = mapreduce(y,min,poly.vertexs)
	maxx = mapreduce(x,max,poly.vertexs)
	maxy = mapreduce(y,max,poly.vertexs)

	(Point(minx,miny), Point(maxx,maxy)) 
end


function Base.in(p::AbstractPoint, poly::AbstractPolygon)
	wn = 0
	for idx in 1:(length(poly) - 1)
		V1 = poly[idx]
		V2 = poly[idx + 1]

		if y(V1) <= y(p)
			if y(V2) > y(p)
				if isleft(p, Line(V1,V2)) > 0
					wn+=1
				end
			end
		else
			if y(V2) <= y(p)
				if isleft(p, Line(V1,V2)) < 0
					wn-=1
				end
			end
		end
	end
	return wn != 0
end

function Base.rand{T}(rng, S::AbstractPolygon{T}, n::Int64)
	pT = eltype(T)
	ret = Point{pT}[]

	(minp,maxp) = boundingbox(S)

	bw = x(maxp) - x(minp)
	bh = y(maxp) - y(minp)

	while length(ret) < n
		rnd = [x(minp),y(minp)] .+ (rand(rng,pT,2) .* [bw,bh])

		newPoint = Point{pT}(rnd...)


		if newPoint in S
			push!(ret,newPoint)
		end
	end
	ret
end

Base.rand(rng,S::AbstractPolygon) = rand(rng,S,1)

Base.rand(S::AbstractPolygon, n) = rand(Base.Random.GLOBAL_RNG,S,n)

Base.rand(S::AbstractPolygon) = rand(Base.Random.GLOBAL_RNG,S,1)[1]