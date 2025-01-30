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
    # Import de 4x40km
    data440 = XLSX.readxlsx(path)["4x40_new"]
    data440 = data440["A1:ADY21"]
    # Import des autres courses
    data = XLSX.readxlsx(path)["Tableau_gl_new"]
    data = data["A1:IZ60"]
    df = DataFrame(data[2:end, 2:end], Symbol.(data[1, 2:end]), makeunique=true)
    df440 = DataFrame(data440[2:end, 2:end], Symbol.(data440[1, 2:end]), makeunique=true)
    CODE_SUJET = DataFrame([:"CODE_SUJET" => data[2:end,1]])
    CODE_SUJET440 = DataFrame([:"CODE_SUJET" => data440[2:end,1]])
    df = hcat(CODE_SUJET, df)
    df440 = hcat(CODE_SUJET440, df440)
    df = replaceDF(df)
    # Création des timestamp pour les 3 courses 
    for col in filter(col -> occursin("TIMESTAMP", col) && !occursin("TIMESTAMP_PRE", col), names(df))
        df[:, Symbol(col)] = [ismissing(df[i, Symbol(col)]) ? missing : Dates.value(df[i, Symbol(col)] - df[i, :TIMESTAMP_PRE])/60000 for i in 1:nrow(df)]
    end
    df.TIMESTAMP_PRE .= 0
    df440 = replaceDF(df440)
    # Création des timestamp pour la 4x40km
    for col in filter(col -> occursin("TIMESTAMP", col) && !occursin("TIMESTAMP_PRE", col), names(df440))
        df440[:, Symbol(col)] = [ismissing(df440[i, Symbol(col)]) ? missing : Dates.value(df440[i, Symbol(col)] - df440[i, :TIMESTAMP_PRE])/60000 for i in 1:nrow(df440)]
    end
    df440.TIMESTAMP_PRE .= 0
    mesures_cardiaques = df[:,24:end]
    # Un peu de préprocessing avant mesures cardiaques 4x40
    # Dans mon dataframe mesure_cardiaques440, je veux supprimer toutes les colonnes pour lesquelles, il n'y a pas PRE,POST1, POST2, POST3, POST4 ou D_2 OU D_5 ou D_10 dans le nom
    keywords = ["PRE", "POST", "POST_2", "POST_3", "POST_4", "D_2", "D_5", "D_10"]
    mesures_cardiaques440 = df440[:,420:end]
    filter(col -> any(kw -> occursin(kw, col), keywords), names(mesures_cardiaques440))
    res = colToRow(mesures_cardiaques)
    res_columns = names(res)
    # Filtrer les colonnes de mesures_cardiaques
    cols_to_keep = filter(col -> any(occursin(res_col, col) for res_col in res_columns), names(mesures_cardiaques440))
    mesures_cardiaques440 = mesures_cardiaques440[:, cols_to_keep]
    mesures_cardiaques440 = mesures_cardiaques440[:, filter(col -> any(kw -> occursin(kw, col), keywords), names(mesures_cardiaques440))]
    res440 = colToRow(mesures_cardiaques440, "4_40")
     
    res = addCOURSE_SUJET(df, res)
    res440 = addCOURSE_SUJET(df440, res440)
    res440 = drop_missing_columns(res440)
    res440 = reorder_columns(res, res440)
    final = vcat(res[:,Not(Symbol("E/A_1"))], res440)
    var = ["CODE_SUJET","COURSE","TIME", "TIMESTAMP", "VOL_OGI","VOL_ODI","VTDVGI","VTSVGI","FE2D","STDi","STSi","E/A" ,"E/Ea"]
    return final[:, var]
end

function build_hda_data(path::String)
    data_440 = XLSX.readxlsx(path)["4x40_new"]
    data_440 = data_440["A1:ADY21"] 
    df_440 = DataFrame(data_440[2:end, 2:end], Symbol.(data_440[1, 2:end]), makeunique=true)[:,[:COURSE, :HDA]]
    data = XLSX.readxlsx(path)["Tableau_gl_new"]
    data = data["A1:IZ60"]
    df = DataFrame(data[2:end, 2:end], Symbol.(data[1, 2:end]), makeunique=true)[:,[:COURSE, :HDA]]
    return vcat(df, df_440)
end

function build_grouped_cardiaque(course_name,path::String, course::String)
    df = build_data_cardiac(path, course)
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
    # C2 = first.(filter(row -> row.COURSE == "4_40", res)[:, "x1"])
    C3 = first.(filter(row -> row.COURSE == 160, res)[:, "x1"])
    C4 = first.(filter(row -> row.COURSE == 40, res)[:, "x1"])
    Mean = mean_values[:, 2]

    trace1 = PlotlyJS.scatter(x=x, y=C1, mode="lines+markers", name="100km")
    # trace2 = PlotlyJS.scatter(x=x, y=C2, mode="lines+markers", name="4x40km")
    trace3 = PlotlyJS.scatter(x=x, y=C3, mode="lines+markers", name="160km")
    trace4 = PlotlyJS.scatter(x=x, y=C4, mode="lines+markers", name="40km")
    trace_mean = PlotlyJS.scatter(x=x, y=Mean, mode="lines", name="Moyenne", line=attr(color="black", dash="dash"))

    layout = PlotlyJS.Layout(
        title = "Variabilité inter-individuelle pour $col",
        xaxis = PlotlyJS.attr(title = "Participants"),
        yaxis = PlotlyJS.attr(title = "$col moyen"),
    )

    return PlotlyJS.plot([trace1, trace3, trace4, trace_mean], layout)
end

function plotlinevariabilityinter_4_40(df, col)
    df_4_40 = filter(row -> row[:COURSE] == "4_40", df)
    grouped = groupby(df_4_40[:, 1:end], [:COURSE, :TIME])
    res = DataFrames.combine(grouped, names(df_4_40, Not([:CODE_SUJET, :COURSE, :TIME])) .=> mean_std)
    col2 = col * "_mean_std"
    res = hcat(res[:, 1:2], Base.getindex.(res[:, Symbol(col2)], 1), makeunique=true)
    grouped = groupby(res, :TIME)
    x = ["PRE", "POST", "POST2", "POST3", "POST4", "J+2", "J+5", "J+10"]
    C2 = first.(filter(row -> row.COURSE == "4_40", res)[:, "x1"])

    trace2 = PlotlyJS.scatter(x=x, y=C2, mode="lines+markers", name="4x40km")

    layout = PlotlyJS.Layout(
        title = "Variabilité inter-individuelle pour $col - Course 4x40km",
        xaxis = PlotlyJS.attr(title = "Participants"),
        yaxis = PlotlyJS.attr(title = "$col moyen"),
    )

    return PlotlyJS.plot([trace2], layout)
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


function drop_missing_columns(df::DataFrame)
    non_missing_cols = names(df)[[sum(ismissing.(df[!, col])) < nrow(df) for col in names(df)]]
    return df[:, non_missing_cols]
end
function reorder_columns(df1::DataFrame, df2::DataFrame)
    common_cols = intersect(names(df1), names(df2))
    df2 = df2[:, common_cols]
    return df2
end