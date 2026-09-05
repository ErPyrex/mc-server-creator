#!/usr/bin/env bash
# ==============================================================================
# core/plugins.sh - Bedrock crossplay (GeyserMC + Floodgate) & essentials
# ==============================================================================

install_geyser_floodgate() {
    local server_dir="$1"
    local plugins_dir="${server_dir}/plugins"
    mkdir -p "$plugins_dir"

    log_info "Instalando GeyserMC y Floodgate para soporte Bedrock (móviles, consolas, Win10/11)..."

    local geyser_url
    geyser_url=$(python3 -c "
import urllib.request, json
try:
    g_meta = json.loads(urllib.request.urlopen('https://download.geysermc.org/v2/projects/geyser').read().decode('utf-8'))
    latest_v = g_meta['versions'][-1]
    b_meta = json.loads(urllib.request.urlopen(f'https://download.geysermc.org/v2/projects/geyser/versions/{latest_v}/builds').read().decode('utf-8'))
    latest_b = b_meta['builds'][-1]['build']
    print(f'https://download.geysermc.org/v2/projects/geyser/versions/{latest_v}/builds/{latest_b}/downloads/spigot')
except Exception:
    sys.exit(1)
" 2>/dev/null)

    local floodgate_url
    floodgate_url=$(python3 -c "
import urllib.request, json
try:
    f_meta = json.loads(urllib.request.urlopen('https://download.geysermc.org/v2/projects/floodgate').read().decode('utf-8'))
    latest_v = f_meta['versions'][-1]
    fb_meta = json.loads(urllib.request.urlopen(f'https://download.geysermc.org/v2/projects/floodgate/versions/{latest_v}/builds').read().decode('utf-8'))
    latest_b = fb_meta['builds'][-1]['build']
    print(f'https://download.geysermc.org/v2/projects/floodgate/versions/{latest_v}/builds/{latest_b}/downloads/spigot')
except Exception:
    sys.exit(1)
" 2>/dev/null)

    if [[ -n "$geyser_url" ]]; then
        log_info "Descargando GeyserMC..."
        wget -q --show-progress -O "${plugins_dir}/Geyser-Spigot.jar" "$geyser_url"
    else
        log_warn "No se pudo obtener la URL de descarga directa de GeyserMC."
    fi

    if [[ -n "$floodgate_url" ]]; then
        log_info "Descargando Floodgate..."
        wget -q --show-progress -O "${plugins_dir}/Floodgate-Spigot.jar" "$floodgate_url"
    else
        log_warn "No se pudo obtener la URL de descarga directa de Floodgate."
    fi

    if [[ -f "${plugins_dir}/Geyser-Spigot.jar" ]]; then
        log_success "Crossplay Bedrock instalado con éxito en /plugins."
        return 0
    else
        return 1
    fi
}
