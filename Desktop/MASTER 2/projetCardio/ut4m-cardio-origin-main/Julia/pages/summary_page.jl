function build_page_summary!(app::Dash.DashApp)
    data = build_data_cardiac("./Ressources/Données complètes UT4M final120419 avec Data cardio.xlsx")
    data_all = build_all_data("./Ressources/Données complètes UT4M final120419 avec Data cardio.xlsx")
    var_of_interest = ["VOL_OGI","VOL_ODI","VTDVGI","VTSVGI","FE2D","STDi","STSi","E/A" ,"E/Ea"]
    course_option = unique(data[:,"COURSE"])

    # Nombre de participants par course
    data[:, :COURSE] = map(x -> format_course_label(x), data[:, :COURSE])
    grouped = groupby(data, :COURSE)
    nparcourse = DataFrames.combine(grouped, nrow)
    nparcourse[!, :nrow] .= nparcourse[!, :nrow] ./ 5
    rename!(nparcourse, Dict(:COURSE => "Course", :nrow => "Nombre de participants"))
    nparcourse = [Dict(col => row[col] for col in names(nparcourse)) for row in eachrow(nparcourse)]
    
    # Obtenir les données des abandons
    abandons_data = count_abandons_course(data_all)
    abandons_data = [Dict(col => row[col] for col in names(abandons_data)) for row in eachrow(abandons_data)]

    # Obtenir les données des non participants
    np_data = count_non_participants(data_all)
    np_data = [Dict(col => row[col] for col in names(np_data)) for row in eachrow(np_data)]

    # Obtenir les données manquantes
    nmissing_data = describe(data, :nmissing)
    rename!(nmissing_data, Dict(:nmissing => "Nombre de valeurs manquantes", :variable => "Variable"))
    nmissing_data_dict = [Dict(col => row[col] for col in names(nmissing_data)) for row in eachrow(nmissing_data)]


    Layout = html_div() do
        children = [
            html_h1("STATISTIQUES DE BASES"),
            html_div(
                style=Dict("display" => "flex", "justify-content" => "space-between")
            ) do
                [
                    html_div(
                        style=Dict("flex" => "1", "margin" => "10px", "max-width" => "300px", "overflow-x" => "auto")
                    ) do
                        dash_datatable(
                            id = "tab_count",
                            data = nparcourse,
                            page_size=20
                        )
                    end,
                    html_div(
                        style=Dict("flex" => "1", "margin" => "10px", "max-width" => "300px", "overflow-x" => "auto")
                    ) do
                        dash_datatable(
                            id = "tab_count_abandons",
                            data = abandons_data,
                            page_size=20
                        )
                    end,
                    html_div(
                        style=Dict("flex" => "1", "margin" => "10px", "max-width" => "300px", "overflow-x" => "auto")                        ) do
                        dash_datatable(
                            id = "tab_count_np",
                            data = np_data,
                            page_size=20
                        )
                    end
                ]
            end,
            html_div(
            style=Dict("display" => "flex", "justify-content" => "space-between")
        ) do
            [
                html_div(
                    style=Dict("flex" => "1", "margin" => "10px", "flex-basis" => "25%")
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
                    style=Dict("flex" => "3", "margin" => "10px", "flex-basis" => "75%")
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
            html_div(
                style=Dict("display" => "flex", "justify-content" => "center")
            ) do
                html_div(
                    style=Dict("flex" => "1", "margin" => "0", "flex-basis" => "100%")
                ) do
                    dash_datatable(
                        id = "tab_summary",
                        data = [Dict(col => row[col] for col in names(custom_summary(data))) for row in eachrow(custom_summary(data))],
                        page_size=20
                    )
                end
            end,
            html_h2("Choix de la dimension pour le comptage des valeurs manquantes"),
            dcc_dropdown(
                id="dim-dropdown",
                options=[:TIME,:COURSE,:CODE_SUJET], 
                value="TIME",
                multi = false
            ),
            dash_datatable(
                id = "tab_nmissing_1D",
                data = [Dict(col => row[col] for col in names(missing_values_1D(data, :TIME))) for row in eachrow(missing_values_1D(data, :TIME))],
                page_size=20
            ),
            html_h2("Choix de la variable pour la variabilité inter et intra-individuelle"),
            dcc_dropdown(
                id="onevar-dropdown",
                #= options=[Dict("label" => course, "value" => course) for course in names(data)],  =#
                options=["VTDVGI","VTSVGI"],
                value="VTDVGI",
                multi = false
            ),
            dcc_graph(id = "graph-vi"),
        ]
    end
    callback!(
        app,
        Output("tab_summary", "data"),
        Input("course-dropdown", "value"),
        Input("variable-dropdown", "value")
    ) do course_name, list_var
        selected_columns = var_of_interest
        if course_name != ""
            filtered_data = build_dataframe(course_name,list_var)
            summary_data = custom_summary(filtered_data)
            return [Dict(col => row[col] for col in names(summary_data)) for row in eachrow(summary_data)]
        end
        return [Dict(col => row[col] for col in names(custom_summary(data))) for row in eachrow(custom_summary(data))]
    end    
    callback!(
        app,
        Output("tab_nmissing", "data"),
        Input("course-dropdown", "value"),
        Input("variable-dropdown", "value")
    ) do course_name, list_var
        selected_columns = var_of_interest
        if course_name != ""
            data = build_dataframe(course_name, list_var)
            nmissing_data = describe(data, :nmissing)
            rename!(nmissing_data, Dict(:nmissing => "Nombre de valeurs manquantes", :variable => "Variable"))
            nmissing_data_dict = [Dict(col => row[col] for col in names(nmissing_data)) for row in eachrow(nmissing_data)]
            return nmissing_data_dict
        end
        nmissing_data = describe(data, :nmissing)
        rename!(nmissing_data, Dict(:nmissing => "Nombre de valeurs manquantes", :variable => "Variable"))
        return [Dict(col => row[col] for col in names(nmissing_data)) for row in eachrow(nmissing_data)]
    end
    callback!(
        app,
        Output("tab_nmissing_1D", "data"),
        Input("variable-dropdown", "value"),
        Input("dim-dropdown", "value")
    ) do list_var, dim
        selected_columns = var_of_interest
        data = build_dataframe("", vcat(["TIME", "COURSE", "CODE_SUJET"], list_var))
        nmissing_1D_data = missing_values_1D(data, Symbol(dim))
        nmissing_1D_data_dict = [Dict(col => row[col] for col in names(nmissing_1D_data)) for row in eachrow(nmissing_1D_data)]
        return nmissing_1D_data_dict
    end
    callback!(
        app,
        Output("graph-vi", "figure"),
        Input("onevar-dropdown", "value")
    ) do one_var
        #= selected_columns = "VTDVGI" =#
        plot = plotlinevariabilityinter(data, one_var)
        return plot
    end
    return Layout
end