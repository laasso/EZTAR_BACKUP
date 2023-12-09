#!/bin/bash

# Solicitar al usuario la información necesaria con Zenity

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

# Configurar clave pública/privada si no está configurada
if [ ! -e "$HOME/.ssh/id_rsa" ]; then
    zenity --info --title="Configuración" --text="Configurando clave pública/privada para autenticación sin contraseña..."
    ssh-keygen -t rsa -N "" -f "$HOME/.ssh/id_rsa"
fi

# Agregar la clave pública al servidor remoto si no está presente
ssh-copy-id -i "$HOME/.ssh/id_rsa" $REMOTE_USER@$REMOTE_IP

# Crear el directorio remoto si no existe
ssh $REMOTE_USER@$REMOTE_IP "mkdir -p $REMOTE_DIR"

# Verificar si existe un archivo de snapshot previo para respaldos incrementales
if [ -e "$REMOTE_SNAPSHOT_FILE" ]; then
    INCREMENTAL="true"
    zenity --info --title="Respaldo Incremental" --text="Se realizará un respaldo incremental."
else
    INCREMENTAL="false"
    # Crear un archivo snapshot inicial si no existe
    touch "$LOCAL_SNAPSHOT_FILE"
    scp "$LOCAL_SNAPSHOT_FILE" $REMOTE_USER@$REMOTE_IP:$REMOTE_SNAPSHOT_FILE
fi

# Realizar el respaldo

# Cambiar al directorio antes de crear el archivo tar
cd $SOURCE

# Crear el archivo tar localmente (incremental si es necesario)
if [ "$INCREMENTAL" = "true" ]; then
    tar -czpf $BACKUP_NAME --listed-incremental="$LOCAL_SNAPSHOT_FILE" .
else
    tar -czpf $BACKUP_NAME .
fi

# Copiar el archivo tar al servidor remoto
zenity --info --title="Transferencia" --text="Transfiriendo el respaldo al servidor remoto..."
scp $BACKUP_NAME $REMOTE_USER@$REMOTE_IP:$REMOTE_DIR/$BACKUP_NAME

# Eliminar el archivo tar local después de la transferencia
rm $BACKUP_NAME

# Notificar al usuario
zenity --info --title="Respaldo Completado" --text="Respaldo completado con éxito."
