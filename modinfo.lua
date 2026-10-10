-- English by default. The game sets `locale` for modinfo: "pt" is Portuguese
-- (Brazil), "zh" Simplified Chinese on Steam, "zhr" the same language on the
-- WeGame (Rail) release and "ru" Russian.
local ALIASES = { zhr = "zh" }
local function T(texts)
    return texts[locale] or texts[ALIASES[locale]] or texts.en
end

name = T{
    en = "Codex Umbra for Wortox",
    pt = "Codex Umbra para o Wortox",
    zh = "沃拓克斯的暗影秘典",
    ru = "Кодекс Умбра для Вортокса",
}
description = T{
    en = [[Wortox learns Maxwell's shadow magic.

Codex Umbra: Wortox crafts and uses the Codex Umbra like Maxwell. He summons shadow workers and protectors and casts the trap and pillars, with the same max sanity penalty. His minions are silhouettes in the shape of his skin, coloured by his skill tree lean and allegiance, and can be examined.

Panflute Troupe: playing the panflute while carrying the Codex Umbra summons three shadow dancers in his colour, who dance for a few seconds and vanish.]],
    pt = [[O Wortox aprende a magia de sombra do Maxwell.

Codex Umbra: o Wortox cria e usa o Codex Umbra como o Maxwell. Invoca trabalhadores e protetores de sombra e lança a armadilha e os pilares, com a mesma penalidade de sanidade máxima. Os lacaios dele são silhuetas com a forma da skin do Wortox, coloridas conforme a inclinação e a aliança da árvore de habilidades, e podem ser examinados.

Trupe da Flauta: ao tocar a flauta de pã carregando o Codex Umbra, o Wortox invoca três sombras dançarinas com a cor dele, que dançam por alguns segundos e somem.]],
    zh = [[沃拓克斯学会了麦斯威尔的暗影魔法。

暗影秘典：沃拓克斯可以像麦斯威尔一样制作并使用暗影秘典，召唤暗影仆人和暗影角斗士，施放暗影陷阱和暗影囚牢，并承受相同的理智上限惩罚。他的暗影傀儡是带有他皮肤轮廓的剪影，颜色取决于技能树的倾向和阵营，并且可以检查。

排箫剧团：携带暗影秘典时吹奏排箫，沃拓克斯会召唤三个与他同色的暗影舞者，跳几秒舞后消失。]],
    ru = [[Вортокс осваивает теневую магию Максвелла.

Кодекс Умбра: Вортокс создаёт и использует Кодекс Умбра, как Максвелл. Он призывает теневых слуг и партнёров, ставит теневые уловки и клетки и получает тот же штраф к максимальному рассудку. Его тени — силуэты в форме его скина, окрашенные по наклонностям и союзу в древе навыков, и их можно осмотреть.

Труппа флейты: если сыграть на флейте Пана с Кодексом Умбра при себе, Вортокс призовёт трёх теневых танцоров своего цвета, которые потанцуют несколько секунд и исчезнут.]],
}
author = "Leonardo"
version = "0.2.0"

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

local ON_OFF =
{
    { description = T{ en = "Enabled", pt = "Ativado", zh = "启用", ru = "Включено" }, data = true },
    { description = T{ en = "Disabled", pt = "Desativado", zh = "禁用", ru = "Отключено" }, data = false },
}

configuration_options =
{
    {
        name = "codex_umbra",
        label = T{ en = "Codex Umbra", pt = "Codex Umbra", zh = "暗影秘典", ru = "Кодекс Умбра" },
        hover = T{
            en = "Lets Wortox craft and use the Codex Umbra like Maxwell.",
            pt = "Permite que o Wortox crie e use o Codex Umbra como o Maxwell.",
            zh = "让沃拓克斯像麦斯威尔一样制作和使用暗影秘典。",
            ru = "Вортокс может создавать и использовать Кодекс Умбра, как Максвелл.",
        },
        options = ON_OFF,
        default = true,
    },
    {
        name = "panflute_troupe",
        label = T{ en = "Panflute Troupe", pt = "Trupe da Flauta", zh = "排箫剧团", ru = "Труппа флейты" },
        hover = T{
            en = "Playing the panflute while carrying the Codex Umbra summons shadow dancers for a few seconds.",
            pt = "Ao tocar a flauta de pã carregando o Codex Umbra, o Wortox invoca sombras dançarinas por alguns segundos.",
            zh = "携带暗影秘典时吹奏排箫，会召唤暗影舞者跳几秒舞。",
            ru = "Игра на флейте Пана с Кодексом Умбра при себе призывает теневых танцоров на несколько секунд.",
        },
        options = ON_OFF,
        default = true,
    },
    {
        name = "language",
        label = T{ en = "Language", pt = "Idioma", zh = "语言", ru = "Язык" },
        hover = T{
            en = "Language of Wortox's lines in the world. Auto follows the server's language.",
            pt = "Idioma das falas do Wortox no mundo. Automático segue o idioma do servidor.",
            zh = "世界中沃拓克斯台词的语言。自动会跟随服务器的语言。",
            ru = "Язык реплик Вортокса в мире. «Авто» следует языку сервера.",
        },
        options =
        {
            { description = T{ en = "Auto", pt = "Automático", zh = "自动", ru = "Авто" }, data = "auto" },
            { description = "English", data = "en" },
            { description = "Português", data = "pt" },
            { description = "简体中文", data = "zh" },
            { description = "Русский", data = "ru" },
        },
        default = "auto",
    },
}
