#!/bin/bash
#
# Test de performance de l'API FastAPI
# Utilise le script de benchmark dédié
#

DURATION=${1:-30}
API_URL=${2:-"http://localhost:8000"}

echo "=========================================="
echo "  Test API FastAPI - OptiVolt"
echo "=========================================="
echo "Durée: ${DURATION}s"
echo "URL: ${API_URL}"
echo ""

# Vérifier que curl est disponible
if ! command -v curl &> /dev/null; then
    echo "Installation de curl..."
    apk add --no-cache curl 2>/dev/null || apt-get install -y curl 2>/dev/null
fi

# Vérifier que l'API est accessible
echo "Vérification de l'API..."
if ! curl -s -f "${API_URL}/" > /dev/null 2>&1; then
    echo "❌ Erreur: API non accessible sur ${API_URL}"
    echo "Assurez-vous que l'API est démarrée avec:"
    echo "  ./scripts/deploy_fastapi.sh"
    exit 1
fi

echo "✅ API accessible"
echo ""

# Utiliser le script de benchmark
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"${SCRIPT_DIR}/benchmark_api.sh" "$DURATION" "$API_URL"

exit $?
