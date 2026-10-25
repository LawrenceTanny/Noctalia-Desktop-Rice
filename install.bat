@echo off
setlocal
if exist "%ProgramFiles%\Git\bin\bash.exe" (
    "%ProgramFiles%\Git\bin\bash.exe" "%~dp0install.sh"
    goto :eof
)
if exist "%ProgramFiles(x86)%\Git\bin\bash.exe" (
    "%ProgramFiles(x86)%\Git\bin\bash.exe" "%~dp0install.sh"
    goto :eof
)
where bash >nul 2>&1
if %errorlevel% equ 0 (
    bash "%~dp0install.sh"
    goto :eof
)
echo Git Bash was not found. Please run install.sh within Git Bash.
pause
