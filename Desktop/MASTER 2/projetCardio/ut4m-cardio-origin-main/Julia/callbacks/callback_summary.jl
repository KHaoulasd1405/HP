

function build_summary_callback!(app::Dash.DashApp)
        var_of_interest = ["VOL_OGI","VOL_ODI","VTDVGI","VTSVGI","FE2D","STDi","STSi","E/A" ,"E/Ea"]
        callback!(
            app,
            Output("table-summary-header", "children"),
            Output("table-summary-body", "children"),
            Input("course-dropdown", "value"),
            Input("variable-dropdown", "value")
        ) do course_name, list_var
            selected_columns = var_of_interest
            filtered_data = build_dataframe(course_name,list_var)
            summary_data = custom_summary(filtered_data)
            return html_tr([html_th(col) for col in names(summary_data)]), [html_tr([html_td(summary_data[r, c]) for c in names(summary_data)]) for r = 1:nrow(summary_data)]
        end    
        callback!(
            app,
            Output("table-nmissing-header", "children"),
            Output("table-nmissing-body", "children"),
            Input("variable-dropdown", "value"),
            Input("dim-dropdown", "value")
        ) do list_var, dim
            data = build_dataframe("", vcat(["TIME", "COURSE", "CODE_SUJET"], list_var))
            nmissing_1D_data = missing_values_1D(data, Symbol(dim))
            return html_tr([html_th(col) for col in names(nmissing_1D_data)]), [html_tr([html_td(nmissing_1D_data[r, c]) for c in names(nmissing_1D_data)]) for r = 1:nrow(nmissing_1D_data)]
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
        callback!(
            app,
            Output("graph-vi2", "figure"),
            Input("onevar-dropdown", "value"),
            Input("course-dropdown", "value")
        ) do one_var, course_name
            plot = plotvariabilityintra(data, one_var, course_name)
            return plot
        end
    end
    
    function build_dataframe(course_name::Any,var_of_interest::Any)
        data = build_data_cardiac("./Ressources/Données complètes UT4M final120419 avec Data cardio.xlsx")
        if course_name == ""
            data_to_plot = data
        else
            data_to_plot = filter(row -> row[:COURSE] == course_name, data)
        end
        if var_of_interest == ""
            return data_to_plot
        else
            data_to_plot = data_to_plot[:,[Symbol(var) for var in var_of_interest]]
            return data_to_plot
        end
    end