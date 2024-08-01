#!/bin/bash

# Configuración inicial
ARCH_LINUX_URL="http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-armv7-latest.tar.gz"
IMAGE_PATH="$HOME/Downloads/ArchLinuxARM-rpi-armv7-latest.tar.gz"
SD_CARD="/dev/sdb"  # Cambia esto a la ruta de tu tarjeta SD (e.g., /dev/sdb)

# Verificar permisos de superusuario
if [[ $EUID -ne 0 ]]; then
   echo "Este script debe ejecutarse con permisos de superusuario (root)." 
   exit 0
fi

# Descargar la imagen de Arch Linux ARM
echo "Descargando la imagen de Arch Linux ARM..."
#wget $ARCH_LINUX_URL

# Formatear la tarjeta SD
echo "Formateando la tarjeta SD..."
fdisk $SD_CARD <<EOT
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
echo "Creando sistema de archivos..."
mkfs.vfat ${SD_CARD}1
mkdir boot
mount ${SD_CARD}1 boot

# Montar la tarjeta SD
mkfs.ext4 ${SD_CARD}2
mkdir root
mount ${SD_CARD}2 root

# Extraer la imagen
echo "Extrayendo la imagen..."
tar -xzf ArchLinuxARM* -C root/ >&/dev/null

# Sincronizar y desmontar
echo "Sincronizando y desmontando..."
sync
mv root/boot/* boot
umount boot root

echo "La instalación de Arch Linux ARM en la Raspberry Pi 3 B se ha completado."
