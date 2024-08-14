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

    MARKER_START="# START CUSTOM RULES"
    MARKER_END="# END CUSTOM RULES"

    RULES="
$MARKER_START
# Reglas para Detección de Ataques DoS

alert icmp any any -> any any (msg:\"DoS Attempt - ICMP Flood\"; itype:8; sid:1000001; rev:1;)
alert udp any any -> any 53 (msg:\"DoS Attempt - DNS Amplification Attack\"; content:\"|00 01 00 01 00 00 00 00 00 00|\"; sid:1000002; rev:1;)
alert tcp any any -> any 80 (msg:\"DoS Attempt - HTTP GET Flood\"; flow:to_server,established; content:\"GET\"; http_method; threshold:type threshold, track by_src, count 100, seconds 10; sid:1000003; rev:1;)
alert tcp any any -> any 443 (msg:\"DoS Attempt - SSL Flood\"; flow:to_server,established; content:\"|16 03|\"; threshold:type threshold, track by_src, count 100, seconds 10; sid:1000004; rev:1;)
alert tcp any any -> any 80 (msg:\"DoS Attempt - Slowloris Attack\"; flow:to_server,established; content:\"Connection: keep-alive\"; http_header; threshold:type threshold, track by_src, count 100, seconds 10; sid:1000005; rev:1;)
alert tcp any any -> any 80 (msg:\"DoS Attempt - RUDY Attack\"; flow:to_server,established; content:\"POST\"; http_method; content:\"Content-Length: 0\"; http_header; sid:1000006; rev:1;)
alert tcp any any -> any 80 (msg:\"DoS Attempt - Apache Range Header Attack\"; flow:to_server,established; content:\"Range: bytes=\"; http_header; sid:1000007; rev:1;)
alert udp any any -> any 80 (msg:\"DoS Attempt - UDP Flood\"; threshold:type threshold, track by_src, count 100, seconds 10; sid:1000008; rev:1;)
alert tcp any any -> any 21 (msg:\"DoS Attempt - FTP Bounce Attack\"; flow:to_server,established; content:\"PORT\"; ftp_command; sid:1000009; rev:1;)
alert tcp any any -> any 443 (msg:\"DoS Attempt - TLS Renegotiation Attack\"; flow:to_server,established; content:\"|16 03|\"; content:\"|00 01 00 01 01|\"; sid:1000010; rev:1;)

# Reglas para Detección de Inyección SQL

alert tcp any any -> any 80 (msg:\"SQL Injection Attempt - Generic UNION SELECT\"; flow:to_server,established; content:\"UNION SELECT\"; nocase; sid:1001001; rev:1;)
alert tcp any any -> any 80 (msg:\"SQL Injection Attempt - Generic SELECT FROM\"; flow:to_server,established; content:\"SELECT * FROM\"; nocase; sid:1001002; rev:1;)
alert tcp any any -> any 80 (msg:\"SQL Injection Attempt - SQL Comment Injection\"; flow:to_server,established; content:\"--\"; sid:1001003; rev:1;)
alert tcp any any -> any 80 (msg:\"SQL Injection Attempt - SQL Sleep Injection\"; flow:to_server,established; content:\"SLEEP(\"; sid:1001004; rev:1;)
alert tcp any any -> any 80 (msg:\"SQL Injection Attempt - Blind SQL Injection AND 1=1\"; flow:to_server,established; content:\" AND 1=1\"; nocase; sid:1001005; rev:1;)
alert tcp any any -> any 80 (msg:\"SQL Injection Attempt - UNION SELECT with HTTP Encoding\"; flow:to_server,established; uricontent:\"%55%4e%49%4f%4e%20%53%45%4c%45%43%54\"; sid:1001006; rev:1;)
alert tcp any any -> any 80 (msg:\"SQL Injection Attempt - SQL Injection Benchmark\"; flow:to_server,established; content:\"BENCHMARK(\"; sid:1001007; rev:1;)
alert tcp any any -> any 80 (msg:\"SQL Injection Attempt - SQL Injection with Boolean Condition\"; flow:to_server,established; content:\"' OR '1'='1\"; nocase; sid:1001008; rev:1;)
alert tcp any any -> any 80 (msg:\"SQL Injection Attempt - SQL Injection Waitfor Delay\"; flow:to_server,established; content:\"WAITFOR DELAY\"; sid:1001009; rev:1;)
alert tcp any any -> any 80 (msg:\"SQL Injection Attempt - SQL Error Response\"; flow:from_server,established; content:\"SQL syntax\"; sid:1001010; rev:1;)

# Reglas para Detección de Ataques de Fuerza Bruta

alert tcp any any -> any 22 (msg:\"Brute Force Attempt - SSH Multiple Login Failures\"; flow:to_server,established; content:\"Failed password\"; threshold:type both, track by_src, count 5, seconds 60; sid:1002001; rev:1;)
alert tcp any any -> any 21 (msg:\"Brute Force Attempt - FTP Multiple Login Failures\"; flow:to_server,established; content:\"530 Login incorrect\"; threshold:type both, track by_src, count 5, seconds 60; sid:1002002; rev:1;)
alert tcp any any -> any 25 (msg:\"Brute Force Attempt - SMTP Multiple Login Failures\"; flow:to_server,established; content:\"535 5.7.8 Error: authentication failed\"; threshold:type both, track by_src, count 5, seconds 60; sid:1002003; rev:1;)
alert tcp any any -> any 3306 (msg:\"Brute Force Attempt - MySQL Multiple Login Failures\"; flow:to_server,established; content:\"Access denied for user\"; threshold:type both, track by_src, count 5, seconds 60; sid:1002004; rev:1;)
alert tcp any any -> any 1433 (msg:\"Brute Force Attempt - MS SQL Server Multiple Login Failures\"; flow:to_server,established; content:\"Login failed for user\"; threshold:type both, track by_src, count 5, seconds 60; sid:1002005; rev:1;)
alert tcp any any -> any 389 (msg:\"Brute Force Attempt - LDAP Multiple Login Failures\"; flow:to_server,established; content:\"invalidCredentials\"; threshold:type both, track by_src, count 5, seconds 60; sid:1002006; rev:1;)
alert tcp any any -> any 80 (msg:\"Brute Force Attempt - HTTP Basic Authentication Multiple Failures\"; flow:to_server,established; content:\"401 Unauthorized\"; threshold:type both, track by_src, count 5, seconds 60; sid:1002007; rev:1;)
alert tcp any any -> any 3389 (msg:\"Brute Force Attempt - RDP Multiple Login Failures\"; flow:to_server,established; content:\"Logon attempt failed\"; threshold:type both, track by_src, count 5, seconds 60; sid:1002008; rev:1;)
alert tcp any any -> any 110 (msg:\"Brute Force Attempt - POP3 Multiple Login Failures\"; flow:to_server,established; content:\"-ERR Authentication failed\"; threshold:type both, track by_src, count 5, seconds 60; sid:1002009; rev:1;)
alert tcp any any -> any 143 (msg:\"Brute Force Attempt - IMAP Multiple Login Failures\"; flow:to_server,established; content:\"NO LOGIN failed\"; threshold:type both, track by_src, count 5, seconds 60; sid:1002010; rev:1;)

# Reglas para Detección de Aprovechamiento de Servicios o Aplicaciones Vulnerables en Ubuntu Server

alert tcp any any -> any 80 (msg:\"Exploitation Attempt - Shellshock Bash Vulnerability (Apache)\"; flow:to_server,established; content:\"() {\"; http_header; sid:1004001; rev:2;)
alert tcp any any -> any 445 (msg:\"Exploitation Attempt - EternalBlue SMBv1 Vulnerability (Samba)\"; flow:to_server,established; content:\"|FF 53 4D 42|\"; sid:1004002; rev:2;)
alert tcp any any -> any 443 (msg:\"Exploitation Attempt - Heartbleed OpenSSL Vulnerability (Apache)\"; flow:to_server,established; content:\"|18 03 02 00 03|\"; sid:1004003; rev:2;)
alert tcp any any -> any 8080 (msg:\"Exploitation Attempt - Apache Struts RCE CVE-2017-5638\"; flow:to_server,established; content:\"Content-Type: \"; pcre:\"/Content-Type:.*multipart\/form-data/\"; sid:1004004; rev:2;)
alert tcp any any -> any 3306 (msg:\"Exploitation Attempt - MySQL/MariaDB CVE-2012-2122 Authentication Bypass\"; flow:to_server,established; content:\"|00 00 00 0C 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00|\"; sid:1004005; rev:2;)
alert tcp any any -> any 80 (msg:\"Exploitation Attempt - Drupalgeddon 2 (CVE-2018-7600)\"; flow:to_server,established; content:\"/user/register?element_parents=account/mail/%23value&ajax_form=1&_wrapper_format=drupal_ajax\"; http_uri; sid:1004006; rev:2;)
alert tcp any any -> any 9200 (msg:\"Exploitation Attempt - Elasticsearch RCE CVE-2015-1427\"; flow:to_server,established; content:\"POST\"; http_method; content:\"script_fields\"; http_uri; sid:1004007; rev:2;)
alert tcp any any -> any 21 (msg:\"Exploitation Attempt - ProFTPD Mod_copy Command Execution CVE-2015-3306\"; flow:to_server,established; content:\"SITE CPFR\"; sid:1004008; rev:2;)
alert tcp any any -> any 389 (msg:\"Exploitation Attempt - OpenLDAP CVE-2019-13565 StartTLS\"; flow:to_server,established; content:\"StartTLS\"; sid:1004009; rev:2;)
alert tcp any any -> any 53 (msg:\"Exploitation Attempt - DNS Amplification Attack (Bind9)\"; content:\"|00 01 00 01 00 00 00 00 00 00|\"; sid:1004010; rev:2;)
$MARKER_END
"

    if ! grep -q "$MARKER_START" "$RULE_FILE"; then
        echo "$RULES" | sudo tee -a "$RULE_FILE" > /dev/null
        echo -e "\n${CYAN}[✅]Listo!, las reglas fueron instaladas.${RESET}"
    else
        echo "Las reglas ya están presentes en $RULE_FILE."
    fi
}


confiRed(){
        ip_address=$(ifconfig eth0 | grep 'inet ' | awk '{print $2}' | sed 's/\.[0-9]\+$/\.0/')
        sed -i "s/^ipvar HOME_NET.*/ipvar HOME_NET $ip_address\/24/" /etc/snort/snort.conf"
        echo -e "\n${CYAN}[✅]Ya se configuro la interfaz de red.${RESET}"
}

creacionServicio() {
    tput cuu1 && tput el 
    tput cuu1 && tput el


    # Ruta al archivo del servicio
    local service_file="/etc/systemd/system/snort.service"

    # Verificar si el archivo del servicio ya existe
    if [ -f "$service_file" ]; then
        echo -e "${YELLOW}[*] El servicio SNORT ya existe.${RESET}"
        echo -e "${CYAN}+-----------------------------------------+${RESET}"
        return
    fi

    echo -e "${BLUE}[*] Creando servicio SNORT${RESET}"
    echo -e "${CYAN}+-----------------------------------------+${RESET}"

    # Crear el archivo del servicio
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

    # Recargar el sistema de servicios y habilitar/start el servicio
    sudo systemctl daemon-reload
    sudo systemctl enable snort
    sudo systemctl start snort

    tput cuu1 && tput el  # Mueve el cursor una línea hacia arriba y limpia la línea
    tput cuu1 && tput el
    echo -e "${GREEN}[*] El servicio SNORT ha sido creado exitosamente.${RESET}"
    echo -e "${CYAN}+-----------------------------------------+${RESET}"
}


activandoReglas() {
        SNORT_CONF="/etc/snort/snort.conf"
        sed -i '/^\s*#\s*include \$RULE_PATH/s/^#\s*//' "$SNORT_CONF"        
}


mostrar_progreso() {
    local total=3  # Número total de pasos para la barra de progreso
    local progress=0
    local icon_chars=("🐧" "🍇" "💻" "🔧" "📡")  # Caracteres de animación
    clear
    echo -e "${GREEN}Verificando conexión a internet ${RESET}"

    while [[ $progress -le $total ]]; do
        # Ejecutar un ping a google.com con un límite de tiempo
        if ping -c 3 www.google.com &> /dev/null; then
            progress=$((progress + 1))
        else
            echo -e "\n${RED}[⚠️] Sin conexión a internet. Verifique su conexion.${RESET}"
            break
        fi

        # Calcular el porcentaje completado
        local percent=$((progress * 100 / total))
        local done=$((progress * 50 / total))
        local left=$((50 - done))

        # Determinar el carácter de Pac-Man actual
        local icon_index=$((progress % ${#icon_chars[@]}))
        local icon="${icon_chars[$icon_index]}"

        # Mostrar la barra de progreso con Pac-Man comiendo

        printf "\r["
        printf "%s" "$icon"
        printf "%0.s#" $(seq 1 $done)
        printf "%0.s-" $(seq 1 $left)
        printf "] %d%%" $percent

            # Verificar si la conexión es estable
        if [[ $progress -ge $total ]]; then
            echo -e "\n${CYAN}[✅]Conexión a internet verificada.${RESET}"
            sleep 5
            clear
            install_parted
            break
        fi

       
    done
}


installRules

