#!/bin/bash

# Verificar si existe el archivo de configuración
if [ ! -e "configuracion_backup.txt" ]; then
    zenity --error --title="Error" --text="El archivo de configuración no existe. Ejecuta configurar_backup.sh primero."
    exit 1
fi

# Cargar la configuración desde el archivo
source "configuracion_backup.txt"

# Crear un identificador único para el backup basado en la fecha y hora
DATE=$(date +%Y-%m-%d-%H%M%S)

# Nombre del archivo de backup
BACKUP_NAME="$DATE.tar.gz"

# Archivo de snapshot para backups incrementales
LOCAL_SNAPSHOT_FILE="$HOME/snapshot.snar"
REMOTE_SNAPSHOT_FILE="$REMOTE_DIR/snapshot.snar"

# Función para realizar el respaldo
backup() {
    tar -czpf "$BACKUP_NAME" $SNAPSHOT_OPTION "$SOURCE"
    scp "$BACKUP_NAME" "$REMOTE_USER@$REMOTE_IP:$REMOTE_DIR/$BACKUP_NAME"
    scp "$LOCAL_SNAPSHOT_FILE" "$REMOTE_USER@$REMOTE_IP:$REMOTE_DIR_SNAP"
    
    # Eliminar el archivo de respaldo local después de transferirlo al servidor
    rm "$BACKUP_NAME"
}

# Cambiar al directorio de respaldos
cd "$BACKUP_DIR" || exit 1

# Realizar el respaldo
backup

