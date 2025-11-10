#!/bin/bash

# Script de collecte des métriques OptiVolt
# Usage: ./collect_metrics.sh <environment> <duration_seconds> <output_file>

ENVIRONMENT=${1:-docker}
DURATION=${2:-30}
OUTPUT_FILE=${3:-/tmp/optivolt-metrics.json}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "[METRICS] Démarrage de la collecte pour: $ENVIRONMENT"
echo "[METRICS] Durée: ${DURATION}s"
echo "[METRICS] Fichier de sortie: $OUTPUT_FILE"

# Créer le répertoire de sortie si nécessaire
mkdir -p $(dirname $OUTPUT_FILE)

# Début de la collecte
START_TIME=$(date +%s)

# Fonction pour collecter les métriques système
collect_system_metrics() {
    # CPU Usage
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    
    # Memory Usage
    MEM_TOTAL=$(free -m | awk 'NR==2{print $2}')
    MEM_USED=$(free -m | awk 'NR==2{print $3}')
    MEM_PERCENT=$(awk "BEGIN {printf \"%.2f\", ($MEM_USED/$MEM_TOTAL)*100}")
    
    # Disk I/O
    DISK_READ=$(iostat -d -k 1 1 | awk 'NR==4{print $3}')
    DISK_WRITE=$(iostat -d -k 1 1 | awk 'NR==4{print $4}')
    
    # Temperature (si disponible)
    if command -v sensors &> /dev/null; then
        TEMP=$(sensors | grep 'Core 0' | awk '{print $3}' | tr -d '+°C')
    else
        TEMP="N/A"
    fi
    
    echo "{\"cpu_usage\":$CPU_USAGE,\"mem_used_mb\":$MEM_USED,\"mem_total_mb\":$MEM_TOTAL,\"mem_percent\":$MEM_PERCENT,\"disk_read_kb\":$DISK_READ,\"disk_write_kb\":$DISK_WRITE,\"temp_celsius\":\"$TEMP\"}"
}

# Fonction pour collecter avec Scaphandre
collect_energy_metrics() {
    # Scaphandre en mode JSON (si RAPL disponible)
    if scaphandre stdout -t 5 2>/dev/null | head -n 1; then
        ENERGY_DATA=$(scaphandre stdout -t 5 2>/dev/null | head -n 1)
        echo "$ENERGY_DATA"
    else
        echo "{\"energy_wh\":\"N/A\",\"power_w\":\"N/A\",\"note\":\"RAPL not available\"}"
    fi
}

# Fonction pour collecter les métriques Docker
collect_docker_metrics() {
    if [ "$ENVIRONMENT" = "docker" ]; then
        CONTAINER_ID=$(docker ps | grep optivolt-test-app | awk '{print $1}')
        
        if [ ! -z "$CONTAINER_ID" ]; then
            # Stats Docker
            DOCKER_CPU=$(docker stats --no-stream --format "{{.CPUPerc}}" $CONTAINER_ID | tr -d '%')
            DOCKER_MEM=$(docker stats --no-stream --format "{{.MemUsage}}" $CONTAINER_ID | awk '{print $1}')
            DOCKER_NET_IN=$(docker stats --no-stream --format "{{.NetIO}}" $CONTAINER_ID | awk '{print $1}')
            DOCKER_NET_OUT=$(docker stats --no-stream --format "{{.NetIO}}" $CONTAINER_ID | awk '{print $3}')
            
            echo "{\"container_id\":\"$CONTAINER_ID\",\"cpu_percent\":$DOCKER_CPU,\"memory\":\"$DOCKER_MEM\",\"net_in\":\"$DOCKER_NET_IN\",\"net_out\":\"$DOCKER_NET_OUT\"}"
        else
            echo "{\"error\":\"No Docker container found\"}"
        fi
    else
        echo "{}"
    fi
}

# Collecte initiale
echo "[METRICS] Collecte des métriques initiales..."
SYSTEM_METRICS_START=$(collect_system_metrics)

# Attendre la durée spécifiée
echo "[METRICS] Surveillance en cours pendant ${DURATION}s..."

# Collecte périodique
SAMPLES=()
INTERVAL=5
NUM_SAMPLES=$((DURATION / INTERVAL))

for i in $(seq 1 $NUM_SAMPLES); do
    SAMPLE=$(collect_system_metrics)
    SAMPLES+=("$SAMPLE")
    sleep $INTERVAL
done

# Collecte finale
SYSTEM_METRICS_END=$(collect_system_metrics)
ENERGY_METRICS=$(collect_energy_metrics)
DOCKER_METRICS=$(collect_docker_metrics)

END_TIME=$(date +%s)
ACTUAL_DURATION=$((END_TIME - START_TIME))

# Calcul des moyennes
AVG_CPU=$(echo "${SAMPLES[@]}" | jq -s 'map(.cpu_usage) | add / length')
AVG_MEM=$(echo "${SAMPLES[@]}" | jq -s 'map(.mem_percent) | add / length')

# Générer le JSON final
cat > $OUTPUT_FILE <<EOF
{
  "metadata": {
    "environment": "$ENVIRONMENT",
    "timestamp": "$TIMESTAMP",
    "duration_seconds": $ACTUAL_DURATION,
    "hostname": "$(hostname)",
    "kernel": "$(uname -r)"
  },
  "system_metrics": {
    "start": $SYSTEM_METRICS_START,
    "end": $SYSTEM_METRICS_END,
    "averages": {
      "cpu_usage_percent": $AVG_CPU,
      "memory_usage_percent": $AVG_MEM
    },
    "samples": [$(IFS=,; echo "${SAMPLES[*]}")]
  },
  "energy_metrics": $ENERGY_METRICS,
  "container_metrics": $DOCKER_METRICS
}
EOF

echo "[METRICS] ✓ Collecte terminée"
echo "[METRICS] Résultats sauvegardés dans: $OUTPUT_FILE"

# Afficher un résumé
echo ""
echo "=== RÉSUMÉ ==="
echo "CPU moyen: ${AVG_CPU}%"
echo "Mémoire moyenne: ${AVG_MEM}%"
echo "Durée: ${ACTUAL_DURATION}s"

cat $OUTPUT_FILE
