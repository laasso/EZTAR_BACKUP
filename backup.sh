REMOTE_USER = iker
REMOTE_IP = 192.168.1.175
REMOTE_DIR=$REMOTE_FOLDER
DATE=$(date +%Y-%m-%d-%H%M%S)
BACKUP_NAME=$BACKUP_DIR/$DATE.tar.gz
SNAPSHOT_FILE=$BACKUP_DIR/snapshot.snar


read -p "Introduce la IP del servidor remoto: " REMOTE_IP

read -p "Introduce la carpeta del servidor remoto: " REMOTE_FOLDER

read -p "Introduce la carpeta a respaldar (ruta completa): " SOURCE
if [ ! -d "$SOURCE" ]; then
	echo "Error: La carpeta no existe."
	exit 1
fi

read -p "¿Quieres que sea un respaldo incremental? (si/no): " INCREMENTAL
if [ "$INCREMENTAL" = "si" ]; then
	SNAPSHOT_OPTION="-g $SNAPSHOT_FILE"
else
	SNAPSHOT_OPTION=""
fi

read -p "Introduce cada cuánto tiempo quieres hacer el respaldo (en minutos): " FRECUENCIA

if [ ! -e "$HOME/.ssh/id_rsa" ]; then
	echo "Configurando clave pública/privada para autenticación sin contraseña..."
	ssh-keygen -t rsa -N "" -f "$HOME/.ssh/id_rsa"
fi

ssh-copy-id -i "$HOME/.ssh/id_rsa" $REMOTE_USER@$REMOTE_IP

ssh $REMOTE_USER@$REMOTE_IP "mkdir -p $REMOTE_DIR"

exit

(crontab -l ; echo "*/$FRECUENCIA * * * * $0") | crontab -

backup() {
	tar -cvzpf $BACKUP_NAME $SNAPSHOT_OPTION $SOURCE
	scp $BACKUP_NAME $REMOTE_USER@$REMOTE_IP:$REMOTE_DIR
	scp $SNAPSHOT_FILE $REMOTE_USER@$REMOTE_IP:$REMOTE_DIR
}

backup
