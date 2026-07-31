@echo off
setlocal
cd /d "%~dp0"
title HEIC Converter

where python >nul 2>&1
if errorlevel 1 (
  echo [FAIL] Python not found. Install Python 3 and retry.
  echo https://www.python.org/downloads/
  pause
  exit /b 1
)

echo [%time%] Starting HEIC Converter...
echo [%time%] Tool folder: %cd%

if "%~1"=="" (
  echo [%time%] Opening GUI...
  python "%~dp0heic_convert.py" --gui
) else (
  echo [%time%] Converting dropped/arg files...
  python "%~dp0heic_convert.py" %*
)

set ERR=%errorlevel%
echo [%time%] Exit code: %ERR%
if not %ERR%==0 pause
exit /b %ERR%
