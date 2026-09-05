#!/usr/bin/env bash
# ==============================================================================
# core/ui.sh - Visual interface, ANSI colors, spinners, banners and prompts
# ==============================================================================

# ANSI Color Palette (256-color support with fallback)
COLOR_RESET="\e[0m"
COLOR_BOLD="\e[1m"
COLOR_DIM="\e[2m"
COLOR_UNDERLINE="\e[4m"

COLOR_EMERALD="\e[38;5;48m"
COLOR_GREEN="\e[38;5;82m"
COLOR_CYAN="\e[38;5;51m"
COLOR_BLUE="\e[38;5;39m"
COLOR_PURPLE="\e[38;5;141m"
COLOR_YELLOW="\e[38;5;220m"
COLOR_RED="\e[38;5;196m"
COLOR_GRAY="\e[38;5;244m"
COLOR_WHITE="\e[38;5;255m"

# Print high-impact ASCII banner
print_banner() {
    clear 2>/dev/null || true
    echo -e "${COLOR_EMERALD}${COLOR_BOLD}"
    cat << "EOF"
  ███╗   ███╗ ██████╗    ███████╗███████╗██████╗ ██╗   ██╗███████╗██████╗ 
  ████╗ ████║██╔════╝    ██╔════╝██╔════╝██╔══██╗██║   ██║██╔════╝██╔══██╗
  ██╔████╔██║██║         ███████╗█████╗  ██████╔╝██║   ██║█████╗  ██████╔╝
  ██║╚██╔╝██║██║         ╚════██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██╔══╝  ██╔══██╗
  ██║ ╚═╝ ██║╚██████╗    ███████║███████╗██║  ██║ ╚████╔╝ ███████╗██║  ██║
  ╚═╝     ╚═╝ ╚═════╝    ╚══════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝
EOF
    echo -e "${COLOR_CYAN}${COLOR_BOLD}      ⛏️   Minecraft Server Creator + Tunnels & Crossplay   ⛏️${COLOR_RESET}"
    echo -e "${COLOR_GRAY}      ───────────────────────────────────────────────────────────${COLOR_RESET}"
    echo ""
}

# Logging helpers
log_info() {
    echo -e " ${COLOR_BLUE}${COLOR_BOLD}ℹ${COLOR_RESET}  $1"
}

log_success() {
    echo -e " ${COLOR_GREEN}${COLOR_BOLD}✔${COLOR_RESET}  ${COLOR_WHITE}$1${COLOR_RESET}"
}

log_warn() {
    echo -e " ${COLOR_YELLOW}${COLOR_BOLD}⚠${COLOR_RESET}  ${COLOR_YELLOW}$1${COLOR_RESET}"
}

log_error() {
    echo -e " ${COLOR_RED}${COLOR_BOLD}✖${COLOR_RESET}  ${COLOR_RED}$1${COLOR_RESET}"
}

log_step() {
    local step_num="$1"
    local total_steps="$2"
    local title="$3"
    echo ""
    echo -e " ${COLOR_PURPLE}${COLOR_BOLD}[Paso $step_num/$total_steps]${COLOR_RESET} ${COLOR_BOLD}${COLOR_WHITE}$title${COLOR_RESET}"
    echo -e " ${COLOR_GRAY}───────────────────────────────────────────────────${COLOR_RESET}"
}

