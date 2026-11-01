# Alien: Isolation — DXVK (Vulkan) + Alias Isolation (TAA) Seamless Integration

Guía y paquete de integración para hacer funcionar **[Alias Isolation](https://github.com/aliasIsolation/aliasIsolation)** (Temporal Anti-Aliasing) junto a **[DXVK](https://github.com/doitsujin/dxvk)** (Direct3D 11 a Vulkan) en **Windows**, con *frame pacing* completamente plano y sin bloqueos de FPS.

---

## Problemas que resuelve este proyecto

1. **Conflicto de archivos DLL (`d3d11.dll`):**
   Tanto Alias Isolation (vía Ultimate ASI Loader) como DXVK utilizan una librería llamada `d3d11.dll` en la raíz del juego (`AI.exe`). Al intentar usar ambos, uno sobreescribe al otro.
2. **Arquitectura de 32 bits (`x86`):**
   *Alien: Isolation* es un juego de 32 bits. Si se colocan las DLLs de DXVK de 64 bits (`x64`), el juego arroja el error `0xc000007b` y no inicia.
3. **El bloqueo a 90 FPS (Half-Refresh Rate Lock en monitores de 144Hz/180Hz):**
   Con V-Sync activo, cuando el motor no sostiene el refresco máximo por la carga del TAA, el juego divide la tasa de refresco a la mitad exacta ($180 \div 2 = 90\text{ FPS}$), provocando un patrón en "dientes de sierra" que va de 3.7 ms a más de 30 ms.
4. **Microtirones del limitador interno de DXVK:**
   El limitador por software integrado de DXVK en Windows genera fluctuaciones en los tiempos de cuadro (*frametimes*).

---

## Arquitectura y funcionamiento (DLL Chaining)

Se utiliza el mecanismo de encadenamiento nativo de **Ultimate ASI Loader**:
* `d3d11.dll` (1.69 MB): Cargador ASI de Alias Isolation. Inyecta `aliasIsolation.asi`.
* `d3d11Hooked.dll` (8.19 MB): Librería `d3d11.dll` de **DXVK (x32)** renombrada. El cargador la detecta automáticamente por el sufijo `Hooked` y le delega la tubería gráfica hacia Vulkan.
* `dxgi.dll` (5.87 MB): Componente DXGI de **DXVK (x32)**.
* `dxvk.conf`: Archivo de configuración optimizado para desactivar el V-Sync restrictivo y optimizar buffers dinámicos.

---

## Instalación

### Método 1: Automático (Recomendado)
1. Descarga el archivo **`Alien-Isolation-DXVK-AliasIsolation-v1.0.0.zip`** desde la sección de [Releases](../../releases).
2. Descomprímelo y ejecuta **`install.bat`**. Detectará tu instalación de Steam y copiará todos los archivos necesarios.

### Método 2: Manual
Copia los archivos de la carpeta `files/` a la raíz de tu juego (donde se encuentra `AI.exe`, por defecto en `C:\Program Files (x86)\Steam\steamapps\common\Alien Isolation`):
```text
Alien Isolation/
├── AI.exe
├── aliasIsolation.asi
├── d3d11.dll             <- Loader de Alias Isolation
├── d3d11Hooked.dll       <- DXVK 32 bits renombrado
├── dxgi.dll              <- DXVK 32 bits
├── dxvk.conf             <- Configuración optimizada
└── mods/
    └── aliasIsolation/   <- Shaders del mod
```

---

## Ajustes obligatorios dentro del juego

Entra a **Opciones -> Vídeo** en *Alien: Isolation* y configura:

| Ajuste | Valor requerido | Motivo |
| :--- | :--- | :--- |
| **Anti-Aliasing** | **SMAA T1x** | Obligatorio para que Alias Isolation intercepte e inyecte el TAA |
| **Aberración cromática** | **Desactivado** | El mod procesa su propia aberración cromática configurable |
| **Desenfoque de movimiento** | **Activado** | Necesario para la generación de vectores temporales |
| **Sincronización vertical (V-Sync)** | **Desactivado** | Evita el bloqueo del divisor a 90 FPS |

> [!NOTE]
> Durante la partida, pulsa la tecla **`Supr` (`Delete`)** para abrir el menú en pantalla de Alias Isolation y ajustar nitidez o aberración cromática.

---

## Monitorización y gráfica de rendimiento (HUD)

El archivo **`dxvk.conf`** incluye la posibilidad de monitorizar en tiempo real los FPS y la línea de estabilidad de fotogramas (*frametime graph*).

1. Abre `dxvk.conf` con un editor de texto.
2. Añade o descomenta la siguiente línea al final:
   ```ini
   dxvk.hud = fps,frametimes
   ```
3. Inicia el juego. Aparecerá el contador en la esquina superior izquierda:
   * **Línea plana y recta:** *Frame pacing* perfecto (máxima fluidez visual).
   * **Picos o dientes de sierra:** Indican tirones o pérdidas de sincronización.
4. Para quitarlo una vez comprobado, simplemente borra esa línea o déjala comentada:
   ```ini
   # dxvk.hud = fps,frametimes
   ```

---

## Recomendación fundamental: Limitar a 120 FPS con RivaTuner (RTSS) o Radeon Chill

*Alien: Isolation* fue desarrollado sobre el motor **Cathode**. En este motor, la simulación física, las animaciones de puertas, la interpolación de la cámara y los activadores de sonido están fuertemente ligados a la tasa de fotogramas:

> [!IMPORTANT]
> **Superar los 120–144 FPS puede provocar fallos en el motor:**
> * Comportamiento errático del Xenomorfo y fallos en las animaciones de muerte.
> * Desincronización de sonido (pasos que no se escuchan o audios cortados).
> * Puertas o tranvías que sufren *softlock* o tardan en abrirse.
> * Sensación de *judder* (cámara a tirones) al girar la vista.

### Configuración del límite a 120 FPS
Se recomienda no utilizar el limitador interno de DXVK en Windows, ya que emplea temporizadores de software (`sleep`) que provocan irregularidades en la entrega de cuadros. Utiliza un limitador externo a nivel de hardware o controlador:

#### Opción A: Con RivaTuner Statistics Server (RTSS)
1. Abre **RTSS**.
2. Añade `AI.exe` (o usa el perfil global).
3. Establece **Framerate limit** en **`120`**.

#### Opción B: Con AMD Software: Adrenalin Edition (AMD Radeon)
1. Abre el panel de AMD (`Alt + R`).
2. Ve a **Juegos -> Alien: Isolation**.
3. Activa **Radeon Chill** y establece:
   * *FPS mínimos:* **120**
   * *FPS máximos:* **120**

#### Opción C: Con el Panel de Control de NVIDIA
1. Abre el **Panel de Control de NVIDIA**.
2. Ve a **Controlar la configuración 3D -> Configuración de programa -> Alien: Isolation**.
3. Busca **Velocidad máxima de fotogramas** y ajústala a **`120 FPS`**.

---

## Créditos y Licencias

* **[Alias Isolation](https://github.com/aliasIsolation/aliasIsolation)** — Desarrollado por el equipo de Alias Isolation (Licencia MIT).
* **[DXVK](https://github.com/doitsujin/dxvk)** — Desarrollado por doitsujin y colaboradores (Licencia zlib/libpng).
* **[Ultimate ASI Loader](https://github.com/ThirteenAG/Ultimate-ASI-Loader)** — Desarrollado por ThirteenAG (Licencia MIT).
