#!/bin/bash

# ==============================================================================
# Script de Démarrage des Containers de Benchmark Persistants
# OptiVolt - Docker vs MicroVM vs Unikernel
# ==============================================================================

set -e

# Sourcer les fonctions communes
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

if [ -f "$SCRIPT_DIR/common.sh" ]; then
    source "$SCRIPT_DIR/common.sh"
else
    # Fallback si common.sh n'existe pas
    log_info() { echo "[INFO] $1"; }
    log_success() { echo "[SUCCESS] $1"; }
    log_error() { echo "[ERROR] $1"; }
    log_warning() { echo "[WARNING] $1"; }
fi

# ==============================================================================
# Banner
# ==============================================================================
print_banner "OptiVolt Benchmark Containers"

echo ""
log_info "Ce script démarre 3 containers persistants pour tester :"
echo "  🐳 Docker      - Container standard (256 MB RAM, 1 CPU)"
echo "  ⚡ MicroVM     - Container optimisé (128 MB RAM, 0.5 CPU)"
echo "  🚀 Unikernel   - Container minimal (64 MB RAM, 0.25 CPU)"
echo ""
log_info "Ces containers génèrent une charge CPU continue pour alimenter Grafana"
echo ""

# ==============================================================================
# Vérification Docker
# ==============================================================================
log_info "Vérification Docker..."
if ! check_docker; then
    log_error "Docker n'est pas disponible"
    exit 1
fi
log_success "Docker OK"

# ==============================================================================
# Vérification du réseau monitoring
# ==============================================================================
log_info "Vérification du réseau monitoring_default..."
if ! docker network inspect monitoring_default >/dev/null 2>&1; then
    log_warning "Réseau monitoring_default introuvable"
    log_info "Démarrage de la stack monitoring..."
    bash "$PROJECT_ROOT/start-monitoring.sh" || {
        log_error "Échec du démarrage de la stack monitoring"
        exit 1
    }
else
    log_success "Réseau monitoring_default existant"
fi

# ==============================================================================
# Arrêt des containers existants
# ==============================================================================
log_info "Arrêt des containers benchmark existants..."
for container in optivolt-docker optivolt-microvm optivolt-unikernel; do
    if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
        log_info "Arrêt de $container..."
        docker stop "$container" >/dev/null 2>&1 || true
        docker rm "$container" >/dev/null 2>&1 || true
    fi
done
log_success "Containers nettoyés"

# ==============================================================================
# Démarrage des containers de benchmark
# ==============================================================================
log_info "Démarrage des containers de benchmark..."
cd "$PROJECT_ROOT"

docker-compose -f docker-compose-benchmark.yml up -d

if [ $? -eq 0 ]; then
    log_success "Containers de benchmark démarrés !"
else
    log_error "Échec du démarrage des containers"
    exit 1
fi

# ==============================================================================
# Attente et vérification
# ==============================================================================
log_info "Attente du démarrage des containers (10 secondes)..."
sleep 10

echo ""
log_info "═══════════════════════════════════════════════════════════════"
log_success "✅ CONTAINERS DE BENCHMARK ACTIFS"
log_info "═══════════════════════════════════════════════════════════════"
echo ""

# Vérification des containers
for container in optivolt-docker optivolt-microvm optivolt-unikernel; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        status=$(docker inspect --format='{{.State.Status}}' "$container")
        cpu=$(docker inspect --format='{{.HostConfig.NanoCpus}}' "$container" | awk '{printf "%.2f", $1/1000000000}')
        mem=$(docker inspect --format='{{.HostConfig.Memory}}' "$container" | awk '{printf "%d MB", $1/1024/1024}')
        
        echo "  ✅ $container"
        echo "     Status: $status | CPU: ${cpu} | RAM: ${mem}"
    else
        echo "  ❌ $container - NON ACTIF"
    fi
done

echo ""
log_info "═══════════════════════════════════════════════════════════════"
log_info "📊 ACCÈS GRAFANA"
log_info "═══════════════════════════════════════════════════════════════"
echo ""
echo "1. Ouvrir Grafana : VS Code → Onglet PORTS → Port 3000 → 🌐"
echo "2. Login : admin / optivolt2025"
echo "3. Dashboard : Menu ☰ → Dashboards → OptiVolt - Docker vs MicroVM vs Unikernel"
echo "4. Configuration :"
echo "   • Time Range : Last 5 minutes"
echo "   • Auto-refresh : 10s"
echo ""
log_success "🎉 Vous devriez voir 3 courbes (Docker, MicroVM, Unikernel) !"
echo ""

log_info "═══════════════════════════════════════════════════════════════"
log_info "🔧 COMMANDES UTILES"
log_info "═══════════════════════════════════════════════════════════════"
echo ""
echo "Voir les logs en temps réel :"
echo "  docker-compose -f docker-compose-benchmark.yml logs -f"
echo ""
echo "Arrêter les containers :"
echo "  docker-compose -f docker-compose-benchmark.yml down"
echo ""
echo "Redémarrer un container spécifique :"
echo "  docker restart optivolt-docker"
echo "  docker restart optivolt-microvm"
echo "  docker restart optivolt-unikernel"
echo ""
echo "Vérifier les métriques Prometheus :"
echo "  curl -s 'http://localhost:9090/api/v1/query?query=container_cpu_usage_seconds_total{name=~\"optivolt-(docker|microvm|unikernel)\"}' | jq"
echo ""

log_info "═══════════════════════════════════════════════════════════════"
log_success "✅ SETUP TERMINÉ - Les containers génèrent des métriques en continu"
log_info "═══════════════════════════════════════════════════════════════"
