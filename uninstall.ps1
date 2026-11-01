# Alien: Isolation - DXVK + Alias Isolation uninstaller
# Usage: uninstall.bat "D:\Games\Alien Isolation"   (or run it and type the path)
param([string]$GamePath)

$ErrorActionPreference = 'Stop'
$es = (Get-UICulture).TwoLetterISOLanguageName -eq 'es'
function T([string]$esText, [string]$enText) { if ($es) { $esText } else { $enText } }
function Info($m) { Write-Host "[*] $m" }
function Fail($m) { Write-Host "[ERROR] $m" -ForegroundColor Red; exit 1 }

$Files      = 'd3d11.dll', 'd3d11Hooked.dll', 'dxgi.dll', 'aliasIsolation.asi', 'dxvk.conf'
$BackupName = '_backup_dxvk_aliasisolation'

if (-not $GamePath) {
    foreach ($c in $PSScriptRoot, (Split-Path $PSScriptRoot -Parent)) {
        if (Test-Path -LiteralPath (Join-Path $c "AI.exe")) { $GamePath = $c; break }
    }
}
if (-not $GamePath) {
    $GamePath = (Read-Host (T 'Introduce la carpeta donde esta AI.exe' 'Enter the folder that contains AI.exe')).Trim().Trim('"')
}
$GamePath = $GamePath.Trim().Trim('"')
if (-not (Test-Path -LiteralPath (Join-Path $GamePath 'AI.exe'))) { Fail (T "No se encontro AI.exe en: $GamePath" "AI.exe not found in: $GamePath") }

$backup = Join-Path $GamePath $BackupName
if (-not (Test-Path -LiteralPath $backup)) {
    Write-Host (T 'No hay copia de seguridad del instalador. Se borraran los archivos del mod sin restaurar nada.' `
                  'No installer backup found. The mod files will be removed without restoring anything.') -ForegroundColor Yellow
    if ((Read-Host (T 'Continuar? (s/n)' 'Continue? (y/n)')) -notmatch '^[sy]') { exit 1 }
}

try {
    foreach ($f in $Files + 'AI_d3d11.log', 'AI_dxgi.log') {
        $p = Join-Path $GamePath $f
        if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Force; Info (T "Eliminado: $f" "Removed: $f") }
    }
    $mod = Join-Path $GamePath 'mods\aliasIsolation'
    if (Test-Path -LiteralPath $mod) { Remove-Item -LiteralPath $mod -Recurse -Force; Info (T 'Eliminado: mods\aliasIsolation' 'Removed: mods\aliasIsolation') }
    $mods = Join-Path $GamePath 'mods'
    if ((Test-Path -LiteralPath $mods) -and -not (Get-ChildItem -LiteralPath $mods -Force)) { Remove-Item -LiteralPath $mods -Force }

    if (Test-Path -LiteralPath $backup) {
        foreach ($item in Get-ChildItem -LiteralPath $backup -Force) {
            if ($item.Name -eq 'mods_aliasIsolation') {
                New-Item -ItemType Directory -Path $mods -Force | Out-Null
                Copy-Item -LiteralPath $item.FullName -Destination $mod -Recurse -Force
                Info (T 'Restaurado: mods\aliasIsolation' 'Restored: mods\aliasIsolation')
            } else {
                Copy-Item -LiteralPath $item.FullName -Destination (Join-Path $GamePath $item.Name) -Force
                Info (T "Restaurado: $($item.Name)" "Restored: $($item.Name)")
            }
        }
        Remove-Item -LiteralPath $backup -Recurse -Force
    }
} catch {
    Fail (T "Fallo: $($_.Exception.Message)  -  Cierra el juego y, si hace falta, ejecuta como administrador." `
            "Failed: $($_.Exception.Message)  -  Close the game and, if needed, run as administrator.")
}

Write-Host ''
Write-Host (T '[EXITO] Desinstalado. El juego vuelve a usar DirectX 11 nativo.' '[SUCCESS] Uninstalled. The game is back to native DirectX 11.') -ForegroundColor Green
Write-Host (T 'Si quieres el SMAA original, revisa el Anti-Aliasing en Opciones > Video.' 'Re-check Anti-Aliasing in Options > Video if you want the stock SMAA back.')
exit 0
