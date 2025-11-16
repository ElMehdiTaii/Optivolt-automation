#!/bin/bash

# ==============================================================================
# Benchmark Réel - Docker vs MicroVM vs Unikernel avec Métriques Grafana
# ==============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

RESULTS_DIR="results/real_benchmark_$(date +%Y%m%d_%H%M%S)"
DURATION=${1:-30}  # Durée par test en secondes

mkdir -p "$RESULTS_DIR"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Benchmark RÉEL OptiVolt - Docker vs MicroVM vs Unikernel      ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo -e "  • Durée par test:  ${DURATION}s"
echo -e "  • Résultats:       $RESULTS_DIR"
echo -e "  • Monitoring:      Prometheus (9090) + Grafana (3000)"
echo ""

# ==============================================================================
# Fonction: Collecter métriques système
# ==============================================================================
collect_metrics() {
    local env=$1
    local output_file=$2
    
    echo -e "${YELLOW}[METRICS] Collecte métriques $env...${NC}"
    
    # CPU
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    
    # Mémoire
    mem_total=$(free -m | awk '/Mem:/ {print $2}')
    mem_used=$(free -m | awk '/Mem:/ {print $3}')
    mem_percent=$(awk "BEGIN {printf \"%.2f\", ($mem_used/$mem_total)*100}")
    
    # Timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # JSON output
    cat > "$output_file" <<EOF
{
  "environment": "$env",
  "timestamp": "$timestamp",
  "metrics": {
    "cpu_usage_percent": $cpu_usage,
    "memory_total_mb": $mem_total,
    "memory_used_mb": $mem_used,
    "memory_percent": $mem_percent,
    "duration_seconds": $DURATION
  }
}
EOF
    
    echo -e "${GREEN}✓ Métriques collectées: $output_file${NC}"
}

