# palworld

Palworld mods from our setup (Game Pass client + dedicated server).

| Folder | Type | Where it runs | What |
|--------|------|---------------|------|
| [Palworld-Base-Camp-Range-2x](./Palworld-Base-Camp-Range-2x) | PalSchema | **Server** | 2x base build radius |
| [SendHome](./SendHome) | UE4SS Lua | **Client** | F8: party pal → Palbox |
| [ZeroGrappleCD](./ZeroGrappleCD) | UE4SS Lua | **Client** | Grapple cooldown = 0 |
| [ZeroGrappleCD-PalSchema](./ZeroGrappleCD-PalSchema) | PalSchema | **Server** | Same, blueprint CDO |

## Install notes

- **Range 2x / ZeroGrappleCD-PalSchema:** server `PalSchema/mods/...`
- **SendHome / ZeroGrappleCD (Lua):** client `ue4ss\Mods\...` with `dwmapi.dll` **next to** the game `.exe`
- Put **both** ZeroGrapple pieces (server PalSchema + client Lua) for dedicated play
