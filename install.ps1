# Alien: Isolation - DXVK (Vulkan) + Alias Isolation (TAA) installer
# Usage: install.bat            (auto-detects the game)
#        install.bat "D:\Games\Alien Isolation"
param([string]$GamePath)

$ErrorActionPreference = 'Stop'
$es = (Get-UICulture).TwoLetterISOLanguageName -eq 'es'
function T([string]$esText, [string]$enText) { if ($es) { $esText } else { $enText } }
function Info($m)  { Write-Host "[*] $m" }
function Warn($m)  { Write-Host "[!] $m" -ForegroundColor Yellow }
function Fail($m)  { Write-Host "[ERROR] $m" -ForegroundColor Red; exit 1 }

$Files      = 'd3d11.dll', 'd3d11Hooked.dll', 'dxgi.dll', 'aliasIsolation.asi', 'dxvk.conf'
$ModDir     = 'mods\aliasIsolation'
$BackupName = '_backup_dxvk_aliasisolation'

Write-Host '=============================================================='
Write-Host '  Alien: Isolation - DXVK (Vulkan) + Alias Isolation (TAA)'
Write-Host '=============================================================='
Write-Host ''

# --- 1. Source files ---------------------------------------------------------
$src = if (Test-Path (Join-Path $PSScriptRoot 'files')) { Join-Path $PSScriptRoot 'files' } else { $PSScriptRoot }
$missing = @($Files + $ModDir | Where-Object { -not (Test-Path (Join-Path $src $_)) })
if ($missing.Count) {
    Fail (T "Faltan archivos del paquete: $($missing -join ', '). Extrae el ZIP completo antes de ejecutar el instalador." `
            "Package files missing: $($missing -join ', '). Extract the whole ZIP before running the installer.")
}

# --- 2. Locate the game --------------------------------------------------------
function Test-Game($p) { $p -and (Test-Path -LiteralPath (Join-Path $p 'AI.exe')) }

function Find-Games {
    $found = New-Object System.Collections.Generic.List[object]
    function Add($store, $path) {
        if (Test-Game $path) {
            $full = (Resolve-Path -LiteralPath $path).Path.TrimEnd('\')
            if (-not ($found | Where-Object { $_.Path -eq $full })) { $found.Add([pscustomobject]@{ Store = $store; Path = $full }) }
        }
    }

    # Steam: every library listed in libraryfolders.vdf
    $steamRoots = @()
    foreach ($k in 'HKCU:\Software\Valve\Steam', 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam', 'HKLM:\SOFTWARE\Valve\Steam') {
        try { $v = Get-ItemProperty -Path $k -ErrorAction Stop
              if ($v.SteamPath)   { $steamRoots += ($v.SteamPath -replace '/', '\') }
              if ($v.InstallPath) { $steamRoots += $v.InstallPath } } catch {}
    }
    $steamRoots += "${env:ProgramFiles(x86)}\Steam"
    $libs = @()
    foreach ($root in ($steamRoots | Select-Object -Unique)) {
        $libs += $root
        $vdf = Join-Path $root 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $vdf) {
            foreach ($m in [regex]::Matches((Get-Content -LiteralPath $vdf -Raw), '"path"\s+"([^"]+)"')) {
                $libs += ($m.Groups[1].Value -replace '\\\\', '\')
            }
        }
    }
    foreach ($l in ($libs | Select-Object -Unique)) { Add 'Steam' (Join-Path $l 'steamapps\common\Alien Isolation') }

    # Epic Games Store manifests
    $man = Join-Path $env:ProgramData 'Epic\EpicGamesLauncher\Data\Manifests'
    if (Test-Path -LiteralPath $man) {
        foreach ($f in Get-ChildItem -LiteralPath $man -Filter *.item -ErrorAction SilentlyContinue) {
            try { $j = Get-Content -LiteralPath $f.FullName -Raw | ConvertFrom-Json
                  if ($j.DisplayName -match 'Alien' -or $j.LaunchExecutable -match 'AI\.exe') { Add 'Epic' $j.InstallLocation } } catch {}
        }
    }

    # GOG Galaxy / GOG installers
    foreach ($k in 'HKLM:\SOFTWARE\WOW6432Node\GOG.com\Games', 'HKLM:\SOFTWARE\GOG.com\Games') {
        if (Test-Path $k) {
            foreach ($g in Get-ChildItem $k -ErrorAction SilentlyContinue) {
                try { $p = Get-ItemProperty $g.PSPath; if ($p.gameName -match 'Alien') { Add 'GOG' $p.path } } catch {}
            }
        }
    }

    # The installer was copied into the game folder itself
    Add (T 'Carpeta actual' 'Current folder') $PSScriptRoot
    Add (T 'Carpeta actual' 'Current folder') (Split-Path $PSScriptRoot -Parent)
    return $found
}

if ($GamePath) {
    $GamePath = $GamePath.Trim().Trim('"')
} else {
    $games = @(Find-Games)
    if ($games.Count -eq 1) {
        $GamePath = $games[0].Path
    } elseif ($games.Count -gt 1) {
        Write-Host (T 'Se encontraron varias instalaciones:' 'Several installations were found:')
        for ($i = 0; $i -lt $games.Count; $i++) { Write-Host ("  [{0}] {1,-14} {2}" -f ($i + 1), $games[$i].Store, $games[$i].Path) }
        $sel = Read-Host (T 'Elige un numero' 'Pick a number')
        if ($sel -notmatch '^\d+$' -or [int]$sel -lt 1 -or [int]$sel -gt $games.Count) { Fail (T 'Seleccion no valida.' 'Invalid selection.') }
        $GamePath = $games[[int]$sel - 1].Path
    } else {
        Warn (T 'No se encontro el juego automaticamente (Steam, Epic, GOG).' 'The game was not found automatically (Steam, Epic, GOG).')
        $GamePath = (Read-Host (T 'Introduce la carpeta donde esta AI.exe' 'Enter the folder that contains AI.exe')).Trim().Trim('"')
    }
}

if ($GamePath -match '\\WindowsApps\\' -or $GamePath -match '\\XboxGames\\') {
    Fail (T 'La version de Microsoft Store / Game Pass no es compatible: sus archivos estan protegidos.' `
            'The Microsoft Store / Game Pass version is not supported: its files are protected.')
}
if (-not (Test-Game $GamePath)) { Fail (T "No se encontro AI.exe en: $GamePath" "AI.exe not found in: $GamePath") }
$GamePath = (Resolve-Path -LiteralPath $GamePath).Path.TrimEnd('\')
Info (T "Carpeta del juego: $GamePath" "Game folder: $GamePath")

# --- 3. Backup anything we are about to replace -------------------------------
$backup = Join-Path $GamePath $BackupName
$firstInstall = -not (Test-Path -LiteralPath $backup)
try {
    if ($firstInstall) { New-Item -ItemType Directory -Path $backup | Out-Null }
} catch {
    Fail (T "No hay permiso de escritura en la carpeta del juego. Ejecuta install.bat como administrador." `
            "No write permission in the game folder. Run install.bat as administrator.")
}

# Only back up files that are not ours. On a re-install the originals are already saved.
$ourHashes = @{}
foreach ($f in $Files) { $ourHashes[$f] = (Get-FileHash -LiteralPath (Join-Path $src $f)).Hash }

foreach ($f in $Files) {
    $dst = Join-Path $GamePath $f
    if (-not (Test-Path -LiteralPath $dst)) { continue }
    $info = (Get-Item -LiteralPath $dst).VersionInfo
    if ($info.ProductName -match 'ReShade|Special K') {
        Warn (T "$f pertenece a $($info.ProductName). Se guardara una copia, pero no funcionara a la vez que este mod." `
                "$f belongs to $($info.ProductName). It will be backed up, but it will not work alongside this mod.")
    }
    $bak = Join-Path $backup $f
    if ((Get-FileHash -LiteralPath $dst).Hash -ne $ourHashes[$f] -and -not (Test-Path -LiteralPath $bak)) {
        Copy-Item -LiteralPath $dst -Destination $bak
        Info (T "Copia de seguridad: $f" "Backed up: $f")
    }
}

