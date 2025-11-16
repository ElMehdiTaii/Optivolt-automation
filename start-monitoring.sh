#!/bin/bash
#
# start-monitoring.sh - Démarrage de la stack monitoring OptiVolt
#
# Description:
#   Lance Prometheus, Grafana, cAdvisor, Node Exporter et Scaphandre
#
# Usage:
#   bash start-monitoring.sh
#

set -e

# Charger les fonctions communes
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/common.sh"

print_banner "OptiVolt Monitoring Stack - Démarrage"

log_info "Scaphandre + Prometheus + Grafana + cAdvisor"
echo ""

# ========================================
# Vérifications des Prérequis
# ========================================

log_step "Vérification des prérequis..."

check_docker

# Vérifier Docker Compose
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
  log_error "Docker Compose n'est pas installé"
  exit 1
fi
log_success "Docker Compose disponible"

# ========================================
# Vérification RAPL (Optionnel)
# ========================================

log_step "Vérification module RAPL (métriques énergétiques)..."

if [ -d "/sys/class/powercap/intel-rapl" ] || [ -d "/sys/class/powercap/intel-rapl:0" ]; then
  log_success "Module RAPL détecté - Métriques énergétiques disponibles"
else
  log_warning "Module RAPL non détecté"
  log_info "Tentative de chargement du module..."
  sudo modprobe intel_rapl_common 2>/dev/null || sudo modprobe intel_rapl 2>/dev/null || true
  
  if [ -d "/sys/class/powercap/intel-rapl" ] || [ -d "/sys/class/powercap/intel-rapl:0" ]; then
    log_success "Module RAPL chargé"
  else
    log_warning "RAPL non disponible (normal dans GitHub Codespaces)"
    log_info "Scaphandre fonctionnera en mode dégradé"
  fi
fi

# ========================================
# Arrêt des Containers Existants
# ========================================

log_step "Nettoyage des containers existants..."

docker-compose -f docker-compose-monitoring.yml down 2>/dev/null || \
  docker compose -f docker-compose-monitoring.yml down 2>/dev/null || true

log_success "Nettoyage terminé"

# ========================================
# Démarrage de la Stack
# ========================================

log_step "Démarrage de la stack monitoring..."

if docker-compose -f docker-compose-monitoring.yml up -d 2>/dev/null; then
  log_success "Stack démarrée (docker-compose)"
elif docker compose -f docker-compose-monitoring.yml up -d; then
  log_success "Stack démarrée (docker compose)"
else
  log_error "Échec du démarrage de la stack"
  exit 1
fi

# ========================================
# Attente des Services
# ========================================

log_step "Attente du démarrage des services (30s)..."
sleep 30

# ========================================
# Vérification des Services
# ========================================

log_step "Vérification des services..."
echo ""

check_service_health "http://localhost:8080/metrics" "Scaphandre"
check_service_health "http://localhost:9090/-/healthy" "Prometheus"
check_service_health "http://localhost:3000/api/health" "Grafana"
check_service_health "http://localhost:9100/metrics" "Node Exporter"
check_service_health "http://localhost:8081/healthz" "cAdvisor"

# ========================================
# Informations d'Accès
# ========================================

echo ""
log_section "ACCÈS AUX SERVICES"

echo "📊 Grafana (Visualisation):"
echo "   URL:      http://localhost:3000"
echo "   User:     admin"
echo "   Password: admin"
echo ""
echo "🔍 Prometheus (Métriques):"
echo "   URL:      http://localhost:9090"
echo ""
echo "⚡ Scaphandre (Énergie):"
echo "   URL:      http://localhost:8080/metrics"
echo ""
echo "💻 Node Exporter (Système):"
echo "   URL:      http://localhost:9100/metrics"
echo ""
echo "🐳 cAdvisor (Containers):"
echo "   URL:      http://localhost:8081"
echo ""

log_section "COMMANDES UTILES"

echo "Voir les logs:"
echo "  docker-compose -f docker-compose-monitoring.yml logs -f"
echo ""
echo "Arrêter la stack:"
echo "  docker-compose -f docker-compose-monitoring.yml down"
echo ""
echo "Redémarrer un service:"
echo "  docker-compose -f docker-compose-monitoring.yml restart <service>"
echo ""
echo "Status des containers:"
echo "  docker ps | grep optivolt"
echo ""

log_success "Stack monitoring démarrée avec succès!"
log_info "📊 Ouvrez Grafana: http://localhost:3000 (admin/admin)"
echo ""
