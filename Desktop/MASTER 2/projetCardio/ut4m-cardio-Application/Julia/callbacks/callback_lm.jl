function fit_linear_model(df::DataFrame, val_study::String,t1::String,t2::String, times::Dict{String,Int64})    
    filtered_rows_t1 = filter(row -> row.TIME == times[t1], df)
    filtered_rows_t2 = filter(row -> row.TIME == times[t2], df)
    
    
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
    combined_df = filter(row -> row.COURSE != "4_40", combined_df)
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

    group_names = Dict(1 => "100 km", 2 => "160 km", 3 => "40 km")

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

function build_callback_lm!(app)
    callback!(
        app,
        Output("table-lm-header", "children"),
        Output("table-lm-body", "children"),
        Output("graph-lm", "figure"),
        Input("lm-var-dropdown", "value"),
        Input("lm-t1-dropdown", "value"),
        Input("lm-t2-dropdown", "value"),
    ) do var, t1,t2
        fit_linear_model(data,var,t1,t2,temps)
    end
end
