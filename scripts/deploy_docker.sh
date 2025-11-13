#!/bin/bash
set -e

echo "========================================="
echo "[DOCKER] Déploiement de l'environnement Docker"
echo "========================================="

# Variables
WORKDIR=${1:-/tmp/optivolt-tests}
CONTAINER_NAME="optivolt-test-app"
NETWORK_NAME="optivolt-net"

# Création du répertoire de travail
mkdir -p $WORKDIR
cd $WORKDIR
echo "[DOCKER] Workdir: $WORKDIR"

# Vérification que Docker est disponible
if ! command -v docker &> /dev/null; then
    echo "[DOCKER] ✗ Docker n'est pas installé"
    exit 1
fi

# Test de connexion Docker
if ! docker ps &> /dev/null; then
    echo "[DOCKER] ✗ Docker daemon non accessible"
    echo "[DOCKER] Tentative de démarrage du service..."
    service docker start 2>/dev/null || true
    sleep 2
fi

echo "[DOCKER] ✓ Docker disponible"
docker version --format '{{.Server.Version}}' | head -1

# Nettoyage des conteneurs existants
echo "[DOCKER] Nettoyage des conteneurs précédents..."
docker rm -f $CONTAINER_NAME 2>/dev/null || echo "[DOCKER] Aucun conteneur à nettoyer"

# Création d'un réseau dédié
echo "[DOCKER] Création du réseau $NETWORK_NAME..."
docker network rm $NETWORK_NAME 2>/dev/null || true
docker network create $NETWORK_NAME
echo "[DOCKER] ✓ Réseau créé"

# Création d'un script de test de charge
cat > $WORKDIR/workload.py << 'EOF'
import time
import hashlib
import sys
from datetime import datetime

print(f"[WORKLOAD] Démarrage à {datetime.now()}")
print("[WORKLOAD] Génération de charge CPU...")

iteration = 0
while True:
    # Calcul intensif pour générer de la charge
    data = f"optivolt-test-{iteration}-{time.time()}".encode()
    for _ in range(10000):
        hash_result = hashlib.sha256(data).hexdigest()
    
    iteration += 1
    if iteration % 100 == 0:
        print(f"[WORKLOAD] Iteration {iteration} - {datetime.now()}")
        sys.stdout.flush()
    
    time.sleep(0.01)  # Petite pause pour ne pas saturer
EOF

echo "[DOCKER] ✓ Script de charge créé"

# Déploiement du conteneur avec charge de travail
echo "[DOCKER] Déploiement du conteneur de test..."
docker run -d \
  --name $CONTAINER_NAME \
  --network $NETWORK_NAME \
  --cpus="1.5" \
  --memory="256m" \
  --memory-swap="256m" \
  -v "$WORKDIR:/workload:ro" \
  python:3.11-slim \
  python /workload/workload.py

echo "[DOCKER] ✓ Conteneur démarré"

# Attendre que le conteneur soit bien démarré
sleep 3

# Vérification du déploiement
if docker ps --filter "name=$CONTAINER_NAME" --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
  CONTAINER_ID=$(docker ps --filter "name=$CONTAINER_NAME" --format "{{.ID}}")
  CONTAINER_STATUS=$(docker ps --filter "name=$CONTAINER_NAME" --format "{{.Status}}")
  
  echo ""
  echo "========================================="
  echo "[DOCKER] ✓ Déploiement réussi"
  echo "========================================="
  echo "Container ID:     $CONTAINER_ID"
  echo "Container Name:   $CONTAINER_NAME"
  echo "Status:           $CONTAINER_STATUS"
  echo "Network:          $NETWORK_NAME"
  echo "CPU Limit:        1.5 cores"
  echo "Memory Limit:     256MB"
  echo ""
  
  # Afficher les premières lignes des logs
  echo "[DOCKER] Logs du conteneur:"
  docker logs $CONTAINER_NAME --tail 10
  echo ""
  
  # Statistiques en temps réel
  echo "[DOCKER] Statistiques du conteneur (5 sec):"
  timeout 5 docker stats $CONTAINER_NAME --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" || true
  
  exit 0
else
  echo ""
  echo "========================================="
  echo "[DOCKER] ✗ Échec du déploiement"
  echo "========================================="
  docker logs $CONTAINER_NAME 2>&1 || true
  exit 1
fi
