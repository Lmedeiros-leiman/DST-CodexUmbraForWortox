# DST Codex Umbra for Wortox

<img src="modicon.png" alt="Mod icon: Wortox next to the Codex Umbra" width="128" align="right">

[English](#english) · [Português](#português) · [简体中文](#简体中文) · [Русский](#русский)

## English

A Don't Starve Together mod that teaches Wortox Maxwell's shadow magic.

### Codex Umbra

- Wortox crafts the Codex Umbra from Maxwell's shadow tab (2 papyrus, 2 nightmare fuel, 50 health).
- The Codex summons shadow workers and protectors and casts the shadow trap and pillars, spending nightmare fuel as it does for Maxwell.
- Each minion lowers Wortox's max sanity like Maxwell's (15% per worker, 90% cap).
- Minions vanish when Wortox dies, becomes a ghost, swaps character or travels between the surface and the caves.
- Minions are translucent silhouettes like Maxwell's shadows, copying Wortox's skin (including wardrobe changes), which shows in the silhouette's shape. Tools and swords are part of the same silhouette.
- The colour follows Wortox's skill tree. His lean sets the base: Neutral is crimson, Nice a pinkish red, Naughty a dark blood red toward Maxwell's black. His allegiance tints it: Shadow darkens everything toward wine and violet (Naughty is the darkest), Lunar turns the shadow cyan and glowing, like a gestalt. Shadows already out recolour as soon as his skills change.

  | Lean / Allegiance | None | Lunar | Shadow |
  |---|---|---|---|
  | Nice | Rose `#FF6F91` | Moonbeam `#7FE8FF` | Dusk Rose `#A0206A` |
  | Neutral | Crimson `#DC143C` (default) | Gestalt `#2FD0F0` | Wine `#7A0A3A` |
  | Naughty | Blood `#8A0A22` | Deep Moon `#2A9ED4` | Void Red `#4E0418` |

- Shadows keep a little light of their own to stay visible at night, Lunar most of all.
- Opacity depends on the allegiance: 65% with none, 75% for Shadow, 50% for Lunar. The red shadows stay clearly darker than the ground, so their edges read sharply; Lunar keeps a gestalt's translucency.
- The despawn smoke and splat take the minion's colour. Maxwell's minions stay black.
- Wortox's minions can be examined: the owner has one line, another Wortox another, Maxwell his own, and everyone else a generic one. Maxwell's shadows stay unexaminable, as in the base game.
- Wortox has his own lines for the Codex.

### Panflute Troupe

- When Wortox plays the panflute while carrying the Codex Umbra (inventory, cursor or backpack), three shadow dancers appear around him with his skin and skill tree colour.
- They dance for about 10 seconds and vanish in smoke of the same colour. Playing again replaces the troupe instead of stacking dancers.
- They are purely visual: not minions, no sanity cost, never saved, and the flute does not put them to sleep.
- It has its own option. With the Codex Umbra option off Wortox cannot craft the book, but a Maxwell Codex he carries still calls the troupe.

### Languages

The mod list text and Wortox's lines are in English, Portuguese (Brazil), Simplified Chinese (Steam and WeGame) and Russian; any other language uses English.

- The mod list text follows each player's own game language.
- Wortox's lines are resolved on the server, so everyone hears the same language. The `Language` option picks it: `Auto` (default) uses the server's language, or force `English`, `Português`, `简体中文` or `Русский`.
- A world hosted from the game menu takes the host's game language each time it starts (`cluster_language` in `cluster.ini`). A standalone dedicated server sets `cluster_language` by hand.

### Local install

1. Close Don't Starve Together.
2. Copy `modinfo.lua`, `modmain.lua`, `modicon.tex`, `modicon.xml` and the `wortox_shenanigans_*.lua` files to `mods/wortox_shenanigans` in the game folder. The default Steam path on Linux is `~/.local/share/Steam/steamapps/common/Don't Starve Together/mods/wortox_shenanigans`.
3. Enable the mod for the server and pick the `Codex Umbra`, `Panflute Troupe` and `Language` options.
4. Restart the server after changing options or mod files.

### Notes

- The quick puff when a minion appears without its animation and the puff on skin changes stay black: their visuals only exist on clients, out of the mod's reach.
- The mod adds the `shadowmagic` tag, which also shows Maxwell's shadow crafting tab. The magician top hat and chest recipes appear, but Wortox lacks the magician ability, so the top hat works as a plain hat.

## Português

Mod para Don't Starve Together que ensina ao Wortox a magia de sombra do Maxwell.

### Codex Umbra

- O Wortox cria o Codex Umbra pela aba de sombra do Maxwell (2 papiros, 2 combustíveis do pesadelo, 50 de vida).
- O Codex invoca trabalhadores e protetores de sombra e lança a armadilha e os pilares de sombra, gastando combustível do pesadelo como no Maxwell.
- Cada lacaio reduz a sanidade máxima do Wortox como no Maxwell (15% por trabalhador, limite de 90%).
- Os lacaios somem quando o Wortox morre, vira fantasma, troca de personagem ou viaja entre a superfície e as cavernas.
- Os lacaios são silhuetas translúcidas, como as sombras do Maxwell, e copiam a skin do Wortox (inclusive ao trocar de skin no armário), que aparece no formato da silhueta. Ferramentas e espadas fazem parte da mesma silhueta.
- A cor segue a árvore de habilidades do Wortox. A inclinação define a base: Neutro é carmesim, Bonzinho é rosado, Travesso é um vermelho sangue escuro puxando para o preto do Maxwell. A aliança tinge a base: Sombra escurece tudo puxando para vinho e violeta (Travesso fica a cor mais escura) e Lunar deixa a sombra ciano e brilhante, como um gestalt. As sombras que já estão fora mudam de cor assim que as habilidades mudam.

  | Inclinação / Aliança | Nenhuma | Lunar | Sombra |
  |---|---|---|---|
  | Bonzinho | Rose `#FF6F91` | Moonbeam `#7FE8FF` | Dusk Rose `#A0206A` |
  | Neutro | Crimson `#DC143C` (padrão) | Gestalt `#2FD0F0` | Wine `#7A0A3A` |
  | Travesso | Blood `#8A0A22` | Deep Moon `#2A9ED4` | Void Red `#4E0418` |

- As sombras guardam um pouco de luz própria para continuar visíveis à noite, mais ainda na Lunar.
- A opacidade depende da aliança: 65% sem aliança, 75% na Sombra e 50% na Lunar. As sombras vermelhas ficam bem mais escuras que o chão, com bordas nítidas; a Lunar continua translúcida como um gestalt.
- A fumaça e a mancha que aparecem quando um lacaio some ficam da cor do lacaio. Os lacaios do Maxwell continuam pretos.
- Os lacaios do Wortox podem ser examinados: o dono tem uma fala, outro Wortox outra, o Maxwell uma própria e os demais personagens uma fala genérica. As sombras do Maxwell continuam sem exame, como no jogo base.
- O Wortox tem falas próprias para o Codex.

### Trupe da Flauta

- Quando o Wortox toca a flauta de pã carregando o Codex Umbra (no inventário, no cursor ou na mochila), três sombras dançarinas aparecem ao redor dele, com a skin e a cor da árvore de habilidades dele.
- Elas dançam por cerca de 10 segundos e somem numa fumaça da mesma cor. Tocar de novo troca a trupe em vez de acumular dançarinos.
- São só visuais: não contam como lacaios, não custam sanidade, não são salvas e não dormem com a música.
- Tem opção própria. Com a opção Codex Umbra desativada o Wortox não cria o livro, mas um Codex do Maxwell carregado por ele ainda chama a trupe.

### Idiomas

O texto da lista de mods e as falas do Wortox estão em inglês, português (Brasil), chinês simplificado (Steam e WeGame) e russo; outros idiomas usam inglês.

- O texto da lista de mods segue o idioma do jogo de cada jogador.
- As falas do Wortox são resolvidas no servidor, então todos ouvem o mesmo idioma. A opção `Idioma` escolhe qual: `Automático` (padrão) usa o idioma do servidor, ou force `English`, `Português`, `简体中文` ou `Русский`.
- Um mundo hospedado pelo menu do jogo pega o idioma do jogo de quem hospeda toda vez que inicia (`cluster_language` no `cluster.ini`). Um servidor dedicado avulso define `cluster_language` à mão.

### Instalação local

1. Feche o Don't Starve Together.
2. Copie `modinfo.lua`, `modmain.lua`, `modicon.tex`, `modicon.xml` e os arquivos `wortox_shenanigans_*.lua` para `mods/wortox_shenanigans` na instalação do jogo. O caminho Steam padrão no Linux é `~/.local/share/Steam/steamapps/common/Don't Starve Together/mods/wortox_shenanigans`.
3. Ative o mod para o servidor e escolha as opções `Codex Umbra`, `Trupe da Flauta` e `Idioma`.
4. Reinicie o servidor depois de alterar opções ou arquivos do mod.

### Notas

- A fumaça rápida quando um lacaio aparece sem animação e a fumaça ao trocar de skin continuam pretas: o visual delas só existe nos clientes e o mod não consegue tingi-las.
- O mod adiciona a tag `shadowmagic`, que também mostra a aba de criação de sombra do Maxwell. As receitas do chapéu e do baú de mágico aparecem, mas o Wortox não tem a habilidade de mágico, então o chapéu funciona como um chapéu comum.

## 简体中文

一个《饥荒联机版》模组，让沃拓克斯学会麦斯威尔的暗影魔法。

### 暗影秘典

- 沃拓克斯可以在麦斯威尔的暗影栏制作暗影秘典（2 莎草纸、2 噩梦燃料、50 生命值）。
- 暗影秘典可以召唤暗影仆人和暗影角斗士，施放暗影陷阱和暗影囚牢，像麦斯威尔一样消耗噩梦燃料。
- 每个暗影傀儡会像麦斯威尔一样降低沃拓克斯的理智上限（每个暗影仆人 15%，上限 90%）。
- 沃拓克斯死亡、变成鬼魂、更换角色或往返地面与洞穴时，暗影傀儡会消失。
- 暗影傀儡是半透明的剪影，和麦斯威尔的暗影一样，并复制沃拓克斯的皮肤（包括在衣柜更换皮肤），皮肤会体现在剪影的轮廓上。工具和武器也属于同一个剪影。
- 颜色取决于沃拓克斯的技能树。倾向决定底色：中立是深红，好孩子偏粉红，淘气包是接近麦斯威尔黑色的暗血红。阵营给底色上色：暗影阵营整体变暗，偏向酒红与紫色（淘气包最暗）；月亮阵营让暗影变成会发光的青色，像虚影一样。技能改变时，已经召唤出的暗影会立刻变色。

  | 倾向 / 阵营 | 无 | 月亮 | 暗影 |
  |---|---|---|---|
  | 好孩子 | Rose `#FF6F91` | Moonbeam `#7FE8FF` | Dusk Rose `#A0206A` |
  | 中立 | Crimson `#DC143C`（默认） | Gestalt `#2FD0F0` | Wine `#7A0A3A` |
  | 淘气包 | Blood `#8A0A22` | Deep Moon `#2A9ED4` | Void Red `#4E0418` |

- 暗影自带少量光亮，夜晚也能看清，月亮阵营最亮。
- 不透明度取决于阵营：无阵营 65%，暗影阵营 75%，月亮阵营 50%。红色的暗影明显比地面更暗，边缘清晰；月亮阵营保持虚影般的半透明。
- 暗影傀儡消失时的烟雾和污渍是它的颜色。麦斯威尔的暗影傀儡保持黑色。
- 沃拓克斯的暗影傀儡可以检查：主人、其他沃拓克斯、麦斯威尔和其他角色各有不同的台词。麦斯威尔的暗影和原版一样无法检查。
- 沃拓克斯对暗影秘典有专属台词。

### 排箫剧团

- 沃拓克斯携带暗影秘典（物品栏、鼠标上或背包里）吹奏排箫时，身边会出现三个暗影舞者，带着他的皮肤和技能树颜色。
- 它们会跳大约 10 秒舞，然后在同色的烟雾中消失。再次吹奏会替换剧团，而不是叠加。
- 它们只是视觉效果：不是暗影傀儡，不消耗理智，不会被保存，也不会被排箫催眠。
- 有独立选项。关闭暗影秘典选项时，沃拓克斯无法制作这本书，但他携带的麦斯威尔的暗影秘典仍然可以召唤剧团。

### 语言

模组列表文本和沃拓克斯的台词支持英语、葡萄牙语（巴西）、简体中文（Steam 与 WeGame）和俄语；其他语言使用英语。

- 模组列表文本跟随每位玩家自己的游戏语言。
- 沃拓克斯的台词在服务器上生成，所以所有人听到的是同一种语言。`语言`选项决定使用哪种：`自动`（默认）跟随服务器语言，也可以强制使用 `English`、`Português`、`简体中文` 或 `Русский`。
- 从游戏菜单创建的世界每次启动时都会使用主机的游戏语言（`cluster.ini` 中的 `cluster_language`）。独立的专用服务器需要手动设置 `cluster_language`。

### 本地安装

1. 关闭《饥荒联机版》。
2. 将 `modinfo.lua`、`modmain.lua`、`modicon.tex`、`modicon.xml` 和 `wortox_shenanigans_*.lua` 文件复制到游戏目录的 `mods/wortox_shenanigans`。
3. 为服务器启用模组，并设置`暗影秘典`、`排箫剧团`和`语言`选项。
4. 修改选项或模组文件后重启服务器。

### 说明

- 暗影傀儡无动画出现时的快速烟雾，以及更换皮肤时的烟雾仍是黑色：它们只在客户端显示，模组无法上色。
- 模组会添加 `shadowmagic` 标签，因此也会显示麦斯威尔的暗影制作栏。魔术师高礼帽和魔术师箱子的配方会出现，但沃拓克斯没有魔术师能力，所以高礼帽只是一顶普通帽子。

## Русский

Мод для Don't Starve Together, который учит Вортокса теневой магии Максвелла.

### Кодекс Умбра

- Вортокс создаёт Кодекс Умбра во вкладке теней Максвелла (2 папируса, 2 топлива кошмара, 50 здоровья).
- Кодекс призывает теневых слуг и партнёров, ставит теневые уловки и клетки и тратит топливо кошмара, как у Максвелла.
- Каждая тень снижает максимальный рассудок Вортокса, как у Максвелла (15% за слугу, предел 90%).
- Тени исчезают, когда Вортокс умирает, становится призраком, меняет персонажа или переходит между поверхностью и пещерами.
- Тени — полупрозрачные силуэты, как у Максвелла, и копируют скин Вортокса (включая смену в гардеробе); скин виден в форме силуэта. Инструменты и оружие — часть того же силуэта.
- Цвет зависит от древа навыков Вортокса. Наклонности задают основу: нейтральный — малиновый, благой — розово-красный, озорной — тёмно-кровавый, почти чёрный, как у Максвелла. Союз добавляет оттенок: теневой затемняет всё в сторону винного и фиолетового (озорной — самый тёмный), лунный делает тень светящейся голубой, как гештальт. Уже призванные тени сразу меняют цвет при смене навыков.

  | Наклонности / Союз | Нет | Лунный | Теневой |
  |---|---|---|---|
  | Благие | Rose `#FF6F91` | Moonbeam `#7FE8FF` | Dusk Rose `#A0206A` |
  | Нейтральные | Crimson `#DC143C` (по умолчанию) | Gestalt `#2FD0F0` | Wine `#7A0A3A` |
  | Озорные | Blood `#8A0A22` | Deep Moon `#2A9ED4` | Void Red `#4E0418` |

- Тени немного светятся сами, чтобы их было видно ночью; лунные — сильнее всех.
- Непрозрачность зависит от союза: 65% без союза, 75% у теневого, 50% у лунного. Красные тени заметно темнее земли и с чёткими краями; лунные остаются полупрозрачными, как гештальт.
- Дым и пятно при исчезновении тени окрашены в её цвет. Тени Максвелла остаются чёрными.
- Тени Вортокса можно осмотреть: у хозяина, другого Вортокса, Максвелла и остальных персонажей свои реплики. Тени Максвелла, как и в оригинале, осмотреть нельзя.
- У Вортокса свои реплики про Кодекс.

### Труппа флейты

- Когда Вортокс играет на флейте Пана, держа при себе Кодекс Умбра (в инвентаре, на курсоре или в рюкзаке), вокруг него появляются три теневых танцора с его скином и цветом древа навыков.
- Они танцуют около 10 секунд и исчезают в дыму того же цвета. Повторная игра заменяет труппу, а не добавляет танцоров.
- Это только визуальный эффект: они не считаются тенями-слугами, не тратят рассудок, не сохраняются и не засыпают от флейты.
- У труппы своя настройка. Если настройка «Кодекс Умбра» выключена, Вортокс не может создать книгу, но Кодекс Максвелла при нём всё равно призывает труппу.

### Языки

Текст в списке модов и реплики Вортокса доступны на английском, португальском (Бразилия), упрощённом китайском (Steam и WeGame) и русском; остальные языки используют английский.

- Текст в списке модов следует языку игры каждого игрока.
- Реплики Вортокса формируются на сервере, поэтому все слышат один язык. Его выбирает настройка «Язык»: «Авто» (по умолчанию) следует языку сервера, либо можно выбрать `English`, `Português`, `简体中文` или `Русский`.
- Мир, запущенный из меню игры, при каждом запуске берёт язык игры хоста (`cluster_language` в `cluster.ini`). На отдельном выделенном сервере `cluster_language` задаётся вручную.

### Локальная установка

1. Закройте Don't Starve Together.
2. Скопируйте `modinfo.lua`, `modmain.lua`, `modicon.tex`, `modicon.xml` и файлы `wortox_shenanigans_*.lua` в `mods/wortox_shenanigans` в папке игры.
3. Включите мод для сервера и выберите настройки «Кодекс Умбра», «Труппа флейты» и «Язык».
4. Перезапустите сервер после изменения настроек или файлов мода.

### Примечания

- Быстрая вспышка при появлении тени без анимации и вспышка при смене скина остаются чёрными: их графика существует только у клиентов, и мод не может её окрасить.
- Мод добавляет тег `shadowmagic`, поэтому появляется и вкладка теневого крафта Максвелла. Рецепты цилиндра и сундука фокусника видны, но у Вортокса нет способностей фокусника, так что цилиндр работает как обычная шляпа.

## For mod authors / Para autores de mods

The Codex Umbra module publishes an API used by the Codex Umbra for Everyone add-on. Read it with `rawget(GLOBAL, "CodexUmbraForWortox")` (it is absent when this mod or its Codex Umbra option is off):

- `EnableShadowCaster(inst, config)`: lets a character craft and use the Codex Umbra like Maxwell. `config.tint(inst)` returns a palette index; `config.mine` / `config.other` are the examine statuses for the caster's own shadow and for other viewers (`config.other` may be a function `(pet, viewer, leader)` returning the status). Safe to call on both sides and more than once. `version` is 2.
- `SetShadowDescription(character, status, line)`: sets a character's line for a shadow examine status.
- `TINT_NONE` (Maxwell's vanilla black), `TINT_GESTALT`, `TINT_VOID_VIOLET`: palette indices for allegiance colours.

Each shadow type (worker, protector) has its own pet limit, so the shared pet pool used by critters, Woby, Wormwood's plants and WX-78's drones is untouched.

## Tests / Testes / 测试 / Тесты

Requires Lua 5.1. / Requer Lua 5.1. / 需要 Lua 5.1。 / Требуется Lua 5.1.

```bash
lua5.1 test/test_mod.lua
luac5.1 -p modinfo.lua modmain.lua wortox_shenanigans_tint.lua wortox_shenanigans_codex.lua wortox_shenanigans_panflute.lua test/test_mod.lua
```

## Credits / Créditos / 致谢 / Благодарности

Don't Starve Together, Wortox, Maxwell and the Codex Umbra belong to Klei Entertainment. The mod icon is assembled from game art (Wortox's avatar and the Codex Umbra inventory icon). This is an unofficial fan mod, not made or endorsed by Klei.

Don't Starve Together, Wortox, Maxwell e o Codex Umbra pertencem à Klei Entertainment. O ícone do mod foi montado com arte do jogo (o avatar do Wortox e o ícone do Codex Umbra). Este é um mod de fã não oficial, sem vínculo com a Klei.

《饥荒联机版》、沃拓克斯、麦斯威尔和暗影秘典属于 Klei Entertainment。模组图标使用游戏美术素材制作（沃拓克斯的头像和暗影秘典的物品图标）。这是非官方的玩家模组，与 Klei 无关。

Don't Starve Together, Вортокс, Максвелл и Кодекс Умбра принадлежат Klei Entertainment. Иконка мода собрана из игровой графики (аватар Вортокса и иконка Кодекса Умбра). Это неофициальный фанатский мод, не связанный с Klei.
