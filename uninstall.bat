@echo off
setlocal
title Alien: Isolation - DXVK + Alias Isolation (uninstall)

if not exist "%~dp0uninstall.ps1" (
    echo [ERROR] uninstall.ps1 no encontrado / not found.
    echo         Extrae el ZIP completo antes de ejecutarlo. / Extract the whole ZIP first.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1" %*
set "RC=%ERRORLEVEL%"
echo.
pause
exit /b %RC%
