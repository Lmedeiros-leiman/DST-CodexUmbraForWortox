name = "Wortox Shenanigans"
description = [[
Feature 1:
Wortox pode criar e usar o Codex Umbra como o Maxwell: trabalhadores e
protetores de sombra, armadilha e pilares, com a mesma penalidade de sanidade
maxima.
]]
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
