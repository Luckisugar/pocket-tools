<div align="center">

# Too Many Pals
### *Pal Pra Poha*

### Press **F8**. Send that excess Pal home. Keep walking.
### Aperte **F8**. Manda esse excesso de Pal pra casa. Segue o baile.

[![Palworld](https://img.shields.io/badge/Palworld-UE4SS_Lua-7c3aed?style=for-the-badge)](https://docs.ue4ss.com/)
[![Dual install](https://img.shields.io/badge/Dedicated-Client_%2B_Server-ef4444?style=for-the-badge)](#-install--instalação)
[![Key](https://img.shields.io/badge/Hotkey-F8-f59e0b?style=for-the-badge)](#-usage--como-usar)
[![Lang](https://img.shields.io/badge/Docs-EN_%2B_PT--BR-22c55e?style=for-the-badge)](#-are-you-tired-of-being-full-of-pals-all-the-time)
[![License: MIT](https://img.shields.io/badge/License-MIT-0ea5e9?style=for-the-badge)](../../LICENSE)
[![Stars](https://img.shields.io/github/stars/Luckisugar/pocket-tools?style=for-the-badge)](https://github.com/Luckisugar/pocket-tools/stargazers)

**Party full. Base full. Inventory full.**  
**Grupo cheio. Base cheia. Inventário cheio.**

**Pal here. Pal there. Pal pra… poha.**  
**Pal pra lá. Pal pra cá. Pal pra… poha.**

[Features](#-features--recursos) ·
[How it works](#-how-it-works--como-funciona) ·
[Install](#-install--instalação) ·
[Usage](#-usage--como-usar) ·
[Trust](#-trust--what-this-is-not--confiança--o-que-isso-não-é) ·
[Uninstall](#-uninstall--desinstalar) ·
[FAQ](#-faq) ·
[License](#-license--licença)

</div>

---

## Are you tired of being full of Pals all the time?

> **PT-BR:** Tá cansado de sempre tá cheio de Pal?

You caught one. Then five. Then the party looks like a group chat that never mutes.  
You open the Palbox. You close the Palbox. You open it again. You cry a little.

> **PT-BR:** Você pega um. Aí cinco. Aí o grupo vira aquele chat que nunca silencia.  
> Abre a Palbox. Fecha a Palbox. Abre de novo. Chora um pouquinho.

**Tired of carrying this many Pals?**

> **PT-BR:** Cansado de carregar esse tanto de Pal?

**With this mod, you can be free of your excess Pals, wherever you may be.**

> **PT-BR:** Com esse mod, você pode se livrar do seu excesso de Pal, de onde quer que esteja.

No pilgrimage to the box UI. No inventory Tetris mid-fight.

> **PT-BR:** Sem romaria até a UI da box. Sem Tetris de inventário no meio do fight.

**Press F8 to instantly send your current Pal back home!**

> **PT-BR:** Aperte F8 para instantaneamente enviar seu Pal atual de volta pra casa!

Less clutter. More aura. More room for the next mistake.

> **PT-BR:** Menos bagunça. Mais aura. Mais espaço pro próximo erro.

---

## Features · Recursos

| English | Português (Brasil) |
|:--|:--|
| **One key** — **F8** sends the relevant party Pal into *your* Palbox | **Uma tecla** — **F8** manda o Pal certo do grupo pra *sua* Palbox |
| **Works on dedicated** — game client + dedicated server each run a pure Lua half | **Funciona em dedicado** — cliente + servidor dedicado, cada um com sua metade Lua |
| **Xbox / Game Pass + Steam** — client half for WinGDK *and* Steam | **Xbox / Game Pass + Steam** — metade cliente pro WinGDK *e* pro Steam |
| **No admin slash** — not a `/command` ritual, not “you’re not an admin,” just **F8** | **Sem slash de admin** — não é ritual de `/comando`, não é “você não é admin,” só **F8** |
| **Pure UE4SS Lua** — two mod folders, no mystery `.exe`, no phone-home, no file-drop IPC | **Lua UE4SS puro** — duas pastas de mod, sem `.exe` misterioso, sem telemetria, sem IPC por arquivo |
| **Per-player safe** — server deposits for the player who signaled, not “any pal on the map” | **Seguro por jogador** — o server deposita pro jogador que sinalizou, não “qualquer pal no mapa” |
| **EN + PT-BR docs** — the name is a crime; the jokes write themselves | **Docs EN + PT-BR** — o nome é um crime; as piadas se escrevem sozinhas |

---

## How it works · Como funciona

**Too Many Pals** is a **matched pair**:

> **PT-BR:** **Too Many Pals** é um **par combinado**:

| Half / Lado | Drop-in folder / Pasta | Where it lives / Onde fica | Job / Função |
|------|----------------|----------------|-----|
| **Player / Jogador** | `SendHome` | Game client UE4SS `Mods` | F8 → pick party slot → signal · F8 → escolhe slot → sinal |
| **Host** | `SendHomeServer` | Dedicated `PalServer` UE4SS `Mods` | Receive signal → deposit on authority · Recebe sinal → deposita com autoridade |

On **dedicated servers**, **both** halves are required.  
Client-only was the old dream. Reality said *nope*. Dual install is the real aura.

> **PT-BR:** Em **servidores dedicados**, as **duas** metades são obrigatórias.  
> Só cliente era o sonho antigo. A realidade disse *não*. Instalação dupla é a aura de verdade.

**Singleplayer / local co-op only?** You still need UE4SS on the client. The dedicated-only server folder is for hosts running **PalServer**.

> **PT-BR:** **Só singleplayer / co-op local?** Você ainda precisa de UE4SS no cliente. A pasta de servidor é pra quem roda **PalServer** dedicado.

The signal is a fixed, boring string (`SENDHOME <slot>`). No free-form shell. No admin password in the player guide.

> **PT-BR:** O sinal é uma string fixa e chata (`SENDHOME <slot>`). Sem shell livre. Sem senha de admin no guia do jogador.

---

## Install · Instalação

### You need UE4SS first · Você precisa do UE4SS primeiro

This package is **only** the two Lua mod folders.  
If you do not already run **stock UE4SS** for other mods, install UE4SS for your platform **first**, then come back.

> **PT-BR:** Este pacote é **só** as duas pastas de mod Lua.  
> Se você ainda **não** roda **UE4SS stock** pra outros mods, instale o UE4SS da sua plataforma **primeiro**, depois volte.

You do **not** need Run as Administrator for this mod.  
You do **not** need to disable antivirus / Smart App Control as a normal step.  
If Windows blocks a zip you did not trust, **stop** and verify the source (this repo).

> **PT-BR:** Você **não** precisa de “Executar como administrador” pra este mod.  
> Você **não** precisa desligar antivírus / Smart App Control como passo normal.  
> Se o Windows bloquear um zip em que você não confia, **pare** e confira a origem (este repositório).

---

### A) Xbox / PC Game Pass / Microsoft Store (client)

1. Install **UE4SS** for the Game Pass / WinGDK build (same stack you use for other Lua mods).
2. Open the client Mods folder (typical shape):

```text
...\WindowsApps\PocketpairInc.Palworld_*\Pal\Binaries\WinGDK\ue4ss\Mods\
```

3. Copy the **`SendHome`** folder from this package into `Mods\`  
   so you have `Mods\SendHome\enabled.txt` and `Mods\SendHome\Scripts\main.lua` only.
4. If you are joining a **dedicated** server that runs this mod: the **host** must also install **`SendHomeServer`** (section C). F8 alone on the client cannot invent server authority.
5. **Fully quit** Palworld. Launch again. Join. Press **F8**.

> **PT-BR:**
> 1. Instale o **UE4SS** do build Game Pass / WinGDK (o mesmo stack dos outros mods Lua).
> 2. Abra a pasta `Mods` do cliente (formato típico):
>
> ```text
> ...\WindowsApps\PocketpairInc.Palworld_*\Pal\Binaries\WinGDK\ue4ss\Mods\
> ```
>
> 3. Copie a pasta **`SendHome`** deste pacote para `Mods\`  
>    de modo que exista só `Mods\SendHome\enabled.txt` e `Mods\SendHome\Scripts\main.lua`.
> 4. Se você entra em um servidor **dedicado** com este mod: o **host** também precisa instalar **`SendHomeServer`** (seção C). F8 sozinho no cliente não inventa autoridade de server.
> 5. **Feche o Palworld por completo**. Abra de novo. Entre. Aperte **F8**.

(UE4SS usually sits as community `dwmapi.dll` next to `Palworld-WinGDK-Shipping.exe` — that host is **not** unique to this mod.)

> **PT-BR:** (O UE4SS costuma ficar como `dwmapi.dll` da comunidade ao lado de `Palworld-WinGDK-Shipping.exe` — esse host **não** é exclusivo deste mod.)

**Do not** put `SendHomeServer` on the Xbox/Game Pass client as your only install and expect magic.

> **PT-BR:** **Não** coloque `SendHomeServer` no cliente Xbox/Game Pass como única instalação e espere milagre.

---

### B) Steam (client)

1. Install **UE4SS** for the Steam client build.
2. Open the Steam client Mods folder (typical shape):

```text
...\steamapps\common\Palworld\Pal\Binaries\Win64\ue4ss\Mods\
```

3. Drop **`SendHome`** into `Mods\` (same two files: `enabled.txt` + `Scripts\main.lua`).
4. If you play on a **dedicated** host with this mod: the host needs **`SendHomeServer`**.
5. Full game restart → join → **F8**.

> **PT-BR:**
> 1. Instale o **UE4SS** do build cliente Steam.
> 2. Abra a pasta `Mods` do cliente Steam (formato típico):
>
> ```text
> ...\steamapps\common\Palworld\Pal\Binaries\Win64\ue4ss\Mods\
> ```
>
> 3. Coloque **`SendHome`** em `Mods\` (os mesmos dois arquivos: `enabled.txt` + `Scripts\main.lua`).
> 4. Se você joga em host **dedicado** com este mod: o host precisa de **`SendHomeServer`**.
> 5. Reinício completo do jogo → entrar → **F8**.

Steam client path is **Win64**. Game Pass client path is **WinGDK**. Do not mix those trees.

> **PT-BR:** Caminho do cliente Steam é **Win64**. Caminho do Game Pass é **WinGDK**. Não misture essas árvores.

---

### C) Dedicated server (host) — Steam PalServer

Players who only join **do not** install this half.  
**Only the machine running the dedicated** installs `SendHomeServer`.

> **PT-BR:** Jogadores que só entram **não** instalam esta metade.  
> **Só a máquina do dedicado** instala `SendHomeServer`.

1. Install **UE4SS** on the dedicated (Win64 PalServer), same as other server Lua mods.
2. Open server Mods (typical shape):

```text
...\PalServer\Pal\Binaries\Win64\ue4ss\Mods\
```

3. Drop **`SendHomeServer`** into `Mods\`  
   (`enabled.txt` + `Scripts\main.lua` only).
4. **Full dedicated restart** after file change (half-restarts lie).
5. Confirm boot in server `UE4SS.log`:

```text
[SendHomeServer] ready
```

6. Every player who wants **F8** still installs **`SendHome`** on **their** client (A or B).

> **PT-BR:**
> 1. Instale o **UE4SS** no dedicado (PalServer Win64), igual outros mods Lua de server.
> 2. Abra o `Mods` do server (formato típico):
>
> ```text
> ...\PalServer\Pal\Binaries\Win64\ue4ss\Mods\
> ```
>
> 3. Coloque **`SendHomeServer`** em `Mods\`  
>    (só `enabled.txt` + `Scripts\main.lua`).
> 4. **Reinício completo do dedicado** depois de mudar arquivo (meio-reinício mente).
> 5. Confirme no `UE4SS.log` do server:
>
> ```text
> [SendHomeServer] ready
> ```
>
> 6. Todo jogador que quiser **F8** ainda instala **`SendHome`** no **próprio** cliente (A ou B).

Wrong zip in the wrong tree is an install error, not a skill issue the mod can fix.  
Label mentally: **SendHome = player PC**, **SendHomeServer = host PC**.

> **PT-BR:** Zip errado na árvore errada é erro de instalação, não “falta de habilidade” que o mod conserte.  
> Decal mental: **SendHome = PC do jogador**, **SendHomeServer = PC do host**.

---

### Quick pairing checklist · Checklist rápido de pareamento

| Role (EN) | Installs (EN) | Função (PT) | Instala (PT) |
|------|----------|------|----------|
| Solo / client-only experiments | `SendHome` on client (limited; dedicated needs both) | Solo / só cliente (teste) | `SendHome` no cliente (limitado; dedicado precisa dos dois) |
| Dedicated player | `SendHome` on client | Jogador no dedicado | `SendHome` no cliente |
| Dedicated host | `SendHomeServer` on PalServer | Host do dedicado | `SendHomeServer` no PalServer |
| “It does nothing” | Missing half, wrong Mods path, or no full restart | “Não faz nada” | Falta metade, `Mods` errado, ou sem reinício completo |

---

## Usage · Como usar

1. Be in-game with at least one party Pal.
2. Prefer the Pal you care about selected / out.
3. Press **F8** once (don’t mash).
4. That Pal should leave the party and land in **your** Palbox.

> **PT-BR:**
> 1. Esteja no jogo com pelo menos um Pal no grupo.
> 2. Prefira o Pal que importa selecionado / pra fora.
> 3. Aperte **F8** uma vez (não spam).
> 4. Esse Pal deve sair do grupo e ir pra **sua** Palbox.

**Human success:** party slot empty. Pal’s home. You’re free.  
**Nerd success (optional):** client log `[SendHome]` + server log `[SendHomeServer]` agree.

> **PT-BR:**  
> **Sucesso humano:** slot do grupo vazio. Pal em casa. Você livre.  
> **Sucesso nerd (opcional):** log do cliente `[SendHome]` + log do server `[SendHomeServer]` batem.

---

## Trust — what this is not · Confiança — o que isso não é

| Claim (EN) | Truth (EN) | Afirmação (PT) | Verdade (PT) |
|------:|:------|------:|:------|
| Extra injector EXE? | **No** — pure Lua folders on stock UE4SS | EXE injetor extra? | **Não** — pastas Lua puras no UE4SS stock |
| HTTP / Discord / auto-update? | **No** | HTTP / Discord / auto-update? | **Não** |
| File-drop IPC / “sync folder” product? | **No** | IPC por arquivo / “pasta de sync”? | **Não** |
| Admin REST password in player install? | **No** | Senha REST/admin no install do jogador? | **Não** |
| Free-form console shell for players? | **No** — fixed signal only | Shell de console livre pro jogador? | **Não** — só sinal fixo |
| Other players’ boxes / loot vacuum? | **No** — your party Pal → your Palbox | Box dos outros / vacuum de loot? | **Não** — seu Pal do grupo → sua Palbox |

If a zip contains random `.exe` / `.ps1` / `.bat` downloaders, **do not install** that zip. This package should only need the two mod folders above.

> **PT-BR:** Se um zip trouxer `.exe` / `.ps1` / `.bat` aleatórios de download, **não instale** esse zip. Este pacote só precisa das duas pastas de mod acima.

---

## Uninstall · Desinstalar

Delete:

- Client: `...\ue4ss\Mods\SendHome\`
- Server: `...\ue4ss\Mods\SendHomeServer\`

Restart game / dedicated. Done.  
No leftover services. No registry. No second personality.

> **PT-BR:** Apague:
>
> - Cliente: `...\ue4ss\Mods\SendHome\`
> - Server: `...\ue4ss\Mods\SendHomeServer\`
>
> Reinicie o jogo / o dedicado. Pronto.  
> Sem serviços sobrando. Sem registro. Sem segunda personalidade.

---

## FAQ

**F8 does nothing.**  
Full restart? UE4SS loading other mods? On dedicated: is **`SendHomeServer`** actually on the host and showing `ready`? Client folder name exactly `SendHome`?

> **PT-BR: F8 não faz nada.**  
> Reinício completo? UE4SS carregando outros mods? No dedicado: o **`SendHomeServer`** está no host e mostra `ready`? Pasta do cliente se chama exatamente `SendHome`?

**I’m on Xbox console.**  
This is a **PC UE4SS** mod (Game Pass **PC** / Steam **PC** / dedicated **PC**). Not a retail Xbox console package.

> **PT-BR: Estou no console Xbox.**  
> Isto é mod de **UE4SS no PC** (Game Pass **PC** / Steam **PC** / dedicado **PC**). Não é pacote de console Xbox de prateleira.

**Will this steal other players’ Pals?**  
It resolves **your** controller / player state. Wrong-player deposit is a bug, not a feature. Hosts: watch first-boot logs if you’re paranoid (you should be, a little).

> **PT-BR: Isso rouba Pal de outros jogadores?**  
> Resolve o controller / player state **seu**. Depositar no jogador errado é bug, não feature. Hosts: olhem o log do primeiro boot se forem paranoicos (deviam ser, um pouco).

**Can I rebind F8?**  
Not in v1 ship — F8 is the product. (Letter keys get eaten by inventory UI; F8 was the boring reliable pick.)

> **PT-BR: Dá pra rebindar o F8?**  
> Não na v1 — F8 é o produto. (Teclas de letra o inventário engole; F8 foi a escolha chata e confiável.)

**Does it need internet permission / SmartScreen drama?**  
No network feature in the mod itself. You’re editing local Lua under your existing UE4SS install.

> **PT-BR: Precisa de permissão de internet / drama de SmartScreen?**  
> Sem recurso de rede no próprio mod. Você só edita Lua local na instalação UE4SS que já tem.

---

## Version notes · Notas de versão

| English | Português (Brasil) |
|:--|:--|
| **Tested shape:** client WinGDK (Game Pass) + Steam dedicated Win64 | **Formato testado:** cliente WinGDK (Game Pass) + dedicado Steam Win64 |
| **Stack:** stock UE4SS + pure Lua | **Stack:** UE4SS stock + Lua puro |
| **Player UX:** F8 only | **UX do jogador:** só F8 |
| **Game versions:** Palworld moves fast — pin your own UE4SS/game pair when packaging forks | **Versões do jogo:** Palworld muda rápido — fixe seu par UE4SS/jogo ao empacotar forks |

---

## Credit · Créditos

Shipped under **[Luckisugar/pocket-tools](https://github.com/Luckisugar/pocket-tools)** → `palworld/Too-Many-Pals`.  
Built for people who have **too many Pals** and zero patience left.

> **PT-BR:** Publicado em **[Luckisugar/pocket-tools](https://github.com/Luckisugar/pocket-tools)** → `palworld/Too-Many-Pals`.  
> Feito pra quem tem **Pal demais** e paciência zero.

Not affiliated with Pocketpair / Palworld.

> **PT-BR:** Não afiliado à Pocketpair / Palworld.

---

## Star History · Histórico de estrelas

[![Star History Chart](https://api.star-history.com/svg?repos=Luckisugar/pocket-tools&type=Date)](https://star-history.com/#Luckisugar/pocket-tools&Date)

---

## License · Licença

[MIT](../../LICENSE) — use it, fork it, send your excess Pals home.

> **PT-BR:** [MIT](../../LICENSE) — usa, forka, manda teu excesso de Pal pra casa.

<div align="center">

### Too many Pals?
### Pal demais?

### **Pal. Pra. Poha.**

### Hit **F8**.
### Aperta **F8**.

</div>
