<div align="center">

# Too Many Pals
### *Pal Pra Poha*

### Press **F8**. Send that excess Pal home. Keep walking.

[![Palworld](https://img.shields.io/badge/Palworld-UE4SS_Lua-7c3aed?style=for-the-badge)](https://docs.ue4ss.com/)
[![Dual install](https://img.shields.io/badge/Dedicated-Client_%2B_Server-ef4444?style=for-the-badge)](#-install)
[![Key](https://img.shields.io/badge/Hotkey-F8-f59e0b?style=for-the-badge)](#-usage)
[![Lang](https://img.shields.io/badge/Docs-EN_%7C_PT--BR-22c55e?style=for-the-badge)](#-português-brasil)
[![License: MIT](https://img.shields.io/badge/License-MIT-0ea5e9?style=for-the-badge)](../../LICENSE)
[![Stars](https://img.shields.io/github/stars/Luckisugar/pocket-tools?style=for-the-badge)](https://github.com/Luckisugar/pocket-tools/stargazers)

**Party full. Base full. Inventory full.**  
**Pal pra lá. Pal pra cá. Pal pra… poha.**

[Features](#-features) · [How it works](#-how-it-works) · [Install](#-install) · [Usage](#-usage) · [Trust](#-trust--what-this-is-not) · [Uninstall](#-uninstall) · [PT-BR](#-português-brasil) · [FAQ](#-faq)

</div>

---

## Are you tired of being full of Pals all the time?

**Tá cansado de sempre tá cheio de Pal?**

You caught one. Then five. Then the party looks like a group chat that never mutes.  
You open the Palbox. You close the Palbox. You open it again. You cry a little.  
**Cansado de carregar esse tanto de Pal?** Same.

**With this mod, you can be free of your excess Pals, wherever you may be.**  
**Com esse mod, você pode se livrar do seu excesso de Pal, de onde quer que esteja.**

No pilgrimage to the box UI. No inventory Tetris mid-fight.  
**Press F8 to instantly send your current Pal back home.**  
**Aperte F8 para instantaneamente enviar seu Pal atual de volta pra casa.**

Less clutter. More aura. More room for the next mistake.

---

## Features

| | |
|:--|:--|
| **One key** | **F8** — send the relevant party Pal into *your* Palbox |
| **Works on dedicated** | Game client + dedicated server both run a pure Lua half |
| **Xbox / Game Pass + Steam** | Client half for WinGDK *and* Steam clients |
| **No admin slash** | Not a `/command` ritual. Not “you’re not an admin.” Just **F8** |
| **Pure UE4SS Lua** | Two mod folders. No mystery `.exe`. No phone-home. No file-drop IPC |
| **Per-player safe** | Server deposits for the player who signaled — not “any pal on the map” |
| **EN vibe / PT-BR soul** | The name is a crime. The docs are bilingual. The Pal jokes write themselves |

---

## How it works

**Too Many Pals** is a **matched pair**:

| Half | Drop-in folder | Where it lives | Job |
|------|----------------|----------------|-----|
| **Player** | `SendHome` | Game client UE4SS `Mods` | F8 → pick party slot → signal |
| **Host** | `SendHomeServer` | Dedicated `PalServer` UE4SS `Mods` | Receive signal → deposit on authority |

On **dedicated servers**, **both** halves are required.  
Client-only was the old dream. Reality said *nope*. Dual install is the real aura.

**Singleplayer / local co-op only?** You still need UE4SS on the client; dedicated-only server folder is for hosts running **PalServer**.

Signal is a fixed, boring string (`SENDHOME <slot>`). No free-form shell. No admin password in the player guide.

---

## Install

### You need UE4SS first

This package is **only** the two Lua mod folders.  
If you do not already run **stock UE4SS** for other mods, install UE4SS for your platform **first**, then come back.

You do **not** need Run as Administrator for this mod.  
You do **not** need to disable antivirus / Smart App Control as a normal step.  
If Windows blocks a zip you did not trust, **stop** and verify the source (this repo).

---

### A) Xbox / PC Game Pass / Microsoft Store (client)

1. Install **UE4SS** for the Game Pass / WinGDK build (same stack you use for other Lua mods).
2. Open the client Mods folder (typical shape):

```text
...\WindowsApps\PocketpairInc.Palworld_*\Pal\Binaries\WinGDK\ue4ss\Mods\
```

(UE4SS usually sits as community `dwmapi.dll` next to `Palworld-WinGDK-Shipping.exe` — that host is **not** unique to this mod.)

3. Copy the **`SendHome`** folder from this package into `Mods\`  
   so you have `Mods\SendHome\enabled.txt` and `Mods\SendHome\Scripts\main.lua` only.
4. If you are joining a **dedicated** server that runs this mod: the **host** must also install **`SendHomeServer`** (section C). F8 alone on the client cannot invent server authority.
5. **Fully quit** Palworld. Launch again. Join. Press **F8**.

**Do not** put `SendHomeServer` on the Xbox/Game Pass client as your only install and expect magic.

---

### B) Steam (client)

1. Install **UE4SS** for the Steam client build.
2. Open the Steam client Mods folder (typical shape):

```text
...\steamapps\common\Palworld\Pal\Binaries\Win64\ue4ss\Mods\
```

3. Drop **`SendHome`** into `Mods\` (same two files: `enabled.txt` + `Scripts\main.lua`).
4. If you play on a **dedicated** host with this mod: host needs **`SendHomeServer`**.
5. Full game restart → join → **F8**.

Steam client path is **Win64**. Game Pass client path is **WinGDK**. Do not mix those trees.

---

### C) Dedicated server (host) — Steam PalServer

Players who only join **do not** install this half.  
**Only the machine running the dedicated** installs `SendHomeServer`.

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

Wrong zip in the wrong tree is an install error, not a skill issue the mod can fix.  
Label mentally: **SendHome = player PC**, **SendHomeServer = host PC**.

---

### Quick pairing checklist

| Role | Installs |
|------|----------|
| Solo / client only experiments | `SendHome` on client (limited; dedicated needs both) |
| Dedicated player | `SendHome` on client |
| Dedicated host | `SendHomeServer` on PalServer |
| “It does nothing” | Missing half, wrong Mods path, or no full restart |

---

## Usage

1. Be in-game with at least one party Pal.
2. Prefer the Pal you care about selected / out.
3. Press **F8** once (don’t mash).
4. That Pal should leave the party and land in **your** Palbox.

**Human success:** party slot empty. Pal’s home. You’re free.  
**Nerd success (optional):** client log `[SendHome]` + server log `[SendHomeServer]` agree.

---

## Trust — what this is not

| Claim | Truth |
|------:|:------|
| Extra injector EXE? | **No** — pure Lua folders on stock UE4SS |
| HTTP / Discord / auto-update? | **No** |
| File-drop IPC / “sync folder” product? | **No** |
| Admin REST password in player install? | **No** |
| Free-form console shell for players? | **No** — fixed signal only |
| Other players’ boxes / loot vacuum? | **No** — your party Pal → your Palbox |

If a zip contains random `.exe` / `.ps1` / `.bat` downloaders, **do not install** that zip. This package should only need the two mod folders above.

---

## Uninstall

Delete:

- Client: `...\ue4ss\Mods\SendHome\`
- Server: `...\ue4ss\Mods\SendHomeServer\`

Restart game / dedicated. Done.  
No leftover services. No registry. No second personality.

---

## Português (Brasil)

<div align="center">

### Too Many Pals — *Pal Pra Poha*

**Tá cansado de sempre tá cheio de Pal?**  
**Cansado de carregar esse tanto de Pal?**

</div>

Você pega um. Aí cinco. Aí o grupo vira fila do SUS.  
Abre a Palbox. Fecha. Abre de novo. Questiona suas escolhas.

**Com esse mod, você pode se livrar do seu excesso de Pal, de onde quer que esteja.**  
**Aperte F8 para instantaneamente enviar seu Pal atual de volta pra casa.**

Sem romaria até a UI. Sem Tetris de inventário no meio do fight.  
Menos bagunça. Mais aura. Mais espaço pro próximo erro.

### O que é

Dois lados **Lua UE4SS** (sem exe misterioso):

| Lado | Pasta | Onde | Função |
|------|-------|------|--------|
| Jogador | `SendHome` | Cliente (Game Pass **WinGDK** ou Steam **Win64**) | Tecla **F8** |
| Host | `SendHomeServer` | **PalServer** dedicado Win64 | Autoridade: manda o Pal pra box |

Em **servidor dedicado**, precisa dos **dois**. Só cliente não faz milagre.

### Instalação rápida

1. Tenha **UE4SS** no cliente e, se for host, no dedicado.
2. Cliente Game Pass → `...\WinGDK\ue4ss\Mods\` → pasta **`SendHome`**.
3. Cliente Steam → `...\Win64\ue4ss\Mods\` → pasta **`SendHome`**.
4. Dedicado → `...\PalServer\...\Win64\ue4ss\Mods\` → pasta **`SendHomeServer`**.
5. Reinício **completo** do jogo / do server.
6. Entra, aperta **F8**.

Não precisa “Executar como administrador” pra esse mod.  
Não precisa desligar antivírus como passo normal.  
Se o zip tiver `.exe` aleatório, **não instala**.

### Desinstalar

Apaga as pastas `SendHome` / `SendHomeServer` no `Mods` e reinicia. Fim.

---

## FAQ

**F8 does nothing.**  
Full restart? UE4SS loading other mods? On dedicated: is **`SendHomeServer`** actually on the host and showing `ready`? Client folder name exactly `SendHome`?

**I’m on Xbox console.**  
This is a **PC UE4SS** mod (Game Pass **PC** / Steam **PC** / dedicated **PC**). Not a retail Xbox console package.

**Will this steal other players’ Pals?**  
It resolves **your** controller / player state. Wrong-player deposit is a bug, not a feature. Hosts: watch first-boot logs if you’re paranoid (you should be, a little).

**Can I rebind F8?**  
Not in v1 ship — F8 is the product. (Letter keys get eaten by inventory UI; F8 was the boring reliable pick.)

**Does it need internet permission / SmartScreen drama?**  
No network feature in the mod itself. You’re editing local Lua under your existing UE4SS install.

---

## Version notes

| | |
|:--|:--|
| **Tested shape** | Client WinGDK (Game Pass) + Steam dedicated Win64 |
| **Stack** | Stock UE4SS + pure Lua |
| **Player UX** | F8 only |
| **Game versions** | Palworld moves fast — pin your own UE4SS/game pair when packaging forks |

---

## Credit

Shipped under **[Luckisugar/pocket-tools](https://github.com/Luckisugar/pocket-tools)** → `palworld/Too-Many-Pals`.  
Built for people who have **too many Pals** and zero patience left.

Not affiliated with Pocketpair / Palworld.

---

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=Luckisugar/pocket-tools&type=Date)](https://star-history.com/#Luckisugar/pocket-tools&Date)

---

## License

[MIT](../../LICENSE) — use it, fork it, send your excess Pals home.

<div align="center">

### Too many Pals?  
### **Pal. Pra. Poha.**  
### Hit **F8**.

</div>
