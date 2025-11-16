#!/bin/bash

# Script de collecte des métriques OptiVolt (Version Corrigée)
# Usage: ./collect_metrics.sh <environment> <duration_seconds> <output_file>

ENVIRONMENT=${1:-docker}
DURATION=${2:-30}
OUTPUT_FILE=${3:-/tmp/optivolt-metrics.json}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "[METRICS] Démarrage de la collecte pour: $ENVIRONMENT"
echo "[METRICS] Durée: ${DURATION}s"
echo "[METRICS] Fichier de sortie: $OUTPUT_FILE"

mkdir -p $(dirname $OUTPUT_FILE)

START_TIME=$(date +%s)

# Fonction pour échapper les valeurs JSON
json_escape() {
    local value="$1"
    if [[ "$value" =~ ^[0-9]+\.?[0-9]*$ ]]; then
        # C'est un nombre, pas besoin de guillemets
        echo "$value"
    elif [ "$value" = "N/A" ] || [ -z "$value" ]; then
        # Valeur manquante
        echo "null"
    else
        # Chaîne de caractères, ajouter des guillemets et échapper
        echo "\"$(echo "$value" | sed 's/"/\\"/g')\""
    fi
}

# Fonction pour collecter les métriques système
collect_system_metrics() {
    CPU_USAGE=$(top -bn2 -d 0.5 | grep "Cpu(s)" | tail -n1 | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    
    MEM_TOTAL=$(free -m | awk 'NR==2{print $2}')
    MEM_USED=$(free -m | awk 'NR==2{print $3}')
    MEM_PERCENT=$(awk "BEGIN {printf \"%.2f\", ($MEM_USED/$MEM_TOTAL)*100}")
    
    if command -v iostat &> /dev/null; then
        DISK_READ=$(iostat -d -k 1 1 2>/dev/null | awk 'NR==4{print $3}' || echo "0")
        DISK_WRITE=$(iostat -d -k 1 1 2>/dev/null | awk 'NR==4{print $4}' || echo "0")
    else
        DISK_READ="0"
        DISK_WRITE="0"
    fi
    
    if command -v sensors &> /dev/null; then
        TEMP=$(sensors 2>/dev/null | grep 'Core 0' | awk '{print $3}' | tr -d '+°C' || echo "0")
        [ -z "$TEMP" ] && TEMP="0"
    else
        TEMP="0"
    fi
    
    # S'assurer que toutes les valeurs sont valides
    [ -z "$CPU_USAGE" ] && CPU_USAGE="0"
    [ -z "$DISK_READ" ] && DISK_READ="0"
    [ -z "$DISK_WRITE" ] && DISK_WRITE="0"
    
    echo "{\"cpu_usage\":$CPU_USAGE,\"mem_used_mb\":$MEM_USED,\"mem_total_mb\":$MEM_TOTAL,\"mem_percent\":$MEM_PERCENT,\"disk_read_kb\":$DISK_READ,\"disk_write_kb\":$DISK_WRITE,\"temp_celsius\":$TEMP}"
}

# Fonction pour collecter les métriques Docker
collect_docker_metrics() {
    if [ "$ENVIRONMENT" = "docker" ] || [ "$ENVIRONMENT" = "localhost" ]; then
        CONTAINER_ID=$(docker ps 2>/dev/null | grep optivolt-test-app | awk '{print $1}')
        
        if [ ! -z "$CONTAINER_ID" ]; then
            DOCKER_CPU=$(docker stats --no-stream --format "{{.CPUPerc}}" $CONTAINER_ID 2>/dev/null | tr -d '%' || echo "0")
            DOCKER_MEM=$(docker stats --no-stream --format "{{.MemUsage}}" $CONTAINER_ID 2>/dev/null | awk '{print $1}' || echo "0MiB")
            DOCKER_NET_IN=$(docker stats --no-stream --format "{{.NetIO}}" $CONTAINER_ID 2>/dev/null | awk '{print $1}' || echo "0B")
            DOCKER_NET_OUT=$(docker stats --no-stream --format "{{.NetIO}}" $CONTAINER_ID 2>/dev/null | awk '{print $3}' || echo "0B")
            
            [ -z "$DOCKER_CPU" ] && DOCKER_CPU="0"
            
            echo "{\"container_id\":\"$CONTAINER_ID\",\"cpu_percent\":$DOCKER_CPU,\"memory\":\"$DOCKER_MEM\",\"net_in\":\"$DOCKER_NET_IN\",\"net_out\":\"$DOCKER_NET_OUT\"}"
        else
            echo "{\"note\":\"No Docker container found\"}"
        fi
    else
        echo "{}"
    fi
}

# Fonction pour collecter les métriques Scaphandre (consommation électrique réelle)
collect_scaphandre_metrics() {
    local SCAPH_OUTPUT="/tmp/scaphandre_temp.json"
    
    # Vérifier si Scaphandre est installé et disponible
    if ! command -v scaphandre &> /dev/null; then
        echo "{\"available\":false,\"note\":\"Scaphandre not installed. Run: scripts/setup_scaphandre.sh install\"}"
        return
    fi
    
    # Vérifier si RAPL est disponible
    if [ ! -d "/sys/class/powercap/intel-rapl" ] && [ ! -d "/sys/class/powercap/intel-rapl:0" ]; then
        echo "{\"available\":false,\"note\":\"Intel RAPL not available. CPU may not support power monitoring.\"}"
        return
    fi
    
    # Collecter les métriques pendant 5 secondes
    timeout 5s scaphandre json -t 1 -s > "$SCAPH_OUTPUT" 2>/dev/null || {
        echo "{\"available\":false,\"note\":\"Failed to collect Scaphandre metrics\"}"
        rm -f "$SCAPH_OUTPUT"
        return
    }
    
    # Extraire les données principales si jq est disponible
    if command -v jq &> /dev/null && [ -f "$SCAPH_OUTPUT" ] && [ -s "$SCAPH_OUTPUT" ]; then
        # Extraire la consommation moyenne de l'hôte
        HOST_POWER=$(jq -r '.host.consumption // 0' "$SCAPH_OUTPUT" 2>/dev/null || echo "0")
        SOCKET_POWER=$(jq -r '.host.socket_stats[0].socket_power_microwatts // 0' "$SCAPH_OUTPUT" 2>/dev/null || echo "0")
        
        # Convertir microwatts en watts si nécessaire
        if [ "$SOCKET_POWER" != "0" ] && [ "$SOCKET_POWER" != "null" ]; then
            SOCKET_POWER=$(awk "BEGIN {printf \"%.2f\", $SOCKET_POWER / 1000000}")
        else
            SOCKET_POWER="0"
        fi
        
        # Obtenir les top processus consommateurs
        TOP_PROCESSES=$(jq -c '[.consumers[0:5] | .[] | {pid: .pid, exe: .exe, power_w: .consumption}]' "$SCAPH_OUTPUT" 2>/dev/null || echo "[]")
        
        echo "{\"available\":true,\"host_power_watts\":$HOST_POWER,\"socket_power_watts\":$SOCKET_POWER,\"top_consumers\":$TOP_PROCESSES}"
    else
        # Sans jq, retourner une version simplifiée
        if [ -f "$SCAPH_OUTPUT" ] && [ -s "$SCAPH_OUTPUT" ]; then
            echo "{\"available\":true,\"note\":\"Metrics collected but jq not available for parsing\",\"raw_file\":\"$SCAPH_OUTPUT\"}"
        else
            echo "{\"available\":false,\"note\":\"No metrics collected\"}"
        fi
    fi
    
    # Nettoyer le fichier temporaire
    rm -f "$SCAPH_OUTPUT"
}

# Collecte périodique
echo "[METRICS] Surveillance en cours pendant ${DURATION}s..."
SAMPLES=()
INTERVAL=5
NUM_SAMPLES=$((DURATION / INTERVAL))

for i in $(seq 1 $NUM_SAMPLES); do
    SAMPLE=$(collect_system_metrics)
    SAMPLES+=("$SAMPLE")
    echo "[METRICS] Échantillon $i/$NUM_SAMPLES collecté"
    sleep $INTERVAL
done

DOCKER_METRICS=$(collect_docker_metrics)

# Collecter les métriques Scaphandre (énergie réelle)
echo "[METRICS] Collecte des métriques de consommation électrique (Scaphandre)..."
SCAPHANDRE_METRICS=$(collect_scaphandre_metrics)

END_TIME=$(date +%s)
ACTUAL_DURATION=$((END_TIME - START_TIME))

# Calcul des moyennes
AVG_CPU=0
AVG_MEM=0
COUNT=0

for sample in "${SAMPLES[@]}"; do
    CPU=$(echo $sample | grep -oP '"cpu_usage":\K[0-9.]+' || echo "0")
    MEM=$(echo $sample | grep -oP '"mem_percent":\K[0-9.]+' || echo "0")
    
    AVG_CPU=$(awk "BEGIN {print $AVG_CPU + $CPU}")
    AVG_MEM=$(awk "BEGIN {print $AVG_MEM + $MEM}")
    COUNT=$((COUNT + 1))
done

if [ $COUNT -gt 0 ]; then
    AVG_CPU=$(awk "BEGIN {printf \"%.2f\", $AVG_CPU / $COUNT}")
    AVG_MEM=$(awk "BEGIN {printf \"%.2f\", $AVG_MEM / $COUNT}")
else
    AVG_CPU="0"
    AVG_MEM="0"
fi

# Générer le JSON final (proprement formaté)
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
    "averages": {
      "cpu_usage_percent": $AVG_CPU,
      "memory_usage_percent": $AVG_MEM
    },
    "samples": [$(IFS=,; echo "${SAMPLES[*]}")]
  },
  "energy_metrics": {
    "note": "Real power consumption measured by Scaphandre (if available)",
    "scaphandre": $SCAPHANDRE_METRICS
  },
  "container_metrics": $DOCKER_METRICS
}
EOF

echo "[METRICS] ✓ Collecte terminée"
echo "[METRICS] Résultats sauvegardés dans: $OUTPUT_FILE"
echo ""
echo "=== RÉSUMÉ ==="
echo "CPU moyen: ${AVG_CPU}%"
echo "Mémoire moyenne: ${AVG_MEM}%"
echo "Durée: ${ACTUAL_DURATION}s"
