#!/bin/bash
# backend.sh
# Uso: ./backend.sh <IP_FRONTEND> <IP_BACKEND> <KEY_SSH>

set -e

if [ "$#" -ne 2 ]; then
  echo "Uso: $0 <IP_BACKEND> <KEY_SSH>"
  exit 1
fi

IP_BACKEND=$1
KEY_SSH=$2
USUARIO=ubuntu

# Rutas locales
REPO_BACKEND_LOCAL="./backend"
REPO_BACKEND_URL="git@github.com:Project-Peruvian-Shop/shop-backend.git"
BRANCH="main"

# --- BACKEND ---
echo "📥 Eliminar carpeta local del backend..."
rm -rf "$REPO_BACKEND_LOCAL"

echo "🆕 Clonando repo en la rama $BRANCH..."
git clone -b $BRANCH "$REPO_BACKEND_URL" "$REPO_BACKEND_LOCAL"
cd "$REPO_BACKEND_LOCAL" || exit 1

# --- Activar environment local (si existe) ---
if [ -f "../environment" ]; then
  echo "🌐 Activando environment..."
  source ../environment
fi

# --- Compilar backend ---
echo "💻 Compilando backend..."
chmod +x mvnw
./mvnw clean package -DskipTests

# --- Subir backend a la instancia EC2 ---
echo "🚀 Subiendo backend a la instancia $IP_BACKEND..."
ssh -o StrictHostKeyChecking=no -i "$KEY_SSH" "$USUARIO@$IP_BACKEND" "mkdir -p /home/ubuntu/backend"
scp -o StrictHostKeyChecking=no -i "$KEY_SSH" target/*.jar "$USUARIO@$IP_BACKEND:/home/ubuntu/backend/"

# --- Ajustar permisos y levantar backend ---
echo "⚡ Levantando backend en la instancia..."
ssh -o StrictHostKeyChecking=no -i "$KEY_SSH" "$USUARIO@$IP_BACKEND" "
  sudo chown -R $USUARIO:$USUARIO /home/ubuntu/backend
  cd /home/ubuntu/backend
  exit
"

echo "✅ Deploy del backend completado!"
