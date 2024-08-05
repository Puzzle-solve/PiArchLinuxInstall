#!/bin/bash

# Definición de colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
RESET='\033[0m'  # Resetear colores a los valores por defecto

# Función para mostrar una barra de progreso con Pac-Man comiendo
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

# Función para verificar e instalar parted
install_parted() {

    if command -v parted &> /dev/null; then
        echo -e "${GREEN}[✅] Herramientas instaladas correctamente.${RESET}"
    else
        echo -e "${RED}[⚠️] parted no está instalado. Intentando instalarlo.${RESET}"

            if command -v apt &> /dev/null; then
                sudo apt install -y parted #Debian
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y parted #Fedora
            elif command -v yum &> /dev/null; then
                sudo yum install -y parted #Redhat
            elif command -v pacman &> /dev/null; then
                sudo pacman -S --noconfirm parted #Arch Linux
            elif command -v zypper &> /dev/null; then
                sudo zypper install -y parted #Open Suse
            elif command -v apk &> /dev/null; then
                sudo apk add parted #Alpine Linux
            elif command -v xbps-install &> /dev/null; then
                sudo xbps-install -S parted #Void Linux
            elif command -v eopkg &> /dev/null; then
                sudo eopkg it parted #Solus
            elif command -v guix &> /dev/null; then
                sudo guix package -i parted #GNU Guix System
            elif command -v nix &> /dev/null; then
                sudo nix-env -iA nixpkgs.parted #NixOS
            else
                echo -e "${RED}[⚠️] Distribución no soportada o desconocida. Por favor instala parted manualmente.${RESET}"
                return 1
            fi
       
            # Verificar si la instalación fue exitosa
            if command -v parted &> /dev/null; then
                echo -e "${GREEN}[✅] parted se ha instalado correctamente.${RESET}"
            else
                echo -e "${RED}[⚠️] La instalación de parted ha fallado.${RESET}"
                return 1
            fi
    fi
}

