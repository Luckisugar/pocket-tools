#!/usr/bin/env python3
"""
HEIC/HEIF → JPEG / PNG / WebP converter (Windows-friendly).

HEIC is Apple's High Efficiency Image Container — what modern iPhones
save by default. Most Windows apps and websites don't open it.

Usage:
  python heic_convert.py IMG_7049.heic
  python heic_convert.py photo.heic -f png
  python heic_convert.py folder_of_photos -o out_dir -f jpg -q 92
  python heic_convert.py --gui
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

try:
    from pillow_heif import register_heif_opener
    from PIL import Image, ImageOps
except ImportError:
    print("Missing packages. Run:\n  python -m pip install pillow pillow-heif")
    sys.exit(1)

register_heif_opener()

HEIC_EXTS = {".heic", ".heif", ".hif"}
OUT_FORMATS = {
    "jpg": ("JPEG", ".jpg"),
    "jpeg": ("JPEG", ".jpg"),
    "png": ("PNG", ".png"),
    "webp": ("WEBP", ".webp"),
}


def collect_inputs(paths: list[Path]) -> list[Path]:
    files: list[Path] = []
    for p in paths:
        if p.is_file() and p.suffix.lower() in HEIC_EXTS:
            files.append(p)
        elif p.is_dir():
            for child in sorted(p.rglob("*")):
                if child.is_file() and child.suffix.lower() in HEIC_EXTS:
                    files.append(child)
    return files


def convert_one(
    src: Path,
    dest_dir: Path | None,
    fmt_key: str,
    quality: int,
) -> Path:
    pil_fmt, ext = OUT_FORMATS[fmt_key.lower()]
    out_dir = dest_dir if dest_dir is not None else src.parent
    out_dir.mkdir(parents=True, exist_ok=True)
    out = out_dir / f"{src.stem}{ext}"

    with Image.open(src) as im:
        # Apply EXIF orientation so phone photos aren't sideways
        im = ImageOps.exif_transpose(im)
        # JPEG/WebP don't like RGBA / palette edge cases
        if pil_fmt == "JPEG":
            if im.mode in ("RGBA", "LA", "P"):
                bg = Image.new("RGB", im.size, (255, 255, 255))
                if im.mode == "P":
                    im = im.convert("RGBA")
                alpha = im.split()[-1] if im.mode in ("RGBA", "LA") else None
                if alpha is not None:
                    bg.paste(im.convert("RGBA"), mask=alpha)
                else:
                    bg.paste(im.convert("RGB"))
                im = bg
            elif im.mode != "RGB":
                im = im.convert("RGB")
            save_kwargs = {"quality": quality, "optimize": True}
        elif pil_fmt == "WEBP":
            if im.mode == "P":
                im = im.convert("RGBA")
            save_kwargs = {"quality": quality, "method": 4}
        else:  # PNG
            save_kwargs = {"optimize": True}

        im.save(out, format=pil_fmt, **save_kwargs)

    return out


def run_cli(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Convert HEIC/HEIF images to JPEG, PNG, or WebP."
    )
    parser.add_argument(
        "inputs",
        nargs="*",
        type=Path,
        help="HEIC file(s) and/or folders",
    )
    parser.add_argument(
        "-f",
        "--format",
        default="jpg",
        choices=sorted(set(OUT_FORMATS.keys())),
        help="Output format (default: jpg)",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=None,
        help="Output folder (default: same folder as each source)",
    )
    parser.add_argument(
        "-q",
        "--quality",
        type=int,
        default=92,
        help="JPEG/WebP quality 1-100 (default: 92)",
    )
    parser.add_argument(
        "--gui",
        action="store_true",
        help="Open a simple file picker GUI",
    )
    args = parser.parse_args(argv)

    if args.gui or not args.inputs:
        return run_gui(
            default_fmt=args.format,
            quality=max(1, min(100, args.quality)),
            out_dir=args.output,
        )

    files = collect_inputs(args.inputs)
    if not files:
        print("No .heic / .heif files found.")
        return 1

    quality = max(1, min(100, args.quality))
    ok = 0
    for src in files:
        try:
            out = convert_one(src, args.output, args.format, quality)
            print(f"OK  {src.name}  ->  {out}")
            ok += 1
        except Exception as ex:
            print(f"FAIL {src}: {ex}", file=sys.stderr)
    print(f"Done: {ok}/{len(files)} converted.")
    return 0 if ok == len(files) else 2


def run_gui(
    default_fmt: str = "jpg",
    quality: int = 92,
    out_dir: Path | None = None,
) -> int:
    import tkinter as tk
    from tkinter import filedialog, messagebox, ttk

    root = tk.Tk()
    root.title("HEIC Converter")
    root.geometry("480x220")
    root.minsize(420, 200)

    fmt_var = tk.StringVar(value=default_fmt if default_fmt in ("jpg", "png", "webp") else "jpg")
    q_var = tk.IntVar(value=quality)
    status = tk.StringVar(value="Pick HEIC files (iPhone photos). Output: same folder, or choose one.")

    def pick_and_convert() -> None:
        paths = filedialog.askopenfilenames(
            title="Select HEIC / HEIF photos",
            filetypes=[
                ("Apple HEIC", "*.heic *.HEIC *.heif *.HEIF"),
                ("All files", "*.*"),
            ],
        )
        if not paths:
            return
        dest = out_dir
        if messagebox.askyesno("Output folder", "Save converted files into a different folder?"):
            chosen = filedialog.askdirectory(title="Output folder")
            if chosen:
                dest = Path(chosen)
        files = [Path(p) for p in paths]
        ok = 0
        errors: list[str] = []
        for src in files:
            try:
                out = convert_one(src, dest, fmt_var.get(), q_var.get())
                ok += 1
                status.set(f"Last: {out.name}")
                root.update_idletasks()
            except Exception as ex:
                errors.append(f"{src.name}: {ex}")
        msg = f"Converted {ok}/{len(files)}."
        if errors:
            msg += "\n\n" + "\n".join(errors[:8])
            messagebox.showwarning("Done with errors", msg)
        else:
            messagebox.showinfo("Done", msg)
        status.set(msg.split("\n")[0])

    pad = {"padx": 12, "pady": 6}
    ttk.Label(root, text="HEIC → normal image formats", font=("", 12, "bold")).pack(anchor="w", **pad)
    row = ttk.Frame(root)
    row.pack(fill="x", **pad)
    ttk.Label(row, text="Format:").pack(side="left")
    ttk.Combobox(row, textvariable=fmt_var, values=["jpg", "png", "webp"], width=8, state="readonly").pack(
        side="left", padx=8
    )
    ttk.Label(row, text="Quality:").pack(side="left")
    ttk.Spinbox(row, from_=1, to=100, textvariable=q_var, width=5).pack(side="left", padx=8)
    ttk.Button(root, text="Select HEIC files and convert…", command=pick_and_convert).pack(fill="x", **pad)
    ttk.Label(root, textvariable=status, wraplength=440).pack(anchor="w", **pad)
    root.mainloop()
    return 0


if __name__ == "__main__":
    # Drag-and-drop onto the .py / .bat: paths land in sys.argv
    raise SystemExit(run_cli())
