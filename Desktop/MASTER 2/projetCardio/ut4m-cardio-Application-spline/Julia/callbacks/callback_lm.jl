function fit_linear_model(df::DataFrame, val_study::String,t1::String,t2::String,t440::String,times::Dict{String,Int64}, times440::Dict{String,Int64})    
    filtered_rows_t1 = filter(row -> row.TIME == (row.COURSE == "4_40" ? times440[t440] : times[t1]), df)
    filtered_rows_t2 = filter(row -> row.TIME == (row.COURSE == "4_40" ? times440[t440] : times[t2]), df)
    
    
    # Sélectionner uniquement les colonnes TIME et val_study
    filtered_df_t1 = filtered_rows_t1[:, [Symbol(val_study), :COURSE]]
    rename!(filtered_df_t1, Symbol(val_study) => Symbol(t1))

    filtered_df_t2 = filtered_rows_t2[:, [Symbol(val_study)]]
    rename!(filtered_df_t2, Symbol(val_study) => Symbol(t2))
    

    # Combiner les DataFrames
    combined_df = hcat(filtered_df_t1, filtered_df_t2)
    combined_df = dropmissing(combined_df)
    
    
    # Convertir les colonnes en Float64 et catégoriser COURSE
    
    combined_df[!, Symbol(t1)] = convert.(Float64, combined_df[!, Symbol(t1)])
    combined_df[!, Symbol(t2)] = convert.(Float64, combined_df[!, Symbol(t2)])
    combined_df.COURSE = string.(combined_df.COURSE)
    combined_df.COURSE = categorical(combined_df.COURSE)
    # combined_df = filter(row -> row.COURSE != "4_40", combined_df)
    # Ajuster le modèle linéaire

    valt1 = eval(t1)
    valt2 = eval(t2)
    formula_expr = @eval @formula($(Symbol(t1)) -  $(Symbol(t2)) ~ -1  + COURSE)
    model = lm(formula_expr, combined_df)
    coefficients = coef(model)
    
    println(residuals(model))
    # Extract coefficients and statistics
    coef_table = coeftable(model)
    coef_data = DataFrame(coef_table)
    coef_data[1:end,2:end] = round.(coef_data[1:end,2:end],digits=4)
    IC = coef_data[1:end, end-1:end]

    # Convertir le DataFrame en vecteur par ligne
    X = vec(Matrix(IC)')

    # Générer dynamiquement les colonnes y et id
    n = length(X) ÷ 2
    y = repeat(collect(2:2:2*n), inner=2)
    id = repeat(1:n, inner=2)

    group_names = Dict(1 => "100 km", 2 => "160 km", 3 => "40 km", 4 => "4x40km")

    test_df = DataFrame(
        x = X,
        y = y,
        id = id
    )
    residu = residuals(model)
    # Personnalisation et affichage
    res_pval = pvalue(ShapiroWilkTest(residu))
    res_pval = round(res_pval,digits=4)
    println(typeof(res_pval))
    str_model = t1*" - "*t2*" ~ COURSE"
    layout = Layout(
        title="IC des coefficients pour le modèle "*string(str_model),
        xaxis_title="",
        yaxis_title="",
        shapes = [
            attr(
                type = "line",
                x0 = 0,
                x1 = 0,
                y0 = minimum(test_df.y)-2,
                y1 = maximum(test_df.y)+2,
                line = attr(
                    color = "Black",
                    width = 2,
                    dash = "dash"
                )
            )
        ]
    )

    println(test_df[:,:id])
    test_df.id = [group_names[i] for i in test_df.id]
    plt = plot(test_df, :x, :y, group=:id, layout)
    #plt = plot(traces, layout)
    println(pvalue(ShapiroWilkTest(residu)))
    return html_tr([html_th(col) for col in names(coef_data)]), [html_tr([html_td(coef_data[r, c]) for c in names(coef_data)]) for r = 1:nrow(coef_data)], plt
end
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
    "J+5" => 9,
    "J+10" => 14,
)

#= function lm_timestamp(data, var)
    # Récupérer la colonne TIMESTAMP et la colonne VAR de DATA
    df = data[:, [:COURSE, :TIME, :TIMESTAMP, Symbol(var)]]
    df = dropmissing(df)
    df[!, Symbol(var)] = convert.(Float64, df[!, Symbol(var)])
    df.COURSE = string.(df.COURSE)
    df.COURSE = categorical(df.COURSE)
    
    # Créer le modèle linéaire
    formula_expr = @eval @formula($(Symbol(var)) ~ $(Symbol(:TIMESTAMP)) + COURSE)
    model = lm(formula_expr, df)
    
    # Obtenir les prédictions du modèle
    df[!, :Predicted] = predict(model, df)
    
    # Tracer les points et la droite de régression
    p = plot(df.TIMESTAMP, df[!, Symbol(var)], seriestype = :scatter, label = "Data Points")
    plot!(p, df.TIMESTAMP, df.Predicted, label = "Regression Line", linewidth = 2)
    
    return p
end =#

function build_callback_lm!(app)
    callback!(
        app,
        Output("table-lm-header", "children"),
        Output("table-lm-body", "children"),
        Output("graph-lm", "figure"),
        Input("lm-var-dropdown", "value"),
        Input("lm-t1-dropdown", "value"),
        Input("lm-t2-dropdown", "value"),
        Input("lm-t440-dropdown", "value"),
    ) do var, t1,t2,t440
        fit_linear_model(data,var,t1,t2,t440,temps,temps440)
    end
#=     callback!(
        app,
        Output("graph-lm-timestamp", "figure"),
        Input("lm-var-dropdown", "value"),
    ) do var
        data
        lm_timestamp(data,var)
    end =#
end
