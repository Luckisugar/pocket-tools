# palworld

Palworld mods from our setup (Game Pass client + dedicated server).

| Folder | Type | Where | What |
|--------|------|-------|------|
| [Palworld-Base-Camp-Range-2x](./Palworld-Base-Camp-Range-2x) | PalSchema | **Server** | 2x base build radius |
| [SendHome](./SendHome) | UE4SS Lua | **Client** | F8: party pal → Palbox |
| [ZeroGrappleCD-PalSchema](./ZeroGrappleCD-PalSchema) | PalSchema | **Server** | Grapple cooldown = 0 (all 4 tiers) |

## Install notes

- **PalSchema mods** (range, grapple): dedicated server `PalSchema/mods/<name>/`
- **SendHome**: client `ue4ss\Mods\SendHome\` — needs UE4SS with `dwmapi.dll` **next to** the game `.exe`
- **Do not** run a client Lua that `FindAllOf`-loops every 2s (old ZeroGrappleCD client). Server PalSchema alone zeros grapple CD.
- Blue ring scale is client visual (OursBaseRing); build radius is server PalSchema.

## Grapple tiers (all patched)

Grappling / Mega / Giga / Hyper → `BP_GrapplingGun` … `_4` `CoolDownTime = 0`
