function update_graph!(app::Dash.DashApp)
    callback!(
            app,
            Output("graph", "figure"),
            Input("course-dropdown-plot", "value"),
            Input("var-dropdown-plot", "value"),
        ) do course, var
            data_to_plot = filter(row -> row[:COURSE] == course, data)
            data_to_plot = data_to_plot[:,[:TIME, Symbol(var),:CODE_SUJET]]
            return build_plot(data_to_plot,"TIME",var,"CODE_SUJET")
    end

end

function build_plot(data,x_symbols::String, y_symbols::String, group_symbol::String)
    time = unique(data[:,"TIME"])
    lay = Layout(title="Evolution de la variable "*y_symbols*" en fonction du temps",
        xaxis=attr(
            tickmode="array",              # Mode personnalisé pour les ticks
            tickvals=time,     # Positions des ticks
            ticktext=["PRE","POST","J+2","J+5","J+10"]  # Labels des ticks
        )
    )
    p1 = PlotlyJS.plot(
        PlotlyJS.scatter(
            data,
            x = Symbol(x_symbols),
            y = Symbol(y_symbols),
            group = Symbol(group_symbol),
            mode = "lines+markers"
        ),
        lay
    )
    return p1
end

