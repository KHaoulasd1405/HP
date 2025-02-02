function format_course_label(course)
    if course == "4_40"
        return "4x40km"
    else
        return string(course) * "km"
    end
end

function format_time_4_40(t)
        if t == -2
            return -2
        else
            return convert(Int64,t+3)
        end
end

function format_time_label(time, course)
    if course != "4_40"
        if time == -2
            return "PRE"
        elseif time == 1 
            return "POST"
        elseif time == 3
            return "J+2"
        elseif time == 6
            return "J+5"
        elseif time == 11
            return "J+10"
        end
    elseif course == "4_40"
    if time == -2
        return "PRE"
    elseif time == 4
        return "POST"
    elseif time == 6
        return "J+2"
    elseif time == 9
        return "J+5"
    elseif time == 14
        return "J+10"
    end
    end
end

function build_data_cardiac(path::String)
    data = XLSX.readxlsx(path)["Tableau_gl"]
    data = data["A1:SD80"]
    df = DataFrame(data[2:end, 2:end], Symbol.(data[1, 2:end]), makeunique=true)
    CODE_SUJET = DataFrame([:"CODE_SUJET" => data[2:end,1]])
    df = hcat(CODE_SUJET, df)
    df = replaceDF(df,-1,missing)
    mesures = df[:,24:213]
    mesures_cardiaques = df[:,267:end]
    res = colToRow(mesures_cardiaques)
    res = addCOURSE_SUJET(df, res)
#=     df_4_40 = filter(row -> row[:COURSE] == "4_40", res)
    df_4_40 = format_time_4_40(df_4_40)
    res[findall(row -> row[:COURSE] == "4_40", res), :] .= df_4_40 =#
    return res
end

function build_all_data(path::String)
    data = XLSX.readxlsx(path)["Tableau_gl"]
    data = data["A1:SD80"]
    df = DataFrame(data[2:end, 2:end], Symbol.(data[1, 2:end]), makeunique=true)
    CODE_SUJET = DataFrame([:"CODE_SUJET" => data[2:end,1]])
    df = hcat(CODE_SUJET, df)
    df = replaceDF(df,-1,missing)
    mesures_cardiaques = df[:,267:end]
    res = colToRow(mesures_cardiaques)
    res = addCOURSE_SUJET(df, res)
    return df[:,1:266]
end


function build_grouped_cardiaque(course_name,path::String)
    df = build_data_cardiac(path)
    df_ind_course = filter(row -> row[:COURSE] == course_name, df)
    df_ind_course = groupby(df_ind_course, :CODE_SUJET)

    df_ind_time = filter(row -> row[:COURSE] == course_name, df)
    df_ind_time = groupby(df_ind_time, :TIME)
    return df_ind_course, df_ind_time
end

# Cette fonction permet d'arrondir les colonnes numériques d'un DataFrame
function round_numeric_columns(df, digits=2)
    for col in names(df)
        if eltype(df[!, col]) <: Union{Missing, Number}
            df[!, col] = [ismissing(x) ? missing : round(x, digits=digits) for x in df[!, col]]
        end
    end
    return df
end

function custom_summary(df)
    res = df
    desc = describe(res)[:, 1:6]
    desc = round_numeric_columns(desc)
    pourcent = convert.(Int64, round.(((describe(res)[:, 6] / 79) * 100), digits=0))
    pourcent = string.(pourcent)
    pourcent = pourcent .* "%"
    statistiques = hcat(desc, pourcent)
    rename!(statistiques, Dict(:variable => "Variable", :x1 => "%missing", :mean => "Moyenne", :min => "Minimum", :median => "Médiane", :max => "Maximum", :nmissing => "Nombre de valeurs manquantes"))
    return statistiques
end

function missing_values_1D(df, dim1, dims = [:CODE_SUJET, :COURSE, :TIME])
    res = df
    filter!(x -> x != dim1, dims)
    grouped = groupby(res[:,Not(dims)], dim1)
    cols = names(res[:,Not(dims)]) .!= String(dim1)
    nmissing_per_group = DataFrames.combine(grouped, 
    [col => (x -> sum(ismissing, x)) => Symbol(string(col)) for col in names(res[:,Not(dims)]) if col != String(dim1)]...)
    return nmissing_per_group
end

# On se base uniquement sur la colonne Heure d'arrivée pour déterminer les abandons
function count_abandons_course(df)
    df[:, :COURSE] = format_course_label.(df[:, :COURSE])
    grouped = groupby(df[:, [:COURSE, :HDA]], :COURSE)
    nmissing_per_group = DataFrames.combine(grouped, 
        [col => (x -> sum(y -> y == 999, x)) => Symbol(string(col)) for col in names(df[:, [:COURSE, :HDA]]) if col != "COURSE"]...)
    rename!(nmissing_per_group, Dict(:COURSE => "Course", :HDA => "Nombre d'abandons"))
    return nmissing_per_group
