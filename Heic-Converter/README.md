# Heic-Converter

Convert iPhone **`.heic` / `.heif`** photos to **JPEG**, **PNG**, or **WebP** on Windows.

## What is HEIC?

**HEIC** = High Efficiency Image Container. Apple’s default camera format since ~iPhone 7/8 era. Smaller than JPEG at similar quality. Windows, Discord, most websites, and a lot of apps **don’t open it** unless you install HEIF extensions or convert first.

## Setup (once)

```powershell
python -m pip install pillow pillow-heif
```

## Use

**GUI (easiest)**  
Double-click `Convert-HEIC.bat`

**Drag and drop**  
Drop `.heic` files onto `Convert-HEIC.bat`

**CLI**

```powershell
python heic_convert.py IMG_7049.heic
python heic_convert.py photo.heic -f png
python heic_convert.py .\Photos -o .\converted -f jpg -q 92
```

Default: JPG quality 92, next to the source file. EXIF orientation is applied so phone pics aren’t sideways.
