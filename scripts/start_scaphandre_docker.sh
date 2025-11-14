#!/bin/bash

echo "========================================="
echo "  Scaphandre via Docker"
echo "========================================="

CONTAINER_NAME=${1:-"scaphandre-exporter"}
PORT=${2:-8080}

echo "🐳 Démarrage de Scaphandre dans Docker..."
echo "   Container: $CONTAINER_NAME"
echo "   Port: $PORT"

# Arrêter le container existant
docker rm -f "$CONTAINER_NAME" 2>/dev/null

# Lancer Scaphandre (avec --vm pour les environnements virtualisés)
docker run -d \
  --name "$CONTAINER_NAME" \
  --privileged \
  -v /sys/class/powercap:/sys/class/powercap:ro \
  -v /proc:/proc:ro \
  -p ${PORT}:8080 \
  hubblo/scaphandre:latest prometheus --vm

if [ $? -eq 0 ]; then
    echo "✅ Scaphandre démarré avec succès!"
    echo ""
    echo "📊 Métriques disponibles sur:"
    echo "   http://localhost:${PORT}/metrics"
    echo ""
    echo "🔍 Tester:"
    echo "   curl http://localhost:${PORT}/metrics"
    echo ""
    echo "📝 Logs:"
    echo "   docker logs -f $CONTAINER_NAME"
else
    echo "❌ Échec du démarrage"
    exit 1
fi
