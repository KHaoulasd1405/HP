using Dash
using XLSX
using DataFrames
using PlotlyJS
using CategoricalArrays
using GLM
using HypothesisTests
using MultipleTesting
using Statistics
using MixedModels
using Interpolations
using BasicBSpline
using Dates
using Splines2

include("preprocessing.jl")
include("utils.jl")
include("callbacks/callback_layout.jl")
include("pages/tab_page.jl")
include("callbacks/callback_plot.jl")
include("callbacks/callback_mt.jl")
include("callbacks/tap_page_callback.jl")
include("pages/plot_tab.jl")
include("callbacks/callback_lm.jl")
include("./pages/tab_lm.jl")
include("./pages/tab_multiple_test.jl")
include("./pages/about_tab.jl")
include("./pages/tab_summary_page.jl")
include("./pages/spline_tab.jl")
include("callbacks/callback_spline.jl")
include("./callbacks/callback_summary.jl")


data = build_data_cardiac("./Ressources/Données complètes UT4M final120419 avec Data cardio.xlsx")

app = dash(suppress_callback_exceptions=true)

app.layout = html_div() do
    children = [
        html_div(
            id = "div-header",
            children = [
                html_div(
                    id = "div-logo",
                    children = [
                        html_img(src = "assets/img/Logo-Ut4M.png", id = "logo-UT4M"),
                        html_h1(id ="title-id","UT4M - Modélisation cardiaque"),
                        html_img(src = "assets/img/UFR_IM2AG.png", id = "logo-IM2AG"),
                    ]
                ),
            ]
        ),
        html_div(
            id = "div-container",
            children = [
                html_div(
                    id = "div-tab",
                    children = [
                        dcc_tabs(
                            id = "tabs",
                            value = "tab-about",
                            children = [
                                dcc_tab(
                                    label = "A propos",
                                    id = "tab-about",
                                    value = "tab-about",
                                    children = [
                                        html_label("Projet réalisé par :"),
                                        html_ul(
                                            children = [
                                            html_li("Gabriel BOUR"),
                                            html_li("Robin CHAUSSEMY"),
                                            html_li("Khoula SAOUDI"),
                                            html_li("Delyan ZERGUA"),
                                        ]),
                                        html_label("Superviseur :"),
                                        html_ul(
                                            children = [
                                            html_li("Franck CORSET (LJK)"),
                                            html_li("Anthony COSTA (HP2)"),
                                            html_li("Stéphane DOUTRELEAU (HP2)"),
                                            html_li("Adeline LECLERCQ-SAMSON (LJK)"),
                                        ])
                                    ]
                                ),
                                dcc_tab(
                                    label = "Base de données",
                                    id = "tab-data",
                                    value = "tab-data",
                                    children = [
                                        html_h1("Data"),
                                    ]
                                ),
                                dcc_tab(
                                    label = "Résumés statistiques",
                                    value = "tab-summary",
                                    id = "tab-summary",
                                    children = [
                                        html_h1("Visualisation"),
                                    ]
                                ),
                                dcc_tab(
                                    label = "Plot",
                                    value = "tab-plot",
                                    id = "tab-plot",
                                    children = [
                                        html_h1("Plot"),
                                    ]
                                ),
                                dcc_tab(
                                    label = "Modèle linéaire",
                                    value = "tab-lm",
                                    id = "tab-lm",
                                    children = [
                                        html_h1("Modèle linéaire"),
                                    ]
                                ),
                                dcc_tab(
                                    label = "Spline",
                                    value = "tab-spline",
                                    id = "tab-spline",
                                    children = [
                                        html_h1("Spline"),
                                    ]
                                ),
                                dcc_tab(
                                    label = "Tests multiples",
                                    value = "tab-mt",
                                    id = "tab-mt",
                                    children = [
                                        html_h1("Tests multiples"),
                                    ]
                                ),
                            ]
                        )
                    ]
                ),
                html_div(
                    id = "div-content-tab",
                    children = [
                        html_div(
                            id = "layout-tab",
                            children = [
                                html_h1("Layout"),
                            ]
                        )
                    ]
                )
            ]
        ),

    ]
end

callback!(
    app,
    Output("layout-tab", "children"),
    Output("tab-data", "children"),
    Output("tab-summary", "children"),
    Output("tab-plot", "children"),
    Output("tab-lm", "children"),
    Output("tab-spline", "children"),
    Output("tab-mt", "children"),
    Input("tabs", "value")
) do tab
    if tab == "tab-data"
        layouts = build_tab_data_df!(app)
        return layouts[2],layouts[1],html_h1(""),html_h1(""),html_h1(""),html_h1(""),html_h1("")
    elseif tab == "tab-summary"
        layouts = build_tab_summary!(app)
        return layouts[2],html_h1(""),layouts[1],html_h1(""),html_h1(""),html_h1(""),html_h1("")
    elseif tab == "tab-plot"
        layouts = build_plot_page!(app)
        return layouts[1],html_h1(""),html_h1(""),layouts[2],html_h1(""),html_h1(""),html_h1("")
    elseif tab == "tab-lm"
        layouts = build_linear_tab!(app)
        return layouts[2],html_h1(""),html_h1(""),html_h1(""),layouts[1],html_h1(""),html_h1("")
    elseif tab == "tab-spline"
        layouts = build_spline_tab!(app)
        return layouts[2],html_h1(""),html_h1(""),html_h1(""),html_h1(""),layouts[1],html_h1("")
    elseif tab == "tab-mt"
        layouts = build_multiple_test_tab!(app)
        return layouts[2],html_h1(""),html_h1(""),html_h1(""),html_h1(""),html_h1(""),layouts[1]
    end
    return html_h1(""),html_h1(""),html_h1(""),html_h1(""),html_h1(""),html_h1(""),html_h1("")
end



build_callback_data!(app)
build_summary_callback!(app)
build_callback_lm!(app)
build_plot_spline!(app)
update_graph!(app)
build_callback_mt!(app)


run_server(app, "0.0.0.0", debug=true)