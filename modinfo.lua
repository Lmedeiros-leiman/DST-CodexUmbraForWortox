name = "Wortox Shenanigans"
description = [[Travessuras para o Wortox.

Codex Umbra: Wortox cria e usa o Codex Umbra como o Maxwell. Invoca trabalhadores e protetores de sombra, lanca armadilha e pilares, com a mesma penalidade de sanidade maxima. Os lacaios dele sao silhuetas carmesim com a forma da skin do Wortox, ferramentas na mesma silhueta e fumaca carmesim ao sumir, e podem ser examinados.]]
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
}