$modDst = Join-Path $GamePath $ModDir
if ($firstInstall -and (Test-Path -LiteralPath $modDst)) {
    Copy-Item -LiteralPath $modDst -Destination (Join-Path $backup 'mods_aliasIsolation') -Recurse
    Info (T 'Copia de seguridad: mods\aliasIsolation' 'Backed up: mods\aliasIsolation')
}

# A winmm.dll ASI loader from an older Alias Isolation install would load the .asi twice.
# Only move it if it really is Ultimate ASI Loader; anything else is left untouched.
$winmm = Join-Path $GamePath 'winmm.dll'
if (Test-Path -LiteralPath $winmm) {
    $vi = (Get-Item -LiteralPath $winmm).VersionInfo
    if ("$($vi.ProductName) $($vi.FileDescription)" -match 'ASI[- ]?Loader') {
        Move-Item -LiteralPath $winmm -Destination (Join-Path $backup 'winmm.dll') -Force
        Info (T 'winmm.dll (ASI Loader antiguo) movido a la copia de seguridad para evitar doble carga.' `
                'winmm.dll (old ASI Loader) moved to the backup folder to avoid loading the mod twice.')
    } else {
        Warn (T 'Hay un winmm.dll que no es ASI Loader; se deja intacto. Si el juego falla, revisalo.' `
                'A winmm.dll that is not ASI Loader exists; it was left untouched. Check it if the game fails.')
    }
}

