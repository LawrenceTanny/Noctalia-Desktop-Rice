@echo off
setlocal
where bash >nul 2>&1
if %errorlevel% equ 0 (
    bash "%~dp0install.sh"
    goto :eof
)
if exist "%ProgramFiles%\Git\bin\bash.exe" (
    "%ProgramFiles%\Git\bin\bash.exe" "%~dp0install.sh"
    goto :eof
)
if exist "%ProgramFiles(x86)%\Git\bin\bash.exe" (
    "%ProgramFiles(x86)%\Git\bin\bash.exe" "%~dp0install.sh"
    goto :eof
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
