#!/usr/bin/env bash
# ==============================================================================
# core/java.sh - Java detection, compatibility verification, and installation
# ==============================================================================

# Determines the required Java major version for a given Minecraft version
get_required_java() {
    local mc_ver="$1"
    python3 -c "
v = '$mc_ver'
parts = [int(p) for p in v.split('.') if p.isdigit()]
if not parts:
    print(21)
elif parts[0] > 1:
    print(21)
else:
    minor = parts[1] if len(parts) > 1 else 0
    patch = parts[2] if len(parts) > 2 else 0
    if minor < 17:
        print(8)
    elif minor < 20 or (minor == 20 and patch < 5):
        print(17)
    else:
        print(21)
" 2>/dev/null || echo "21"
}

# Finds an existing Java binary matching the required major version
find_java_binary() {
    local required_ver="$1"

    # 1. Check current default java in PATH
    if command -v java &>/dev/null; then
        local current_ver
        current_ver=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
        [[ "$current_ver" == "1" ]] && current_ver=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f2)

        if [[ "$current_ver" == "$required_ver" ]]; then
            echo "$(command -v java)"
            return 0
        fi
    fi

    # 2. Check /usr/lib/jvm locations
    local jvm_candidates=(
        "/usr/lib/jvm/java-${required_ver}-openjdk-amd64/bin/java"
        "/usr/lib/jvm/java-${required_ver}-openjdk/bin/java"
        "/usr/lib/jvm/java-1.${required_ver}.0-openjdk-amd64/bin/java"
        "/usr/lib/jvm/zulu-${required_ver}/bin/java"
        "/usr/lib/jvm/temurin-${required_ver}/bin/java"
    )

    for cand in "${jvm_candidates[@]}"; do
        if [[ -x "$cand" ]]; then
            echo "$cand"
            return 0
        fi
    done

    # 3. Check any matching /usr/lib/jvm/*${required_ver}*/bin/java
    for cand in /usr/lib/jvm/*"${required_ver}"*/bin/java; do
        if [[ -x "$cand" ]]; then
            echo "$cand"
            return 0
        fi
    done

    return 1
}

# Ensures a compatible Java version is installed and returns its executable path
ensure_java_version() {
    local required_ver="$1"
    log_info "Verificando disponibilidad de Java $required_ver para la versión de Minecraft seleccionada..."

    local found_bin
    found_bin=$(find_java_binary "$required_ver")

    if [[ -n "$found_bin" && -x "$found_bin" ]]; then
        log_success "Java $required_ver compatible encontrado en: $found_bin"
        echo "$found_bin"
        return 0
    fi

    log_warn "No se encontró un ejecutable de Java $required_ver en tu sistema."
    
    # Prompt user to install
    local install_approved=false
    prompt_yes_no install_approved "¿Deseas instalar OpenJDK $required_ver ahora usando apt?" "Y"

    if [[ "$install_approved" == "true" ]]; then
        log_info "Instalando openjdk-${required_ver}-jre-headless..."
        if command -v apt-get &>/dev/null; then
            sudo apt-get update -qq && sudo apt-get install -y "openjdk-${required_ver}-jre-headless"
        else
            log_error "Gestor de paquetes apt no detectado. Instala Java $required_ver manualmente."
            return 1
        fi

        found_bin=$(find_java_binary "$required_ver")
        if [[ -n "$found_bin" && -x "$found_bin" ]]; then
            log_success "Java $required_ver instalado y verificado en: $found_bin"
            echo "$found_bin"
            return 0
        else
            log_error "No se pudo verificar la instalación de Java $required_ver."
            return 1
        fi
    else
        log_error "Se requiere Java $required_ver para ejecutar esta versión de Minecraft."
        return 1
    fi
}
