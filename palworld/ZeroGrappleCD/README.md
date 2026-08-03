# ZeroGrappleCD

Zero grapple cooldown. **Needs BOTH halves** (cooldown is client-visible/authoritative for the gun).

| Half | Where | Path |
|------|--------|------|
| PalSchema | **Server** | `PalSchema/mods/ZeroGrappleCD/` |
| UE4SS Lua | **Client** | `ue4ss/Mods/ZeroGrappleCD/` |

## Why server-only failed
`CoolDownTime` lives on the weapon CDO/instance the **client** simulates. Server blueprint alone often leaves the bar/timer.

## Client methods
1. `PalDebugSetting.bDisableGrapplingCoolDown = true` (if present)
2. `CoolDownTime = 0` on all grapple tiers
3. Hook `StartCoolDown` for grapple
4. Light 1s re-patch of grapple instances only (not full-world scan)

## Install
1. Server: extract PalSchema folder → restart dedicated  
2. Client: `ue4ss\Mods\ZeroGrappleCD\` → restart game  
3. Re-equip grappling gun after load
