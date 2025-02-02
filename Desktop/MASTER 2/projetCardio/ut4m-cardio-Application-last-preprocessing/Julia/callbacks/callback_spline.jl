function predict_spline_coefficients(data::DataFrame, course::Any, response_col::Symbol, show_nodes::Bool=false)
    
    # Filtrer les données pour la course spécifiée
    sub_data = data[data.COURSE .== course, [:CODE_SUJET, :COURSE, :TIME, :TIMESTAMP, response_col]]
    dropmissing!(sub_data)

    # Calculer les timestamps moyens pour chaque temps unique
    list_time = unique(sub_data.TIME)
    mean_timestamp = Vector{Float64}()
    for time in list_time
        push!(mean_timestamp, mean(sub_data[sub_data.TIME .== time, :TIMESTAMP]))
    end

    # Extraire les colonnes de réponse et de timestamp
    vol = sub_data[!, response_col]
    vec_timestamp = sub_data.TIMESTAMP
    vol = convert(Vector{Float64}, vol)
    vec_timestamp = convert(Vector{Float64}, vec_timestamp)

    # Construire la matrice de spline
    build_spline = Splines2.ns(vec_timestamp, boundary_knots=(0.0, maximum(vec_timestamp)), interior_knots=mean_timestamp[2:end])

    # Créer un DataFrame à partir de la matrice de spline et du vecteur de réponse
    num_splines = length(mean_timestamp)
    spline_columns = Symbol.("spline" .* string.(1:num_splines))
    df = DataFrame(build_spline, spline_columns)
    df[!, :VOL] = vol

    # Définir la formule pour le modèle linéaire
    formula = Term(:VOL) ~ sum(Term.(spline_columns))

    # Ajuster le modèle linéaire
    model = lm(formula, df)

    # Obtenir les coefficients du modèle
    coefficients = coef(model)

    # Prédire les valeurs pour de nouveaux points
    newx = collect(0.0:100:maximum(vec_timestamp))
    new_spline = Splines2.ns(newx, boundary_knots=(0.0, maximum(vec_timestamp)), interior_knots=mean_timestamp[2:end])
    new_df = DataFrame(new_spline, spline_columns)
    ypred = predict(model, new_df)

    # Filtrer les prédictions NaN
    filter_pred = isnan.(ypred)
    yto_plot = ypred[.!filter_pred]
    xto_plot = newx[.!filter_pred]

    # Calculer la moyenne des volumes
    average_vol = mean(vol)

    # Créer les graphiques
    if show_nodes
        p2 = scatter(x=xto_plot, y=yto_plot, mode="lines", name="Prediction $(course) km")
        p3 = scatter(x=mean_timestamp[2:end], y=average_vol * ones(length(mean_timestamp[2:end])), mode="markers", name="Noeud interne $(course) km")
        p4 = scatter(x=[mean_timestamp[1], maximum(vec_timestamp)], y=[average_vol, average_vol], mode="markers", name="Noeud externe $(course) km")
        plot = [p2, p3, p4]
        return coefficients, plot
    else
        p1 = scatter(x=xto_plot, y=yto_plot, mode="lines", name="Prediction $(course) km")
        plot = p1
        return coefficients, plot
    end
end

function build_plot_list(liste_plot)
    plot_list = Array{Any,1}()
    for plot in liste_plot
        if length(plot) > 1
            for p in plot
                push!(plot_list, p)
            end
        else
            push!(plot_list, plot)
        end
    end
    return plot_list
    
end

function build_plot_spline!(app)
    callback!(
        app,
        Output("graph-spline", "figure"),
        Input("spline-var-dropdown", "value"),
    ) do variable_study
        data = build_data_cardiac("./Ressources/Données complètes UT4M final120419 avec Data cardio.xlsx")
        courses = unique(data.COURSE)
        temp_list = []
        for c in courses
            coefficients, plot = predict_spline_coefficients(data, c, Symbol(variable_study), true)
            push!(temp_list, (plot))
        end
        plot_list = build_plot_list(temp_list)
        plot_list = convert.(GenericTrace{Dict{Symbol, Any}}, plot_list)
        return Plot(plot_list)
    end
    
end