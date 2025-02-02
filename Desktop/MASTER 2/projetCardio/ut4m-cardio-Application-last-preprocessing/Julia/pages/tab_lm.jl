function build_linear_tab!(app::Dash.DashApp)
    data = build_data_cardiac("./Ressources/Données complètes UT4M final120419 avec Data cardio.xlsx")
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
    list_var = names(data)[5:end]
    layout_input_lm = html_div(
        id = "div-lm-input",
        children = [
            html_h1("Modèle linéaire"),
            html_h2("Choix de la variable"),
            dcc_dropdown(
                id="lm-var-dropdown",
                options=[Dict("label" => var, "value" => var) for var in list_var],
                value=list_var[1]
            ),
            html_h2("Choix du temps T1"),
            dcc_dropdown(
                id="lm-t1-dropdown",
                options=[Dict("label" => t, "value" => t) for t in keys(temps)],
                value="PRE"
            ),
            html_h2("Choix du temps T2"),
            dcc_dropdown(
                id="lm-t2-dropdown",
                options=[Dict("label" => t, "value" => t) for t in keys(temps)],
                value="POST"
            ),
            html_h2("Choix du temps de la course 4x40km"),
            dcc_dropdown(
                id="lm-t440-dropdown",
                options=[Dict("label" => t, "value" => t) for t in keys(temps440)],
                value="POST4"
            ),
        ]
    )
    layout_ouptut_lm = html_div(
        id = "div-lm-output",
        children = [
            html_table([
                html_thead(id = "table-lm-header"),
                html_tbody(id = "table-lm-body")
            ]),
            dcc_graph(id = "graph-lm"),
        ]
    )
    return layout_input_lm,layout_ouptut_lm
end