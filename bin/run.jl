module PlantingRunner
import Planting
import Plots

function __init__()
    Plots.pyplot(leg = false, grid = true, xticks = nothing, yticks = nothing)
end


type PlantingPlot
    plt::Nullable{Plots.Plot}
    active_list::Vector{Planting.AbstractPoint}
    final_list::Vector{Planting.AbstractPoint}
    radius::Float64
    poly::Nullable{Planting.AbstractPolygon}
    anim::Plots.Animation
end

PlantingPlot() = PlantingPlot(Nullable{Plots.Plot}(),[],[],0, Nullable{Planting.AbstractPolygon}(), Plots.Animation())

function drawCircle(plt::Plots.Plot,p::Planting.AbstractPoint, poly::Planting.AbstractPolygon, radius::Float64, args...; kwargs...)
    circlepoint = Plots.partialcircle(0,2π,1000,radius)
    (xs,ys) = Plots.unzip(circlepoint)

    xs += Planting.x(p)
    ys += Planting.y(p)

    ps = map(zip(xs,ys)) do x
        p = Planting.Point(x...)
        if ! (p in poly)
            p2 = [p...]
            closestLine = nothing
            minDist = Inf
            for idx in 1:(length(poly) - 1)

                distance = begin
                    l = norm(Planting.Line(poly[idx],poly[idx + 1]))
                    if l == 0
                        norm(Planting.Line(poly[idx],p))
                    else
                        v = [poly[idx]...]
                        w = [poly[idx + 1]...]

                        t = max(0,min(1,dot(p2 - v, w - v)/(l*l)))

                        proj = v + t * (w - v)
                        norm(Planting.Line(p,Planting.Point(proj...)))
                    end
                end

                if distance < minDist
                    minDist = distance
                    closestLine = idx
                end
            end

            p = begin
                l = norm(Planting.Line(poly[closestLine],poly[closestLine + 1]))
                if l == 0
                    poly[closestLine]
                else
                    v = [poly[closestLine]...]
                    w = [poly[closestLine + 1]...]

                    t = max(0,min(1,dot(p2 - v, w - v)/(l*l)))

                    proj = v + t * (w - v)
                    Planting.Point(proj...)
                end
            end
        end
        return (p...)
    end


    Plots.plot!(plt,Plots.Shape(Plots.unzip(ps)...),args...; kwargs...)
end

function init(plt::PlantingPlot, poly::Planting.AbstractPolygon, o::Planting.AbstractObject, active_list, final_list, grid)
    (lb,ub) = Planting.boundingbox(poly)

    width = Planting.x(ub) - Planting.x(lb)
    height = Planting.y(ub) - Planting.y(lb)

    midx = (Planting.x(lb) + Planting.x(ub)) / 2
    midy = (Planting.y(lb) + Planting.y(ub)) / 2

    xlim = (midx - ((width/2)*1.1),midx + ((width/2)*1.1))
    ylim = (midy - ((height/2)*1.1),midy + ((height/2)*1.1))




    plt.plt = Plots.plot(xlim = xlim, ylim = ylim, aspect_ratio = :equal, xticks = Planting.x(lb):grid.gridSize:Planting.x(ub),yticks = Planting.y(lb):grid.gridSize:Planting.y(ub))
    plt.active_list = active_list
    plt.final_list = final_list
    plt.radius = Planting.radius(o)
    plt.poly = poly

    xs = map(Planting.x,poly)
    ys = map(Planting.y,poly)
    Plots.plot!(get(plt.plt),Plots.Shape(xs[1:end],ys[1:end]), c = Plots.RGBA(1,1,1,0))
    Plots.gui()
    sleep(.01)
end

