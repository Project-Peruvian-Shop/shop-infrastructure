#!/bin/bash
# start_backend.sh
# Uso: ./start_backend.sh <IP_BACKEND> <KEY_SSH>

set -e

if [ "$#" -ne 2 ]; then
  echo "Uso: $0 <IP_BACKEND> <KEY_SSH>"
  exit 1
fi

IP_BACKEND=$1
KEY_SSH=$2
USUARIO=ubuntu

echo "⚡ Levantando backend en la instancia $IP_BACKEND..."

ssh -o StrictHostKeyChecking=no -i "$KEY_SSH" "$USUARIO@$IP_BACKEND" "
  sudo chown -R $USUARIO:$USUARIO /home/ubuntu/backend
  cd /home/ubuntu/backend
  source /etc/environment
  nohup java -jar *.jar \
    --spring.datasource.url=\$SPRING_DATASOURCE_URL \
    --spring.datasource.username=\$SPRING_DATASOURCE_USERNAME \
    --spring.datasource.password=\$SPRING_DATASOURCE_PASSWORD \
    --spring.profiles.active=\$SPRING_PROFILES_ACTIVE \
    > backend.log 2>&1 &
  echo '✅ Backend iniciado en background. Log en backend.log'
"