# --- 4. Copy ------------------------------------------------------------------
Info (T 'Instalando archivos...' 'Installing files...')
try {
    foreach ($f in $Files) { Copy-Item -LiteralPath (Join-Path $src $f) -Destination (Join-Path $GamePath $f) -Force }
    New-Item -ItemType Directory -Path $modDst -Force | Out-Null
    Copy-Item -Path (Join-Path $src "$ModDir\*") -Destination $modDst -Recurse -Force
} catch {
    Fail (T "La copia fallo: $($_.Exception.Message)  -  Cierra el juego y, si hace falta, ejecuta como administrador." `
            "Copy failed: $($_.Exception.Message)  -  Close the game and, if needed, run as administrator.")
}
foreach ($f in $Files) {
    if ((Get-FileHash -LiteralPath (Join-Path $GamePath $f)).Hash -ne $ourHashes[$f]) { Fail (T "Verificacion fallida: $f" "Verification failed: $f") }
}

Write-Host ''
Write-Host (T '[EXITO] Archivos instalados y verificados.' '[SUCCESS] Files installed and verified.') -ForegroundColor Green
Write-Host (T "Copia de seguridad en: $backup  (uninstall.bat la restaura)" "Backup in: $backup  (uninstall.bat restores it)")
Write-Host ''
Write-Host (T 'Ajustes obligatorios en el juego (Opciones > Video):' 'Required in-game settings (Options > Video):')
Write-Host (T '  - Anti-Aliasing: SMAA T1x' '  - Anti-Aliasing: SMAA T1x')
Write-Host (T '  - Aberracion cromatica: Desactivado' '  - Chromatic aberration: Off')
Write-Host (T '  - Desenfoque de movimiento: Activado' '  - Motion blur: On')
Write-Host (T '  - V-Sync: Desactivado' '  - V-Sync: Off')
Write-Host (T '  - Limita a 120 FPS con RTSS, Radeon Chill o el panel de NVIDIA.' '  - Cap at 120 FPS with RTSS, Radeon Chill or the NVIDIA Control Panel.')
exit 0
