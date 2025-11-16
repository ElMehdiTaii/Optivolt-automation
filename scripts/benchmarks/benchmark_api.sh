#!/bin/bash
#
# Script de benchmark pour l'API FastAPI
# Teste tous les endpoints et mesure les performances
#

set -e

DURATION=${1:-30}
API_URL=${2:-"http://localhost:8000"}

echo "=========================================="
echo "  Benchmark API FastAPI"
echo "=========================================="
echo "Durée: ${DURATION}s"
echo "URL: ${API_URL}"
echo ""

# Vérifier que l'API est accessible
echo "🔍 Vérification de l'API..."
if ! curl -s -f "${API_URL}/" > /dev/null 2>&1; then
    echo "❌ Erreur: API non accessible sur ${API_URL}"
    exit 1
fi
echo "✅ API accessible"
echo ""

# Préparer les résultats
RESULTS_FILE="api_benchmark_results.json"
START_TIME=$(date +%s)
END_TIME=$((START_TIME + DURATION))

# Compteurs
COUNT_GET_NORMAL=0
COUNT_GET_HEAVY=0
COUNT_GET_DELAY=0
COUNT_POST_NORMAL=0
COUNT_POST_HEAVY=0
COUNT_POST_DELAY=0
TOTAL_REQUESTS=0
FAILED_REQUESTS=0

# Variables pour latence
TOTAL_LATENCY=0
MIN_LATENCY=999999
MAX_LATENCY=0

echo "🚀 Démarrage du benchmark..."
echo ""

# Fonction pour mesurer la latence
measure_request() {
    local url=$1
    local method=$2
    local data=$3
    
    local start=$(date +%s%3N)  # milliseconds
    
    if [ "$method" == "GET" ]; then
        if curl -s -f -o /dev/null -w "%{http_code}" "$url" > /dev/null 2>&1; then
            local end=$(date +%s%3N)
            local latency=$((end - start))
            echo $latency
            return 0
        fi
    else
        if curl -s -f -X POST -H "Content-Type: application/json" \
             -d "$data" -o /dev/null -w "%{http_code}" "$url" > /dev/null 2>&1; then
            local end=$(date +%s%3N)
            local latency=$((end - start))
            echo $latency
            return 0
        fi
    fi
    
    return 1
}

# Boucle de benchmark
while [ $(date +%s) -lt $END_TIME ]; do
    # Test 1: GET /simulate/normal
    if latency=$(measure_request "${API_URL}/simulate/normal" "GET"); then
        COUNT_GET_NORMAL=$((COUNT_GET_NORMAL + 1))
        TOTAL_LATENCY=$((TOTAL_LATENCY + latency))
        [ $latency -lt $MIN_LATENCY ] && MIN_LATENCY=$latency
        [ $latency -gt $MAX_LATENCY ] && MAX_LATENCY=$latency
    else
        FAILED_REQUESTS=$((FAILED_REQUESTS + 1))
    fi
    
    # Test 2: GET /simulate/heavy?size_kb=100
    if latency=$(measure_request "${API_URL}/simulate/heavy?size_kb=100" "GET"); then
        COUNT_GET_HEAVY=$((COUNT_GET_HEAVY + 1))
        TOTAL_LATENCY=$((TOTAL_LATENCY + latency))
        [ $latency -lt $MIN_LATENCY ] && MIN_LATENCY=$latency
        [ $latency -gt $MAX_LATENCY ] && MAX_LATENCY=$latency
    else
        FAILED_REQUESTS=$((FAILED_REQUESTS + 1))
    fi
    
    # Test 3: GET /simulate/delay?ms=50
    if latency=$(measure_request "${API_URL}/simulate/delay?ms=50" "GET"); then
        COUNT_GET_DELAY=$((COUNT_GET_DELAY + 1))
        TOTAL_LATENCY=$((TOTAL_LATENCY + latency))
        [ $latency -lt $MIN_LATENCY ] && MIN_LATENCY=$latency
        [ $latency -gt $MAX_LATENCY ] && MAX_LATENCY=$latency
    else
        FAILED_REQUESTS=$((FAILED_REQUESTS + 1))
    fi
    
    # Test 4: POST /simulate/normal
    if latency=$(measure_request "${API_URL}/simulate/normal" "POST" '{"content":"test data"}'); then
        COUNT_POST_NORMAL=$((COUNT_POST_NORMAL + 1))
        TOTAL_LATENCY=$((TOTAL_LATENCY + latency))
        [ $latency -lt $MIN_LATENCY ] && MIN_LATENCY=$latency
        [ $latency -gt $MAX_LATENCY ] && MAX_LATENCY=$latency
    else
        FAILED_REQUESTS=$((FAILED_REQUESTS + 1))
    fi
    
    # Test 5: POST /simulate/heavy
    if latency=$(measure_request "${API_URL}/simulate/heavy" "POST" '{"size_kb":50}'); then
        COUNT_POST_HEAVY=$((COUNT_POST_HEAVY + 1))
        TOTAL_LATENCY=$((TOTAL_LATENCY + latency))
        [ $latency -lt $MIN_LATENCY ] && MIN_LATENCY=$latency
        [ $latency -gt $MAX_LATENCY ] && MAX_LATENCY=$latency
    else
        FAILED_REQUESTS=$((FAILED_REQUESTS + 1))
    fi
    
    # Test 6: POST /simulate/delay
    if latency=$(measure_request "${API_URL}/simulate/delay" "POST" '{"content":"test","ms":50}'); then
        COUNT_POST_DELAY=$((COUNT_POST_DELAY + 1))
        TOTAL_LATENCY=$((TOTAL_LATENCY + latency))
        [ $latency -lt $MIN_LATENCY ] && MIN_LATENCY=$latency
        [ $latency -gt $MAX_LATENCY ] && MAX_LATENCY=$latency
    else
        FAILED_REQUESTS=$((FAILED_REQUESTS + 1))
    fi
    
    TOTAL_REQUESTS=$((COUNT_GET_NORMAL + COUNT_GET_HEAVY + COUNT_GET_DELAY + \
                      COUNT_POST_NORMAL + COUNT_POST_HEAVY + COUNT_POST_DELAY))
    
    # Afficher progression toutes les 100 requêtes
    if [ $((TOTAL_REQUESTS % 100)) -eq 0 ]; then
        echo "  Progression: ${TOTAL_REQUESTS} requêtes..."
    fi
    
    # Petite pause pour ne pas surcharger
    sleep 0.01
