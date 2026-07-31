# HEIC Converter

iPhone **`.heic`** → **JPG / PNG / WebP** on Windows.

## What is HEIC?

Apple’s High Efficiency Image format. Small files; most Windows apps won’t open them until converted.

## Run

1. Double-click **`Convert-HEIC.bat`**
2. Activity dock starts **collapsed**; Preflight + Clear Log live in that bar  
3. Default quality **100**; pick HEIC files  
4. **No** = save **next to each original** · **Yes** = other folder  
5. Done dialog lists full paths

## First-time deps

```powershell
python -m pip install pillow pillow-heif
```

Preflight tells you if they’re missing.

## CLI

```powershell
python heic_convert.py photo.heic
python heic_convert.py .\album -o .\out -f png -q 92
```

## Uninstall

Delete this folder. Logs: `convert-log.txt`, language: `ui-language.txt` (both inside the tool).

## Languages

English + Português (BR) — first-run picker; saved in `ui-language.txt`.
