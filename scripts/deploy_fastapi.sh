#!/bin/bash
#
# Déploiement de l'API FastAPI dans Docker
#

set -e

API_DIR="/home/ubuntu/optivolt-automation/greenapps/apps"
API_SUBDIR="web_api"
CONTAINER_NAME="optivolt-fastapi"
IMAGE_NAME="optivolt/fastapi:latest"
PORT=8000

echo "=========================================="
echo "  Déploiement API FastAPI"
echo "=========================================="
echo ""

# Arrêter le conteneur existant si présent
if docker ps -a | grep -q "$CONTAINER_NAME"; then
    echo "🛑 Arrêt du conteneur existant..."
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm "$CONTAINER_NAME" 2>/dev/null || true
fi

# Construire l'image Docker (depuis le contexte apps/ pour inclure shared_module)
echo "🔨 Construction de l'image Docker..."
cd "$API_DIR"
docker build -f "${API_SUBDIR}/Dockerfile" -t "$IMAGE_NAME" .

if [ $? -ne 0 ]; then
    echo "❌ Erreur lors de la construction de l'image"
    exit 1
fi

echo "✅ Image construite: $IMAGE_NAME"
echo ""

# Lancer le conteneur
echo "🚀 Démarrage du conteneur..."
docker run -d \
    --name "$CONTAINER_NAME" \
    -p ${PORT}:8000 \
    "$IMAGE_NAME"

if [ $? -ne 0 ]; then
    echo "❌ Erreur lors du démarrage du conteneur"
    exit 1
fi

echo "✅ Conteneur démarré: $CONTAINER_NAME"
echo ""

# Attendre que l'API soit prête
echo "⏳ Attente du démarrage de l'API..."
MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -s -f http://localhost:${PORT}/ > /dev/null 2>&1; then
        echo "✅ API prête!"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    sleep 1
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "❌ L'API n'a pas démarré dans le délai imparti"
    docker logs "$CONTAINER_NAME"
    exit 1
fi

echo ""
echo "=========================================="
echo "  Déploiement réussi!"
echo "=========================================="
echo "URL: http://localhost:${PORT}"
echo "Documentation: http://localhost:${PORT}/docs"
echo ""
echo "Commandes utiles:"
echo "  • Logs: docker logs -f $CONTAINER_NAME"
echo "  • Arrêt: docker stop $CONTAINER_NAME"
echo "  • Stats: docker stats $CONTAINER_NAME"
echo ""
echo "Test rapide:"
echo "  curl http://localhost:${PORT}/simulate/normal"
echo ""

exit 0
