#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
RESET='\033[0m'

banner(){
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
}

descargaSnort(){
    echo -e "${CYAN}+---------------------------------------------+${RESET}"
    echo -e "${BLUE}[*]Listo!, ya comenzo la descarga de SNORT${RESET}"
    echo -e "${CYAN}+---------------------------------------------+${RESET}"
    if command -v pacman &> /dev/null; then
        echo "Detectado pacman. Instalando Snort usando pacman..."
        sudo pacman -S --noconfirm snort
    elif command -v apt &> /dev/null; then
        echo "Detectado apt. Instalando Snort usando apt..."
        #sudo apt-get update
        sudo DEBIAN_FRONTEND=noninteractive apt install snort -y &> /dev/null
    else
        echo "No se pudo detectar un gestor de paquetes compatible (pacman o apt)."
        exit 1
    fi
    tput cuu1 && tput el  # Mueve el cursor una línea hacia arriba y limpia la línea
    tput cuu1 && tput el
    echo -e "${GREEN}[*]Proceso completo, Ya se descargo SNORT${RESET}"
    echo -e "${CYAN}+---------------------------------------------+${RESET}"
}

dependencias(){
        sudo apt install ruby -y &> /dev/null
        sudo gem install lolcat &> /dev/null
}

installRules(){
    # Ruta al archivo de reglas de Snort
    RULE_FILE="/etc/snort/rules/local.rules"
    RULES=""
    echo "$RULES" | sudo tee -a "$RULE_FILE" > /dev/null
}

confiRed(){
        ip_address=$(ifconfig eth0 | grep 'inet ' | awk '{print $2}' | sed 's/\.[0-9]\+$/\.0/')
        sed -i "s/^ipvar HOME_NET.*/ipvar HOME_NET $ip_address\/24/" /etc/snort/snort.conf"
}

creacionservicio(){
    local service_file="/etc/systemd/system/snort.service"
    sudo bash -c "cat > $service_file" <<EOF
[Unit]
Description=Snort Network Intrusion Detection System
After=network.target

[Service]
ExecStart=/usr/sbin/snort -D -q -c /etc/snort/snort.conf -i eth0
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
"

        sudo systemctl daemon-reload
        sudo systemctl enable snort
        sudo systemctl start snort

}
activandoReglas() {
        SNORT_CONF="/etc/snort/snort.conf"
        sed -i '/^\s*#\s*include \$RULE_PATH/s/^#\s*//' "$SNORT_CONF"
}


installRules

