#!/bin/bash

echo "[UNIKERNEL] Déploiement de l'environnement Unikernel"

# Variables
WORKDIR=${1:-/tmp/optivolt-tests}

mkdir -p $WORKDIR
cd $WORKDIR

# TODO: Implémentation Unikraft
echo "[UNIKERNEL] Configuration Unikraft en cours..."
sleep 2

echo "[UNIKERNEL] ✓ Déploiement simulé (à implémenter)"
exit 0
