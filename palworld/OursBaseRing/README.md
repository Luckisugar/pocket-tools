# OursBaseRing

Client UE4SS: scale **blue palbox ring** to match 2x base range (7000 cm / 2× of 3500).

Does **not** set real build radius — that is server PalSchema **Palworld-Base-Camp-Range-2x**.

## Install (client only)
```
...\ue4ss\Mods\OursBaseRing\
  enabled.txt
  Scripts\config.lua
  Scripts\main.lua
```
Needs working UE4SS (`dwmapi.dll` next to game exe).

## Config
`target_radius_cm = 7000`, `reapply_interval_ms = 0` (no periodic spam).
