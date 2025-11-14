#!/bin/bash

# Script de test API amélioré pour OptiVolt
# Teste les performances de l'API FastAPI

set -e

DURATION=${1:-30}
API_HOST=${2:-"localhost:8000"}

echo "=========================================="
echo "  OptiVolt - Test API Performance"
echo "=========================================="
echo "Duration: ${DURATION}s"
echo "API Host: ${API_HOST}"
echo "=========================================="
echo ""

# Vérifier que curl et jq sont disponibles
if ! command -v curl &> /dev/null; then
    echo "[INSTALL] Installing curl..."
    apk add --no-cache curl 2>/dev/null || apt-get install -y curl 2>/dev/null || yum install -y curl
fi

if ! command -v jq &> /dev/null; then
    echo "[INSTALL] Installing jq..."
    apk add --no-cache jq 2>/dev/null || apt-get install -y jq 2>/dev/null || yum install -y jq
fi

# Attendre que l'API soit disponible
echo "[WAIT] Waiting for API to be ready..."
MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -s -f "http://${API_HOST}/" > /dev/null 2>&1; then
        echo "[OK] API is ready!"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "[WAIT] Attempt $RETRY_COUNT/$MAX_RETRIES..."
    sleep 2
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "[ERROR] API not available after ${MAX_RETRIES} attempts"
    exit 1
fi

# Variables pour les statistiques
START_TIME=$(date +%s)
END_TIME=$((START_TIME + DURATION))

TOTAL_REQUESTS=0
SUCCESS_COUNT=0
FAILURE_COUNT=0
TOTAL_RESPONSE_TIME=0

# Fichier temporaire pour stocker les résultats
RESULTS_FILE="/tmp/api_test_results_$$.json"

echo "" > "$RESULTS_FILE"
echo "[TEST] Starting load test..."
echo ""

# Fonction pour tester un endpoint
test_endpoint() {
    local endpoint=$1
    local method=$2
    local data=$3
    
    local start=$(date +%s%3N)
    
    if [ "$method" == "GET" ]; then
        response=$(curl -s -w "\n%{http_code}" "http://${API_HOST}${endpoint}" 2>/dev/null)
    else
        response=$(curl -s -w "\n%{http_code}" -X POST \
            -H "Content-Type: application/json" \
            -d "$data" \
            "http://${API_HOST}${endpoint}" 2>/dev/null)
    fi
    
    local end=$(date +%s%3N)
    local duration=$((end - start))
    
    http_code=$(echo "$response" | tail -n1)
    
    TOTAL_REQUESTS=$((TOTAL_REQUESTS + 1))
    TOTAL_RESPONSE_TIME=$((TOTAL_RESPONSE_TIME + duration))
    
    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        echo "✓ ${method} ${endpoint} - ${duration}ms - HTTP ${http_code}"
    else
        FAILURE_COUNT=$((FAILURE_COUNT + 1))
        echo "✗ ${method} ${endpoint} - ${duration}ms - HTTP ${http_code}"
    fi
}

# Boucle de test principale
REQUEST_CYCLE=0

while [ $(date +%s) -lt $END_TIME ]; do
    REQUEST_CYCLE=$((REQUEST_CYCLE + 1))
    
    # Test 1: GET /simulate/normal (requête légère)
    test_endpoint "/simulate/normal" "GET"
    
    # Test 2: GET /simulate/heavy (réponse lourde)
    test_endpoint "/simulate/heavy?size_kb=100" "GET"
    
    # Test 3: POST /simulate/normal (envoi de données)
    test_endpoint "/simulate/normal" "POST" '{"content":"Test data from OptiVolt"}'
    
    # Test 4: POST /simulate/heavy (traitement lourd)
    test_endpoint "/simulate/heavy" "POST" '{"size_kb":50}'
    
    # Test 5: GET avec délai
    if [ $((REQUEST_CYCLE % 5)) -eq 0 ]; then
        test_endpoint "/simulate/delay?ms=100" "GET"
    fi
    
    # Pause courte entre les cycles
    sleep 0.1
done

# Calculer les statistiques
ELAPSED_TIME=$(($(date +%s) - START_TIME))
AVG_RESPONSE_TIME=$((TOTAL_RESPONSE_TIME / TOTAL_REQUESTS))
REQUESTS_PER_SEC=$((TOTAL_REQUESTS / ELAPSED_TIME))
SUCCESS_RATE=$((SUCCESS_COUNT * 100 / TOTAL_REQUESTS))

# Sauvegarder les résultats en JSON
cat > "$RESULTS_FILE" <<EOF
{
  "test_type": "api",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "duration_seconds": $ELAPSED_TIME,
  "api_host": "$API_HOST",
  "metrics": {
    "total_requests": $TOTAL_REQUESTS,
    "successful_requests": $SUCCESS_COUNT,
    "failed_requests": $FAILURE_COUNT,
    "success_rate_percent": $SUCCESS_RATE,
    "average_response_time_ms": $AVG_RESPONSE_TIME,
    "requests_per_second": $REQUESTS_PER_SEC,
    "total_response_time_ms": $TOTAL_RESPONSE_TIME
  },
  "endpoints_tested": [
    "/simulate/normal (GET)",
    "/simulate/heavy (GET)",
    "/simulate/normal (POST)",
    "/simulate/heavy (POST)",
    "/simulate/delay (GET)"
  ],
  "status": "completed"
}
EOF

echo ""
echo "=========================================="
echo "  Test Results"
echo "=========================================="
echo "Total Requests:     $TOTAL_REQUESTS"
echo "Successful:         $SUCCESS_COUNT"
echo "Failed:             $FAILURE_COUNT"
echo "Success Rate:       ${SUCCESS_RATE}%"
echo "Avg Response Time:  ${AVG_RESPONSE_TIME}ms"
echo "Requests/sec:       $REQUESTS_PER_SEC"
echo "Elapsed Time:       ${ELAPSED_TIME}s"
echo "=========================================="
echo ""
echo "[SAVE] Results saved to: $RESULTS_FILE"

# Copier les résultats vers api_results.json (pour OptiVoltCLI)
cp "$RESULTS_FILE" "api_results.json" 2>/dev/null || true

echo "[OK] Test completed successfully!"
exit 0
