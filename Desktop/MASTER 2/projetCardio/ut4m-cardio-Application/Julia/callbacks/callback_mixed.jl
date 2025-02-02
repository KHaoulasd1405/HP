import DataFrames: combine
using Colors

function interpolate(xs::AbstractVector, fs::AbstractVector{T}) where T
    p = 3
    k = KnotVector(xs) + KnotVector([xs[1],xs[end]]) * p
    P = BSplineSpace{p}(k)

    m = length(xs)
    n = dim(P)

    ddP = BSplineDerivativeSpace{2}(P)
    dda = [bsplinebasis(ddP,j,xs[1]) for j in 1:n]
    ddb = [bsplinebasis(ddP,j,xs[m]) for j in 1:n]

    M = [bsplinebasis(P,j,xs[i]) for i in 1:m, j in 1:n]
    M = vcat(dda', M, ddb')
    y = vcat(zero(T), fs, zero(T))
    return BSplineManifold(M\y, P)
end

function fit_glm_model(df::DataFrame, val_study::String)    
    symbol_val_study = Symbol(val_study)
    SUB_DATA = df[:, [:CODE_SUJET, :COURSE, :TIME, symbol_val_study]]
    SUB_DATA = dropmissing!(SUB_DATA, symbol_val_study)
    SUB_DATA = filter!(x -> x.COURSE != "4_40", SUB_DATA)
    SUB_DATA[!,symbol_val_study] = convert(Vector{Float64}, SUB_DATA[!,symbol_val_study])
    SUB_DATA.TIME = convert(Vector{Float64}, SUB_DATA.TIME)
    mean_list = combine(groupby(SUB_DATA, :TIME), symbol_val_study => mean => symbol_val_study)
    x = mean_list[!,:TIME]
    y = mean_list[!,symbol_val_study]
    f = interpolate(x,y)
    model = fit(
        MixedModel,
        (@eval @formula($(Symbol(val_study)) ~ -1 + COURSE + $f(TIME) + (1 | CODE_SUJET))),
        SUB_DATA
    )
    coef_table = coeftable(model)
    coef_data = DataFrame(coef_table)
    coef_data[end,1] = "splines"
    
    fitted_values = fitted(model)
    residu = residuals(model)
    random_effects = ranef(model)

    unique_subjects = unique(SUB_DATA.CODE_SUJET)
    color_map = Dict(subject => RGB(rand(), rand(), rand()) for subject in unique_subjects)
    colors = [color_map[subject] for subject in SUB_DATA.CODE_SUJET]

    # Plot 1: Évolution temporelle des mesures cardiaques
    trace1 = scatter(x=mean_list.TIME, y=mean_list[!,symbol_val_study],
    mode="markers+lines",
    name="Tendance globale", marker_color=:blue)

    # Plot 2: Caterpillar Plot des effets aléatoires
    trace2 = scatter(x=1:length(random_effects[:, 1]), y=random_effects[:, 1],
    mode="markers", name="Effets Aléatoires (Intercept)",
    marker_color=:orange)

    # Plot 3: Résidus vs Valeurs Ajustées
    trace3 = scatter(x=fitted_values, y=residu,
    mode="markers", name="Résidus vs Ajustés",
    marker_color=colors)

    # Plot 4: Histogramme des Résidus
    trace4 = histogram(x=residu, nbinsx=10, name="Histogramme Résidus",
    marker_color=:green)

    # Organisation en grille 2x2
    layout1 = Layout(
        title="Tendance globale",
        xaxis=attr(title="Temps",
        tickmode="array",              # Mode personnalisé pour les ticks
        tickvals=unique(df.TIME),     # Positions des ticks
        ticktext=["PRE","POST","J+2","J+5","J+10"]  # Labels des ticks
        ), yaxis=attr(title="Mesure Moyenne"),
    )
    layout2 = Layout(
        title="Résidus vs Ajustés",
        xaxis=attr(title="Valeurs Ajustées"), yaxis=attr(title="Résidus"),
    )
    layout3 = Layout(
        title="Histogramme Résidus",
        xaxis=attr(title="Résidus"), yaxis=attr(title="Fréquence")
    )

    fig = [trace1, trace3, trace4]

    return html_tr([html_th(col) for col in names(coef_data)]), [html_tr([html_td(coef_data[r, c]) for c in names(coef_data)]) for r = 1:nrow(coef_data)], Plot(fig[1],layout1),Plot(fig[2],layout2),Plot(fig[3],layout3)
end



function build_callback_glm!(app,data)
    callback!(
        app,
        Output("table-glm-header", "children"),
        Output("table-glm-body", "children"),
        Output("graph-glm-trend", "figure"),
        Output("graph-glm-hist", "figure"),
        Output("graph-glm-res", "figure"),
        Input("mixed-var-dropdown", "value"),
    ) do var
        fit_glm_model(data,var)
    end
end
