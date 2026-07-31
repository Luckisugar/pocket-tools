@echo off
setlocal
cd /d "%~dp0"

where python >nul 2>&1
if errorlevel 1 (
  echo Python not found. Install Python 3 and retry.
  pause
  exit /b 1
)

REM No args = open GUI. Args = convert those files/folders.
if "%~1"=="" (
  python "%~dp0heic_convert.py" --gui
) else (
  python "%~dp0heic_convert.py" %*
)

if errorlevel 1 pause
exit /b %errorlevel%
