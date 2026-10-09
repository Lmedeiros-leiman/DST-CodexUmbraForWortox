# DST Wortox Shenanigans

Mod para Don't Starve Together que da ao Wortox acesso aos truques de sombra
do Maxwell.

## O que ele faz

### Codex Umbra

- Wortox cria o Codex Umbra pela aba de sombra do Maxwell (2 papiro, 2 combustivel do pesadelo, 50 de vida).
- O Codex invoca trabalhadores e protetores de sombra e lanca a armadilha e os pilares de sombra, gastando combustivel do pesadelo como no Maxwell.
- Cada lacaio reduz a sanidade maxima do Wortox como no Maxwell (15% por trabalhador, limite de 90%).
- Os lacaios somem quando Wortox morre, vira fantasma, troca de personagem ou viaja entre superficie e cavernas.
- Os lacaios sao silhuetas translucidas, como as sombras do Maxwell, e copiam a skin do Wortox (inclusive ao trocar de skin no armario), que aparece no formato da silhueta.
- A cor da silhueta depende da arvore de habilidades do Wortox. A inclinacao define a base: Neutro e carmesim, Bonzinho e rosado, Travesso e um vermelho sangue escuro, puxando para o preto do Maxwell. A alianca tinge a base: Sombra escurece tudo puxando para vinho e violeta (Travesso fica a cor mais escura) e Lunar deixa a sombra ciano, com brilho, parecida com um gestalt. Ao mudar de habilidade, as sombras que ja estao fora mudam de cor na hora.
- As sombras guardam um pouco de luz propria para continuar visiveis a noite, mais ainda na Lunar.
- A opacidade muda com a alianca: 65% sem alianca, 75% na Sombra e 50% na Lunar. As sombras vermelhas ficam mais solidas e bem mais escuras que o chao, o que deixa as bordas nitidas; a Lunar continua translucida como um gestalt.

  | Inclinacao / Alianca | Nenhuma | Lunar | Sombra |
  |---|---|---|---|
  | Bonzinho | Rose `#FF6F91` | Moonbeam `#7FE8FF` | Dusk Rose `#A0206A` |
  | Neutro | Crimson `#DC143C` (padrao) | Gestalt `#2FD0F0` | Wine `#7A0A3A` |
  | Travesso | Blood `#8A0A22` | Deep Moon `#2A9ED4` | Void Red `#4E0418` |
- Os lacaios do Wortox podem ser examinados: o dono tem uma fala, outro Wortox tem outra, o Maxwell tem uma fala propria e os demais personagens usam uma fala generica. As sombras do Maxwell continuam sem exame, como no jogo base.
- As ferramentas e a espada fazem parte da mesma silhueta, como nas sombras do Maxwell.
- A fumaca e a mancha que aparecem quando um lacaio some ficam da mesma cor do lacaio. Os lacaios do Maxwell continuam pretos.
- Wortox tem falas proprias para o Codex.

### Trupe da Flauta

- Quando o Wortox toca a flauta de pa carregando o Codex Umbra (no inventario, no cursor ou na mochila), tres sombras dancarinas aparecem ao redor dele, com a skin e a cor da arvore de habilidades dele.
- Elas dancam por cerca de 10 segundos e somem numa fumaca da mesma cor. Tocar de novo troca a trupe em vez de acumular dancarinos.
- Sao so visuais: nao contam como lacaios, nao custam sanidade, nao sao salvas e nao dormem com a musica.
- Tem opcao propria. Com a opcao Codex Umbra desativada o Wortox nao cria o livro, mas um Codex do Maxwell carregado por ele ainda chama a trupe.

## Instalacao local

1. Feche Don't Starve Together.
2. Copie `modinfo.lua`, `modmain.lua` e os arquivos `wortox_shenanigans_*.lua` para `mods/wortox_shenanigans` na instalacao do jogo. O caminho Steam padrao no Linux e `~/.local/share/Steam/steamapps/common/Don't Starve Together/mods/wortox_shenanigans`.
3. Ative o mod para o servidor e escolha as opcoes `Codex Umbra` e `Trupe da Flauta`.
4. Reinicie o servidor depois de alterar configuracoes ou arquivos do mod.

## Notas

A fumaca rapida ao invocar sem animacao e a fumaca ao trocar de skin continuam pretas: o visual delas so existe nos clientes e o mod nao consegue tingi-las.

O mod adiciona a tag `shadowmagic`, que tambem mostra a aba de criacao de
itens de sombra do Maxwell.

As receitas do chapeu de magico e do bau de magico aparecem, mas Wortox nao
tem a habilidade de magico. Por isso, o chapeu funciona somente como um
chapeu normal.

## Testes locais

Requer Lua 5.1.

```bash
lua5.1 test/test_mod.lua
luac5.1 -p modinfo.lua modmain.lua wortox_shenanigans_tint.lua wortox_shenanigans_codex.lua wortox_shenanigans_panflute.lua test/test_mod.lua
```