done

# Calculer les statistiques
ACTUAL_DURATION=$(($(date +%s) - START_TIME))
REQUESTS_PER_SECOND=$((TOTAL_REQUESTS / ACTUAL_DURATION))
AVG_LATENCY=$((TOTAL_LATENCY / TOTAL_REQUESTS))
SUCCESS_RATE=$((100 - (FAILED_REQUESTS * 100 / (TOTAL_REQUESTS + FAILED_REQUESTS))))

echo ""
echo "=========================================="
echo "  Résultats du Benchmark"
echo "=========================================="
echo "Durée réelle: ${ACTUAL_DURATION}s"
echo ""
echo "📊 Statistiques globales:"
echo "  • Total requêtes: ${TOTAL_REQUESTS}"
echo "  • Requêtes/seconde: ${REQUESTS_PER_SECOND}"
echo "  • Taux de succès: ${SUCCESS_RATE}%"
echo "  • Requêtes échouées: ${FAILED_REQUESTS}"
echo ""
echo "⏱️  Latence:"
echo "  • Moyenne: ${AVG_LATENCY}ms"
echo "  • Minimum: ${MIN_LATENCY}ms"
echo "  • Maximum: ${MAX_LATENCY}ms"
echo ""
echo "🔷 Détail par endpoint:"
echo "  GET /simulate/normal: ${COUNT_GET_NORMAL} requêtes"
echo "  GET /simulate/heavy:  ${COUNT_GET_HEAVY} requêtes"
echo "  GET /simulate/delay:  ${COUNT_GET_DELAY} requêtes"
echo "  POST /simulate/normal: ${COUNT_POST_NORMAL} requêtes"
echo "  POST /simulate/heavy:  ${COUNT_POST_HEAVY} requêtes"
echo "  POST /simulate/delay:  ${COUNT_POST_DELAY} requêtes"
echo ""

# Générer le fichier JSON de résultats
cat > "$RESULTS_FILE" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "duration_seconds": ${ACTUAL_DURATION},
  "total_requests": ${TOTAL_REQUESTS},
  "requests_per_second": ${REQUESTS_PER_SECOND},
  "success_rate": ${SUCCESS_RATE},
  "failed_requests": ${FAILED_REQUESTS},
  "latency": {
    "average_ms": ${AVG_LATENCY},
    "min_ms": ${MIN_LATENCY},
    "max_ms": ${MAX_LATENCY}
  },
  "endpoints": {
    "get_normal": ${COUNT_GET_NORMAL},
    "get_heavy": ${COUNT_GET_HEAVY},
    "get_delay": ${COUNT_GET_DELAY},
    "post_normal": ${COUNT_POST_NORMAL},
    "post_heavy": ${COUNT_POST_HEAVY},
    "post_delay": ${COUNT_POST_DELAY}
  }
}
EOF

echo "💾 Résultats sauvegardés dans: ${RESULTS_FILE}"
echo "=========================================="

exit 0
