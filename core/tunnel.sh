#!/usr/bin/env bash
# ==============================================================================
# core/tunnel.sh - Tunnel management: Ngrok, Playit.gg and Local networking
# ==============================================================================

# Install Ngrok binary if missing
ensure_ngrok_installed() {
    if command -v ngrok &>/dev/null; then
        return 0
    fi

    log_warn "Ngrok no está instalado en el sistema."
    local install_opt=true
    prompt_yes_no install_opt "¿Deseas instalar Ngrok automáticamente ahora?" "Y"

    if [[ "$install_opt" != "true" ]]; then
        return 1
    fi

    log_info "Instalando Ngrok v3..."
    local tmp_dir="/tmp/ngrok_install_$$"
    mkdir -p "$tmp_dir"

    if curl -sSL "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz" | tar -xz -C "$tmp_dir"; then
        if sudo mv "${tmp_dir}/ngrok" /usr/local/bin/ngrok 2>/dev/null; then
            sudo chmod +x /usr/local/bin/ngrok
            rm -rf "$tmp_dir"
            log_success "Ngrok instalado exitosamente en /usr/local/bin/ngrok."
            return 0
        else
            # If no sudo, install to ~/.local/bin
            mkdir -p "$HOME/.local/bin"
            mv "${tmp_dir}/ngrok" "$HOME/.local/bin/ngrok"
            chmod +x "$HOME/.local/bin/ngrok"
            rm -rf "$tmp_dir"
            export PATH="$HOME/.local/bin:$PATH"
            log_success "Ngrok instalado en $HOME/.local/bin/ngrok."
            return 0
        fi
    else
        rm -rf "$tmp_dir"
        log_error "Error al descargar e instalar Ngrok."
        return 1
    fi
}

# Configure Ngrok authtoken
ensure_ngrok_authtoken() {
    # Check if an authtoken is already configured
    local config_file="$HOME/.config/ngrok/ngrok.yml"
    if [[ -f "$config_file" ]] && grep -q "authtoken:" "$config_file"; then
        log_success "Token de autenticación de Ngrok ya configurado en $config_file."
        return 0
    fi

    echo ""
    log_info "Ngrok requiere un token gratuito para abrir túneles TCP."
    echo -e " ${COLOR_GRAY}Obtén tu token en: ${COLOR_CYAN}https://dashboard.ngrok.com/get-started/your-authtoken${COLOR_RESET}"
    echo ""

    local token=""
    prompt_input token "Pega tu Authtoken de Ngrok" ""

    if [[ -n "$token" ]]; then
        ngrok config add-authtoken "$token" &>/dev/null
        if [[ $? -eq 0 ]]; then
            log_success "Authtoken de Ngrok configurado con éxito."
            return 0
        else
            log_error "Error al registrar el Authtoken en Ngrok."
            return 1
        fi
    else
        log_warn "No se ingresó token. Ngrok no podrá establecer conexiones públicas."
        return 1
    fi
}

# Start Ngrok TCP tunnel in background and retrieve public address
start_ngrok_tunnel() {
    local port="$1"
    local log_file="$2"

    log_info "Iniciando túnel Ngrok TCP en el puerto $port..."

    # Kill any dangling ngrok process on the same port or start fresh
    pkill -f "ngrok tcp $port" 2>/dev/null || true
    sleep 1

    # Start ngrok in background
    ngrok tcp "$port" --log=stdout > "$log_file" 2>&1 &
    local ngrok_pid=$!

    log_info "Esperando asignación de IP pública desde Ngrok API..."
    local public_url=""

    for i in {1..20}; do
        sleep 1
        # Check local ngrok API
        if curl -s http://127.0.0.1:4040/api/tunnels &>/dev/null; then
            public_url=$(curl -s http://127.0.0.1:4040/api/tunnels | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    tunnels = data.get('tunnels', [])
    if tunnels:
        # replace tcp://
        print(tunnels[0].get('public_url', '').replace('tcp://', ''))
except Exception:
    pass
" 2>/dev/null)
            if [[ -n "$public_url" ]]; then
                break
            fi
        fi
    done

    if [[ -n "$public_url" ]]; then
        log_success "Túnel Ngrok activo."
        echo "$public_url"
        return 0
    else
        log_warn "No se pudo obtener la IP de Ngrok automáticamente. Revisa $log_file"
        echo "Verifica en tu panel de Ngrok"
        return 1
    fi
}

# Playit.gg support
ensure_playit_installed() {
    if command -v playit &>/dev/null; then
        return 0
    fi

    log_warn "Playit.gg no está instalado."
    local install_opt=true
    prompt_yes_no install_opt "¿Deseas instalar el agente de Playit.gg?" "Y"

    if [[ "$install_opt" != "true" ]]; then
        return 1
    fi

    log_info "Descargando Playit.gg..."
    if sudo curl -SsL https://playit-cloud.github.io/ppa/key.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/playit.gpg 2>/dev/null && \
       echo "deb [signed-by=/etc/apt/trusted.gpg.d/playit.gpg] https://playit-cloud.github.io/ppa/data ./" | sudo tee /etc/apt/sources.list.d/playit-cloud.list >/dev/null; then
        sudo apt-get update -qq && sudo apt-get install -y playit
        log_success "Playit.gg instalado con éxito."
        return 0
    else
        log_error "No se pudo instalar Playit.gg mediante apt."
        return 1
    fi
}
