from pathlib import Path
import json

base = Path(__file__).resolve().parent
js = (base / "dol-stat-panel.js").read_text(encoding="utf-8")

html = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8" />
<title>DoL Stat Panel — how to load</title>
<style>
  :root {{ color-scheme: dark; }}
  body {{
    font: 16px/1.45 system-ui, Segoe UI, sans-serif;
    max-width: 720px;
    margin: 40px auto;
    padding: 0 20px 60px;
    background: #121216;
    color: #eee;
  }}
  h1 {{ font-size: 1.4rem; margin-bottom: 0.25rem; }}
  .sub {{ color: #aaa; margin-bottom: 1.5rem; }}
  .warn {{
    background: #3a1a1a;
    border: 1px solid #a44;
    border-radius: 8px;
    padding: 12px 14px;
    margin: 16px 0;
  }}
  .ok {{
    background: #1a2a1a;
    border: 1px solid #4a4;
    border-radius: 8px;
    padding: 12px 14px;
    margin: 16px 0;
  }}
  ol {{ padding-left: 1.3rem; }}
  li {{ margin: 0.6rem 0; }}
  kbd {{
    background: #2a2a32;
    border: 1px solid #555;
    border-radius: 4px;
    padding: 1px 6px;
    font-size: 0.9em;
  }}
  button {{
    font: inherit;
    font-weight: 600;
    padding: 12px 18px;
    border-radius: 8px;
    border: 1px solid #6a6;
    background: #2a4a2a;
    color: #efe;
    cursor: pointer;
  }}
  button:hover {{ background: #356035; }}
  button.secondary {{
    background: #2a2a32;
    border-color: #666;
    margin-left: 8px;
  }}
  #msg {{ margin-left: 10px; color: #8f8; }}
  textarea {{
    width: 100%;
    height: 160px;
    box-sizing: border-box;
    margin-top: 12px;
    background: #0a0a0e;
    color: #9c9;
    border: 1px solid #444;
    border-radius: 8px;
    padding: 10px;
    font: 12px/1.35 ui-monospace, Consolas, monospace;
  }}
  code {{ background: #222; padding: 1px 5px; border-radius: 3px; }}
</style>
</head>
<body>
  <h1>DoL Stat Panel</h1>
  <p class="sub">Money, state, crime (collapsible), infinite spray — no official cheats / feats lock.</p>

  <div class="warn">
    <strong>Do not double-click <code>dol-stat-panel.js</code></strong> — Windows Script Host will error.
    Paste into the <em>game</em> console only.
  </div>

  <div class="ok">
    <strong>Load once per browser tab:</strong>
    <ol>
      <li>Open the game in Brave and <strong>load a save</strong></li>
      <li>Press <kbd>F12</kbd> → <strong>Console</strong></li>
      <li>Click <strong>Copy script</strong> below → click console → <kbd>Ctrl</kbd>+<kbd>V</kbd> → <kbd>Enter</kbd></li>
    </ol>
    Panel top-right. <strong>Crime</strong> is a collapsible dock section. Hit <strong>Reconnect</strong> if needed.
  </div>

  <p>
    <button type="button" id="copy">Copy script to clipboard</button>
    <button type="button" class="secondary" id="openGame">Open game</button>
    <span id="msg"></span>
  </p>

  <textarea id="code" readonly spellcheck="false"></textarea>

<script>
const SCRIPT = {json.dumps(js)};
document.getElementById("code").value = SCRIPT;
document.getElementById("copy").onclick = async () => {{
  const msg = document.getElementById("msg");
  try {{
    await navigator.clipboard.writeText(SCRIPT);
    msg.textContent = "Copied. Paste into the game console (F12).";
  }} catch {{
    document.getElementById("code").select();
    document.execCommand("copy");
    msg.textContent = "Copied (fallback). Paste into game console.";
  }}
}};
document.getElementById("openGame").onclick = () => {{
  location.href = "Degrees of Lewdity 0.5.11.9.html";
}};
</script>
</body>
</html>
"""

(base / "START-HERE-Stat-Panel.html").write_text(html, encoding="utf-8")
print("ok", len(html))
