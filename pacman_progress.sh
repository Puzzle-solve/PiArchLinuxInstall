#!/usr/bin/env bash

# Definiciones de colores y estilos
readonly Bold='\e[1m' Bred='\e[1;31m' Byellow='\e[1;33m' reset='\e[0m'

# Función para mostrar la barra de progreso
progressbar() {
    local title="${1}" current="${2}" total="${3:-100}"
    local msg1="${4}" msg2="${5}" msg3="${6}"

    # Configuración del tema de la barra de progreso
    local BraketIn="["
    local BraketOut="]"
    local Cursor="${Byellow}C${reset}"
    local CursorSmall="${Byellow}c${reset}"
    local CursorDone="-"
    local CursorNotDone="o"

    # Obtener el número de columnas de la terminal
    cols=$(tput cols)
    (( block=cols/3-cols/20 ))
    (( _title=block-${#title}-1 ))
    (( _msg=block-${#msg1}-${#msg2}-${#msg3}-3 ))

    _title=$(printf "%${_title}s")
    _msg=$(printf "%${_msg}s")

    (( _pbar_size=cols-2*block-8 ))
    (( _progress=current*100/total ))
    (( _current=current*_pbar_size ))
    (( _current=_current/total ))
    (( _total=_pbar_size-_current ))

    # Mostrar la barra de progreso con animación Pac-Man
    if [[ "${ILoveCandy}" == true ]]; then
        (( _motif=_pbar_size/3 ))
        (( _dummy_block=2*block+1 ))
        _dummy_block=$(printf "%${_dummy_block}s")
        _motif=$(printf "%${_motif}s")
        printf "\r${_dummy_block}${BraketIn} ${_motif// /${CursorNotDone}}${BraketOut} ${_progress}%%"

        _current_pair=${_current}
        (( _current=_current-1 ))
        (( _total=_total ))
        _current=$(printf "%${_current}s")
        _total=$(printf "%${_total}s")

        printf "\r ${title}${_title} ${_msg}${msg1} ${msg2} ${msg3} "
        printf "${BraketIn}${_current// /${CursorDone}}"
        if [[ $(( _current_pair % 2)) -eq 0 ]]; then
            printf "${Cursor}"
        else
            printf "${CursorSmall}"
        fi

        if [[ "${_progress}" -eq 100 ]]; then
            printf "\r ${title}${_title} ${_msg}${msg1} ${msg2} ${msg3} ${BraketIn}${_current// /${CursorDone}}${CursorDone}${BraketOut}\n"
        fi
    else
        _current=$(printf "%${_current}s")
        _total=$(printf "%${_total}s")
        printf "\r ${title}${_title} ${_msg}${msg1} ${msg2} ${msg3} "
        printf "${BraketIn}${_current// /${CursorDone}}${_total// /${CursorNotDone}}${BraketOut} ${_progress}%%"
    fi
}

# Ejemplo de uso de la barra de progreso
for i in $(seq 0 100); do
    progressbar "Cargando" "$i" 100
    sleep 0.1
done
