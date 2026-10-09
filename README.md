# DST Wortox Shenanigans

Mod para Don't Starve Together que da ao Wortox acesso aos truques de sombra
do Maxwell.

## O que ele faz

- Feature 1: Wortox pode criar e usar o Codex Umbra como o Maxwell.
- O Codex pode invocar trabalhadores e protetores de sombra.
- O Codex tambem oferece os feiticos de armadilha e pilares.
- Os minions de sombra usam a mesma penalidade de sanidade maxima do Maxwell.
- Os lacaios de sombra do Wortox ficam carmesim.

## Instalacao local

1. Feche Don't Starve Together.
2. Copie estes arquivos para `mods/wortox_shenanigans` na instalacao do jogo.
3. Ative o mod para o servidor e deixe a opcao `Codex Umbra` ativada.
4. Reinicie o servidor depois de alterar configuracoes ou arquivos do mod.

## Notas

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
