function update_graph!(app::Dash.DashApp)
    callback!(
        app,
        Output("graph", "figure"),
        Input("course-dropdown-plot", "value"),
        Input("var-dropdown-plot", "value"),
    ) do course, var
        data_to_plot = filter(row -> row[:COURSE] == course, data)
        data_to_plot = data_to_plot[:, [:TIME, Symbol(var), :CODE_SUJET]]
        return build_plot(data_to_plot, "TIME", var, "CODE_SUJET", course)
    end
end

function build_plot(data, x_symbols::String, y_symbols::String, group_symbol::String, course::Any)
    if course == "4_40"
        time = unique(data[:,"TIME"])
        lay = Layout(title="Evolution de la variable "*y_symbols*" en fonction du temps pour la course 4x40km",
            xaxis=attr(
                tickmode="array",              # Mode personnalisé pour les ticks
                tickvals=time,                 # Positions des ticks
                ticktext=["PRE","POST","POST2","POST3","POST4","J+2","J+5","J+10"]  # Labels des ticks
            )
        )
    else
        time = unique(data[:,"TIME"])
        lay = Layout(title="Evolution de la variable "*y_symbols*" en fonction du temps",
            xaxis=attr(
                tickmode="array",              # Mode personnalisé pour les ticks
                tickvals=time,                 # Positions des ticks
                ticktext=["PRE","POST","J+2","J+5","J+10"]  # Labels des ticks
            )
        )
    end

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