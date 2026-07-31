# DoL-Stat-Panel

Floating browser console panel for **Degrees of Lewdity** (SugarCube / Twine HTML build).

Edits money, state stats (pain, fatigue, stress, control, etc.), **crime** (collapsible dock), and infinite pepper spray **without** turning on the game’s official Cheat mode, so it does **not** set `feats.locked`.

## Why not Cheat Engine?

DoL is a browser JS game. CE is the wrong tool.

## Files

| File | Role |
|------|------|
| `START-HERE-Stat-Panel.html` | Guide only. → **Copy script** button + instructions |
| `dol-stat-panel.js` | Actual script (paste into game f12 console) |

## How to use

1. Open the game in Brave/Chrome and **load a save**
2. Open `START-HERE-Stat-Panel.html` → **Copy script**
3. Game tab → **F12** → **Console** → paste → Enter
4. Panel appears top-right

**Reconnect** re-grabs live `State.variables` after time passes (SugarCube swaps the variables object each passage). The panel also auto-reconnects on passage render.

## Don’t

- Don’t double-click the `.js` (Windows Script Host will error — that’s expected)
- Don’t enable the game’s own Cheat mode if you care about feats on that sav.

## Notes

- Money UI is in **pounds**; internal value is **pence** (`£1` = `100`)
- Fatigue in the UI is `V.tiredness` in the game
