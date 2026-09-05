# ⛏️ MC Server Creator

Un asistente interactivo y modular en Bash para desplegar, configurar y compartir servidores de Minecraft en Linux en cuestión de segundos, con soporte para túneles (**Ngrok** y **Playit.gg**) y juego cruzado con **Minecraft Bedrock**.

---

## 🌟 Características Principales

- 🎮 **Múltiples Motores de Servidor:**
  - **PaperMC:** Rendimiento optimizado estándar con soporte para plugins Bukkit/Spigot/Paper.
  - **Purpur:** Máximo rendimiento y alta personalización de jugabilidad.
  - **Fabric:** Para mods modernos, ligeros y optimizados.
  - **Forge:** Para modpacks y mods clásicos (1.12.2, etc.).
  - **Vanilla:** El servidor original oficial de Mojang.
- ☕ **Detección Inteligente de Java:**
  - Determina automáticamente la versión de Java requerida según el juego (Java 8, 17 o 21).
  - Escanea tu sistema y reutiliza instalaciones existentes antes de solicitar instalaciones innecesarias.
- 📱 **Crossplay Bedrock (GeyserMC + Floodgate):**
  - Permite con 1 click que amigos desde Android, iOS, consolas y Windows 10/11 jueguen en tu servidor Java.
- 🔗 **Túneles para Jugar con Amigos:**
  - **Ngrok:** Apertura rápida de túnel TCP y extracción automática de la IP/puerto público.
  - **Playit.gg:** Alternativa gratuita sin límites de transferencia.
  - **Modo LAN / Local:** Para redes locales o reenvío de puertos propio.
- ⚙️ **Configuración Automatizada:**
  - Aceptación automática del EULA (`eula=true`).
  - Asistente de `server.properties` (modo No-Premium/Cracked, puerto, MOTD, dificultad, PVP).
  - Cálculo inteligente de memoria RAM con flags optimizados de recolector de basura (G1GC / Aikar's flags).
- 🖥️ **Gestión en Segundo Plano (`screen`):**
  - Cada servidor se aísla en `servers/<nombre_del_servidor>/`.
  - Generación de scripts de control:
    - `./start.sh` (arranca en segundo plano dentro de una sesión de `screen`).
    - `./console.sh` (conecta interactivamente a la consola del servidor).
    - `./stop.sh` (guarda mundos y apaga de forma segura).
    - `./backup.sh` (crea un respaldo comprimido `.tar.gz`).
- 🎨 **Interfaz de Terminal Atractiva:**
  - Banners ASCII, paleta de colores ANSI, spinners de carga y tarjeta resumen final con la IP para compartir.

---

## 🚀 Requisitos Previos

- Sistema operativo Linux (Debian, Ubuntu, Linux Mint, Arch, Fedora, etc.).
- `curl`, `wget`, `python3` y `screen` (preinstalados en la mayoría de distros).

---

## 🛠️ Instalación y Uso

1. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/ErPyrex/mc-server-creator.git
   cd mc-server-creator
   ```

2. **Otorgar permisos de ejecución e iniciar el asistente:**
   ```bash
   chmod +x launch_me.sh
   ./launch_me.sh
   ```

3. **Seguir los pasos del asistente en pantalla:**
   - Asigna un nombre a tu servidor.
   - Selecciona el motor (Paper, Purpur, Fabric, Forge o Vanilla).
   - Especifica la versión y cantidad de RAM deseada.
   - Elige si deseas admitir jugadores No-Premium y activar Bedrock crossplay.
   - Elige el método de conexión para tus amigos (Ngrok o Playit).

---

## 📂 Estructura del Proyecto

```text
mc-server-creator/
├── launch_me.sh            # Punto de entrada interactivo (Wizard TUI)
├── core/                   # Módulos desacoplados
│   ├── ui.sh               # Colores ANSI, banner, spinners y tarjeta resumen
│   ├── java.sh             # Detección, validación y gestión de Java (8, 17, 21)
│   ├── server.sh           # Descarga de motores (Paper, Purpur, Fabric, Forge, Vanilla)
│   ├── plugins.sh          # Instalación de GeyserMC + Floodgate (Crossplay)
│   ├── config.sh           # EULA, server.properties, start.sh, stop.sh, console.sh, backup.sh
│   └── tunnel.sh           # Gestión de Ngrok y Playit.gg
├── servers/                # Directorio donde se almacenan las instancias de servidores (ignorado en git)
├── .gitignore              # Excluye mundos, logs, backups y credenciales
└── README.md
```

---

## 🕹️ Comandos Útiles por Servidor

Una vez creado tu servidor en `servers/<nombre>/`:

```bash
cd servers/<nombre>

# Iniciar servidor en segundo plano
./start.sh

# Ver la consola de Minecraft (presiona Ctrl+A luego D para salir sin apagar)
./console.sh

# Apagar el servidor con guardado automático
./stop.sh

# Crear copia de seguridad comprimida
./backup.sh
```

---

## 📄 Licencia

Este proyecto está bajo la Licencia GNU General Public License v3.0. Consulta el archivo [LICENSE](file:///home/pyrex64/Escritorio/dev/mc-server-creator/LICENSE) para más detalles.
