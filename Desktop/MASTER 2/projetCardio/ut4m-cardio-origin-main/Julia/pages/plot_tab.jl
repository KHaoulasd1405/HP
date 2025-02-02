function build_plot_page!(app::Dash.DashApp)
    data = build_data_cardiac("./Ressources/Données complètes UT4M final120419 avec Data cardio.xlsx")
    list_course = filter(x -> x != "4_40", unique(data[:,"COURSE"]))
    list_var = names(data)[4:end]
    div_params = html_div(
        id = "div-params-plot",
        children = [
            html_h1("Choix de la course"),
            dcc_dropdown(
                id="course-dropdown-plot",
                options=[Dict("label" => format_course_label(course), "value" => course) for course in list_course],
                value=unique(data[:,"COURSE"])[1]
            ),
            html_h1("Choix de la variable"),
            dcc_dropdown(
                id="var-dropdown-plot",
                options=[Dict("label" => var, "value" => var) for var in list_var],
                value=list_var[1]
            ),
        ]
    )
    div_plot = html_div(
        id = "div-plot",
        children = [
            dcc_graph(id = "graph"),
        ]
    )
    return  div_plot,div_params
end