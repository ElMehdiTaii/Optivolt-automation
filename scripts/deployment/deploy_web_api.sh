#!/bin/bash

# Script de déploiement de l'API FastAPI pour OptiVolt

set -e

echo "=========================================="
echo "  OptiVolt - Deploy Web API"
echo "=========================================="

API_DIR="/home/ubuntu/optivolt-automation/greenapps/apps/web_api"
CONTAINER_NAME="optivolt-web-api"
API_PORT="8000"

if ! command -v docker &> /dev/null; then
    echo "[ERROR] Docker is not installed!"
    exit 1
fi

cd "$API_DIR" || exit 1

echo "[INFO] Building Docker image..."
docker build -t optivolt-web-api:latest .

echo "[INFO] Stopping existing container..."
docker stop "$CONTAINER_NAME" 2>/dev/null || true
docker rm "$CONTAINER_NAME" 2>/dev/null || true

echo "[INFO] Starting container..."
docker run -d \
    --name "$CONTAINER_NAME" \
    -p "$API_PORT:8000" \
    --restart unless-stopped \
    optivolt-web-api:latest

sleep 5

MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -s -f "http://localhost:$API_PORT/" > /dev/null 2>&1; then
        echo "[OK] API is ready!"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    sleep 2
done

echo ""
echo "=========================================="
echo "  Deployment Successful!"
echo "=========================================="
echo "API URL: http://localhost:$API_PORT"
echo "Documentation: http://localhost:$API_PORT/docs"
echo "=========================================="

exit 0
