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
            break
        fi

        # Esperar un segundo antes de volver a intentar
        sleep 1
    done
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
    echo -e "#---------------------------------------------#"
    echo -e "\t Instalación de Arch Linux ARM"
    echo -e "\t      en Raspberry Pi 3 B"
    echo -e "#---------------------------------------------#"
}

# Función para el logotipo de Raspberry Pi
print_raspberry_icon() {
    echo -e "\t        .~~.   .~~.                "
    echo -e "\t        '. \ ' ' /.'               "
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

# Función para mostrar el menú en formato de tabla
mostrar_menu() {
    echo
    echo -e "${GREEN}+---------------------------------------------+${RESET}"
    echo -e "${GREEN}\t    Seleccione una opción:${RESET}"
    echo -e "${GREEN}+---------------------------------------------+${RESET}"
    echo -e "${GREEN}|${RESET} 1. Verificar conexión a internet           ${GREEN} |${RESET}"
    echo -e "${GREEN}|${RESET} 2. Selección de Micro SD                   ${GREEN} |${RESET}"
    echo -e "${GREEN}|${RESET} 3. Instalación de Arch Linux               ${GREEN} |${RESET}"
    echo -e "${GREEN}|${RESET} x. Versión de Raspberry Pi                 ${GREEN} |${RESET}"
    echo -e "${GREEN}+---------------------------------------------+${RESET}"
    echo -ne "${MAGENTA}[*]Ingrese su opción [1-3]:${RESET}"
}

#Instalacion de Arch Linux 
install_ArchLinux(){

    ARCH_LINUX_URL="http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-armv7-latest.tar.gz"
    directorio_actual=$(pwd)
    cadena_adicional="/ArchLinuxARM-rpi-armv7-latest.tar.gz"
    IMAGE_PATH="${directorio_actual}${cadena_adicional}"
    SD_CARD="/dev/sdb"  # Cambia esto a la ruta de tu tarjeta SD (e.g., /dev/sdb)

    # Verificar permisos de superusuario
    if [[ $EUID -ne 0 ]]; then
        echo "Este script debe ejecutarse con permisos de superusuario (root)." 
        exit 1
    fi

    # Descargar la imagen de Arch Linux ARM
    echo -e "${YELLOW}Descargando la imagen de Arch Linux ARM...${RESET}"
    wget "$ARCH_LINUX_URL" -O "$IMAGE_PATH"

    # Formatear la tarjeta SD
    echo -e "${YELLOW}Formateando la tarjeta SD...${RESET}"
    fdisk "$SD_CARD" <<EOT
o
p
n
p
1

+200M
t
c
n
p
2
y




w
EOT

    # Crear sistema de archivos
    echo -e "${YELLOW}Creando sistema de archivos...${RESET}"
    mkfs.vfat ${SD_CARD}1
    mkdir -p boot
    mount ${SD_CARD}1 boot

    mkfs.ext4 ${SD_CARD}2
    mkdir -p root
    mount ${SD_CARD}2 root

    # Extraer la imagen
    echo -e "${YELLOW}Extrayendo la imagen...${RESET}"
    tar -xzf "$IMAGE_PATH" -C root/ >&/dev/null

    # Sincronizar y desmontar
    echo -e "${YELLOW}Sincronizando y desmontando...${RESET}"
    sync
    mv root/boot/* boot
    umount boot root
    
    echo -e "${MAGENTA}La instalación de Arch Linux ARM en la Raspberry Pi 3 B se ha completado.${RESET}"
    rm -rf ArchLinuxARM-rpi-armv7-latest.tar.gz boot/ root/
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
            echo "Instalacion de Arch Linux"
            install_ArchLinux
            ;;
        x)
            echo "Modificacion de version"
            ;;
        *)
            echo "Opción inválida. Por favor, seleccione una opción válida."
            ;;
    esac
}

print_centrado

while true; do
    mostrar_menu
    seleccion_opcion_menu
done
