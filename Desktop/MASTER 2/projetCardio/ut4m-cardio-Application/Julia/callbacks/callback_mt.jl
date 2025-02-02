function create_multiple_test_MW(data::DataFrame, val_study::String)    
    temps = Dict(
    "PRE" => -2,
    "POST" => 1,
    "J+2" => 3,
    "J+5" => 6,
    "J+10" => 11,
    )
    
    # Exemple d'utilisation
    lst = ["PRE", "POST", "J+2", "J+5", "J+10"]
    courses = [100, 160, 40]
    df_res = DataFrames.DataFrame((Courses = [], Temps = [], N = [], Pvaleur = []))
    combinations = generate_combinations(lst)
    combinations_courses = generate_combinations(courses)
    for c in combinations_courses
        for comb in combinations
            if ((c[1] != c[2]) && (comb[1] != comb[2]))
                continue
            end
            if ((c[1] != c[2]) && (comb[1] == comb[2]))
                t1 = temps[comb[1]]
                t2 = temps[comb[2]]
                x = convert(Vector{Float64}, collect(skipmissing(filter(row -> row.TIME == t1 && row.COURSE == c[1], data)[:, Symbol(val_study)])))
                y = convert(Vector{Float64}, collect(skipmissing(filter(row -> row.TIME == t2 && row.COURSE == c[2], data)[:, Symbol(val_study)])))
                pv = round.(pvalue(MannWhitneyUTest(x, y)),digits=3)
                df_res = vcat(df_res,DataFrames.DataFrame((Courses = ["$(c[1])  VS $(c[2])"], Temps = ["$(comb[1]) VS $(comb[2])"], N = ["($(length(x)), $(length(y)))"], Pvaleur = [pv])))
            end
        end
    end
    pvals = convert(Vector{Float64}, df_res[:, :Pvaleur])
    df_res = hcat(df_res,DataFrame(BY = round.(adjust(pvals, BenjaminiYekutieli()),digits=3)))
    df_res = hcat(df_res,DataFrame(Hochberg = round.(adjust(pvals, Hochberg()),digits=3)))
    df_res = hcat(df_res,DataFrame(Holm = round.(adjust(pvals, Holm()),digits=3)))
    sort!(df_res, :Pvaleur)
    return html_tr([html_th(col) for col in names(df_res)]), [html_tr([html_td(df_res[r, c]) for c in names(df_res)]) for r = 1:nrow(df_res)]
end

function create_multiple_test_WX(data::DataFrame, val_study::String)    
    temps = Dict(
    "PRE" => -2,
    "POST" => 1,
    "J+2" => 3,
    "J+5" => 6,
    "J+10" => 11,
    )
    
    # Exemple d'utilisation
    lst = ["PRE", "POST", "J+2", "J+5", "J+10"]
    courses = [100, 160, 40]
    df_res = DataFrames.DataFrame((Courses = [], Temps = [], N = [], Pvaleur = []))
    combinations = generate_combinations(lst)
    combinations_courses = generate_combinations(courses)
    for c in combinations_courses
        for comb in combinations
            if ((c[1] != c[2]) && (comb[1] != comb[2]))
                continue
            end
            if ((c[1] == c[2]) && (comb[1] != comb[2]))
                t1 = temps[comb[1]]
                t2 = temps[comb[2]]
                # je veux commencer par sortir les indices pour lesquels il y a des missing 
                indicex = findall(ismissing, filter(row -> row.TIME == t1 && row.COURSE == c[1], data)[:, Symbol(val_study)])
                indicey = findall(ismissing, filter(row -> row.TIME == t2 && row.COURSE == c[2], data)[:, Symbol(val_study)])
                indices = sort(unique(union(indicex, indicey)))
                # Dans les listes x et y, je retire les indices pour lesquels il y a des missing
                x = convert(Vector{Float64}, deleteat!(filter(row -> row.TIME == t1 && row.COURSE == c[1], data)[:, Symbol(val_study)], indices))
                y = convert(Vector{Float64}, deleteat!(filter(row -> row.TIME == t2 && row.COURSE == c[2], data)[:, Symbol(val_study)], indices))
                pv = round.(pvalue(SignedRankTest(x, y)),digits=3)
                df_res = vcat(df_res,DataFrames.DataFrame((Courses = ["$(c[1])  VS $(c[2])"], Temps = ["$(comb[1]) VS $(comb[2])"], N = ["($(length(x)), $(length(y)))"], Pvaleur = [pv])))
            end
        end
    end
    pvals = convert(Vector{Float64}, df_res[:, :Pvaleur])
    df_res = hcat(df_res,DataFrame(BY = round.(adjust(pvals, BenjaminiYekutieli()),digits=3)))
    df_res = hcat(df_res,DataFrame(Hochberg = round.(adjust(pvals, Hochberg()),digits=3)))
    df_res = hcat(df_res,DataFrame(Holm = round.(adjust(pvals, Holm()),digits=3)))
    sort!(df_res, :Pvaleur)
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
        create_multiple_test_MW(data,var)
    end
    callback!(
        app,
        Output("table-mt2-header", "children"),
        Output("table-mt2-body", "children"),
        Input("mt-var-dropdown", "value"),
    ) do var
        data = build_data_cardiac("./Ressources/Données complètes UT4M final120419 avec Data cardio.xlsx")
        create_multiple_test_WX(data,var)
    end
end
