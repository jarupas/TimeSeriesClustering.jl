# This file exemplifies the workflow from data input to optimization result generation
#QUESTION using ClustForOpt_priv.col in module Main conflicts with an existing identifier., using ClustForOpt_priv.cols in module Main conflicts with an existing identifier.
@time include(normpath(joinpath(dirname(@__FILE__),"..","src","ClustForOpt_priv_development.jl")))

# This file exemplifies the workflow from data input to optimization result generation
#QUESTION using ClustForOpt_priv.col in module Main conflicts with an existing identifier., using ClustForOpt_priv.cols in module Main conflicts with an existing identifier.

# load data
#input_data,~ = load_timeseries_data("DAM", "GER") DAM
ts_input_data,~ = load_timeseries_data("CEP", "GER";K=365, T=24) #CEP

cep_input_data_GER=load_cep_data("GER")

 # run clustering
Scenarios=Dict{String,Scenario}()
#TODO combine reference and specific scenarios
Scenarios["reference"] = Scenario(clust_res=run_clust(ts_input_data;n_init=10,n_clust_ar=collect(30)).best_results[1])
Scenarios["kmeans-4"] = Scenario(clust_res=run_clust(ts_input_data;n_init=10,n_clust_ar=collect(4))) # default k-means
Scenarios["kmean-10"] = Scenario(clust_res=run_clust(ts_input_data;n_init=10,n_clust_ar=collect(10))) # default

co2limitmax=1e12
co2limitmin=0.1e12
steps=5
for (name,Scenario) in Scenarios
# optimization
    Scenario.name=name
    Scenario.opt_res=OptResult[]
    for co2limit=co2limitmax:(-(co2limitmax-co2limitmin)/(steps-1)):co2limitmin
        if name=="reference"
            tsdata=Scenario.clust_res
        else
            tsdata=Scenario.clust_res.best_results[1]
        end
        push!(Scenario.opt_res,run_cep_opt(tsdata,cep_input_data_GER;solver=GurobiSolver(),co2limit=co2limit))
    end
end

#TODO Masterthesis from here on
@time include(normpath(joinpath(dirname(@__FILE__),"..","src","utils","plot_cep.jl")))
gr(size=(1000,1500),width=1,linecolor=:match,grid=(:y, :black, :dot, 1, 0.9),xticks=plot_prepare_xticks(Scenarios))
colors=[Stanford[:Yellow] Stanford[:LBlue] Stanford[:Brown] Stanford[:Orange] Stanford[:Grey] Stanford[:DGreen] Stanford[:DBlue]]
eurplots=plot_groupedbar_ref_and_comp(Scenarios,"Cost EUR";legend=:topleft,color=colors)
capplots=plot_groupedbar_ref_and_comp(Scenarios,"Cap";color=colors)
pall=plot(eurplots[1],capplots[1],eurplots[2],capplots[2],eurplots[3],capplots[3],layout=@layout([a b; c d; e f]))
savefig(pall,"/home/elias/Studium/Julia/ClustPlot/pall.svg")
