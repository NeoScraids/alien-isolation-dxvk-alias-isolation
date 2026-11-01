@echo off
setlocal
title Alien: Isolation - DXVK + Alias Isolation

if not exist "%~dp0install.ps1" (
    echo [ERROR] install.ps1 no encontrado / not found.
    echo         Extrae el ZIP completo antes de ejecutarlo. / Extract the whole ZIP first.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
set "RC=%ERRORLEVEL%"
echo.
pause
exit /b %RC%
