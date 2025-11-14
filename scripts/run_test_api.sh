#!/bin/bash

DURATION=${1:-30}

echo "[TEST API] Démarrage du test API pour ${DURATION}s"

# Vérifier si curl est disponible
if ! command -v curl &> /dev/null; then
    echo "[TEST API] Installation de curl..."
    apk add --no-cache curl 2>/dev/null || apt-get install -y curl 2>/dev/null
fi

# Test de charge API simple avec httpbin
END_TIME=$(($(date +%s) + DURATION))

COUNT=0
while [ $(date +%s) -lt $END_TIME ]; do
    curl -s http://httpbin.org/get > /dev/null 2>&1 || \
    echo '{"test": "ok"}' > /dev/null
    COUNT=$((COUNT + 1))
    sleep 0.1
done

echo "[TEST API] ✓ Test terminé - $COUNT requêtes"
exit 0
