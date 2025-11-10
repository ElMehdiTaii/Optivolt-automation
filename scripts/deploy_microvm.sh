#!/bin/bash

echo "[MICROVM] Déploiement de l'environnement MicroVM"

# Variables
WORKDIR=${1:-/tmp/optivolt-tests}

mkdir -p $WORKDIR
cd $WORKDIR

# TODO: Implémentation Firecracker
echo "[MICROVM] Configuration Firecracker en cours..."
sleep 2

echo "[MICROVM] ✓ Déploiement simulé (à implémenter)"
exit 0
