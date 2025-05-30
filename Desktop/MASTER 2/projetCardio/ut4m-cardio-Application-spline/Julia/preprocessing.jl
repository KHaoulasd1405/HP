# Remplacer plusieurs valeurs par une autre dans tout le DataFrame
function replaceDF(df, old_values = [-1, ""," ","aucune écho", "pas de mesure ", "absent", "PAS D'IT EXPLOITABLE", "PAS DE MESURE FAITE", "DTI NON FAIT", "2CAV TROP MAUVAISE COUPE", "non rentrée"], new_value = missing)
    for col in names(df)
        for old in old_values
            df[!, col] = replace(df[!, col], old => new_value)
        end
    end
    return df
end

function colToRow_former(df, keywords = ["PRE", "POST", "D_2", "D_5", "D_10"])
    # Remplacer "VOLOGI" par "VOL_OGI" dans les noms de colonnes
    for col in names(df)
        if startswith(col, "VOLOGI")
            new_name = replace(col, "VOLOGI" => "VOL_OGI")
            rename!(df, col => new_name)
        end
    end
    for col in names(df)
        if startswith(col, "VOLODI")
            new_name = replace(col, "VOLODI" => "VOL_ODI")
            rename!(df, col => new_name)
        end
    end
    suffixes = ["_"*s for s in keywords]
    colnames = filter(name -> any(k -> occursin(k, name), keywords), names(df))
    unique_prefixes = Set{String}()
    for name in colnames
        prefix = name
        for suffix in suffixes
            prefix = replace(prefix, suffix => "")
        end
        push!(unique_prefixes, prefix)
    end
    df = df[:,colnames]
    existing_cols = names(df)
    for prefix in unique_prefixes
        for suffix in keywords
            new_col_name = prefix * "_" * suffix
            if !in(new_col_name, existing_cols)
                df[!, new_col_name] = fill(missing, nrow(df))
            end
        end
    end
    nbrow = nrow(df)
    res = DataFrame()
    for p in unique_prefixes
        cols = names(df)[startswith.(names(df), p)]
        cols_to_check = [p*"_"*k for k in keywords]
        existing_cols = filter(c -> c in names(df), cols_to_check)
        if !isempty(cols)
            df2 = DataFrames.stack(df[:, existing_cols], existing_cols[1:end], variable_name = :TIME, value_name = Symbol(p))
        end
        total_nrow = 5*nbrow
        nb_news_rows = total_nrow - nrow(df2)
        if nrow(df2) < total_nrow
            append!(df2,new_rows)
        end
        res = hcat(res, df2; makeunique=true)
    end
    select!(res, Not(names(res)[occursin.("TIME_", names(res))]))
    res.TIME .= replace(res.TIME) do t
        if endswith(t, "_PRE")
            "-2"
        elseif endswith(t, "_POST")
            "1"
        elseif endswith(t, "_D_2")
            "3"
        elseif endswith(t, "_D_5")
            "6"
        elseif endswith(t, "_D_10")
            "11"
        else
            t 
        end
    end
    res.TIME = parse.(Int, res.TIME)
    return res
end


