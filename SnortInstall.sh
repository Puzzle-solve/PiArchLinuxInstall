#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
RESET='\033[0m'


banner() {
clear
    echo -e "
███████╗███╗   ██╗ ██████╗ ██████╗ ████████╗
██╔════╝████╗  ██║██╔═══██╗██╔══██╗╚══██╔══╝
███████╗██╔██╗ ██║██║   ██║██████╔╝   ██║   
╚════██║██║╚██╗██║██║   ██║██╔══██╗   ██║   
███████║██║ ╚████║╚██████╔╝██║  ██║   ██║   
╚══════╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝
" | lolcat
    echo -e "\tInstalación y Configuración." | lolcat
    echo -e "#-----------------------------------------#" | lolcat
    echo -e "#-----------------------------------------#" | lolcat
}

mensaje() {
    local color="$1"
    local mensaje="$2"
    local tipo="$3" 

    case "$color" in
        red)    color_code="${RED}" ;;
        green)  color_code="${GREEN}" ;;
        yellow) color_code="${YELLOW}" ;;
        blue)   color_code="${BLUE}" ;;
        magenta)color_code="${MAGENTA}" ;;
        cyan)   color_code="${CYAN}" ;;
        white)  color_code="${WHITE}" ;;
        *)      color_code="${RESET}" ;; 
    esac

    if [ "$tipo" == "inicio" ]; then
        tput cuu1 && tput el
        echo -e "${color_code}[*] ${mensaje}.${RESET}"
    elif [ "$tipo" == "fin" ]; then
        tput cuu1 && tput el
        tput cuu1 && tput el
        echo -e "${color_code}[*] ${mensaje}.${RESET}"
    else
        echo -e "${RED}[!] Error: Tipo de mensaje no válido.${RESET}"
        return 1
    fi

    echo -e "${CYAN}+-----------------------------------------+${RESET}"
}


activandoReglas() {
    mensaje "yellow" "Se comenzó la activación de reglas" "inicio"

    SNORT_CONF="/etc/snort/snort.conf"
    sed -i '/^\s*#\s*include \$RULE_PATH/s/^#\s*//' "$SNORT_CONF"

    mensaje "green" "Activación de reglas completa" "fin"

}


servicioSnort() {
    mensaje "yellow" "Creando servicio SNORT" "inicio"
  
    local service_file="/etc/systemd/system/snort.service"
    
    local template_file="snort_service_template.txt"

    if [ -f "$service_file" ]; then

        mensaje "green" "El servicio SNORT ya existe" "fin"

        return
    fi


    if [ ! -f "$template_file" ]; then
        mensaje "red" "Error: No se encontró la plantilla del servicio SNORT" "fin"
        return
    fi

    sudo cp "$template_file" "$service_file"
    
   
    sudo systemctl daemon-reload
    sudo systemctl enable snort
    sudo systemctl start snort

    mensaje "green" "El servicio SNORT ha sido creado exitosamente" "fin"

}

descargaSnort() {
    mensaje "yellow" "Listo!, ya comenzó la descarga de SNORT" "inicio"

    if command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm snort
    elif command -v apt &> /dev/null; then
        sudo DEBIAN_FRONTEND=noninteractive apt install snort -y &> /dev/null
    else
        exit 1
    fi

    mensaje "green" "Proceso completo, ya se descargó SNORT" "fin"

}

dependencias() {

    mensaje "yellow" "Listo!, ya comenzó la descarga de dependencias" "inicio"


    sudo apt install ruby -y &> /dev/null
    sudo gem install lolcat &> /dev/null

    mensaje "green" "Proceso completo, dependencias instaladas" "fin"

}

installRules() {
    mensaje "yellow" "Se están instalando las reglas de SNORT" "inicio"

    RULE_FILE="/etc/snort/rules/local.rules"
    MARKER_START="# START CUSTOM RULES"
    MARKER_END="# END CUSTOM RULES"
    RULES_FILE_PATH="snort_rules.txt"

    if [ -f "$RULES_FILE_PATH" ]; then
	tput cuu1 && tput el
        tput cuu1 && tput el
        if grep -q "$MARKER_START" "$RULE_FILE" && grep -q "$MARKER_END" "$RULE_FILE"; then
            echo -e "${YELLOW}[!] Reglas personalizadas ya existentes.${RESET}"
            read -p "¿Desea sobrescribir las reglas existentes? (s/n): " response
            if [[ "$response" != "s" && "$response" != "S" ]]; then
                echo -e "${CYAN}[!] Sobrescritura cancelada por el usuario.${RESET}"
                return
            fi
        fi

        sed -i "/$MARKER_START/,/$MARKER_END/d" "$RULE_FILE"

        {
            echo "$MARKER_START"
            cat "$RULES_FILE_PATH"
            echo "$MARKER_END"
        } >> "$RULE_FILE"

         mensaje "green" "Reglas de SNORT instaladas exitosamente" "fin"

    else

        echo -e "${RED}[!] Error: No se encontró el archivo de reglas $RULES_FILE_PATH.${RESET}"
        exit 1
    fi
}

confiRed() {
    mensaje "yellow" "Configurando interfaz de red" "inicio"

    ip_address=$(ifconfig eth0 | grep 'inet ' | awk '{print $2}' | sed 's/\.[0-9]\+$/\.0/')
    sed -i "s/^ipvar HOME_NET.*/ipvar HOME_NET $ip_address\/24/" "/etc/snort/snort.conf"
 
    mensaje "green" "La interfaz de red de SNORT está lista" "fin"
}

banner
dependencias
descargaSnort
confiRed
servicioSnort
installRules
activandoReglas
