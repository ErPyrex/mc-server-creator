#!/usr/bin/env bash
# ==============================================================================
# core/server.sh - Server download and installation engine
# ==============================================================================

# Get latest Minecraft release version from Mojang manifest
get_latest_vanilla_version() {
    python3 -c "
import urllib.request, json
res = urllib.request.urlopen('https://piston-meta.mojang.com/mc/game/version_manifest_v2.json')
manifest = json.loads(res.read().decode('utf-8'))
print(manifest['latest']['release'])
" 2>/dev/null || echo "1.20.4"
}

# Download PaperMC server
download_paper() {
    local target_dir="$1"
    local version="$2"
    log_info "Consultando API de PaperMC para la versión ${version}..."

    local jar_url
    jar_url=$(python3 -c "
import sys, urllib.request, json
ver = '$version'
try:
    req = urllib.request.Request(f'https://fill.papermc.io/v3/projects/paper/versions/{ver}/builds', headers={'User-Agent': 'mc-server-creator/1.0'})
    builds = json.loads(urllib.request.urlopen(req).read().decode('utf-8'))
    print(builds[-1]['downloads']['server:default']['url'])
except Exception:
    sys.exit(1)
" 2>/dev/null)

    if [[ -z "$jar_url" ]]; then
        log_error "No se encontró un build estable de PaperMC para la versión $version."
        return 1
    fi

    log_info "Descargando PaperMC $version..."
    wget -q --show-progress -O "${target_dir}/server.jar" "$jar_url"
    return $?
}

# Download Purpur server
download_purpur() {
    local target_dir="$1"
    local version="$2"
    local url="https://api.purpurmc.org/v2/purpur/${version}/latest/download"
    log_info "Descargando Purpur $version..."
    wget -q --show-progress -O "${target_dir}/server.jar" "$url"
    return $?
}

# Download Vanilla server
download_vanilla() {
    local target_dir="$1"
    local version="$2"
    log_info "Consultando manifiesto de Mojang para Minecraft $version..."

    local jar_url
    jar_url=$(python3 -c "
import sys, urllib.request, json
ver = '$version'
try:
    manifest = json.loads(urllib.request.urlopen('https://piston-meta.mojang.com/mc/game/version_manifest_v2.json').read().decode('utf-8'))
    v_url = next(v['url'] for v in manifest['versions'] if v['id'] == ver)
    v_data = json.loads(urllib.request.urlopen(v_url).read().decode('utf-8'))
    print(v_data['downloads']['server']['url'])
except Exception:
    sys.exit(1)
" 2>/dev/null)

    if [[ -z "$jar_url" ]]; then
        log_error "No se encontró la versión Vanilla $version en Mojang."
        return 1
    fi

    log_info "Descargando Vanilla $version..."
    wget -q --show-progress -O "${target_dir}/server.jar" "$jar_url"
    return $?
}

# Install Fabric server
install_fabric() {
    local target_dir="$1"
    local version="$2"
    local java_bin="$3"

    log_info "Obteniendo instalador oficial de Fabric..."
    local installer_url
    installer_url=$(python3 -c "
import urllib.request, json
data = json.loads(urllib.request.urlopen('https://meta.fabricmc.net/v2/versions/installer').read().decode('utf-8'))
print(data[0]['url'])
" 2>/dev/null)

    if [[ -z "$installer_url" ]]; then
        installer_url="https://maven.fabricmc.net/net/fabricmc/fabric-installer/1.0.1/fabric-installer-1.0.1.jar"
    fi

    wget -q --show-progress -O "${target_dir}/fabric-installer.jar" "$installer_url"
    log_info "Instalando servidor Fabric y descargando dependencias de Minecraft $version..."

    (
        cd "$target_dir" || exit 1
        "$java_bin" -jar fabric-installer.jar server -mcversion "$version" -downloadMinecraft
        rm -f fabric-installer.jar
    )

    if [[ -f "${target_dir}/fabric-server-launch.jar" ]]; then
        # Create symlink or rename for standard start script
        cp -f "${target_dir}/fabric-server-launch.jar" "${target_dir}/server.jar" 2>/dev/null || true
        return 0
    else
        log_error "La instalación de Fabric falló."
        return 1
    fi
}

# Install Forge server
install_forge() {
    local target_dir="$1"
    local version="$2"
    local java_bin="$3"

    log_info "Consultando versiones de Forge para $version..."
    local installer_url
    installer_url=$(python3 -c "
import sys, urllib.request, json
ver = '$version'
try:
    promos = json.loads(urllib.request.urlopen('https://files.minecraftforge.net/net/minecraftforge/forge/promotions_slim.json').read().decode('utf-8')).get('promos', {})
    f_ver = promos.get(f'{ver}-recommended') or promos.get(f'{ver}-latest')
    if not f_ver and ver == '1.12.2':
        f_ver = '14.23.5.2859'
    if f_ver:
        print(f'https://maven.minecraftforge.net/net/minecraftforge/forge/{ver}-{f_ver}/forge-{ver}-{f_ver}-installer.jar')
except Exception:
    sys.exit(1)
" 2>/dev/null)

    if [[ -z "$installer_url" ]]; then
        if [[ "$version" == "1.12.2" ]]; then
            installer_url="https://maven.minecraftforge.net/net/minecraftforge/forge/1.12.2-14.23.5.2859/forge-1.12.2-14.23.5.2859-installer.jar"
        else
            log_error "No se encontró versión recomendada de Forge para $version."
            return 1
        fi
    fi

    log_info "Descargando instalador de Forge..."
    wget -q --show-progress -O "${target_dir}/forge-installer.jar" "$installer_url"
    
    log_info "Instalando servidor Forge (esto puede tardar unos minutos)..."
    (
        cd "$target_dir" || exit 1
        "$java_bin" -jar forge-installer.jar --installServer
        rm -f forge-installer.jar
        rm -f forge-installer.jar.log
    )

    # In 1.12.2 Forge, the main jar is named forge-1.12.2-*.jar
    local forge_jar
    forge_jar=$(find "$target_dir" -maxdepth 1 -name "forge-*.jar" | head -n 1)
    if [[ -n "$forge_jar" ]]; then
        cp -f "$forge_jar" "${target_dir}/server.jar" 2>/dev/null || true
        return 0
    elif [[ -f "${target_dir}/run.sh" ]]; then
        # Modern Forge 1.18+ provides run.sh
        return 0
    else
        log_error "La instalación de Forge falló o no se encontró el ejecutable principal."
        return 1
    fi
}
