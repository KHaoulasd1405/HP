function create_multiple_test_MW(data::DataFrame, val_study)    
    temps = Dict(
    "PRE" => -2,
    "POST" => 1,
    "J+2" => 3,
    "J+5" => 6,
    "J+10" => 11,
    )
    
    temps440 = Dict(
        "PRE" => -2,
        "POST" => 1,
        "POST2" => 2,
        "POST3" => 3,
        "POST4" => 4,
        "J+2" => 6,
        "J+5" => 8,
        "J+10" => 13,
        )
    
    
    # Exemple d'utilisation
    lst = ["PRE", "POST", "J+2", "J+5", "J+10"]
    courses = [100, 160, 40]
    lst440 = ["PRE","POST4", "POST", "J+2", "J+5", "J+10"]
    courses440 = ["4_40", 100, 160, 40]
    df_res = DataFrames.DataFrame((Variable = [], Courses = [], Temps = [], N = [], Pvaleur = []))
    combinations = generate_combinations(lst)
    combinations440 = generate_combinations(lst440)
    combinations_courses = generate_combinations(courses)
    combinations_courses_440 = generate_combinations(courses440)
    for v in val_study
        for c in combinations_courses
            for comb in combinations
                if ((c[1] != c[2]) && (comb[1] != comb[2]))
                    continue
                end
                if ((c[1] != c[2]) && (comb[1] == comb[2]))
                    t1 = temps[comb[1]]
                    t2 = temps[comb[2]]
                    x = convert(Vector{Float64}, collect(skipmissing(filter(row -> row.TIME == t1 && row.COURSE == c[1], data)[:, Symbol(v)])))
                    y = convert(Vector{Float64}, collect(skipmissing(filter(row -> row.TIME == t2 && row.COURSE == c[2], data)[:, Symbol(v)])))
                    pv = round.(pvalue(MannWhitneyUTest(x, y)),digits=5)
                    if pv < 0 || pv > 1
                        continue
                    end
                    df_res = vcat(df_res,DataFrames.DataFrame((Variable = [v], Courses = ["$(c[1])  VS $(c[2])"], Temps = ["$(comb[1]) VS $(comb[2])"], N = ["($(length(x)), $(length(y)))"], Pvaleur = [pv])))
                end
            end
        end
    end
    for v in val_study
        for c in combinations_courses_440
            for comb in combinations440
                if ((c[1] == "4_40") && (comb[1] == "POST"))
                    continue
                end
                if ((c[1] == "4_40") && (c[1] != c[2]) && (comb[1] == comb[2] || (comb[1] == "POST4" && comb[2] == "POST")) && (comb[2] != "POST4"))
                    t1 = temps440[comb[1]]
                    t2 = temps[comb[2]]
                    x = convert(Vector{Float64}, collect(skipmissing(filter(row -> row.TIME == t1 && row.COURSE == c[1], data)[:, Symbol(v)])))
                    y = convert(Vector{Float64}, collect(skipmissing(filter(row -> row.TIME == t2 && row.COURSE == c[2], data)[:, Symbol(v)])))
                    pv = round.(pvalue(MannWhitneyUTest(x, y)),digits=5)
                    if pv < 0 || pv > 1
                        continue
                    end
                    df_res = vcat(df_res,DataFrames.DataFrame((Variable = [v], Courses = ["$(c[1])  VS $(c[2])"], Temps = ["$(comb[1]) VS $(comb[2])"], N = ["($(length(x)), $(length(y)))"], Pvaleur = [pv])))
                end
            end
        end
    end
    # je veux ajouter une colonne qui contient que des "MW" pour dire que c'est un test de Mann-Whitney
    df_res = hcat(df_res,DataFrame(Test = fill("MW",nrow(df_res))))
    return df_res
end

