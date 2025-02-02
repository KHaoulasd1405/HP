# Remplacer une valeurs par une autre dans tout le dataframe
function replaceDF(df, old, new)
    for col in names(df)
        df[!, col] = replace(df[!, col], old => new)
    end
    return df
end

# Cette fonction prend un dataframe en entrée et pivote les colonnes en lignes
function colToRow(df, keywords = ["PRE", "POST", "D_2", "D_5", "D_10"])
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

# Ajout de la course et du code sujet modifié 
function addCOURSE_SUJET(df, df_stacked)
    COURSE = df[:,"COURSE"]
    CODE_SUJET = repeat(1:nrow(df), 5)
    COURSE  = repeat(COURSE, 5)
    res = hcat(COURSE, df_stacked)
    rename!(res, :x1 => "COURSE")
    res = hcat(CODE_SUJET, res)
    rename!(res, :x1 => "CODE_SUJET")
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