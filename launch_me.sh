#!/usr/bin/env bash
# ==============================================================================
#  ⛏️  MC SERVER CREATOR - CLI / TUI Interactive Wizard
#  Automated Minecraft Server Deployment with Tunneling & Bedrock Crossplay
# ==============================================================================

set -e

# Base directory
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source core modules
source "${BASE_DIR}/core/ui.sh"
source "${BASE_DIR}/core/java.sh"
source "${BASE_DIR}/core/server.sh"
source "${BASE_DIR}/core/plugins.sh"
source "${BASE_DIR}/core/config.sh"
source "${BASE_DIR}/core/tunnel.sh"

# Trap interrupt
trap 'echo -e "\n${COLOR_RED}Proceso cancelado por el usuario.${COLOR_RESET}"; exit 130' INT

main() {
    print_banner

    TOTAL_STEPS=6

    # --------------------------------------------------------------------------
    # PASO 1: Nombre del Servidor e Instancia
    # --------------------------------------------------------------------------
    log_step 1 "$TOTAL_STEPS" "Identidad del Servidor"
    local server_name=""
    prompt_input server_name "Nombre de la instancia del servidor" "my-server"
    
    # Sanitize name
    server_name=$(echo "$server_name" | tr -cd '[:alnum:]_-')
    [[ -z "$server_name" ]] && server_name="my-server"

    local server_dir="${BASE_DIR}/servers/${server_name}"
    if [[ -d "$server_dir" ]]; then
        log_warn "Ya existe una carpeta para el servidor '${server_name}'."
        local overwrite=false
        prompt_yes_no overwrite "¿Deseas reutilizar / sobrescribir los archivos de este servidor?" "Y"
        if [[ "$overwrite" != "true" ]]; then
            log_error "Operación cancelada. Elige otro nombre de servidor."
            exit 1
        fi
    fi
    mkdir -p "$server_dir"

    # --------------------------------------------------------------------------
    # PASO 2: Selección de Motor / Software
    # --------------------------------------------------------------------------
    log_step 2 "$TOTAL_STEPS" "Tipo de Servidor y Versión"
    local software_choice
    local software_options=(
        "PaperMC  (Recomendado: Alto rendimiento, optimizado, plugins Bukkit/Paper)"
        "Purpur   (Rendimiento extremo y personalización avanzada de jugabilidad)"
        "Fabric   (Ideal para mods modernos y ligeros con alto rendimiento)"
        "Forge    (Soporte para mods clásicos como Pixelmon, Twilight Forest, etc.)"
        "Vanilla  (Servidor oficial original de Mojang sin modificaciones)"
    )
    prompt_choice software_choice "Selecciona el motor para tu servidor:" "${software_options[@]}"

    local software_type="paper"
    local default_version="1.20.4"

    case "$software_choice" in
        1) software_type="paper";   default_version="1.20.4" ;;
        2) software_type="purpur";  default_version="1.20.4" ;;
        3) software_type="fabric";  default_version="1.20.4" ;;
        4) software_type="forge";   default_version="1.12.2" ;;
        5) software_type="vanilla"; default_version="1.20.4" ;;
    esac

    local mc_version=""
    prompt_input mc_version "Versión de Minecraft deseada" "$default_version"

    # --------------------------------------------------------------------------
    # PASO 3: Memoria RAM y Recursos
    # --------------------------------------------------------------------------
    log_step 3 "$TOTAL_STEPS" "Asignación de Memoria RAM"
    local total_ram_mb
    total_ram_mb=$(free -m 2>/dev/null | awk '/^Mem:/{print $2}' || echo "4096")
    local recommended_ram=2048
    if (( total_ram_mb >= 16000 )); then
        recommended_ram=6144
    elif (( total_ram_mb >= 8000 )); then
        recommended_ram=4096
    fi

    log_info "Memoria RAM total del sistema detectada: ${total_ram_mb} MB"
    local ram_allocated=""
    prompt_input ram_allocated "Memoria RAM asignada al servidor (en MB)" "$recommended_ram"

    # --------------------------------------------------------------------------
    # PASO 4: Configuración de Jugadores, Modo y Bedrock
    # --------------------------------------------------------------------------
    log_step 4 "$TOTAL_STEPS" "Configuración del Servidor"

    local cracked_allowed=true
    prompt_yes_no cracked_allowed "¿Permitir jugadores No-Premium (launchers no oficiales)?" "Y"
    local online_mode="false"
    [[ "$cracked_allowed" != "true" ]] && online_mode="true"

    local server_port=""
    prompt_input server_port "Puerto del servidor" "25565"

    local server_motd=""
    prompt_input server_motd "Mensaje del Servidor (MOTD)" "Servidor de $server_name - Creado con MC-Server-Creator"

    local bedrock_crossplay=false
    if [[ "$software_type" == "paper" || "$software_type" == "purpur" ]]; then
        prompt_yes_no bedrock_crossplay "¿Deseas activar Crossplay Bedrock (amigos en celular, consolas y Windows 10/11)?" "Y"
    fi

    # --------------------------------------------------------------------------
    # PASO 5: Conectividad y Túnel
    # --------------------------------------------------------------------------
    log_step 5 "$TOTAL_STEPS" "Conexión para Amigos (Túnel)"
    local tunnel_choice
    local tunnel_options=(
        "Ngrok     (Túnel TCP confiable y rápido con URL pública)"
        "Playit.gg (Túnel para juegos gratuito y sin límites de transferencia)"
        "Ninguno   (Solo red local / LAN o reenvío de puertos propio)"
    )
    prompt_choice tunnel_choice "¿Cómo se conectarán tus amigos?" "${tunnel_options[@]}"

    local tunnel_type="none"
    case "$tunnel_choice" in
        1) tunnel_type="ngrok" ;;
        2) tunnel_type="playit" ;;
        3) tunnel_type="none" ;;
    esac

    # Prepare tunnel dependencies
    if [[ "$tunnel_type" == "ngrok" ]]; then
        ensure_ngrok_installed
        ensure_ngrok_authtoken
    elif [[ "$tunnel_type" == "playit" ]]; then
        ensure_playit_installed
    fi

    # --------------------------------------------------------------------------
    # PASO 6: Preparación de Java, Descarga y Scripts
    # --------------------------------------------------------------------------
    log_step 6 "$TOTAL_STEPS" "Instalación y Despliegue"

    # Check Java
    local required_java
    required_java=$(get_required_java "$mc_version")
    local java_bin
    java_bin=$(ensure_java_version "$required_java")

    if [[ -z "$java_bin" || ! -x "$java_bin" ]]; then
        log_error "No se pudo obtener un binario válido de Java $required_java. Abortando."
        exit 1
    fi

    # Download Software
    echo ""
    log_info "Descargando e instalando $software_type $mc_version en '$server_dir'..."
    case "$software_type" in
        paper)
            download_paper "$server_dir" "$mc_version" || exit 1
            ;;
        purpur)
            download_purpur "$server_dir" "$mc_version" || exit 1
            ;;
        fabric)
            install_fabric "$server_dir" "$mc_version" "$java_bin" || exit 1
            ;;
        forge)
            install_forge "$server_dir" "$mc_version" "$java_bin" || exit 1
            ;;
        vanilla)
            download_vanilla "$server_dir" "$mc_version" || exit 1
            ;;
    esac

    # Install Bedrock crossplay if selected
    if [[ "$bedrock_crossplay" == "true" ]]; then
        install_geyser_floodgate "$server_dir"
    fi

    # Configure EULA & Server Properties
    setup_eula "$server_dir"
    setup_server_properties "$server_dir" "$server_port" "$server_motd" "$online_mode" "normal" "survival" "20" "true"
    setup_runtime_scripts "$server_dir" "$server_name" "$ram_allocated" "$java_bin" "server.jar" "$tunnel_type"

    # --------------------------------------------------------------------------
    # FINALIZACIÓN: Iniciar o Mostrar Panel
    # --------------------------------------------------------------------------
    echo ""
    local start_now=true
    prompt_yes_no start_now "¿Deseas iniciar el servidor de Minecraft ahora mismo?" "Y"

    local public_ip="localhost:${server_port}"
    if [[ "$start_now" == "true" ]]; then
        log_info "Lanzando el servidor en segundo plano con screen..."
        "${server_dir}/start.sh"

        if [[ "$tunnel_type" == "ngrok" ]]; then
            public_ip=$(start_ngrok_tunnel "$server_port" "${server_dir}/ngrok.log")
        elif [[ "$tunnel_type" == "playit" ]]; then
            public_ip="Configura tu túnel en el panel de Playit.gg"
            log_info "Iniciando Playit en segundo plano..."
            playit > "${server_dir}/playit.log" 2>&1 &
        fi
    fi

    # Print summary card
    print_dashboard_card \
        "$server_name" \
        "$software_type" \
        "$mc_version" \
        "$ram_allocated" \
        "$server_port" \
        "$online_mode" \
        "$tunnel_type" \
        "$public_ip" \
        "$bedrock_crossplay" \
        "$server_dir"
}

main "$@"
