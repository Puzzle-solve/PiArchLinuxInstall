#!/bin/bash

# Función para mostrar una barra de progreso con Pac-Man comiendo
show_progress() {
    local total=30  # Número total de pasos para la barra de progreso
    local progress=0
    local pacman_chars=("🐧" "🍇" "💻" "🔧" "📡")  # Caracteres de animación

    echo "Verificando conexión a internet..."

    while [[ $progress -le $total ]]; do
        # Ejecutar un ping a google.com con un límite de tiempo
        if ping -c 1 www.google.com &> /dev/null; then
            progress=$((progress + 1))
        else
            echo -e "\n${Bred}[⚠️] Sin conexión a internet. Verifique su conexion.${reset}"
            break
        fi

        # Calcular el porcentaje completado
        local percent=$((progress * 100 / total))
        local done=$((progress * 50 / total))
        local left=$((50 - done))

        # Determinar el carácter de Pac-Man actual
        local pacman_index=$((progress % ${#pacman_chars[@]}))
        local pacman="${pacman_chars[$pacman_index]}"

        # Mostrar la barra de progreso con Pac-Man comiendo
        printf "\r["
        printf "%s" "$pacman"
        printf "%0.s#" $(seq 1 $done)
        printf "%0.s-" $(seq 1 $left)
        printf "] %d%%" $percent

        # Verificar si la conexión es estable
        if [[ $progress -ge $total ]]; then
            echo -e "\nConexión a internet verificada."
            break
        fi

        # Esperar un segundo antes de volver a intentar
        sleep 1
    done
}

# Función para mostrar la tabla de dispositivos de almacenamiento conectados
show_storage_devices() {
    echo "Cargando lista de dispositivos de almacenamiento..."
    echo
    
    # Ejecutar lsblk y formatear la salida en una tabla
    lsblk -o NAME,SIZE,TYPE -e 3 | awk '
    BEGIN {
        print "Device   Size    Type"
        print "------ ------ ----\n"
    }
    NR > 1 {  # Omitir la primera línea de encabezado de lsblk
        printf "%-3s %-7s %-5s\n", $1, $2, $3
    }' | column -t
}

# Función para mostrar los nombres principales de los dispositivos de almacenamiento conectados
show_main_device_names() {
    echo "Cargando lista de dispositivos de almacenamiento..."

    # Inicializar el contador
    local count=1

    # Ejecutar lsblk y extraer solo los nombres principales de los dispositivos
    lsblk -o NAME,TYPE -e 7 | awk -v cnt="$count" '
    BEGIN {
        # Imprimir cabecera
        printf "+-----+-----------------+\n"
        printf "| No  | Device          |\n"
        printf "+-----+-----------------+\n"
    }
    NR > 1 {
        if ($2 == "disk") {
            printf "| %-3d | %-15s |\n", cnt, $1
            cnt++
        }
    }
    END {
        # Imprimir pie de la tabla
        printf "+-----+-----------------+\n"
    }' | column -t -s '|'
}

# Función para solicitar al usuario que seleccione un dispositivo
select_device() {
    # Mostrar la lista de dispositivos
    show_main_device_names

    # Pedir al usuario que seleccione un número
    echo -n "Seleccione el número del dispositivo de almacenamiento (0 para salir): "
    read -r choice

    # Validar la selección
    if [[ $choice =~ ^[0-9]+$ ]]; then
        if [[ $choice -eq 0 ]]; then
            echo "Saliendo..."
            exit 0
        fi
        
        # Obtener el nombre del dispositivo seleccionado
        device=$(lsblk -o NAME,TYPE -e 7 | awk -v num=$((choice + 1)) '
        NR == num+1 && $2 == "disk" { print $1 }')

        if [[ -n $device ]]; then
            echo "Has seleccionado el dispositivo: $device"
            # Aquí puedes agregar más código para trabajar con el dispositivo seleccionado
        else
            echo "Selección inválida. Por favor, intente nuevamente."
            select_device
        fi
    else
        echo "Entrada inválida. Por favor, ingrese un número."
        select_device
    fi
}

# Función para el banner de texto
print_banner() {
    echo "#------------------------------#"
    echo " Instalación de Arch Linux ARM"
    echo "      en Raspberry Pi 3 B"
    echo "#------------------------------#"
}

# Función para el logotipo de Raspberry Pi
print_raspberry_icon() {
    echo "        .~~.   .~~.                "
    echo "       '. \ ' ' / .'               "
    echo "        .~ .~~~..~.               "
    echo "       : .~.'~'.~. :              "
    echo "      ~ (   ) (   ) ~             "
    echo "     ( : '~'.~.'~' : )           "
    echo "      ~ .~ (   ) ~. ~             "
    echo "       (  : '~' :  )             "
    echo "        '~ .~~~. ~'             "
    echo "            '~'                "
}

# Función para imprimir el banner e ícono centrados
print_centered() {
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
show_menu() {
    echo
    echo " Seleccione una opción:"
    echo "+-------------------------------------------+"
    echo "| 1. Verificar conexión a internet           |"
    echo "| 2. Selección de Micro SD                  |"
    echo "| 3. Modificación de versión de Raspberry Pi |"
    echo "+-------------------------------------------+"
    echo -n " Ingrese su opción [1-3]: "
}

# Función para manejar la selección del menú
handle_menu_selection() {
    local choice
    read -r choice
    case $choice in
        1)
            show_progress
            ;;
        2)
            echo "Seleccionando Micro SD..."
            #show_storage_devices
            select_device
            ;;
        3)
            echo "Modificando la versión de Raspberry Pi..."
            # Aquí puedes agregar el código para modificar la versión de Raspberry Pi
            ;;
        *)
            echo "Opción inválida. Por favor, seleccione una opción válida."
            ;;
    esac
}

# Mostrar el banner e ícono
print_centered

# Mostrar el menú y manejar la selección del usuario
while true; do
    show_menu
    handle_menu_selection
done
