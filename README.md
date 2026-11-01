# Alien: Isolation — DXVK (Vulkan) + Alias Isolation (TAA) Seamless Integration

**English** · [Español](README.es.md)

A ready-to-use package and guide for running **[Alias Isolation](https://github.com/aliasIsolation/aliasIsolation)** (Temporal Anti-Aliasing) together with **[DXVK](https://github.com/doitsujin/dxvk)** (Direct3D 11 → Vulkan) on **Windows**, with flat frame pacing and no FPS lock.

---

## Included components

| File | Component | Version |
| :--- | :--- | :--- |
| `d3d11.dll` | [Ultimate ASI Loader](https://github.com/ThirteenAG/Ultimate-ASI-Loader) (Win32) | 7.7.0 |
| `aliasIsolation.asi` + `mods/aliasIsolation/` | [Alias Isolation](https://github.com/aliasIsolation/aliasIsolation) | 1.2.0 |
| `d3d11Hooked.dll` | DXVK `d3d11.dll`, **x86 (32-bit)**, renamed | 3.1.1 |
| `dxgi.dll` | DXVK `dxgi.dll`, **x86 (32-bit)** | 3.1.1 |
| `dxvk.conf` | Tuned DXVK configuration | — |

SHA-256 checksums of every file are listed in [`SHA256SUMS.txt`](SHA256SUMS.txt).

---

## Problems this project solves

1. **DLL name clash (`d3d11.dll`):** Alias Isolation (through Ultimate ASI Loader) and DXVK both need a `d3d11.dll` next to `AI.exe`, so installing one overwrites the other.
2. **32-bit architecture:** *Alien: Isolation* is a 32-bit game. The x64 DXVK DLLs make it fail with error `0xc000007b`.
3. **Half-refresh lock (e.g. 90 FPS on a 180 Hz monitor):** with V-Sync on, whenever the engine can't hold the full refresh rate under the TAA load, it drops to exactly half ($180 \div 2 = 90$ FPS). Frametimes then swing in a saw-tooth pattern between 3.7 ms and more than 30 ms.
4. **Stutter from DXVK's internal limiter:** DXVK's software frame limiter on Windows adds frametime jitter.

---

## How it works (DLL chaining)

The package relies on Ultimate ASI Loader's chain-loading:

* `d3d11.dll`: Ultimate ASI Loader. It loads `aliasIsolation.asi`.
* `d3d11Hooked.dll`: the DXVK x86 `d3d11.dll`, renamed. The loader picks it up through the `Hooked` suffix and forwards Direct3D 11 to it, which translates to Vulkan.
* `dxgi.dll`: the DXVK x86 DXGI component.
* `dxvk.conf`: disables forced V-Sync and DXVK's limiter and tunes dynamic buffers.

---

## Installation

### Option 1: Automatic (recommended)
1. Download the latest ZIP from [Releases](../../releases).
2. **Extract the whole ZIP**, then run **`install.bat`**.

The installer:
* finds the game in **every Steam library** (not only `C:\`), in **Epic Games Store** and in **GOG**. You can also pass a path: `install.bat "D:\Games\Alien Isolation"`.
* **backs up** any file it replaces into `_backup_dxvk_aliasisolation\` inside the game folder.
* moves an old `winmm.dll` ASI Loader (from a previous Alias Isolation install) to the backup, and leaves any other `winmm.dll` untouched.
* checks every copied file against its hash and reports a clear error if something fails.

> [!NOTE]
> The **Microsoft Store / Game Pass** version is not supported: its game folder is write-protected.

### Option 2: Manual
Copy the contents of `files/` into the game folder, next to `AI.exe` (by default `C:\Program Files (x86)\Steam\steamapps\common\Alien Isolation`):
```text
Alien Isolation/
├── AI.exe
├── aliasIsolation.asi
├── d3d11.dll             <- Ultimate ASI Loader
├── d3d11Hooked.dll       <- DXVK 32-bit (renamed d3d11.dll)
├── dxgi.dll              <- DXVK 32-bit
├── dxvk.conf             <- Tuned configuration
└── mods/
    └── aliasIsolation/   <- Mod shaders
```

### Uninstall
Run **`uninstall.bat`** from the package (or pass the path: `uninstall.bat "D:\Games\Alien Isolation"`). It removes the mod files and restores everything from the backup.

---

## Required in-game settings

Go to **Options → Video** and set:

| Setting | Value | Why |
| :--- | :--- | :--- |
| **Anti-Aliasing** | **SMAA T1x** | Required: Alias Isolation replaces this mode with its TAA |
| **Chromatic Aberration** | **Off** | The mod applies its own, configurable chromatic aberration |
| **Motion Blur** | **On** | Needed for the motion vectors the TAA uses |
| **V-Sync** | **Off** | Avoids the half-refresh lock |

> [!NOTE]
> In-game, press **`Delete`** to open the Alias Isolation overlay and adjust sharpening or chromatic aberration.

---

## Performance HUD

`dxvk.conf` has a commented-out HUD line at the end. Remove the leading `#` to show FPS and the frametime graph:
```ini
dxvk.hud = fps,frametimes
```
* **Flat line:** perfect frame pacing.
* **Spikes or saw-tooth:** stutter or lost sync.

Put the `#` back to hide it again.

---

## Strongly recommended: cap at 120 FPS

*Alien: Isolation* runs on the **Cathode** engine. Physics, door animations, camera interpolation and audio triggers are tied to the frame rate.

> [!IMPORTANT]
> Players report problems **above roughly 120–144 FPS**, such as erratic Xenomorph behaviour, missing or cut audio, doors or trams that hang, and camera judder.

Don't use DXVK's internal limiter on Windows: it is sleep-based and adds frametime jitter. Use a driver-level or RTSS limiter instead:

* **RivaTuner Statistics Server (RTSS):** add `AI.exe` (or use the global profile) and set **Framerate limit** to **120**.
* **AMD Adrenalin:** `Alt + R` → **Gaming → Alien: Isolation** → enable **Radeon Chill** with min = max = **120**.
* **NVIDIA Control Panel:** **Manage 3D settings → Program settings → Alien: Isolation** → **Max Frame Rate = 120**.

---

## Troubleshooting

| Symptom | Fix |
| :--- | :--- |
| Error `0xc000007b` at launch | x64 DXVK DLLs were used. Reinstall from this package, which ships x86 DLLs. |
| No TAA effect / `Delete` doesn't open the overlay | Anti-Aliasing isn't set to **SMAA T1x**, or another `winmm.dll` / `dinput8.dll` ASI loader is loading a second copy of the mod. |
| Black screen or crash at launch | Update your GPU driver (Vulkan support is required). Turn off other overlays (Discord, MSI Afterburner) to test. Check `AI_d3d11.log` and `AI_dxgi.log` in the game folder. |
| ReShade / Special K stopped working | They also use `d3d11.dll` / `dxgi.dll`. The installer backed them up in `_backup_dxvk_aliasisolation\`. |
| Stutter during the first minutes | DXVK compiles Vulkan pipelines on first use. This settles after playing for a while. |

### Notes on HDR
The game has no HDR output, so DXVK's `dxgi.enableHDR` does nothing here. Windows **Auto HDR** only works with native DX11/DX12, so it is not available while DXVK is in use. If you want HDR, look at driver-level options such as NVIDIA RTX HDR.

---

## Steam Deck / Linux (experimental, untested)

Proton already uses DXVK, so only the Alias Isolation part is needed:
1. Copy **only** `d3d11.dll`, `aliasIsolation.asi` and the `mods/` folder into the game folder. Do **not** copy `d3d11Hooked.dll` or `dxgi.dll`.
2. In Steam → game **Properties → Launch Options**, set:
   ```
   WINEDLLOVERRIDES="d3d11=n,b" %command%
   ```
The loader should then chain to Proton's own DXVK. Feedback on whether this works is welcome in [Issues](../../issues).

---

## Credits and licenses

* **[Alias Isolation](https://github.com/aliasIsolation/aliasIsolation)** — Alias Isolation team (The Unlicense).
* **[DXVK](https://github.com/doitsujin/dxvk)** — Philip Rebohle (doitsujin) and contributors (zlib/libpng License).
* **[Ultimate ASI Loader](https://github.com/ThirteenAG/Ultimate-ASI-Loader)** — ThirteenAG (MIT License).

The full license texts are in the [`licenses/`](licenses) folder.