end

# On se base uniquement sur la colonne Heure d'arrivée pour déterminer les non-participants
function count_non_participants(df)
    grouped = groupby(df[:, [:COURSE, :HDA]], :COURSE)
    nmissing_per_group = DataFrames.combine(grouped, 
        [col => (x -> sum(y -> y == 998, x)) => Symbol(string(col)) for col in names(df[:, [:COURSE, :HDA]]) if col != "COURSE"]...)
    rename!(nmissing_per_group, Dict(:COURSE => "Course", :HDA => "Nombre de non-participants"))
    return nmissing_per_group
end

function mean_std(x)
    non_missing_values = skipmissing(x)
    non_missing_values = collect(non_missing_values)
    
    if isempty(non_missing_values)
        return (NaN, NaN)
    else
        mean_val = round(Statistics.mean(non_missing_values), digits=1)
        std_val = round(Statistics.std(non_missing_values), digits=1)
        return (mean_val, std_val)
    end
end

function plotlinevariabilityinter(df, col)
    grouped = groupby(df[:, 1:end], [:COURSE, :TIME])
    res = DataFrames.combine(grouped, names(df, Not([:CODE_SUJET, :COURSE, :TIME])) .=> mean_std)
    col2 = col * "_mean_std"
    res = hcat(res[:, 1:2], Base.getindex.(res[:, Symbol(col2)], 1), makeunique=true)
    grouped = groupby(res, :TIME)
    mean_values = DataFrames.combine(grouped, :x1 => (x -> mean(skipmissing(x))) => Symbol("mean_" * col))
    x = ["J-2", "J+1", "J+3", "J+6", "J+11"]
    C1 = first.(filter(row -> row.COURSE == 100, res)[:, "x1"])
    C2 = first.(filter(row -> row.COURSE == "4_40", res)[:, "x1"])
    C3 = first.(filter(row -> row.COURSE == 160, res)[:, "x1"])
    C4 = first.(filter(row -> row.COURSE == 40, res)[:, "x1"])
    Mean = mean_values[:, 2]

    trace1 = PlotlyJS.scatter(x=x, y=C1, mode="lines+markers", name="100km")
    trace2 = PlotlyJS.scatter(x=x, y=C2, mode="lines+markers", name="4x40km")
    trace3 = PlotlyJS.scatter(x=x, y=C3, mode="lines+markers", name="160km")
    trace4 = PlotlyJS.scatter(x=x, y=C4, mode="lines+markers", name="40km")
    trace_mean = PlotlyJS.scatter(x=x, y=Mean, mode="lines", name="Moyenne", line=attr(color="black", dash="dash"))

    layout = PlotlyJS.Layout(
        title = "Variabilité inter-individuelle pour $col",
        xaxis = PlotlyJS.attr(title = "Participants"),
        yaxis = PlotlyJS.attr(title = "$col moyen"),
    )

    return PlotlyJS.plot([trace1, trace2, trace3, trace4, trace_mean], layout)
end

function plotvariabilityintra(df, col, course)
    grouped = groupby(df[:, 1:end], [:CODE_SUJET, :COURSE])
    df = DataFrames.combine(grouped, names(df, Not([:CODE_SUJET, :COURSE, :TIME])) .=> mean_std)
    col2 = col * "_mean_std"
    df = filter(row -> row.COURSE == course, df)
    df = hcat(df[:, 1:2], getindex.(df[:, Symbol(col2)], 1), getindex.(df[:, Symbol(col2)], 2), makeunique=true)
    df = filter(row -> !ismissing(row[:x1]) && !isnan(row[:x1]), df)
    df = filter(row -> !ismissing(row[:x1_1]) && !isnan(row[:x1_1]), df)

    trace = PlotlyJS.scatter(
        x = string.(df[:, :CODE_SUJET]),  # Convert CODE_SUJET to string to treat as categories
        y = df[:, 3],
        error_y = PlotlyJS.attr(
            type = "data",
            symmetric = true,
            array = df[:, 4]
        ),
        mode = "markers",
        #= marker = PlotlyJS.attr(color = df[:, :CODE_SUJET]), =#
        name = string.(df[:, :CODE_SUJET])
    )

    layout = PlotlyJS.Layout(
        title = "Variabilité intra-individuelle pour $col - course $course km",
        xaxis = PlotlyJS.attr(title = "Participants", type = "category"),  # Set xaxis type to category
        yaxis = PlotlyJS.attr(title = "$col moyen"),
        legend = PlotlyJS.attr(orientation = "h", x = 0.5, xanchor = "center")
    )

    plot = PlotlyJS.plot([trace], layout)
    return plot
end