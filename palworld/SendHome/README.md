# SendHome

UE4SS Lua: send **one party pal → Palbox** (not a chest).

## Use
1. Be in-world on the **play client** (UE4SS loaded).
2. Prefer having the pal you want gone as the active/out slot (or first filled).
3. Press **F8** (default).

Party menu click opens skills — that is not selection.

## Install (client only)
```
...\Pal\Binaries\WinGDK\ue4ss\Mods\SendHome\
```
(Steam is usually `Win64`.) Requires working UE4SS: **`dwmapi.dll` next to the game `.exe`**, plus `ue4ss\UE4SS.dll`.

`enabled.txt` required.

## Config
`Scripts/config.lua` — `key` (default F8), `target` (`active` / `selected` / `first`), `use_poll`.

## Server
**Do not need** SendHome on the dedicated server for this. Client calls native `RequestMoveToPalBox_ToServer_Rep` (etc.); the server game binary already handles it. A server-side SendHome install only logs `ready` and never sees F8.

## Debug
Client `UE4SS.log` lines tagged `[SendHome]`.