# Braille Spinner for background tasks
show_spinner() {
    local pid="$1"
    local message="$2"
    local spin_chars=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local i=0

    # Hide cursor
    tput civis 2>/dev/null || true

    while kill -0 "$pid" 2>/dev/null; do
        local char="${spin_chars[i]}"
        printf "\r ${COLOR_CYAN}%s${COLOR_RESET}  %s" "$char" "$message"
        i=$(( (i + 1) % ${#spin_chars[@]} ))
        sleep 0.08
    done

    wait "$pid"
    local exit_code=$?

    # Restore cursor
    tput cnorm 2>/dev/null || true

    if [[ $exit_code -eq 0 ]]; then
        printf "\r ${COLOR_GREEN}✔${COLOR_RESET}  %s\n" "$message"
    else
        printf "\r ${COLOR_RED}✖${COLOR_RESET}  %s (Error)\n" "$message"
    fi
    return $exit_code
}

# Text input prompt with default
prompt_input() {
    local var_name="$1"
    local label="$2"
    local default_val="$3"

    echo -ne " ${COLOR_CYAN}?${COLOR_RESET} ${label} "
    if [[ -n "$default_val" ]]; then
        echo -ne "${COLOR_GRAY}[${default_val}]${COLOR_RESET}: "
    else
        echo -ne ": "
    fi

    local user_input
    read -r user_input
    if [[ -z "$user_input" ]]; then
        eval "$var_name=\"$default_val\""
    else
        eval "$var_name=\"$user_input\""
    fi
}

# Yes/No prompt with default
prompt_yes_no() {
    local var_name="$1"
    local question="$2"
    local default_choice="${3:-Y}" # Y or N

    local hint="[Y/n]"
    [[ "${default_choice^^}" == "N" ]] && hint="[y/N]"

    while true; do
        echo -ne " ${COLOR_CYAN}?${COLOR_RESET} ${question} ${COLOR_GRAY}${hint}${COLOR_RESET}: "
        read -r choice
        choice="${choice:-$default_choice}"
        choice="${choice^^}" # Uppercase

        if [[ "$choice" == "Y" || "$choice" == "YES" || "$choice" == "S" || "$choice" == "SI" ]]; then
            eval "$var_name=true"
            return 0
        elif [[ "$choice" == "N" || "$choice" == "NO" ]]; then
            eval "$var_name=false"
            return 0
        else
            log_warn "Por favor responde Y o N."
        fi
    done
}

# Menu choice prompt
prompt_choice() {
    local var_name="$1"
    local title="$2"
    shift 2
    local -a options=("$@")

    echo -e " ${COLOR_CYAN}?${COLOR_RESET} ${COLOR_BOLD}$title${COLOR_RESET}"
    local idx=1
    for opt in "${options[@]}"; do
        echo -e "    ${COLOR_EMERALD}${idx})${COLOR_RESET} $opt"
        idx=$((idx + 1))
    done

    local choice
    while true; do
        echo -ne "    ${COLOR_GRAY}Selecciona una opción [1-${#options[@]}] (Default: 1): ${COLOR_RESET}"
        read -r choice
        choice="${choice:-1}"
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
            eval "$var_name=$choice"
            return 0
        else
            log_warn "Opción inválida. Ingresa un número entre 1 y ${#options[@]}."
        fi
    done
}

# Final Server Dashboard Card
print_dashboard_card() {
    local server_name="$1"
    local software="$2"
    local version="$3"
    local ram="$4"
    local port="$5"
    local online_mode="$6"
    local tunnel_type="$7"
    local public_ip="$8"
    local bedrock_enabled="$9"
    local server_path="${10}"

    local mode_desc="${COLOR_GREEN}Premium (Solo cuentas oficiales)${COLOR_RESET}"
    if [[ "$online_mode" == "false" ]]; then
        mode_desc="${COLOR_YELLOW}No-Premium (Permite launchers no oficiales)${COLOR_RESET}"
    fi

    local bedrock_desc="${COLOR_RED}Deshabilitado${COLOR_RESET}"
    if [[ "$bedrock_enabled" == "true" ]]; then
        bedrock_desc="${COLOR_GREEN}Habilitado (GeyserMC + Floodgate)${COLOR_RESET}"
    fi

    echo ""
    echo -e "${COLOR_EMERALD}┌────────────────────────────────────────────────────────────────────────┐${COLOR_RESET}"
    echo -e "${COLOR_EMERALD}│${COLOR_RESET}               ${COLOR_BOLD}🚀 ¡SERVIDOR DE MINECRAFT CONFIGURADO!${COLOR_RESET}                   ${COLOR_EMERALD}│${COLOR_RESET}"
    echo -e "${COLOR_EMERALD}├────────────────────────────────────────────────────────────────────────┤${COLOR_RESET}"
    printf "${COLOR_EMERALD}│${COLOR_RESET}  ${COLOR_BOLD}%-16s${COLOR_RESET}: %-50b ${COLOR_EMERALD}│${COLOR_RESET}\n" "Nombre Servidor" "$server_name"
    printf "${COLOR_EMERALD}│${COLOR_RESET}  ${COLOR_BOLD}%-16s${COLOR_RESET}: %-50b ${COLOR_EMERALD}│${COLOR_RESET}\n" "Software / Motor" "$software (v$version)"
    printf "${COLOR_EMERALD}│${COLOR_RESET}  ${COLOR_BOLD}%-16s${COLOR_RESET}: %-50b ${COLOR_EMERALD}│${COLOR_RESET}\n" "RAM Asignada" "${ram} MB (~$((ram / 1024)) GB)"
    printf "${COLOR_EMERALD}│${COLOR_RESET}  ${COLOR_BOLD}%-16s${COLOR_RESET}: %-50b ${COLOR_EMERALD}│${COLOR_RESET}\n" "Modo de Cuentas" "$mode_desc"
    printf "${COLOR_EMERALD}│${COLOR_RESET}  ${COLOR_BOLD}%-16s${COLOR_RESET}: %-50b ${COLOR_EMERALD}│${COLOR_RESET}\n" "Crossplay Bedrock" "$bedrock_desc"
    echo -e "${COLOR_EMERALD}├────────────────────────────────────────────────────────────────────────┤${COLOR_RESET}"
    printf "${COLOR_EMERALD}│${COLOR_RESET}  ${COLOR_BOLD}%-16s${COLOR_RESET}: %-50b ${COLOR_EMERALD}│${COLOR_RESET}\n" "Puerto Local" "localhost:${port}"
    printf "${COLOR_EMERALD}│${COLOR_RESET}  ${COLOR_BOLD}%-16s${COLOR_RESET}: %-50b ${COLOR_EMERALD}│${COLOR_RESET}\n" "Tipo de Túnel" "$tunnel_type"
    if [[ -n "$public_ip" && "$public_ip" != "none" ]]; then
        printf "${COLOR_EMERALD}│${COLOR_RESET}  ${COLOR_BOLD}%-16s${COLOR_RESET}: ${COLOR_GREEN}${COLOR_BOLD}%-50s${COLOR_RESET} ${COLOR_EMERALD}│${COLOR_RESET}\n" "🔗 IP PÚBLICA" "$public_ip"
    fi
    echo -e "${COLOR_EMERALD}├────────────────────────────────────────────────────────────────────────┤${COLOR_RESET}"
    echo -e "${COLOR_EMERALD}│${COLOR_RESET}  ${COLOR_PURPLE}${COLOR_BOLD}COMANDOS ÚTILES:${COLOR_RESET}                                                      ${COLOR_EMERALD}│${COLOR_RESET}"
    printf "${COLOR_EMERALD}│${COLOR_RESET}  • Consola del servidor:  ${COLOR_CYAN}%-43s${COLOR_RESET} ${COLOR_EMERALD}│${COLOR_RESET}\n" "$server_path/console.sh"
    printf "${COLOR_EMERALD}│${COLOR_RESET}  • Detener servidor:      ${COLOR_CYAN}%-43s${COLOR_RESET} ${COLOR_EMERALD}│${COLOR_RESET}\n" "$server_path/stop.sh"
    printf "${COLOR_EMERALD}│${COLOR_RESET}  • Iniciar servidor:      ${COLOR_CYAN}%-43s${COLOR_RESET} ${COLOR_EMERALD}│${COLOR_RESET}\n" "$server_path/start.sh"
    printf "${COLOR_EMERALD}│${COLOR_RESET}  • Crear copia de backup: ${COLOR_CYAN}%-43s${COLOR_RESET} ${COLOR_EMERALD}│${COLOR_RESET}\n" "$server_path/backup.sh"
    echo -e "${COLOR_EMERALD}└────────────────────────────────────────────────────────────────────────┘${COLOR_RESET}"
    echo ""
}
