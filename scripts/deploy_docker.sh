#!/bin/bash

echo "[DOCKER] Déploiement de l'environnement Docker"

# Variables
WORKDIR=${1:-/tmp/optivolt-tests}

# Création du répertoire de travail
mkdir -p $WORKDIR
cd $WORKDIR

# Nettoyage des conteneurs existants
echo "[DOCKER] Nettoyage des conteneurs précédents..."
docker ps -a | grep optivolt | awk '{print $1}' | xargs -r docker rm -f

# Création d'un réseau dédié
echo "[DOCKER] Création du réseau optivolt-net..."
docker network rm optivolt-net 2>/dev/null || true
docker network create optivolt-net

# Déploiement de l'application de test
echo "[DOCKER] Déploiement de l'application de test..."
docker run -d \
  --name optivolt-test-app \
  --network optivolt-net \
  --cpus="2" \
  --memory="512m" \
  python:3.11-slim \
  python -c "import time; print('Container ready'); time.sleep(3600)"

# Vérification
if docker ps | grep -q optivolt-test-app; then
  echo "[DOCKER] ✓ Déploiement réussi"
  echo "[DOCKER] Container ID: $(docker ps | grep optivolt-test-app | awk '{print $1}')"
  exit 0
else
  echo "[DOCKER] ✗ Échec du déploiement"
  exit 1
fi
