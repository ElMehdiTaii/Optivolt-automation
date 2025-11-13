#!/bin/bash

# Script de démarrage de la stack de monitoring OptiVolt
# Prometheus + Grafana + Scaphandre

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     OptiVolt Monitoring Stack - Démarrage                      ║"
echo "║     Scaphandre + Prometheus + Grafana                          ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Vérifier Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker n'est pas installé"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose n'est pas installé"
    exit 1
fi

print_success "Docker et Docker Compose détectés"

# Vérifier RAPL
if [ -d "/sys/class/powercap/intel-rapl" ] || [ -d "/sys/class/powercap/intel-rapl:0" ]; then
    print_success "Module RAPL détecté - Métriques énergétiques disponibles"
else
    print_warning "Module RAPL non détecté"
    print_info "Tentative de chargement du module..."
    sudo modprobe intel_rapl_common 2>/dev/null || sudo modprobe intel_rapl 2>/dev/null || true
    
    if [ -d "/sys/class/powercap/intel-rapl" ] || [ -d "/sys/class/powercap/intel-rapl:0" ]; then
        print_success "Module RAPL chargé avec succès"
    else
        print_warning "RAPL non disponible - Scaphandre fonctionnera en mode dégradé"
    fi
fi

# Arrêter les conteneurs existants
print_info "Arrêt des conteneurs existants..."
docker-compose -f docker-compose-monitoring.yml down 2>/dev/null || docker compose -f docker-compose-monitoring.yml down 2>/dev/null || true

# Démarrer la stack
print_info "Démarrage de la stack de monitoring..."
if docker-compose -f docker-compose-monitoring.yml up -d 2>/dev/null; then
    print_success "Stack démarrée avec docker-compose"
elif docker compose -f docker-compose-monitoring.yml up -d; then
    print_success "Stack démarrée avec docker compose"
else
    print_error "Échec du démarrage de la stack"
    exit 1
fi

echo ""
print_info "Attente du démarrage des services (30 secondes)..."
sleep 30

# Vérifier les services
print_info "Vérification des services..."
echo ""

check_service() {
    local service=$1
    local port=$2
    local url=$3
    
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:${port}${url} | grep -q "200\|302\|301"; then
        print_success "$service est opérationnel sur http://localhost:$port"
        return 0
    else
        print_warning "$service ne répond pas encore sur http://localhost:$port"
        return 1
    fi
}

check_service "Scaphandre" "8080" "/metrics"
check_service "Prometheus" "9090" "/"
check_service "Grafana" "3000" "/"
check_service "Node Exporter" "9100" "/metrics"
check_service "cAdvisor" "8081" "/"

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                   ACCÈS AUX SERVICES                           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "📊 Grafana (Visualisation):"
echo "   URL:      http://localhost:3000"
echo "   User:     admin"
echo "   Password: optivolt2025"
echo ""
echo "🔍 Prometheus (Base de données):"
echo "   URL:      http://localhost:9090"
echo ""
echo "⚡ Scaphandre (Métriques énergétiques):"
echo "   URL:      http://localhost:8080/metrics"
echo ""
echo "💻 Node Exporter (Métriques système):"
echo "   URL:      http://localhost:9100/metrics"
echo ""
echo "🐳 cAdvisor (Métriques Docker):"
echo "   URL:      http://localhost:8081"
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                   COMMANDES UTILES                             ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Voir les logs:"
echo "  docker-compose -f docker-compose-monitoring.yml logs -f"
echo ""
echo "Arrêter la stack:"
echo "  docker-compose -f docker-compose-monitoring.yml down"
echo ""
echo "Redémarrer un service:"
echo "  docker-compose -f docker-compose-monitoring.yml restart <service>"
echo ""
echo "Status des conteneurs:"
echo "  docker-compose -f docker-compose-monitoring.yml ps"
echo ""

print_success "Stack de monitoring OptiVolt démarrée avec succès!"
print_info "Ouvrez http://localhost:3000 dans votre navigateur pour accéder à Grafana"
