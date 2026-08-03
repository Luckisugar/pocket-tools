# Palworld Base Camp Range 2x

PalSchema blueprint: **2x** base build radius (`BaseCampAreaRange` 3500 → **7000**).

Also scales pal work / foliage / neighbor / spawn-suppress distances so pals can actually work outside the old edge.

## Important

- **Server = real build range.** Dedicated / host needs this mod.
- **Blue circle is client-only visual.** Server install alone does **not** enlarge the ring. If the circle is small but you can still build past it — **the mod is working.** Test by placing walls outside the ring.
- Existing palboxes keep the old radius until you **destroy + rebuild** the box.
- Do **not** stack with other base-range mods (BetterBaseRange, Ultimate, etc.).

## Requirements

- [UE4SS (Palworld)](https://github.com/UE4SS-RE/RE-UE4SS) experimental Palworld build
- [PalSchema](https://github.com/Okaetsu/PalSchema) under `ue4ss/Mods/PalSchema`

## Install (dedicated / Palsitter)

1. Stop the server.
2. Copy this whole folder into:

```
.../ue4ss/Mods/PalSchema/mods/Palworld-Base-Camp-Range-2x/
```

So you have:

```
PalSchema/mods/Palworld-Base-Camp-Range-2x/blueprints/Base Camp Range.jsonc
```

3. Start the server.
4. In-game: **destroy + rebuild** each palbox (or place a new base).
5. Try building **outside** the blue circle.

## Install (single-player / listen host)

Same path under the **game** install:

```
Pal/Binaries/Win64/ue4ss/Mods/PalSchema/mods/Palworld-Base-Camp-Range-2x/
```

(MS Store / Game Pass: `WinGDK` instead of `Win64` if that is your binary folder.)

## Tweak size

Edit `blueprints/Base Camp Range.jsonc` → `BaseCampAreaRange`:

| Multiplier | Value |
|------------|------:|
| 1x vanilla | 3500 |
| 1.5x | 5250 |
| **2x (default)** | **7000** |
| 3x | 10500 |

Keep work/foliage/spawn distances in the same ballpark as range, or pals/spawns will feel wrong.

## Uninstall

Delete the `Palworld-Base-Camp-Range-2x` folder under `PalSchema/mods`, restart, rebuild palbox.

## License

MIT — do whatever. Game assets remain Pocketpair’s.
