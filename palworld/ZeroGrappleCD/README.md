# ZeroGrappleCD

Zero cooldown on **all grappling gun tiers** (T1–T4).

| Piece | Where | Path |
|--------|--------|------|
| **PalSchema** | **Server** (Palsitter) | `PalSchema/mods/ZeroGrappleCD/` |
| **UE4SS Lua** | **Client** (Game Pass) | `ue4ss/Mods/ZeroGrappleCD/` |

Sets `CoolDownTime` and `NearCoolTimeRate` to `0` on:
- `BP_GrapplingGun_C` (12s → 0)
- `BP_GrapplingGun_2_C` (10s → 0)
- `BP_GrapplingGun_3_C` (8s → 0)
- `BP_GrapplingGun_4_C` (6s → 0)

## Install

**Server:** copy `PalSchema/mods/ZeroGrappleCD` into server PalSchema mods, restart server.

**Client:** copy `ZeroGrappleCD` folder into live `ue4ss\Mods\` (same place as SendHome), restart game.

## Config (client Lua)
`Scripts/config.lua` — change `cool_down_time` if you want a tiny delay instead of hard zero.
