#!/usr/bin/env python3
"""
HEIC/HEIF → JPEG / PNG / WebP converter with Preflight + Log (memory.md UX).
Tool root = this folder (portable: delete folder = uninstall).
"""

from __future__ import annotations

import argparse
import json
import os
import platform
import subprocess
import sys
import traceback
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

TOOL_ROOT = Path(__file__).resolve().parent
I18N_DIR = TOOL_ROOT / "src" / "i18n"
LANG_FILE = TOOL_ROOT / "ui-language.txt"
LOG_FILE = TOOL_ROOT / "convert-log.txt"

HEIC_EXTS = {".heic", ".heif", ".hif"}
OUT_FORMATS = {
    "jpg": ("JPEG", ".jpg"),
    "jpeg": ("JPEG", ".jpg"),
    "png": ("PNG", ".png"),
    "webp": ("WEBP", ".webp"),
}


# ---------------------------------------------------------------------------
# i18n
# ---------------------------------------------------------------------------

def load_strings(lang: str) -> dict[str, str]:
    code = "pt-BR" if lang.lower().startswith("pt") else "en"
    path = I18N_DIR / f"{code}.json"
    if not path.is_file():
        path = I18N_DIR / "en.json"
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def get_saved_lang() -> str | None:
    if LANG_FILE.is_file():
        v = LANG_FILE.read_text(encoding="utf-8").strip()
        if v:
            return v
    return None


def save_lang(lang: str) -> None:
    LANG_FILE.write_text(lang.strip() + "\n", encoding="utf-8")


# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------

@dataclass
class Check:
    name: str
    status: str  # Pass | Warn | Fail
    detail: str


def run_preflight(t: dict[str, str]) -> tuple[list[Check], bool]:
    checks: list[Check] = []

    # OS
    checks.append(
        Check(
            t["pf_os"],
            "Pass",
            f"{platform.system()} {platform.release()} ({platform.version()})",
        )
    )

    # Python
    py = sys.version.split()[0]
    checks.append(Check(t["pf_python"], "Pass", f"{py} @ {sys.executable}"))

    # Pillow
    try:
        import PIL

        checks.append(Check(t["pf_pillow"], "Pass", f"Pillow {PIL.__version__}"))
        pillow_ok = True
    except Exception as ex:
        checks.append(Check(t["pf_pillow"], "Fail", f"{ex} — {t['install_hint']}"))
        pillow_ok = False

    # pillow-heif
    try:
        import pillow_heif  # noqa: F401
        from pillow_heif import register_heif_opener

        register_heif_opener()
        ver = getattr(pillow_heif, "__version__", "?")
        checks.append(Check(t["pf_heif"], "Pass", f"pillow-heif {ver} (HEIC opener registered)"))
        heif_ok = True
    except Exception as ex:
        checks.append(Check(t["pf_heif"], "Fail", f"{ex} — {t['install_hint']}"))
        heif_ok = False

    # write tool folder
    try:
        probe = TOOL_ROOT / ".write-test"
        probe.write_text("ok", encoding="utf-8")
        probe.unlink(missing_ok=True)
        checks.append(Check(t["pf_write"], "Pass", str(TOOL_ROOT)))
    except Exception as ex:
        checks.append(Check(t["pf_write"], "Warn", f"Limited write in tool folder: {ex}"))

    can_run = all(c.status != "Fail" for c in checks) and pillow_ok and heif_ok
    return checks, can_run


# ---------------------------------------------------------------------------
# Convert core
# ---------------------------------------------------------------------------

def collect_inputs(paths: list[Path]) -> list[Path]:
    files: list[Path] = []
    for p in paths:
        p = Path(p)
        if p.is_file() and p.suffix.lower() in HEIC_EXTS:
            files.append(p.resolve())
        elif p.is_dir():
            for child in sorted(p.rglob("*")):
                if child.is_file() and child.suffix.lower() in HEIC_EXTS:
                    files.append(child.resolve())
    return files


