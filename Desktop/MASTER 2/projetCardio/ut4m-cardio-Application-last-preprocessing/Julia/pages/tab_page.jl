function build_tab_data_df!(app::Dash.DashApp)
    data = build_data_cardiac("./Ressources/Données complètes UT4M final120419 avec Data cardio.xlsx")
    data[:, "COURSE"] = replace(data[:, "COURSE"], "4_40" => 440)
    var_of_interest = ["COURSE","TIME","CODE_SUJET", "TIMESTAMP", "VOL_OGI","VOL_ODI","VTDVGI","VTSVGI","FE2D","STDi","STSi","E/A" ,"E/Ea"]
    course_option = unique(data[:,"COURSE"])
    Layout_content = html_div(
        children = [
            dash_datatable(
            id = "tab_data",
            columns = [Dict("name" => col, "id" => col) for col in names(data)],
            data = Dict.(pairs.(eachrow(data))),
            page_size=20
        )
        ]    
    )
    Layout_tab = html_div(
        id = "layout-tab-data",
        children = [
            html_h2("Choix de la course"),
            dcc_dropdown(
                id="course-dropdown",
                options=[Dict("label" => format_course_label(course), "value" => course) for course in course_option],
                value=course_option[1]
            ),
            html_h2("Choix des variables"),
            dcc_dropdown(
                id="variable-dropdown",
                options=[Dict("label" => course, "value" => course) for course in names(data)], 
                value=var_of_interest,
                multi = true
            ),
        ]
    )
    return Layout_tab,Layout_content
end

function build_dataframe_tab_page(course_name::Any,var_of_interest::Any)
    data = build_data_cardiac("./Ressources/Données complètes UT4M final120419 avec Data cardio.xlsx")  
    data[:, "COURSE"] = replace(data[:, "COURSE"], "4_40" => 440)
    data_to_plot = filter(row -> row[:COURSE] == course_name, data)
    data_to_plot = data_to_plot[:,[Symbol(var) for var in var_of_interest]]
    return data_to_plot
end