function create_multiple_test_WX(data::DataFrame, val_study)    
    temps = Dict(
    "PRE" => -2,
    "POST" => 1,
    "J+2" => 3,
    "J+5" => 6,
    "J+10" => 11,
    )

    temps440 = Dict(
        "PRE" => -2,
        "POST" => 1,
        "POST2" => 2,
        "POST3" => 3,
        "POST4" => 4,
        "J+2" => 6,
        "J+5" => 8,
        "J+10" => 13,
        )
    
    # Exemple d'utilisation
    lst = ["PRE", "POST", "J+2", "J+5", "J+10"]
    courses = [100, 160, 40]
    lst440 = ["PRE", "POST","POST2","POST3","POST4", "J+2", "J+5", "J+10"]
    df_res = DataFrames.DataFrame((Variable = [], Courses = [], Temps = [], N = [], Pvaleur = []))
    combinations = generate_combinations(lst)
    combinations440 = generate_combinations(lst440)
    combinations_courses = generate_combinations(courses)
    for v in val_study
        for c in combinations_courses
            for comb in combinations
                if ((c[1] != c[2]) && (comb[1] != comb[2]))
                    continue
                end
                if ((c[1] == c[2]) && (comb[1] == "PRE") && (comb[1] != comb[2]))
                    t1 = temps[comb[1]]
                    t2 = temps[comb[2]]
                    # je veux commencer par sortir les indices pour lesquels il y a des missing 
                    indicex = findall(ismissing, filter(row -> row.TIME == t1 && row.COURSE == c[1], data)[:, Symbol(v)])
                    indicey = findall(ismissing, filter(row -> row.TIME == t2 && row.COURSE == c[2], data)[:, Symbol(v)])
                    indices = sort(unique(union(indicex, indicey)))
                    # Dans les listes x et y, je retire les indices pour lesquels il y a des missing
                    x = convert(Vector{Float64}, deleteat!(filter(row -> row.TIME == t1 && row.COURSE == c[1], data)[:, Symbol(v)], indices))
                    y = convert(Vector{Float64}, deleteat!(filter(row -> row.TIME == t2 && row.COURSE == c[2], data)[:, Symbol(v)], indices))
                    pv = round.(pvalue(SignedRankTest(x, y)),digits=5)
                    if pv < 0 || pv > 1
                        continue
                    end
                    df_res = vcat(df_res,DataFrames.DataFrame((Variable = [v], Courses = ["$(c[1])  VS $(c[2])"], Temps = ["$(comb[1]) VS $(comb[2])"], N = ["($(length(x)), $(length(y)))"], Pvaleur = [pv])))
                end
            end
        end
    end
    for v in val_study
        for c in combinations440
            if ((c[1] == "PRE") && (c[1] != c[2]))
                t1 = temps440[c[1]]
                t2 = temps440[c[2]]
                x = convert(Vector{Float64}, collect(skipmissing(filter(row -> row.TIME == t1 && row.COURSE == "4_40", data)[:, Symbol(v)])))
                y = convert(Vector{Float64}, collect(skipmissing(filter(row -> row.TIME == t2 && row.COURSE == "4_40", data)[:, Symbol(v)])))
                pv = round.(pvalue(MannWhitneyUTest(x, y)),digits=5)
                if pv < 0 || pv > 1
                    continue
                end
                df_res = vcat(df_res,DataFrames.DataFrame((Variable = [v], Courses = ["4x40 VS 4x40"], Temps = ["$(c[1]) VS $(c[2])"], N = ["($(length(x)), $(length(y)))"], Pvaleur = [pv])))
            end
        end
    end
    # je veux ajouter une colonne qui contient que des "WX" pour dire que c'est un test de Wilcoxon
    df_res = hcat(df_res,DataFrame(Test = fill("WX",nrow(df_res))))
    return df_res
#=     pvals = convert(Vector{Float64}, df_res[:, :Pvaleur])
    df_res = hcat(df_res,DataFrame(BY = round.(adjust(pvals, BenjaminiYekutieli()),digits=3)))
    df_res = hcat(df_res,DataFrame(Hochberg = round.(adjust(pvals, Hochberg()),digits=3)))
    df_res = hcat(df_res,DataFrame(Holm = round.(adjust(pvals, Holm()),digits=3)))
    sort!(df_res, :Pvaleur)
    return html_tr([html_th(col) for col in names(df_res)]), [html_tr([html_td(df_res[r, c]) for c in names(df_res)]) for r = 1:nrow(df_res)] =#
end

function corrections(dfMW, dfWX)
    df = vcat(dfMW,dfWX)
    pvals = convert(Vector{Float64}, df[:, :Pvaleur])
    df = hcat(df,DataFrame(BY = round.(adjust(pvals, BenjaminiYekutieli()),digits=5)))
    df = hcat(df,DataFrame(Hochberg = round.(adjust(pvals, Hochberg()),digits=5)))
    df = hcat(df,DataFrame(Holm = round.(adjust(pvals, Holm()),digits=5)))
    sort!(df, :Pvaleur)
    return df
end

function get_MW(data,var)
    df1 = create_multiple_test_MW(data,var)
    df2 = create_multiple_test_WX(data,var)
    df = corrections(df1,df2)
    df_res = df[df.Test .== "MW", :]
    df_res = select(df_res, Not(:Test))
    return html_tr([html_th(col) for col in names(df_res)]), [html_tr([html_td(df_res[r, c]) for c in names(df_res)]) for r = 1:nrow(df_res)]
end

function get_WX(data,var)
    df1 = create_multiple_test_MW(data,var)
    df2 = create_multiple_test_WX(data,var)
    df = corrections(df1,df2)
    df_res = df[df.Test .== "WX", :]
    df_res = select(df_res, Not(:Test))
    return html_tr([html_th(col) for col in names(df_res)]), [html_tr([html_td(df_res[r, c]) for c in names(df_res)]) for r = 1:nrow(df_res)]
end

function generate_combinations(lst)
    combinations = []
    for i in 1:length(lst)
        for j in i:length(lst)
            push!(combinations, (lst[i], lst[j]))
        end
    end
    return combinations
end

function build_callback_mt!(app)
    callback!(
        app,
        Output("table-mt1-header", "children"),
        Output("table-mt1-body", "children"),
        Input("mt-var-dropdown", "value"),
    ) do var
        data = build_data_cardiac("./Ressources/Données complètes UT4M final120419 avec Data cardio.xlsx")
        get_MW(data,var)
    end
    callback!(
        app,
        Output("table-mt2-header", "children"),
        Output("table-mt2-body", "children"),
        Input("mt-var-dropdown", "value"),
    ) do var
        data = build_data_cardiac("./Ressources/Données complètes UT4M final120419 avec Data cardio.xlsx")
        get_WX(data,var)
    end
end
