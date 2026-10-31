@echo off
setlocal
title Instalador Alien: Isolation - DXVK + Alias Isolation

echo ==============================================================
echo   Alien: Isolation - DXVK (Vulkan) + Alias Isolation (TAA)
echo ==============================================================
echo.

set "TARGET_DIR=C:\Program Files (x86)\Steam\steamapps\common\Alien Isolation"

if not exist "%TARGET_DIR%\AI.exe" (
    if exist "%~dp0AI.exe" (
        set "TARGET_DIR=%~dp0"
    ) else (
        echo [!] No se encontro la carpeta del juego en la ruta por defecto:
        echo     %TARGET_DIR%
        echo.
        set /p TARGET_DIR="Por favor, introduce la ruta donde esta instalado AI.exe: "
    )
)

if not exist "%TARGET_DIR%\AI.exe" (
    echo [ERROR] No se encontro AI.exe en la ruta especificada. Abortando.
    pause
    exit /b 1
)

echo [*] Carpeta del juego detectada: %TARGET_DIR%
echo [*] Instalando archivos...

if exist "%~dp0files" (
    set "SOURCE_DIR=%~dp0files"
) else (
    set "SOURCE_DIR=%~dp0"
)

copy /y "%SOURCE_DIR%\d3d11.dll" "%TARGET_DIR%\" >nul
copy /y "%SOURCE_DIR%\d3d11Hooked.dll" "%TARGET_DIR%\" >nul
copy /y "%SOURCE_DIR%\dxgi.dll" "%TARGET_DIR%\" >nul
copy /y "%SOURCE_DIR%\aliasIsolation.asi" "%TARGET_DIR%\" >nul
copy /y "%SOURCE_DIR%\dxvk.conf" "%TARGET_DIR%\" >nul

if exist "%SOURCE_DIR%\mods" (
    xcopy /e /i /y "%SOURCE_DIR%\mods" "%TARGET_DIR%\mods" >nul
)

if exist "%TARGET_DIR%\winmm.dll" (
    echo [*] Limpiando winmm.dll antiguo para evitar conflictos...
    del /f /q "%TARGET_DIR%\winmm.dll" >nul
)

echo.
echo [EXITO] Archivos instalados correctamente.
echo.
echo Recordatorio de configuracion en el juego:
echo   - Anti-Aliasing: SMAA T1x
echo   - Aberracion cromatica: Desactivado
echo   - Desenfoque de movimiento: Activado
echo   - Sincronizacion vertical (V-Sync): Desactivado
echo   - Limitar FPS a 120 desde RivaTuner (RTSS) o Radeon Chill.
echo.
pause
