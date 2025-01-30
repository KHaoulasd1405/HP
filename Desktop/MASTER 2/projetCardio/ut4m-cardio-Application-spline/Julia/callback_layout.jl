
function callback_layout!(app::Dash.DashApp,page_data_layout,index_page,page_plot_layout,linear_page, page_summary_layout)
    callback!(
        app,
        Output("page-content", "children"),
        Output("data_page_button", "n_clicks"),
        Output("plot_page_button", "n_clicks"),
        Output("linear_page_button", "n_clicks"),
        Output("summary_page_button", "n_clicks"),
        Input("url", "pathname"),
        Input("data_page_button", "n_clicks"),
        Input("plot_page_button", "n_clicks"),
        Input("linear_page_button", "n_clicks"),
        Input("summary_page_button", "n_clicks")
    ) do pathname,n_clicks_data,n_clicks_plot,n_clicks_linear,n_clicks_summary
        if (pathname == "/data_page" || n_clicks_data > 0)
            page_data_layout,0,0,0,0
        elseif  (pathname == "/plot_page" || n_clicks_plot > 0)
            page_plot_layout,0,0,0,0
        elseif (pathname == "/linear_page" || n_clicks_linear > 0)
            linear_page,0,0,0,0
        elseif (pathname == "/summary_page" || n_clicks_summary > 0)
            page_summary_layout,0,0,0,0
        else
            index_page,0,0,0,0
        end
    end
end
