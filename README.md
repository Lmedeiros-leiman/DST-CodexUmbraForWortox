# DST Wortox Shenanigans

Mod para Don't Starve Together que da ao Wortox acesso aos truques de sombra
do Maxwell.

## O que ele faz

### Codex Umbra

- Wortox cria o Codex Umbra pela aba de sombra do Maxwell (2 papiro, 2 combustivel do pesadelo, 50 de vida).
- O Codex invoca trabalhadores e protetores de sombra e lanca a armadilha e os pilares de sombra, gastando combustivel do pesadelo como no Maxwell.
- Cada lacaio reduz a sanidade maxima do Wortox como no Maxwell (15% por trabalhador, limite de 90%).
- Os lacaios somem quando Wortox morre, vira fantasma, troca de personagem ou viaja entre superficie e cavernas.
- Os lacaios copiam a skin do Wortox (inclusive ao trocar de skin no armario) e aparecem como sombras carmesim translucidas, com a skin ainda reconhecivel.
- As ferramentas e a espada dos lacaios ficam pretas, como as sombras do Maxwell.
- A fumaca e a mancha que aparecem quando um lacaio some ficam carmesim. Os lacaios do Maxwell continuam pretos.
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
