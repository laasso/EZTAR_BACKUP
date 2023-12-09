#!/bin/bash

# Carpeta que se respaldará
SOURCE=$(zenity --file-selection --directory --title="Configuración del respaldo" --text="Selecciona la carpeta a respaldar:")

# Asegurarse de que la carpeta exista
if [ ! -d "$SOURCE" ]; then
    zenity --error --title="Error" --text="La carpeta no existe."
    exit 1
fi

# Usuario remoto
REMOTE_USER=$(zenity --entry --title="Configuración del respaldo" --text="Introduce el nombre de usuario remoto:")

# IP del servidor remoto
REMOTE_IP=$(zenity --entry --title="Configuración del respaldo" --text="Introduce la IP del servidor remoto:")

# Directorio remoto
REMOTE_DIR=$(zenity --entry --title="Configuración del respaldo" --text="Introduce el directorio remoto donde se almacenará el respaldo:")

# Crear un identificador único para el backup basado en la fecha y hora
DATE=$(date +%Y-%m-%d-%H%M%S)

# Nombre del archivo de backup
BACKUP_NAME="$DATE.tar.gz"

# Archivo de snapshot para backups incrementales
LOCAL_SNAPSHOT_FILE="$HOME/snapshot.snar"
REMOTE_SNAPSHOT_FILE="$REMOTE_DIR/snapshot.snar"

# Solicitar la frecuencia del respaldo
FRECUENCIA=$(zenity --entry --title="Configuración del respaldo" --text="Introduce cada cuánto tiempo quieres hacer el respaldo (en minutos):")

# Verificar que la frecuencia sea un número entero
if ! [[ "$FRECUENCIA" =~ ^[0-9]+$ ]]; then
    zenity --error --title="Error" --text="La frecuencia debe ser un número entero."
    exit 1
fi

# Guardar la información en un archivo de configuración
echo "SOURCE=$SOURCE" > configuracion_backup.txt
echo "REMOTE_USER=$REMOTE_USER" >> configuracion_backup.txt
echo "REMOTE_IP=$REMOTE_IP" >> configuracion_backup.txt
echo "REMOTE_DIR=$REMOTE_DIR" >> configuracion_backup.txt
echo "BACKUP_NAME=$BACKUP_NAME" >> configuracion_backup.txt
echo "LOCAL_SNAPSHOT_FILE=$LOCAL_SNAPSHOT_FILE" >> configuracion_backup.txt
echo "REMOTE_SNAPSHOT_FILE=$REMOTE_SNAPSHOT_FILE" >> configuracion_backup.txt
echo "FRECUENCIA=$FRECUENCIA" >> configuracion_backup.txt

# Programar el respaldo usando cron
(crontab -l ; echo "*/$FRECUENCIA * * * * $PWD/ejecutar_backup.sh") | crontab -

# Ejecutar el script de respaldo inmediatamente
bash $PWD/ejecutar_backup.sh

zenity --info --title="Configuración Completada" --text="Configuración completada con éxito. Respaldos programados cada $FRECUENCIA minutos y ejecutado inmediatamente."
