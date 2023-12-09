#!/bin/bash

# VARIABLES

# Directorio donde se guardarán los backups localmente
BACKUP_DIR="/home/alumne_2n/backups"
# Carpeta que se respaldará
SOURCE="$HOME/directori"
# Usuario remoto
REMOTE_USER=iker
# IP del servidor remoto
REMOTE_IP=192.168.1.82
# Directorio remoto
REMOTE_DIR=/home/iker/backups
# Crear un identificador único para el backup basado en la fecha y hora
DATE=$(date +%Y-%m-%d-%H%M%S)
# Nombre del archivo de backup
BACKUP_NAME=$BACKUP_DIR/$DATE.tar.gz
# Archivo de snapshot para backups incrementales
SNAPSHOT_FILE=$BACKUP_DIR/snapshot.snar

# FIN DE VARIABLES

# Configurar clave pública/privada si no está configurada
if [ ! -e "$HOME/.ssh/id_rsa" ]; then
    echo "Configurando clave pública/privada para autenticación sin contraseña..."
    ssh-keygen -t rsa -N "" -f "$HOME/.ssh/id_rsa"
fi

# Agregar la clave pública al servidor remoto si no está presente
ssh-copy-id -i "$HOME/.ssh/id_rsa" $REMOTE_USER@$REMOTE_IP

# Solicitar al usuario la información necesaria con Zenity

# Solicitar la IP del servidor remoto
REMOTE_IP=$(zenity --entry --title="Configuración del respaldo" --text="Introduce la IP del servidor remoto:")

# Solicitar la carpeta a respaldar
SOURCE=$(zenity --file-selection --directory --title="Configuración del respaldo" --text="Selecciona la carpeta a respaldar:")

# Asegurarse de que la carpeta exista
if [ ! -d "$SOURCE" ]; then
    zenity --error --title="Error" --text="La carpeta no existe."
    exit 1
fi

# Solicitar si el respaldo será incremental o diferencial
INCREMENTAL=$(zenity --list --title="Configuración del respaldo" --text="¿Quieres que sea un respaldo incremental?" --radiolist --column="" --column="Opción" FALSE "No" TRUE "Sí")

# En caso de ser incremental, establecer el archivo de snapshot
SNAPSHOT_OPTION=""
if [ "$INCREMENTAL" = "Sí" ]; then
    SNAPSHOT_OPTION="-g $SNAPSHOT_FILE"
fi

# Solicitar la frecuencia del respaldo
FRECUENCIA=$(zenity --entry --title="Configuración del respaldo" --text="Introduce cada cuánto tiempo quieres hacer el respaldo (en minutos):")

# Programar el respaldo usando cron
(crontab -l ; echo "*/$FRECUENCIA * * * * $0") | crontab -

# Función para realizar el respaldo
backup() {
    tar -cvzpf $BACKUP_NAME $SNAPSHOT_OPTION $SOURCE
    scp $BACKUP_NAME $REMOTE_USER@$REMOTE_IP:$REMOTE_DIR
    scp $SNAPSHOT_FILE $REMOTE_USER@$REMOTE_IP:$REMOTE_DIR
}

# Realizar el respaldo inmediato
backup
