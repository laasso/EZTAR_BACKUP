#!/bin/bash

# Función para obtener información de forma interactiva
get_info() {
    local prompt="$1"
    local default="$2"
    local result

    result=$(zenity --entry --title="Configuración del respaldo" --text="$prompt" --entry-text="$default" 2>/dev/null)

    if [ $? -ne 0 ]; then
        # Si el usuario cancela, salimos del script
        exit 1
    fi

    echo "$result"
}

# Carpeta que se respaldará
SOURCE=$(zenity --file-selection --directory --title="Configuración del respaldo" --text="Selecciona la carpeta a respaldar:")

# Asegurarse de que la carpeta exista
if [ ! -d "$SOURCE" ]; then
    zenity --error --title="Error" --text="La carpeta no existe."
    exit 1
fi

# Resto de la configuración
REMOTE_USER=$(get_info "Introduce el nombre de usuario remoto:" "")
REMOTE_IP=$(get_info "Introduce la IP del servidor remoto:" "")
REMOTE_DIR=$(get_info "Introduce el directorio remoto donde se almacenará el respaldo:" "")
DATE=$(date +%Y-%m-%d-%H%M%S)
BACKUP_NAME="$DATE.tar.gz"
LOCAL_SNAPSHOT_FILE="$HOME/snapshot.snar"
REMOTE_SNAPSHOT_FILE="$REMOTE_DIR/snapshot.snar"

# Generar un par de claves SSH
ssh-keygen -t rsa -N "" -f "$HOME/.ssh/id_rsa"

# Copiar la clave pública al servidor remoto
ssh-copy-id -i "$HOME/.ssh/id_rsa.pub" "$REMOTE_USER@$REMOTE_IP"

# Solicitar la frecuencia del respaldo
FRECUENCIA=$(get_info "Introduce cada cuánto tiempo quieres hacer el respaldo (en minutos): ")

# Verificar que la frecuencia sea un número entero
if ! [[ "$FRECUENCIA" =~ ^[0-9]+$ ]]; then
    zenity --error --title="Error" --text="La frecuencia debe ser un número entero."
    exit 1
fi

# Eliminar todas las entradas existentes en el crontab
crontab -r

# Programar el respaldo usando cron
(crontab -l ; echo "*/$FRECUENCIA * * * * $PWD/ejecutar_backup.sh >> /home/lasso/log.txt 2>&1") | crontab -

# Ejecutar el script de respaldo inmediatamente
bash $PWD/ejecutar_backup.sh

zenity --info --title="Configuración Completada" --text="Configuración completada con éxito. Respaldos programados cada $FRECUENCIA minutos y ejecutado inmediatamente."
