# Alien: Isolation — DXVK (Vulkan) + Alias Isolation (TAA) Seamless Integration

[English](README.md) · **Español**

Guía y paquete de integración para hacer funcionar **[Alias Isolation](https://github.com/aliasIsolation/aliasIsolation)** (Temporal Anti-Aliasing) junto a **[DXVK](https://github.com/doitsujin/dxvk)** (Direct3D 11 → Vulkan) en **Windows**, con *frame pacing* plano y sin bloqueos de FPS.

---

## Componentes incluidos

| Archivo | Componente | Versión |
| :--- | :--- | :--- |
| `d3d11.dll` | [Ultimate ASI Loader](https://github.com/ThirteenAG/Ultimate-ASI-Loader) (Win32) | 7.7.0 |
| `aliasIsolation.asi` + `mods/aliasIsolation/` | [Alias Isolation](https://github.com/aliasIsolation/aliasIsolation) | 1.2.0 |
| `d3d11Hooked.dll` | `d3d11.dll` de DXVK, **x86 (32 bits)**, renombrado | 3.1.1 |
| `dxgi.dll` | `dxgi.dll` de DXVK, **x86 (32 bits)** | 3.1.1 |
| `dxvk.conf` | Configuración optimizada de DXVK | — |

Las sumas SHA-256 de todos los archivos están en [`SHA256SUMS.txt`](SHA256SUMS.txt).

---

## Problemas que resuelve este proyecto

1. **Conflicto de DLL (`d3d11.dll`):** Alias Isolation (vía Ultimate ASI Loader) y DXVK necesitan una `d3d11.dll` junto a `AI.exe`, así que al instalar uno se sobrescribe el otro.
2. **Arquitectura de 32 bits:** *Alien: Isolation* es un juego de 32 bits. Con las DLL x64 de DXVK, el juego da el error `0xc000007b`.
3. **Bloqueo a la mitad del refresco (p. ej. 90 FPS en un monitor de 180 Hz):** con V-Sync activo, cuando el motor no sostiene el refresco máximo por la carga del TAA, baja exactamente a la mitad ($180 \div 2 = 90$ FPS). Los *frametimes* oscilan entonces en "dientes de sierra" entre 3,7 ms y más de 30 ms.
4. **Microtirones del limitador interno de DXVK:** el limitador por software de DXVK en Windows genera fluctuaciones en los *frametimes*.

---

## Arquitectura (DLL chaining)

El paquete usa la carga encadenada de Ultimate ASI Loader:

* `d3d11.dll`: Ultimate ASI Loader. Carga `aliasIsolation.asi`.
* `d3d11Hooked.dll`: la `d3d11.dll` x86 de DXVK, renombrada. El loader la detecta por el sufijo `Hooked` y le delega Direct3D 11, que DXVK traduce a Vulkan.
* `dxgi.dll`: el componente DXGI x86 de DXVK.
* `dxvk.conf`: desactiva el V-Sync forzado y el limitador de DXVK, y optimiza los buffers dinámicos.

---

## Instalación

### Método 1: Automático (recomendado)
1. Descarga el ZIP más reciente desde [Releases](../../releases).
2. **Extrae el ZIP completo** y ejecuta **`install.bat`**.

El instalador:
* busca el juego en **todas las bibliotecas de Steam** (no solo en `C:\`), en **Epic Games Store** y en **GOG**. También puedes indicar la ruta: `install.bat "D:\Juegos\Alien Isolation"`.
* hace **copia de seguridad** de todo lo que reemplaza en `_backup_dxvk_aliasisolation\`, dentro de la carpeta del juego.
* mueve a la copia de seguridad un `winmm.dll` antiguo de ASI Loader (de una instalación previa de Alias Isolation) y deja intacto cualquier otro `winmm.dll`.
* comprueba el hash de cada archivo copiado y muestra un error claro si algo falla.

> [!NOTE]
> La versión de **Microsoft Store / Game Pass** no es compatible: su carpeta está protegida contra escritura.

### Método 2: Manual
Copia el contenido de `files/` en la carpeta del juego, junto a `AI.exe` (por defecto `C:\Program Files (x86)\Steam\steamapps\common\Alien Isolation`):
```text
Alien Isolation/
├── AI.exe
├── aliasIsolation.asi
├── d3d11.dll             <- Ultimate ASI Loader
├── d3d11Hooked.dll       <- DXVK 32 bits (d3d11.dll renombrado)
├── dxgi.dll              <- DXVK 32 bits
├── dxvk.conf             <- Configuración optimizada
└── mods/
    └── aliasIsolation/   <- Shaders del mod
```

### Desinstalación
Ejecuta **`uninstall.bat`** del paquete (o indica la ruta: `uninstall.bat "D:\Juegos\Alien Isolation"`). Borra los archivos del mod y restaura todo lo que había en la copia de seguridad.

---

## Ajustes obligatorios dentro del juego

Entra en **Opciones → Vídeo** y configura:

| Ajuste | Valor | Motivo |
| :--- | :--- | :--- |
| **Anti-Aliasing** | **SMAA T1x** | Obligatorio: Alias Isolation sustituye este modo por su TAA |
| **Aberración cromática** | **Desactivado** | El mod aplica su propia aberración cromática configurable |
| **Desenfoque de movimiento** | **Activado** | Necesario para los vectores de movimiento que usa el TAA |
| **Sincronización vertical (V-Sync)** | **Desactivado** | Evita el bloqueo a la mitad del refresco |

> [!NOTE]
> Durante la partida, pulsa **`Supr` (`Delete`)** para abrir el menú de Alias Isolation y ajustar la nitidez o la aberración cromática.

---

## HUD de rendimiento

Al final de `dxvk.conf` hay una línea del HUD comentada. Quita la `#` inicial para ver los FPS y la gráfica de *frametimes*:
```ini
dxvk.hud = fps,frametimes
```
* **Línea plana:** *frame pacing* perfecto.
* **Picos o dientes de sierra:** tirones o pérdidas de sincronización.

Vuelve a poner la `#` para ocultarlo.

---

## Recomendación fundamental: limitar a 120 FPS

*Alien: Isolation* usa el motor **Cathode**. La física, las animaciones de puertas, la interpolación de la cámara y los activadores de sonido están ligados a la tasa de fotogramas.

> [!IMPORTANT]
> Los jugadores informan de problemas **por encima de unos 120–144 FPS**, como comportamiento errático del Xenomorfo, sonidos que no se oyen o se cortan, puertas o tranvías que se quedan bloqueados y *judder* de cámara.

No uses el limitador interno de DXVK en Windows: se basa en `sleep` y genera irregularidades en los *frametimes*. Usa un limitador del controlador o RTSS:

* **RivaTuner Statistics Server (RTSS):** añade `AI.exe` (o usa el perfil global) y pon **Framerate limit** en **120**.
* **AMD Adrenalin:** `Alt + R` → **Juegos → Alien: Isolation** → activa **Radeon Chill** con mínimo = máximo = **120**.
* **Panel de Control de NVIDIA:** **Controlar la configuración 3D → Configuración de programa → Alien: Isolation** → **Velocidad máxima de fotogramas = 120**.

---

## Solución de problemas

| Síntoma | Solución |
| :--- | :--- |
| Error `0xc000007b` al iniciar | Se usaron DLL x64 de DXVK. Reinstala desde este paquete, que trae las x86. |
| No hay TAA / `Supr` no abre el menú | El Anti-Aliasing no está en **SMAA T1x**, o hay otro ASI loader (`winmm.dll` / `dinput8.dll`) cargando una segunda copia del mod. |
| Pantalla negra o cierre al iniciar | Actualiza el driver de la GPU (hace falta Vulkan). Desactiva otros overlays (Discord, MSI Afterburner) para probar. Revisa `AI_d3d11.log` y `AI_dxgi.log` en la carpeta del juego. |
| ReShade / Special K dejaron de funcionar | También usan `d3d11.dll` / `dxgi.dll`. El instalador los guardó en `_backup_dxvk_aliasisolation\`. |
| Tirones en los primeros minutos | DXVK compila las *pipelines* de Vulkan la primera vez que se usan. Desaparecen tras jugar un rato. |

### Sobre el HDR
El juego no tiene salida HDR, así que `dxgi.enableHDR` de DXVK no hace nada aquí. El **Auto HDR** de Windows solo funciona con DX11/DX12 nativo, así que no está disponible mientras se usa DXVK. Si quieres HDR, prueba opciones del controlador como NVIDIA RTX HDR.

---

## Steam Deck / Linux (experimental, sin probar)

Proton ya usa DXVK, así que solo hace falta la parte de Alias Isolation:
1. Copia **solo** `d3d11.dll`, `aliasIsolation.asi` y la carpeta `mods/` en la carpeta del juego. **No** copies `d3d11Hooked.dll` ni `dxgi.dll`.
2. En Steam → **Propiedades** del juego → **Opciones de lanzamiento**, escribe:
   ```
   WINEDLLOVERRIDES="d3d11=n,b" %command%
   ```
El loader debería encadenarse al DXVK del propio Proton. Si lo pruebas, cuéntanos si funciona en [Issues](../../issues).

---

## Créditos y licencias

* **[Alias Isolation](https://github.com/aliasIsolation/aliasIsolation)** — Equipo de Alias Isolation (The Unlicense).
* **[DXVK](https://github.com/doitsujin/dxvk)** — Philip Rebohle (doitsujin) y colaboradores (licencia zlib/libpng).
* **[Ultimate ASI Loader](https://github.com/ThirteenAG/Ultimate-ASI-Loader)** — ThirteenAG (licencia MIT).

Los textos completos de las licencias están en la carpeta [`licenses/`](licenses).
