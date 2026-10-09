-- English by default; Portuguese when the game runs in Portuguese (Brazil),
-- whose locale code is "pt". The game sets `locale` for modinfo.
local function T(en, pt)
    return locale == "pt" and pt or en
end

name = T("Codex Umbra for Wortox", "Codex Umbra para o Wortox")
description = T([[Wortox learns Maxwell's shadow magic.

Codex Umbra: Wortox crafts and uses the Codex Umbra like Maxwell. He summons shadow workers and protectors and casts the trap and pillars, with the same max sanity penalty. His minions are silhouettes in the shape of his skin, coloured by his skill tree lean and allegiance, and can be examined.

Panflute Troupe: playing the panflute while carrying the Codex Umbra summons three shadow dancers in his colour, who dance for a few seconds and vanish.]],
[[O Wortox aprende a magia de sombra do Maxwell.

Codex Umbra: o Wortox cria e usa o Codex Umbra como o Maxwell. Invoca trabalhadores e protetores de sombra e lança a armadilha e os pilares, com a mesma penalidade de sanidade máxima. Os lacaios dele são silhuetas com a forma da skin do Wortox, coloridas conforme a inclinação e a aliança da árvore de habilidades, e podem ser examinados.

Trupe da Flauta: ao tocar a flauta de pã carregando o Codex Umbra, o Wortox invoca três sombras dançarinas com a cor dele, que dançam por alguns segundos e somem.]])
author = "Leonardo"
version = "0.1.0"

forumthread = ""

api_version = 10

dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false

all_clients_require_mod = true
client_only_mod = false

icon = "modicon.tex"
icon_atlas = "modicon.xml"

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
        hover = T("Lets Wortox craft and use the Codex Umbra like Maxwell.",
            "Permite que o Wortox crie e use o Codex Umbra como o Maxwell."),
        options =
        {
            { description = T("Enabled", "Ativado"), data = true },
            { description = T("Disabled", "Desativado"), data = false },
        },
        default = true,
    },
    {
        name = "panflute_troupe",
        label = T("Panflute Troupe", "Trupe da Flauta"),
        hover = T("Playing the panflute while carrying the Codex Umbra summons shadow dancers for a few seconds.",
            "Ao tocar a flauta de pã carregando o Codex Umbra, o Wortox invoca sombras dançarinas por alguns segundos."),
        options =
        {
            { description = T("Enabled", "Ativado"), data = true },
            { description = T("Disabled", "Desativado"), data = false },
        },
        default = true,
    },
    {
        name = "language",
        label = T("Language", "Idioma"),
        hover = T("Language of Wortox's lines in the world. Auto follows the server's language.",
            "Idioma das falas do Wortox no mundo. Automático segue o idioma do servidor."),
        options =
        {
            { description = T("Auto", "Automático"), data = "auto" },
            { description = "English", data = "en" },
            { description = "Português", data = "pt" },
        },
        default = "auto",
    },
}
