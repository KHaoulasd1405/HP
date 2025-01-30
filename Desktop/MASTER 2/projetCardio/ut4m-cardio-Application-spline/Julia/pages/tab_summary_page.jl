function build_tab_summary!(app::Dash.DashApp)
    data = build_data_cardiac("./Ressources/Données complètes UT4M final120419 avec Data cardio.xlsx")
    data_hda = build_hda_data("./Ressources/Données complètes UT4M final120419 avec Data cardio.xlsx")
    var_of_interest = ["VOL_OGI","VOL_ODI","VTDVGI","VTSVGI","FE2D","STDi","STSi","E/A" ,"E/Ea"]
    course_option = unique(data[:,"COURSE"])

    # Nombre de participants par course
    data[:, :COURSE] = map(x -> format_course_label(x), data[:, :COURSE])
    grouped = groupby(data, :COURSE)
    nparcourse = DataFrames.combine(grouped, nrow)
    nparcourse[!, :nrow] = map(row -> row[:COURSE] == "4_40" ? row[:nrow] / 8 : row[:nrow] / 5, eachrow(nparcourse))
    rename!(nparcourse, Dict(:COURSE => "Course", :nrow => "Nombre de participants"))
    
    # Obtenir les données des abandons
    abandons_data = count_abandons_course(data_hda)
    
    # Obtenir les données des non participants
    np_data = count_non_participants(data_hda)

    final_data = hcat(nparcourse, abandons_data[:,2], np_data[:,2], makeunique=true)
    rename!(final_data, Dict(:Course => "Course", :x1 => "Nombre d'abandons", :x1_1 => "Nombre de non-participants"))

    Layout_content = html_div(
        children = [
            html_div(id = "div-tab-nb-participants",
            children = [
                html_table([
                    html_thead(id = "table-count-header", children = [
                        html_tr([html_th(col) for col in names(final_data)])
                    ]),
                    html_tbody(id = "table-count-body", children = [
                            html_tr([html_td(final_data[r, c]) for c in names(final_data)]) for r = 1:nrow(final_data)
                    ])
                ]),
            ]),
            html_div(id = "div-tab-summary",
                    children = [
                        html_table([
                            html_thead(id = "table-summary-header"),
                            html_tbody(id = "table-summary-body")
                        ]),
                        html_table([
                            html_thead(id = "table-nmissing-header"),
                            html_tbody(id = "table-nmissing-body")
                        ]),
                    ]
            ),
            html_div(id="graph-div",
                children = [
                    dcc_graph(id = "graph-vi"),
                    dcc_graph(id = "graph-vi-440"),
                    dcc_graph(id = "graph-vi2")
                ]
            )
        ]    
    )
    Layout_tab = html_div(
        id = "layout-tab-summary",
        children = [
            html_div(
        ) do
            [
                html_div(
                ) do
                    [
                        html_h2("Choix de la course"),
                        dcc_dropdown(
                            id="course-dropdown",
                            options=[Dict("label" => format_course_label(course), "value" => course) for course in course_option],
                            value=course_option[1]
                        )
                    ]
                end,
                html_div(
                ) do
                    [
                        html_h2("Choix des variables"),
                        dcc_dropdown(
                            id="variable-dropdown",
                            options=[Dict("label" => course, "value" => course) for course in names(data)], 
                            value=var_of_interest,
                            multi = true
                        )
                    ]
                end
            ]
            end,
            html_h2("Choix de la dimension pour le comptage des valeurs manquantes"),
            dcc_dropdown(
                id="dim-dropdown",
                options=[:TIME,:COURSE,:CODE_SUJET], 
                value="TIME",
                multi = false
            ),
            html_h2("Choix de la variable pour la variabilité inter et intra-individuelle"),
            dcc_dropdown(
                id="onevar-dropdown",
                options=[Dict("label" => course, "value" => course) for course in names(data)], 
                value="VTDVGI",
                multi = false
            ),
        ]
    )
    return Layout_tab, Layout_content
end