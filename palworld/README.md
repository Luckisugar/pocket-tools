# palworld

Palworld mods from our setup (Game Pass client + dedicated server).

| Folder | Type | Where it runs | What |
|--------|------|---------------|------|
| [Palworld-Base-Camp-Range-2x](./Palworld-Base-Camp-Range-2x) | PalSchema | **Server** (data/BP) | 2x base build radius |
| [SendHome](./SendHome) | UE4SS Lua | **Client** (keyboard + ToServer RPC) | F8: party pal → Palbox |

## Install notes

- **Range 2x:** server PalSchema `mods` folder (not LogicMods).
- **SendHome:** client `ue4ss\Mods\SendHome\` with UE4SS actually injected (`dwmapi.dll` **next to** the game `.exe`). Server copy of SendHome does nothing useful for F8.
- Blue ring matches range when client visuals/mods are correct; range itself is the server PalSchema value.

Default SendHome key: **F8** (`Scripts/config.lua`).