# Cette fonction prend un dataframe en entrée et pivote les colonnes en lignes
function colToRow(df, course = "")
    if course == "4_40"
        keywords = ["PRE", "POST", "POST_2", "POST_3", "POST_4", "D_2", "D_5", "D_10"]
    else
        keywords = ["PRE", "POST", "D_2", "D_5", "D_10"]
    end
    # Remplacer "VOLOGI" par "VOL_OGI" dans les noms de colonnes
    for col in names(df)
        if startswith(col, "VOLOGI")
            new_name = replace(col, "VOLOGI" => "VOL_OGI")
            rename!(df, col => new_name)
        end
    end
    for col in names(df)
        if startswith(col, "VOLODI")
            new_name = replace(col, "VOLODI" => "VOL_ODI")
            rename!(df, col => new_name)
        end
    end
    suffixes = ["_"*s for s in keywords]
    colnames = filter(name -> any(k -> occursin(k, name), keywords), names(df))
    unique_prefixes = Set{String}()
    for name in colnames
        prefix = name
        for suffix in suffixes
            prefix = replace(prefix, suffix => "")
        end
        push!(unique_prefixes, prefix)
    end
    df = df[:,colnames]
    existing_cols = names(df)
    for prefix in unique_prefixes
        for suffix in keywords
            new_col_name = prefix * "_" * suffix
            if !in(new_col_name, existing_cols)
                df[!, new_col_name] = fill(missing, nrow(df))
            end
        end
    end
    nbrow = nrow(df)
    res = DataFrame()
    for p in unique_prefixes
        cols = names(df)[startswith.(names(df), p)]
        cols_to_check = [p*"_"*k for k in keywords]
        existing_cols = filter(c -> c in names(df), cols_to_check)
        if !isempty(cols)
            df2 = DataFrames.stack(df[:, existing_cols], existing_cols[1:end], variable_name = :TIME, value_name = Symbol(p))
        end
        total_nrow = 5*nbrow
        nb_news_rows = total_nrow - nrow(df2)
        if nrow(df2) < total_nrow
            append!(df2,new_rows)
        end
        res = hcat(res, df2; makeunique=true)
    end
    select!(res, Not(names(res)[occursin.("TIME_", names(res))]))
    res.TIME .= replace(res.TIME) do t
        if course == "4_40"
            if endswith(t, "_PRE")
                "-2"
            elseif endswith(t, "_POST")
                "1"
            elseif endswith(t, "_POST_2")
                "2"
            elseif endswith(t, "_POST_3")
                "3"
            elseif endswith(t, "_POST_4")
                "4"
            elseif endswith(t, "_D_2")
                "6"
            elseif endswith(t, "_D_5")
                "8"
            elseif endswith(t, "_D_10")
                "13"
            else
                t
            end
        else
            if endswith(t, "_PRE")
                "-2"
            elseif endswith(t, "_POST")
                "1"
            elseif endswith(t, "_D_2")
                "3"
            elseif endswith(t, "_D_5")
                "6"
            elseif endswith(t, "_D_10")
                "11"
            else
                t
            end
        end
    end
    res.TIME = parse.(Int, res.TIME)
    return res
end

# Ajout de la course et du code sujet modifié 
function addCOURSE_SUJET(df, df_stacked)
    if df.COURSE[1] == "4_40"
        COURSE = df[:,"COURSE"]
        COURSE = repeat(COURSE, 8)
        CODE_SUJET = repeat(60:79,8)
        res = hcat(COURSE, df_stacked)
        rename!(res, :x1 => "COURSE")
        res = hcat(CODE_SUJET, res)
        rename!(res, :x1 => "CODE_SUJET")
    else
        COURSE = df[:,"COURSE"]
        CODE_SUJET = repeat(1:nrow(df), 5)
        COURSE  = repeat(COURSE, 5)
        res = hcat(COURSE, df_stacked)
        rename!(res, :x1 => "COURSE")
        res = hcat(CODE_SUJET, res)
        rename!(res, :x1 => "CODE_SUJET")
    end
    return res
end

# L'objectif de cette fonction est de convertir les colonnes en int et float
function convert_float_int(df)
    for col in names(df)
        # Vérifie si la colonne contient au moins un élément avec un point décimal
        if any(x -> occursin(r"\.", string(x)), df[!, col])
            # Convertir en Float64 tout en préservant les missing
            df[!, col] = [ismissing(x) ? missing : Float64(x) for x in df[!, col]]
        else
            # Convertir en Int64 tout en préservant les missing
            df[!, col] = [ismissing(x) ? missing : Int64(x) for x in df[!, col]]
        end
    end
end

# Cette fonction permet de convertir une chaîne de caractères en En entier
function convert_to_times(df)
    for col in filter(col -> occursin("TIMESTAMP", col) && !occursin("TIMESTAMP_PRE", col), names(df))
        df[:, Symbol(col)] = [ismissing(df[i, Symbol(col)]) ? missing : Dates.value(df[i, Symbol(col)] - df[i, :TIMESTAMP_PRE])/60000 for i in 1:nrow(df)]
    end
    # Remplacer toutes les valeurs de la colonne TIMESTAMP_PRE par 0
    df.TIMESTAMP_PRE .= 0
    return df
end