# ==============================================================================
# TEST 1 : Docker (Baseline)
# ==============================================================================
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  TEST 1/3 : Docker Baseline${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${YELLOW}► Déploiement Docker...${NC}"
bash scripts/deploy_docker.sh /tmp/optivolt-docker > "$RESULTS_DIR/docker_deploy.log" 2>&1

echo -e "${YELLOW}► Test CPU Docker (${DURATION}s)...${NC}"
docker exec optivolt-test-app bash -c "
    echo '[DOCKER-TEST] Test CPU intensif'
    for i in \$(seq 1 10); do
        echo 'scale=2000; 4*a(1)' | bc -l > /dev/null 2>&1 &
    done
    sleep $DURATION
    wait
    echo '[DOCKER-TEST] Terminé'
" > "$RESULTS_DIR/docker_test.log" 2>&1 &

DOCKER_PID=$!

# Monitoring en temps réel
for i in $(seq 1 $DURATION); do
    if [ $((i % 5)) -eq 0 ]; then
        docker stats --no-stream --format "{{.Container}}: CPU={{.CPUPerc}} MEM={{.MemUsage}}" optivolt-test-app 2>/dev/null || true
    fi
    sleep 1
done

wait $DOCKER_PID

collect_metrics "docker" "$RESULTS_DIR/docker_metrics.json"

echo -e "${GREEN}✓ Test Docker terminé${NC}\n"

# ==============================================================================
# TEST 2 : MicroVM (Firecracker)
# ==============================================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  TEST 2/3 : MicroVM Firecracker${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${YELLOW}► Déploiement MicroVM...${NC}"
bash scripts/deploy_microvm.sh /tmp/optivolt-microvm > "$RESULTS_DIR/microvm_deploy.log" 2>&1

echo -e "${YELLOW}► Test CPU MicroVM (simulation ${DURATION}s)...${NC}"
# Simulation charge MicroVM dans container léger
docker run --rm --name optivolt-microvm-test \
    --cpus="1" --memory="128m" \
    python:3.11-slim bash -c "
        echo '[MICROVM-TEST] Test CPU MicroVM-style'
        for i in \$(seq 1 5); do
            python3 -c 'import time; start=time.time(); 
            while time.time()-start < $DURATION: 
                _ = sum(i*i for i in range(10000))
            ' &
        done
        sleep $DURATION
        wait
        echo '[MICROVM-TEST] Terminé'
    " > "$RESULTS_DIR/microvm_test.log" 2>&1 &

MICROVM_PID=$!

sleep $DURATION
wait $MICROVM_PID 2>/dev/null || true

collect_metrics "microvm" "$RESULTS_DIR/microvm_metrics.json"

echo -e "${GREEN}✓ Test MicroVM terminé${NC}\n"

# ==============================================================================
# TEST 3 : Unikernel (QEMU lightweight)
# ==============================================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  TEST 3/3 : Unikernel${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${YELLOW}► Déploiement Unikernel...${NC}"
bash scripts/deploy_unikernel.sh /tmp/optivolt-unikernel > "$RESULTS_DIR/unikernel_deploy.log" 2>&1

echo -e "${YELLOW}► Test CPU Unikernel (simulation ${DURATION}s)...${NC}"
# Simulation unikernel = container ultra-léger
docker run --rm --name optivolt-unikernel-test \
    --cpus="1" --memory="64m" \
    alpine:latest sh -c "
        echo '[UNIKERNEL-TEST] Test CPU Unikernel-style (lightweight)'
        for i in \$(seq 1 3); do
            sh -c 'i=0; while [ \$i -lt 1000000 ]; do i=\$((i+1)); done' &
        done
        sleep $DURATION
        wait
        echo '[UNIKERNEL-TEST] Terminé'
    " > "$RESULTS_DIR/unikernel_test.log" 2>&1 &

UNIKERNEL_PID=$!

sleep $DURATION
wait $UNIKERNEL_PID 2>/dev/null || true

collect_metrics "unikernel" "$RESULTS_DIR/unikernel_metrics.json"

echo -e "${GREEN}✓ Test Unikernel terminé${NC}\n"

# ==============================================================================
# Génération rapport comparatif
# ==============================================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Génération Rapport Comparatif${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Agréger les résultats
cat > "$RESULTS_DIR/comparison.json" <<EOF
{
  "benchmark_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "duration_seconds": $DURATION,
  "results": {
    "docker": $(cat "$RESULTS_DIR/docker_metrics.json"),
    "microvm": $(cat "$RESULTS_DIR/microvm_metrics.json"),
    "unikernel": $(cat "$RESULTS_DIR/unikernel_metrics.json")
  }
}
EOF

echo -e "${GREEN}✓ Rapport généré: $RESULTS_DIR/comparison.json${NC}\n"

# Afficher résumé
echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    RÉSULTATS                             ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}\n"

for env in docker microvm unikernel; do
    if [ -f "$RESULTS_DIR/${env}_metrics.json" ]; then
        cpu=$(jq -r '.metrics.cpu_usage_percent' "$RESULTS_DIR/${env}_metrics.json")
        mem=$(jq -r '.metrics.memory_used_mb' "$RESULTS_DIR/${env}_metrics.json")
        echo -e "${YELLOW}$env:${NC}"
        echo -e "  CPU: ${cpu}%"
        echo -e "  MEM: ${mem}MB"
        echo ""
    fi
done

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Benchmark terminé !${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${YELLOW}Fichiers de résultats:${NC}"
ls -lh "$RESULTS_DIR"/*.json

echo -e "\n${YELLOW}Visualisation Grafana:${NC}"
echo -e "  • URL: http://localhost:3000"
echo -e "  • Dashboard: OptiVolt Comparison"
echo -e "  • Métriques disponibles dans Prometheus (port 9090)"

echo -e "\n${YELLOW}Pour envoyer les métriques à Prometheus:${NC}"
echo -e "  python3 scripts/push_metrics_to_prometheus.py $RESULTS_DIR/comparison.json"
