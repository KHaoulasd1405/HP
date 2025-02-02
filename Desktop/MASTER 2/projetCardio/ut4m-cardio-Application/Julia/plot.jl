using DataFrames
using Plots
using Statistics 

"""
    plot_combined_data(grouped_by_ind::GroupedDataFrame, grouped_by_time::GroupedDataFrame, col_name::String)

Plots individual data points and lines for each group in `grouped_by_ind` and a mean curve for `grouped_by_time`.

# Arguments
- `grouped_by_ind::GroupedDataFrame`: A grouped DataFrame where each group represents an individual.
- `grouped_by_time::GroupedDataFrame`: A grouped DataFrame where each group represents a time point.
- `col_name::String`: The name of the column to be plotted.

# Returns
- `plt`: A plot object with individual data points, lines, and a mean curve.

# Details
- The function generates a scatter plot and a line plot for each individual in `grouped_by_ind`.
- Each individual's data is plotted with a unique color.
- The mean curve is calculated and plotted using the data in `grouped_by_time`.
- The x-axis labels are set to ["PRE", "POST", "J+2", "J+5", "J+10"].
- The legend is displayed at the bottom of the plot with three columns.
"""
function plot_combined_data(grouped_by_ind::GroupedDataFrame, grouped_by_time::GroupedDataFrame, col_name::String)
    plt = plot(title="Line Plots and Mean Curve for "*col_name, xlabel="", ylabel="", legend=true)
    xlab = ["PRE","POST","J+2","J+5","J+10"]
    
    # Plot individual data points and lines
    for subdf in grouped_by_ind
        times = subdf[:,:TIME]
        individu = subdf[:,Symbol(col_name)]
        filtered_data = []
        filtered_time = []
        for i in 1:length(individu)
            if !ismissing(individu[i])
                push!(filtered_data, individu[i])
                push!(filtered_time, times[i])
            end
        end
        convert(Array{Int16,1},filtered_time)
        convert(Array{Float64,1},filtered_data)
        color = rand(1:100)
        plot!(plt, filtered_time, filtered_data, seriestype=:scatter, label="individu "*string(subdf[1,1]), color=color)
        plot!(plt, filtered_time, filtered_data, seriestype=:line, label="", color=color)
        plot!(plt, legend=:outerbottom, legendcolumns=3, xticks=([-2, 1, 3, 6, 11],xlab))
    end
    
    # Plot mean curve
    mean_data = []
    filtered_time = []
    for i in 1:length(grouped_by_time)
        subdf = grouped_by_time[i]
        times = subdf[:,:TIME]
        col_data = subdf[:, Symbol(col_name)]
        if any(.!ismissing.(col_data))
            temp_mean = mean(skipmissing(col_data))
            push!(mean_data, temp_mean)
            push!(filtered_time, times[i])
        end
    end
    plot!(plt, filtered_time, mean_data, seriestype=:scatter, label="Mean", color="black")
    plot!(plt, filtered_time, mean_data, seriestype=:line, label="", color="black")
    
    return plt
end