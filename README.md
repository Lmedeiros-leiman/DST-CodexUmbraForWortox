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
- A cor da silhueta depende da arvore de habilidades do Wortox: a inclinacao (Bonzinho, Neutro, Travesso) e a alianca (nenhuma, Lunar, Sombra). As cores vem das skins do Wortox. Ao mudar de habilidade, as sombras que ja estao fora mudam de cor na hora.

  | Inclinacao / Alianca | Nenhuma | Lunar | Sombra |
  |---|---|---|---|
  | Bonzinho | Clay Rose `#B36955` | Moonmist `#6B8DA6` | Rosewood `#8C2F3C` |
  | Neutro | Imp Brick `#A04636` (padrao) | Slate `#456478` | Oxblood `#6B1F2A` |
  | Travesso | Rust `#7F3428` | Midnight `#253341` | Abyss `#3D1016` |
- Os lacaios do Wortox podem ser examinados: o dono tem uma fala, outro Wortox tem outra, o Maxwell tem uma fala propria e os demais personagens usam uma fala generica. As sombras do Maxwell continuam sem exame, como no jogo base.
- As ferramentas e a espada fazem parte da mesma silhueta, como nas sombras do Maxwell.
- A fumaca e a mancha que aparecem quando um lacaio some ficam da mesma cor do lacaio. Os lacaios do Maxwell continuam pretos.
- Wortox tem falas proprias para o Codex.

## Instalacao local

1. Feche Don't Starve Together.
2. Copie `modinfo.lua`, `modmain.lua` e `wortox_shenanigans_codex.lua` para `mods/wortox_shenanigans` na instalacao do jogo. O caminho Steam padrao no Linux e `~/.local/share/Steam/steamapps/common/Don't Starve Together/mods/wortox_shenanigans`.
3. Ative o mod para o servidor e deixe a opcao `Codex Umbra` ativada.
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
lua5.1 test/test_codex.lua
luac5.1 -p modinfo.lua modmain.lua wortox_shenanigans_codex.lua test/test_codex.lua
```
