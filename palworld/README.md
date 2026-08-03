# palworld

| Folder | Type | Where | What |
|--------|------|-------|------|
| [Palworld-Base-Camp-Range-2x](./Palworld-Base-Camp-Range-2x) | PalSchema | Server | 2x base build radius |
| [SendHome](./SendHome) | UE4SS Lua | Client | F8 party pal → Palbox |
| [ZeroGrappleCD-PalSchema](./ZeroGrappleCD-PalSchema) | PalSchema | Server | Grapple CoolDownTime = 0 |
| [ZeroGrappleCD](./ZeroGrappleCD) | UE4SS Lua | Client | Zero grapple CD (required; CD is client-side) |

## Notes
- **ZeroGrapple needs BOTH** server PalSchema + client Lua (server-only was not enough).
- VacuumLoot / ThunderHome abandoned (crash or wrong approach).
- SendHome + range still good.
