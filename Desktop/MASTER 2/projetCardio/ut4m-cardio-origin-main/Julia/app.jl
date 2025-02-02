using Dash
using XLSX
using DataFrames
using PlotlyJS
using CategoricalArrays
using GLM
using HypothesisTests
using MultipleTesting
using PlotlyJS
using Statistics
using Plots

include("./preprocessing.jl")
include("./utils.jl")
include("./callback_layout.jl")
include("./pages/data_page.jl")
include("./pages/plot_page.jl")
include("./pages/summary_page.jl")
include("./callback_update_graph.jl")
include("./pages/linear_page.jl")

app = dash(suppress_callback_exceptions=true)
data = build_data_cardiac("./Ressources/Données complètes UT4M final120419 avec Data cardio.xlsx")

function create_navbar()
    return html_div(
        id = "navbar",
        children=[
            html_button("Résumé statistiques", id="summary_page_button",  n_clicks=0),
            html_button("Visualisation des données", id="data_page_button",  n_clicks=0),
            html_button("Plot", id="plot_page_button", n_clicks=0),
            html_button("Modèle linéaire", id="linear_page_button",  n_clicks=0),
        ],
        style=Dict("background-color" => "#f8f9fa", "padding" => "10px", "border-bottom" => "1px solid #dee2e6")
    )
end

app.layout = html_div() do
    children = [
        create_navbar(),
        dcc_location(id="url", refresh=false),
        html_div(
            id = "page-content",

        )
    ]
end

index_page = html_div() do
    children = [
        html_img(
            src="https://im2ag.univ-grenoble-alpes.fr/uas/IM2AG/UGA_LOGO_ACCUEIL/UFR_IM2AG_2020.svg",
            style=Dict("width" => "100px")
        ),
        html_img(
            src="https://www.chamrousse.com/medias/images/prestations/multitailles/1920x1440_4502357-chamrousse_logo_trail_ut4m_utra_tour_quatre_massifs_belledonne_station_montagne_grenoble_isere_alpes_france.jpg",
            style=Dict("width" => "150px")
        ),
        html_h1("Projet UT4M - Données cardiaques"),
#=         dcc_link("Résumés statistiques", href="/summary_page"),
        html_br(),
        dcc_link("Données cardiaques", href="/data_page"),
        html_br(),
        dcc_link("Plots", href="/plot_page"),
        html_br(),
        dcc_link("Modèle linéaire", href="/linear_page"),
        html_br(), =#
        ]
    
end

callback_layout!(app,build_page_data_df!(app),index_page,build_plot_page!(app),build_linear_page!(app),build_page_summary!(app))

update_graph!(app)

run_server(app, "0.0.0.0", debug=true)