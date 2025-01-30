function build_callback_data!(app::Dash.DashApp)
    callback!(
        app,
        Output("tab_data", "columns"),
        Output("tab_data", "data"),
        Input("variable-dropdown", "value"),
        Input("course-dropdown", "value")
    ) do list_var,course_name
        var_of_interest = ["VOL_OGI","VOL_ODI","VTDVGI","VTSVGI","FE2D","STDi","STSi","E/A" ,"E/Ea"]
        selected_columns = var_of_interest
        if course_name != ""
            data = build_dataframe_tab_page(course_name,list_var)
            dict_col_name = [Dict("name" => col, "id" => col) for col in names(data)]
            return dict_col_name[2:end],Dict.((pairs.(eachrow(round.(data[:,Not(:COURSE)],digits=2)))))
        end
        return [Dict("name" => col, "id" => col) for col in selected_columns]
    end
end