function test(plt::PlantingPlot, p::Planting.AbstractPoint, np::Planting.AbstractPoint, points::Vector, active_list, final_list, grid)
    px = Planting.x(p)
    py = Planting.y(p)
    poly = get(plt.poly)
    (lb,ub) = Planting.boundingbox(get(plt.poly))

    width = Planting.x(ub) - Planting.x(lb)
    height = Planting.y(ub) - Planting.y(lb)

    midx = (Planting.x(lb) + Planting.x(ub)) / 2
    midy = (Planting.y(lb) + Planting.y(ub)) / 2

    xlim = (midx - ((width/2)*1.1),midx + ((width/2)*1.1))
    ylim = (midy - ((height/2)*1.1),midy + ((height/2)*1.1))
    xticks = Planting.x(lb):grid.gridSize:Planting.x(ub)
    yticks = Planting.y(lb):grid.gridSize:Planting.y(ub)
    plt.plt = Plots.plot(xlim = xlim, ylim = ylim, aspect_ratio = :equal, xticks = (xticks,repmat([""],length(xticks))), yticks = (yticks,repmat([""],length(yticks))))

    xs = map(Planting.x,poly)
    ys = map(Planting.y,poly)
    Plots.plot!(get(plt.plt),Plots.Shape(xs[1:end],ys[1:end]), c = Plots.RGBA(1,1,1,0))



    # active_idx = findin(final_list,active_list)
    for point in points
        norm(Planting.Line(np,point)) <= plt.radius && Plots.plot!(get(plt.plt),map(Planting.x,[np,point]),map(Planting.y,[np,point]), linecolor = :black, marker = :none)
    end

    for plant in final_list
        circlepoint = Plots.partialcircle(0,2π,1000,plt.radius)
        (xs,ys) = Plots.unzip(circlepoint)

        xs += Planting.x(plant)
        ys += Planting.y(plant)


        drawCircle(get(plt.plt),plant,get(plt.poly), plt.radius; c = Plots.RGBA(.5,.5,.5,.1), linewidth = 0)

        if plant in active_list
            Plots.scatter!(get(plt.plt),[Planting.x(plant)],[Planting.y(plant)], markercolor = :red)
        else
            Plots.scatter!(get(plt.plt),[Planting.x(plant)],[Planting.y(plant)], markercolor = :black)
        end
    end


    drawCircle(get(plt.plt),p,get(plt.poly), plt.radius; c = Plots.RGBA(.5,.5,.5,0))
    drawCircle(get(plt.plt),p,get(plt.poly), 2 * plt.radius; c = Plots.RGBA(.5,.5,.5,.2))


    Plots.scatter!(get(plt.plt),[Planting.x(np)],[Planting.y(np)], markercolor = :white)



    Plots.gui()
    sleep(.01)
    # sleep(.1)


end

function step(plt::PlantingPlot, active_list, final_list, grid)
    px = Planting.x(p)
    py = Planting.y(p)
    poly = get(plt.poly)
    (lb,ub) = Planting.boundingbox(get(plt.poly))

    width = Planting.x(ub) - Planting.x(lb)
    height = Planting.y(ub) - Planting.y(lb)

    midx = (Planting.x(lb) + Planting.x(ub)) / 2
    midy = (Planting.y(lb) + Planting.y(ub)) / 2

    xlim = (midx - ((width/2)*1.1),midx + ((width/2)*1.1))
    ylim = (midy - ((height/2)*1.1),midy + ((height/2)*1.1))
    xticks = Planting.x(lb):grid.gridSize:Planting.x(ub)
    yticks = Planting.y(lb):grid.gridSize:Planting.y(ub)
    plt.plt = Plots.plot(xlim = xlim, ylim = ylim, aspect_ratio = :equal, xticks = (xticks,repmat([""],length(xticks))), yticks = (yticks,repmat([""],length(yticks))))

    xs = map(Planting.x,poly)
    ys = map(Planting.y,poly)
    Plots.plot!(get(plt.plt),Plots.Shape(xs[1:end],ys[1:end]), c = Plots.RGBA(1,1,1,0))

    for plant in final_list
        circlepoint = Plots.partialcircle(0,2π,1000,plt.radius)
        (xs,ys) = Plots.unzip(circlepoint)

        xs += Planting.x(plant)
        ys += Planting.y(plant)


        drawCircle(get(plt.plt),plant,get(plt.poly), plt.radius; c = Plots.RGBA(.5,.5,.5,.1), linewidth = 0)

        if plant in active_list
            Plots.scatter!(get(plt.plt),[Planting.x(plant)],[Planting.y(plant)], markercolor = :red)
        else
            Plots.scatter!(get(plt.plt),[Planting.x(plant)],[Planting.y(plant)], markercolor = :black)
        end
    end

    Plots.gui()
    sleep(.01)
end



function main()
    plt = PlantingPlot()


    callbacks = Dict{String,Function}(
        "init" => (poly,o,active_list, final_list, grid) -> init(plt,poly,o,active_list,final_list,grid),
        "test" => (p, np, points, active_list, final_list, grid) -> test(plt,p,np,points, active_list, final_list, grid)
    )

    poly = Planting.Polygon([ Planting.Point(0.0,0.0),Planting.Point(0.0,1.0),Planting.Point(1.0,1.0), Planting.Point(1.0,0.0), Planting.Point(.5,-.5)])

    obj = Planting.SimpleObject(.2)

    plants = Planting.plant(Planting.FastPoissonDisk(30), poly, obj; seed = 0, callback = callbacks)

end


end