# Función para solicitar al usuario que seleccione un dispositivo
seleccion_almacenamiento() {
    clear
    echo "Listando dispositivos y sus tamaños:"
    echo -e "${YELLOW}+------------------------------------+${RESET}"
    
    # Obtener la lista de dispositivos y tamaños
    mapfile -t dispositivos < <(sudo fdisk -l | grep '^Disk /dev/' | awk '{print $2, $3, $4}' | sed 's/,$//')

    # Mostrar la lista numerada de dispositivos
    for i in "${!dispositivos[@]}"; do
        echo -e "${YELLOW}|>${RESET} [$((i+1))] ${YELLOW}|${RESET} ${dispositivos[$i]} "
    done
    echo -e "${YELLOW}+------------------------------------+${RESET}"

    # Solicitar al usuario que seleccione un dispositivo por número
    echo -en "${MAGENTA}Selecciona el número del dispositivo: ${RESET}"
    read -r seleccion

    # Verificar si la selección es válida
    if (( seleccion > 0 && seleccion <= ${#dispositivos[@]} )); then
        dispositivo_seleccionado="${dispositivos[$((seleccion-1))]}"
        almacenamiento="${dispositivos[$((seleccion-1))]}"
        clear
        echo -e "${CYAN}[✅] Has seleccionado: $dispositivo_seleccionado ${RESET}"
    else
        echo -e "\n${RED}[⚠️ ] Selección no válida. Por favor, intenta de nuevo.${RESET}"
        sleep 2
        seleccion_almacenamiento
    fi
}

# Función para el banner de texto
print_banner() {
    echo -e "#---------------------------------------------#
        Instalación de Arch Linux ARM
              en Raspberry Pi 🍇
#---------------------------------------------#"
}

# Función para el logotipo de Raspberry Pi
print_raspberry_icon() {
    echo -e "\t        .~~.   .~~.                "
    echo -e "\t         '. \' '/.'               "
    echo -e "\t         .~ .~~~..~.               "
    echo -e "\t        : .~.'~'.~. :              "
    echo -e "\t       ~ (   ) (   ) ~             "
    echo -e "\t      ( : '~'.~.'~' : )           "
    echo -e "\t       ~ .~ (   ) ~. ~             "
    echo -e "\t        (  : '~' :  )             "
    echo -e "\t         '~ .~~~. ~'             "
    echo -e "\t             '~'                "
}

# Función para imprimir el banner e ícono centrados
print_centrado() {
    local banner=$(print_banner)
    local icon=$(print_raspberry_icon)
    
    # Dividir el banner en líneas
    IFS=$'\n' read -r -d '' -a banner_lines <<< "$banner"
    # Dividir el ícono en líneas
    IFS=$'\n' read -r -d '' -a icon_lines <<< "$icon"
    
    # Determinar el ancho máximo de las líneas
    local max_length=0
    for line in "${banner_lines[@]}"; do
        local length=${#line}
        if (( length > max_length )); then
            max_length=$length
        fi
    done
    
    # Imprimir el banner
    for i in "${!banner_lines[@]}"; do
        local banner_line=${banner_lines[$i]}
        printf "%s\n" "$banner_line" | lolcat
    done
    
    # Imprimir el ícono
    for i in "${!icon_lines[@]}"; do
        local icon_line=${icon_lines[$i]}
        printf "%s\n" "$icon_line" | lolcat
    done
}

#Informacion de Raspberry Pi compatibles con Arch Linux
print_info(){
    clear
    echo
    echo -e "${GREEN}+---------------------------------------------+${RESET}"
    echo -e "${RED}    Versiones compatibles de Raspberry Pi:${RESET}"
    echo -e "${GREEN}+---------------------------------------------+${RESET}"
    echo -e "${GREEN}|${RESET} \t\t1. Raspberry Pi 2            ${GREEN} |${RESET}"
    echo -e "${GREEN}|${RESET} \t\t   - Model B                 ${GREEN} |${RESET}"
    echo -e "${GREEN}|${RESET} \t\t2. Raspberry Pi 3            ${GREEN} |${RESET}"
    echo -e "${GREEN}|${RESET} \t\t   - Model B                 ${GREEN} |${RESET}"
    echo -e "${GREEN}|${RESET} \t\t   - Model B+                ${GREEN} |${RESET}"
    echo -e "${GREEN}|${RESET} \t\t3. Raspberry Pi 4            ${GREEN} |${RESET}"
    echo -e "${GREEN}|${RESET} \t\t   - Model B                 ${GREEN} |${RESET}"
    echo -e "${GREEN}|${RESET} \t\t4. Raspberry Pi Zero         ${GREEN} |${RESET}"
    echo -e "${GREEN}|${RESET} \t\t   - Zero                    ${GREEN} |${RESET}"
    echo -e "${GREEN}|${RESET} \t\t   - Zero W                  ${GREEN} |${RESET}"
    echo -e "${GREEN}|${RESET} \t\t   - Zero WH                 ${GREEN} |${RESET}"
    echo -e "${GREEN}+---------------------------------------------+${RESET}"
    echo -e "${GREEN}|🍇🍇🍇🍇🍇🍇🍇🍇🍇🍇🍇🍇🍇🍇🍇🍇🍇🍇🍇🍇🍇🍇🍇|${RESET}"
    sleep 7
    clear
    
}

# Función para mostrar el menú en formato de tabla
mostrar_menu() {
    echo
    echo -e "${GREEN}+---------------------------------------------+${RESET}"
    echo -e "${GREEN}\t    Seleccione una opción:${RESET}"
    echo -e "${GREEN}+---------------------------------------------+${RESET}"
    echo -e "${GREEN}|${RESET} 1. Verificar conexión a internet           ${GREEN} |${RESET}"
    echo -e "${GREEN}|${RESET} 2. Selección de Micro SD                   ${GREEN} |${RESET}"
    echo -e "${GREEN}|${RESET} 3. Instalación de Arch Linux               ${GREEN} |${RESET}"
    echo -e "${GREEN}|${RESET} q. Salir                                   ${GREEN} |${RESET}"
    echo -e "${GREEN}|${RESET} x. Versiónes compatibles de Raspberry Pi   ${GREEN} |${RESET}"
    echo -e "${GREEN}+---------------------------------------------+${RESET}"
    echo -ne "${MAGENTA}[*]Ingrese su opción [1-3]:${RESET}"
}

show_progress() {
    local progress=$1
    local total=$2
    local width=50

    local pct=$((progress * 100 / total))
    local filled=$((pct * width / 100))
    local empty=$((width - filled))

    printf "["
    printf "%0.s#" $(seq 1 $filled)
    printf "%0.s-" $(seq 1 $empty)
    printf "] %d%%\r" $pct
}

#Instalacion de Arch Linux 
install_ArchLinux() {
    clear
    SD_CARD=$(echo "${dispositivo_seleccionado}" | cut -d':' -f1) # Cambia esto a la ruta de tu tarjeta SD (e.g., /dev/sdb)
    estatus="-"

    if [ -z "$SD_CARD" ]; then
        echo -e "${BLUE}+---------------------------------------------------+${RESET}"
        echo -e "${RED} Error: No se ha especificado el dispositivo MicroSD${RESET}"
        echo -e "${RED} ⚠️ Seleccione la MicroSD a utilizar, utilizando la${RESET}"
        echo -e "${RED} opción 2 del menu principal.${RESET}"
        echo -e "${BLUE}+---------------------------------------------------+${RESET}"
        return
    fi

    # Crear tabla de particiones y particiones
    echo -e "${GREEN}+---------------------------------------------+${RESET}"
    echo -e "${GREEN}  Creando tabla de particiones y particiones${RESET}"
    echo -e "${GREEN}+---------------------------------------------+${RESET}"
    yes | sudo parted ${SD_CARD} mklabel msdos >&/dev/null
    yes | sudo parted -a optimal ${SD_CARD} mkpart primary fat32 0% 200MB >&/dev/null
    yes | sudo parted -a optimal ${SD_CARD} mkpart primary ext4 200MB 100% >&/dev/null
    echo -e "${GREEN}|${RESET}${BLUE}   [✅] Creación de particiones.${RESET}${GREEN}             |${RESET}"

    # Formatear particiones
    sudo mkfs.vfat ${SD_CARD}1 >&/dev/null
    yes | sudo mkfs.ext4 -F ${SD_CARD}2 >&/dev/null
    if [ $? -eq 0 ]; then
        estatus="✅"
    else
        estatus="❌"
    fi
    echo -e "${GREEN}|${RESET}${BLUE}   [${estatus}] Formateo particiones.${RESET}${GREEN}                |${RESET}"

    # Crear directorios de montaje
    sudo mkdir -p /mnt/boot >&/dev/null
    sudo mkdir -p /mnt/root >&/dev/null
    if [ $? -eq 0 ]; then
        estatus="✅"
    else
        estatus="❌"
    fi
    echo -e "${GREEN}|${RESET}${BLUE}   [${estatus}] Creación de directorios de montaje.${RESET}${GREEN}  |${RESET}"

    # Montar particiones
    sudo mount ${SD_CARD}1 /mnt/boot >&/dev/null
    sudo mount ${SD_CARD}2 /mnt/root >&/dev/null
    if [ $? -eq 0 ]; then
        estatus="✅"
    else
        estatus="❌"
    fi
    echo -e "${GREEN}|${RESET}${BLUE}   [${estatus}] Montaje de particiones.${RESET}${GREEN}              |${RESET}"

  # Descargar la imagen
    wget --show-progress -q http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-armv7-latest.tar.gz 
    tput cuu1 && tput el
    # Comprobar si la descarga fue exitosa
    if [ $? -eq 0 ]; then
      estatus="✅"
     # Mover el cursor hacia arriba para la barra de progreso y borrar la línea
        tput cuu1 && tput el
        echo -e "${GREEN}|${RESET}${BLUE}   [${estatus}] Descarga de Arch Linux completo.${RESET}${GREEN}|${RESET}"
    else
        estatus="❌"
        echo -e "${GREEN}|${RESET}${BLUE}   [${estatus}] Error en la descarga.${RESET}${GREEN}           |${RESET}"
    fi

    # Verificar que la descarga fue exitosa
    if [ ! -f ArchLinuxARM-rpi-armv7-latest.tar.gz ]; then
        echo -e "${RED}|${RESET}${BLUE}   [❌] Error: La descarga de la imagen falló.${RESET}${RED}       |${RESET}"
        exit 1
    fi

    # Extraer la imagen en la partición raíz
    sudo tar -xzf ArchLinuxARM-rpi-armv7-latest.tar.gz -C /mnt/root >&/dev/null
    if [ $? -eq 0 ]; then
        estatus="✅"
    else
        estatus="❌"
    fi
    echo -e "${GREEN}|${RESET}${BLUE}   [${estatus}] Extracción de imagen correctamente.${RESET}${GREEN}  |${RESET}"

    # Mover archivos de boot
    sudo mv /mnt/root/boot/* /mnt/boot/
    if [ $? -eq 0 ]; then
        estatus="✅"
    else
        estatus="❌"
    fi
    echo -e "${GREEN}|${RESET}${BLUE}   [${estatus}] Moviendo archivos correctamente.${RESET}${GREEN}     |${RESET}"

    # Desmontar particiones
    sudo umount /mnt/boot
    sudo umount /mnt/root
    if [ $? -eq 0 ]; then
        estatus="✅"
    else
        estatus="❌"
    fi
    echo -e "${GREEN}|${RESET}${BLUE}   [${estatus}] Desmontando particion correctamente.${RESET}${GREEN} |${RESET}"

    # Sincronizar y limpiar
    sync
    sudo rm -rf /mnt/boot/
    sudo rm -rf /mnt/root/
    rm -f ArchLinuxARM-rpi-armv7-latest.tar.gz
    if [ $? -eq 0 ]; then
        estatus="✅"
    else
        estatus="❌"
    fi
    echo -e "${GREEN}|${RESET}${BLUE}   [${estatus}] Sincronización y limpieza.${RESET}${GREEN}           |${RESET}"
    echo -e "${GREEN}+---------------------------------------------+${RESET}"
    echo -e "\n${GREEN}[✅] La instalación de Arch Linux ARM en la Raspberry Pi 3 B se ha completado.${RESET}"
}

# Función para manejar la selección del menú
seleccion_opcion_menu() {
    local choice
    read -r choice
    case $choice in
        1)
            mostrar_progreso
            ;;
        2)
            seleccion_almacenamiento
            ;;
        3)
            install_ArchLinux
            ;;
        q)
            echo -e "${GREEN}🐧 Hasta luego...${RESET}"
            sleep 4
            clear
            exit 
            ;;
        x)
            print_info
            ;;
        *)
            echo -e "${RED}Opción inválida. Por favor, seleccione una opción válida.${RESET}"
            ;;
    esac
}

print_centrado

while true; do
    mostrar_menu
    seleccion_opcion_menu
done