def convert_one(src: Path, dest_dir: Path | None, fmt_key: str, quality: int) -> Path:
    from PIL import Image, ImageOps

    pil_fmt, ext = OUT_FORMATS[fmt_key.lower()]
    out_dir = dest_dir if dest_dir is not None else src.parent
    out_dir.mkdir(parents=True, exist_ok=True)
    out = out_dir / f"{src.stem}{ext}"

    # avoid silent overwrite: add (1) if exists
    if out.exists():
        n = 1
        while True:
            candidate = out_dir / f"{src.stem} ({n}){ext}"
            if not candidate.exists():
                out = candidate
                break
            n += 1

    with Image.open(src) as im:
        im = ImageOps.exif_transpose(im)
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
            save_kwargs: dict = {"quality": quality, "optimize": True}
        elif pil_fmt == "WEBP":
            if im.mode == "P":
                im = im.convert("RGBA")
            save_kwargs = {"quality": quality, "method": 4}
        else:
            save_kwargs = {"optimize": True}
        im.save(out, format=pil_fmt, **save_kwargs)
    return out.resolve()


def open_in_explorer(path: Path) -> None:
    path = path.resolve()
    if path.is_file():
        path = path.parent
    if sys.platform == "win32":
        os.startfile(str(path))  # type: ignore[attr-defined]
    elif sys.platform == "darwin":
        subprocess.run(["open", str(path)], check=False)
    else:
        subprocess.run(["xdg-open", str(path)], check=False)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def run_cli(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Convert HEIC/HEIF to JPEG/PNG/WebP.")
    parser.add_argument("inputs", nargs="*", type=Path)
    parser.add_argument("-f", "--format", default="jpg", choices=sorted(set(OUT_FORMATS)))
    parser.add_argument("-o", "--output", type=Path, default=None)
    parser.add_argument("-q", "--quality", type=int, default=100)
    parser.add_argument("--gui", action="store_true")
    parser.add_argument("--lang", default=None, help="en | pt-BR")
    args = parser.parse_args(argv)

    if args.gui or not args.inputs:
        return run_gui(
            default_fmt=args.format,
            quality=max(1, min(100, args.quality)),
            out_dir=args.output,
            lang_override=args.lang,
        )

    lang = args.lang or get_saved_lang() or "en"
    t = load_strings(lang)
    print(f"[preflight] {t['preflight']}…", flush=True)
    checks, can_run = run_preflight(t)
    for c in checks:
        print(f"  [{c.status}] {c.name}: {c.detail}", flush=True)
    print(t["can_run"] if can_run else t["cannot_run"], flush=True)
    if not can_run:
        return 1

    files = collect_inputs(args.inputs)
    if not files:
        print(t["no_files"])
        return 1

    quality = max(1, min(100, args.quality))
    if args.output:
        print(f"Destination: {args.output.resolve()}", flush=True)
    else:
        print("Destination: SAME FOLDER as each source HEIC", flush=True)

    ok = 0
    outs: list[Path] = []
    for i, src in enumerate(files, 1):
        print(f"[{i}/{len(files)}] {src.name} …", flush=True)
        try:
            out = convert_one(src, args.output, args.format, quality)
            print(f"  → {out}", flush=True)
            outs.append(out)
            ok += 1
        except Exception as ex:
            print(f"  FAIL: {ex}", flush=True)
    print(f"Done: {ok}/{len(files)}", flush=True)
    if outs:
        print(f"Open folder: {outs[0].parent}", flush=True)
    return 0 if ok == len(files) else 2


# ---------------------------------------------------------------------------
# GUI
# ---------------------------------------------------------------------------

def run_gui(
    default_fmt: str = "jpg",
    quality: int = 100,
    out_dir: Path | None = None,
    lang_override: str | None = None,
) -> int:
    import tkinter as tk
    from tkinter import filedialog, messagebox, ttk

    # Language first-run
    lang = lang_override or get_saved_lang()
    if not lang:
        pick = tk.Tk()
        pick.title("Language / Idioma")
        pick.geometry("320x120")
        chosen: dict[str, str] = {"v": "en"}

        def set_lang(code: str) -> None:
            chosen["v"] = code
            save_lang(code)
            pick.destroy()

        ttk.Label(pick, text="Choose language / Escolha o idioma", font=("", 11, "bold")).pack(pady=12)
        row = ttk.Frame(pick)
        row.pack()
        ttk.Button(row, text="English", command=lambda: set_lang("en")).pack(side="left", padx=8)
        ttk.Button(row, text="Português (BR)", command=lambda: set_lang("pt-BR")).pack(side="left", padx=8)
        pick.mainloop()
        lang = chosen["v"]

    t = load_strings(lang)
    last_out_dir: list[Path | None] = [None]
    can_run_flag = {"ok": False}

    root = tk.Tk()
    root.title(t["app_title"])
    # Start compact — activity dock is collapsed by default
    root.geometry("640x240")
    root.minsize(480, 160)

    fmt_var = tk.StringVar(value=default_fmt if default_fmt in ("jpg", "png", "webp") else "jpg")
    q_var = tk.IntVar(value=quality)
    status = tk.StringVar(value=t["status_ready"])
    banner = tk.StringVar(value="")
    lang_var = tk.StringVar(value="Português (BR)" if lang.startswith("pt") else "English")
    # Remember open size so Hide can shrink the window (no empty grey void)
    geom = {"open": "640x520", "collapsed_h": 240}

    # --- log ---
    def log(msg: str) -> None:
        line = f"[{datetime.now().strftime('%H:%M:%S')}] {msg}"
        log_box.configure(state="normal")
        log_box.insert("end", line + "\n")
        log_box.see("end")
        log_box.configure(state="disabled")
        try:
            with LOG_FILE.open("a", encoding="utf-8") as f:
                f.write(line + "\n")
        except OSError:
            pass
        root.update_idletasks()

    def clear_log() -> None:
        log_box.configure(state="normal")
        log_box.delete("1.0", "end")
        log_box.configure(state="disabled")

    def _window_width() -> int:
        root.update_idletasks()
        w = root.winfo_width()
        return w if w > 100 else 640

    def set_dock_open(open_: bool) -> None:
        dock_open["v"] = open_
        w = _window_width()
        if open_:
            body.pack(fill="both", expand=True, padx=6, pady=(0, 6))
            dock.pack_configure(fill="both", expand=True)
            dock_toggle.configure(text=t["dock_hide"])
            chevron.set("▾ " + t["activity"])
            root.minsize(480, 360)
            try:
                h = int(geom["open"].split("x")[1])
            except (ValueError, IndexError, KeyError):
                h = 520
            root.geometry(f"{w}x{max(h, 400)}")
            root.update_idletasks()
        else:
            # save size while expanded, then drop log body and shrink shell
            root.update_idletasks()
            if root.winfo_height() > 300:
                geom["open"] = f"{root.winfo_width()}x{root.winfo_height()}"
            body.pack_forget()
            # dock must stop expanding or the window keeps a huge empty region
            dock.pack_configure(fill="x", expand=False)
            dock_toggle.configure(text=t["dock_show"])
            chevron.set("▸ " + t["activity"])
            root.minsize(480, 160)
            root.update_idletasks()
            req = root.winfo_reqheight()
            h = max(190, min(req + 12, 300))
            geom["collapsed_h"] = h
            root.geometry(f"{w}x{h}")
            root.update_idletasks()

    def toggle_dock() -> None:
        set_dock_open(not dock_open["v"])

    def apply_preflight_ui() -> None:
        nonlocal t
        t = load_strings("pt-BR" if lang_var.get().startswith("Port") else "en")
        checks, can = run_preflight(t)
        can_run_flag["ok"] = can
        log("—— " + t["preflight"] + " ——")
        for c in checks:
            log(f"  [{t.get(c.status.lower(), c.status)}] {c.name}: {c.detail}")
        log(t["can_run"] if can else t["cannot_run"])
        banner.set(t["can_run"] if can else t["cannot_run"])
        status.set(t["status_ready"] if can else t["cannot_run"])
        convert_btn.configure(state="normal" if can else "disabled")
        # keep chevron label in sync after language change
        set_dock_open(dock_open["v"])

    def change_lang(_evt=None) -> None:
        code = "pt-BR" if lang_var.get().startswith("Port") else "en"
        save_lang(code)
        nonlocal t
        t = load_strings(code)
        root.title(t["app_title"])
        subtitle_lbl.configure(text=t["subtitle"])
        fmt_lbl.configure(text=t["format"] + ":")
        q_lbl.configure(text=t["quality"] + ":")
        pf_btn.configure(text=t["run_preflight"])
        convert_btn.configure(text=t["btn_convert"])
        open_btn.configure(text=t["btn_open_last"])
        clear_btn.configure(text=t["btn_clear_log"])
        lang_lbl.configure(text=t["lang_label"] + ":")
        set_dock_open(dock_open["v"])
        apply_preflight_ui()

    def pick_and_convert() -> None:
        if not can_run_flag["ok"]:
            messagebox.showerror(t["app_title"], t["cannot_run"])
            return

        paths = filedialog.askopenfilenames(
            title=t["pick_title"],
            filetypes=[
                ("Apple HEIC", "*.heic *.HEIC *.heif *.HEIF"),
                ("All files", "*.*"),
            ],
        )
        if not paths:
            log(t["no_files"])
            status.set(t["no_files"])
            return

        use_custom = messagebox.askyesno(t["ask_other_folder_title"], t["ask_other_folder"])
        dest: Path | None = None
        if use_custom:
            chosen = filedialog.askdirectory(title=t["pick_out_title"])
            if not chosen:
                log(t["cancelled"])
                status.set(t["cancelled"])
                messagebox.showinfo(t["app_title"], t["cancelled"])
                return
            dest = Path(chosen)
            where = t["custom_folder_explain"].format(path=str(dest.resolve()))
            log(t["log_dest_custom"].format(path=str(dest.resolve())))
        else:
            dest = None
            where = t["same_folder_explain"]
            log(t["log_dest_same"])
            # show concrete example from first file
            first = Path(paths[0]).resolve()
            log(f"  e.g. {first.parent / (first.stem + '.' + fmt_var.get())}")

        files = [Path(p) for p in paths]
        status.set(t["status_busy"])
        convert_btn.configure(state="disabled")
        root.update_idletasks()

        log(t["log_start"].format(n=len(files)))
        ok = 0
        errors: list[str] = []
        outs: list[Path] = []
        n = len(files)
        for i, src in enumerate(files, 1):
            status.set(f"{t['status_busy']} {i}/{n} — {src.name}")
            root.update_idletasks()
            try:
                out = convert_one(src, dest, fmt_var.get(), int(q_var.get()))
                ok += 1
                outs.append(out)
                log(t["log_item"].format(i=i, n=n, name=src.name, out=str(out)))
            except Exception as ex:
                err = str(ex)
                errors.append(f"{src.name}: {err}")
                log(t["log_fail"].format(i=i, n=n, name=src.name, err=err))
                log(traceback.format_exc().strip().splitlines()[-1])

        log(t["log_done"].format(ok=ok, total=n))
        if outs:
            last_out_dir[0] = outs[0].parent
            log(f"→ {outs[0].parent}")

        examples = "\n".join(str(p) for p in outs[:5]) or "—"
        body = t["done_body"].format(ok=ok, total=n, where=where, examples=examples)
        if errors:
            body += "\n\n" + "\n".join(errors[:8])
            messagebox.showwarning(t["done_warn_title"], body)
        else:
            messagebox.showinfo(t["done_title"], body)

        status.set(t["log_done"].format(ok=ok, total=n) + f" | {where.splitlines()[0]}")
        convert_btn.configure(state="normal")
        open_btn.configure(state="normal" if last_out_dir[0] else "disabled")

    def open_last() -> None:
        p = last_out_dir[0]
        if not p:
            return
        try:
            open_in_explorer(p)
            log(f"Opened: {p}")
        except Exception as ex:
            messagebox.showerror(t["app_title"], t["open_failed"].format(path=f"{p}\n{ex}"))

    # --- layout: controls on top, ONE dockable activity pane (preflight + log) ---
    pad = {"padx": 10, "pady": 4}
    dock_open = {"v": False}  # docked/collapsed by default
    chevron = tk.StringVar(value="")

    top = ttk.Frame(root)
    top.pack(fill="x", **pad)
    subtitle_lbl = ttk.Label(top, text=t["subtitle"], font=("", 12, "bold"))
    subtitle_lbl.pack(side="left")
    lang_row = ttk.Frame(top)
    lang_row.pack(side="right")
    lang_lbl = ttk.Label(lang_row, text=t["lang_label"] + ":")
    lang_lbl.pack(side="left")
    lang_cb = ttk.Combobox(
        lang_row,
        textvariable=lang_var,
        values=["English", "Português (BR)"],
        width=14,
        state="readonly",
    )
    lang_cb.pack(side="left", padx=4)
    lang_cb.bind("<<ComboboxSelected>>", change_lang)

    ttk.Label(root, textvariable=banner, foreground="#0a6").pack(anchor="w", **pad)

    opts = ttk.Frame(root)
    opts.pack(fill="x", **pad)
    fmt_lbl = ttk.Label(opts, text=t["format"] + ":")
    fmt_lbl.pack(side="left")
    ttk.Combobox(opts, textvariable=fmt_var, values=["jpg", "png", "webp"], width=8, state="readonly").pack(
        side="left", padx=6
    )
    q_lbl = ttk.Label(opts, text=t["quality"] + ":")
    q_lbl.pack(side="left")
    ttk.Spinbox(opts, from_=1, to=100, textvariable=q_var, width=5).pack(side="left", padx=6)

    convert_btn = ttk.Button(root, text=t["btn_convert"], command=pick_and_convert)
    convert_btn.pack(fill="x", **pad)

    btn_row = ttk.Frame(root)
    btn_row.pack(fill="x", **pad)
    open_btn = ttk.Button(btn_row, text=t["btn_open_last"], command=open_last, state="disabled")
    open_btn.pack(side="left")

    ttk.Label(root, textvariable=status, wraplength=600).pack(anchor="w", **pad)

    # Single dock: header holds Preflight + Clear; body is the shared terminal
    dock = ttk.Frame(root, relief="groove", borderwidth=1)
    dock.pack(fill="x", expand=False, **pad)

    dock_hdr = ttk.Frame(dock)
    dock_hdr.pack(fill="x", padx=4, pady=4)
    ttk.Label(dock_hdr, textvariable=chevron, font=("", 10, "bold")).pack(side="left")
    dock_toggle = ttk.Button(dock_hdr, width=12, command=toggle_dock)
    dock_toggle.pack(side="right", padx=(4, 0))
    clear_btn = ttk.Button(dock_hdr, text=t["btn_clear_log"], command=clear_log)
    clear_btn.pack(side="right", padx=4)
    pf_btn = ttk.Button(dock_hdr, text=t["run_preflight"], command=apply_preflight_ui)
    pf_btn.pack(side="right", padx=4)

    body = ttk.Frame(dock)
    log_box = tk.Text(body, height=14, wrap="word", state="disabled", font=("Consolas", 9))
    scroll = ttk.Scrollbar(body, command=log_box.yview)
    log_box.configure(yscrollcommand=scroll.set)
    scroll.pack(side="right", fill="y")
    log_box.pack(side="left", fill="both", expand=True)

    log(f"Tool root: {TOOL_ROOT}")
    # Collapsed by default (docked); preflight still runs into the log for when user expands
    set_dock_open(False)
    apply_preflight_ui()
    root.mainloop()
    return 0


if __name__ == "__main__":
    raise SystemExit(run_cli())
