function build_spline_tab!(app::Dash.DashApp)
    data = build_data_cardiac("./Ressources/Données complètes UT4M final120419 avec Data cardio.xlsx")
    list_var = names(data)[5:end]
    layout_input_spline = html_div(
        id = "div-spline-input",
        children = [
            html_h1("Modèle spline"),
            html_h2("Choix de la variable"),
            dcc_dropdown(
                id="spline-var-dropdown",
                options=[Dict("label" => var, "value" => var) for var in list_var],
                value=list_var[1]
            ),
        ]
    )
    layout_ouptut_spline = html_div(
        id = "div-spline-output",
        children = [
            dcc_graph(id = "graph-spline"),
        ]
    )
    return layout_input_spline,layout_ouptut_spline
end