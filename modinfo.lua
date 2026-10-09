name = "Wortox Shenanigans"
description = [[Travessuras para o Wortox.

Codex Umbra: Wortox cria e usa o Codex Umbra como o Maxwell. Invoca trabalhadores e protetores de sombra, lanca armadilha e pilares, com a mesma penalidade de sanidade maxima. Os lacaios dele sao silhuetas com a forma da skin do Wortox, coloridas conforme a inclinacao e a alianca da arvore de habilidades, e podem ser examinados.

Trupe da Flauta: ao tocar a flauta de pa, Wortox invoca tres sombras dancarinas com a cor dele, que dancam por alguns segundos e somem.]]
author = "Leonardo"
version = "0.1.0"

forumthread = ""

api_version = 10

dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false

all_clients_require_mod = true
client_only_mod = false

icon = nil
icon_atlas = nil

server_filter_tags =
{
    "wortox",
    "character",
}

configuration_options =
{
    {
        name = "codex_umbra",
        label = "Codex Umbra",
        hover = "Permite que Wortox crie e use o Codex Umbra como Maxwell.",
        options =
        {
            { description = "Ativado", data = true },
            { description = "Desativado", data = false },
        },
        default = true,
    },
    {
        name = "panflute_troupe",
        label = "Trupe da Flauta",
        hover = "Ao tocar a flauta de pa, Wortox invoca sombras dancarinas por alguns segundos.",
        options =
        {
            { description = "Ativado", data = true },
            { description = "Desativado", data = false },
        },
        default = true,
    },
}
