function build_about()
    layout = html_div(
        id = "div-about",
        children = [
            html_h1("À propos"),
            html_p("Ce tableau de bord a été réalisé dans le cadre du Projet Tutoré du Master 2 SSD de l'Université Grenoble Alpes."),
            html_p("Il a pour but de permettre l'analyse de données cardiaque réalisés sur des coureurs lors de l'UT4M."),
        ]
    )
    return layout
end