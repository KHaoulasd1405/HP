function build_mixed_tab!(app::Dash.DashApp)
    data = build_data_cardiac("./Ressources/Données complètes UT4M final120419 avec Data cardio.xlsx")
    list_var = names(data)[4:end]
    layout_input_mix = html_div(
        id = "div-mix-input",
        children = [
            html_h1("Modèle mixte"),
            html_h2("Choix de la variable"),
            dcc_dropdown(
                id="mixed-var-dropdown",
                options=[Dict("label" => var, "value" => var) for var in list_var],
                value=list_var[1]
            ),
        ]
    )
    layout_ouptut_mixed = html_div(
        id = "div-glm-output",
        children = [
            html_table([
                html_thead(id = "table-glm-header"),
                html_tbody(id = "table-glm-body")
            ]),
            dcc_graph(id = "graph-glm-trend"),
            dcc_graph(id = "graph-glm-hist"),
            dcc_graph(id = "graph-glm-res"),
        ]
    )
    return layout_input_mix,layout_ouptut_mixed
end