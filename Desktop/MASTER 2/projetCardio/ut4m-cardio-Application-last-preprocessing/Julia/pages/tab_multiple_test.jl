function build_multiple_test_tab!(app::Dash.DashApp)
    data = build_data_cardiac("./Ressources/Données complètes UT4M final120419 avec Data cardio.xlsx")
    temps = Dict(
        "PRE" => -2,
        "POST" => 1,
        "J+2" => 3,
        "J+5" => 6,
        "J+10" => 11,
    )
    list_var = names(data)[5:end]
    layout_input_mt = html_div(
        id = "div-mt-input",
        children = [
            html_h1("Tests multiples"),
            html_h2("Choix des variables"),
            dcc_dropdown(
                id="mt-var-dropdown",
                options=[Dict("label" => var, "value" => var) for var in list_var],
                value=list_var,
                multi=true
            ),
        ]
    )
    layout_output_mt = html_div(
        id = "div-mt-output",
        children = [
            html_h3("Tests multiples basés sur le test de Mann-Whitney pour évaluer la différence pour les mêmes temps à des courses différentes"),
            html_table([
                html_thead(id = "table-mt1-header"),
                html_tbody(id = "table-mt1-body")
            ]),
            html_h3("Tests multiples basés sur le test de Wilcoxon (appariées) pour évaluer la différence pour les mêmes courses à des temps différents"),
            html_table([
                html_thead(id = "table-mt2-header"),
                html_tbody(id = "table-mt2-body")
            ]),
        ]
    )
    return layout_input_mt,layout_output_mt
end