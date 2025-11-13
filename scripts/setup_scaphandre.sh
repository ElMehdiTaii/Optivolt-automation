#!/bin/bash

# Script d'installation et configuration de Scaphandre pour OptiVolt
# Scaphandre : Outil de métrologie de consommation électrique
# Usage: ./setup_scaphandre.sh [install|check|run|docker]

set -e

ACTION=${1:-check}
SCAPHANDRE_VERSION="1.0.0"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérification des prérequis système
check_prerequisites() {
    print_info "Vérification des prérequis système..."
    
    # Vérifier si on est sous Linux
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        print_error "Scaphandre nécessite Linux (actuellement: $OSTYPE)"
        return 1
    fi
    
    # Vérifier le module RAPL (Intel CPU power monitoring)
    if [ -d "/sys/class/powercap/intel-rapl" ] || [ -d "/sys/class/powercap/intel-rapl:0" ]; then
        print_success "Module Intel RAPL détecté"
    else
        print_warning "Module Intel RAPL non détecté - tentative de chargement..."
        
        # Tenter de charger le module
        if command -v modprobe &> /dev/null; then
            sudo modprobe intel_rapl_common 2>/dev/null || sudo modprobe intel_rapl 2>/dev/null || true
            
            if [ -d "/sys/class/powercap/intel-rapl" ] || [ -d "/sys/class/powercap/intel-rapl:0" ]; then
                print_success "Module Intel RAPL chargé avec succès"
            else
                print_warning "Impossible de charger le module RAPL"
                print_warning "Scaphandre ne pourra pas mesurer la consommation électrique"
                print_info "Votre CPU est peut-être AMD ou ne supporte pas RAPL"
            fi
        fi
    fi
    
    # Vérifier les permissions
    if [ -r "/sys/class/powercap/intel-rapl:0/energy_uj" ] 2>/dev/null; then
        print_success "Permissions OK pour lire les métriques RAPL"
    elif [ -d "/sys/class/powercap/intel-rapl:0" ]; then
        print_warning "Permissions insuffisantes pour /sys/class/powercap"
        print_info "Vous devrez peut-être exécuter Scaphandre avec sudo"
    fi
    
    return 0
}

# Installation de Scaphandre
install_scaphandre() {
    print_info "Installation de Scaphandre v${SCAPHANDRE_VERSION}..."
    
    # Vérifier si déjà installé
    if command -v scaphandre &> /dev/null; then
        print_warning "Scaphandre est déjà installé"
        scaphandre --version
        read -p "Voulez-vous réinstaller ? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    # Détecter le gestionnaire de paquets
    if command -v apt-get &> /dev/null; then
        print_info "Installation via APT (Debian/Ubuntu)..."
        
        # Méthode 1: Via le binaire pré-compilé (recommandé)
        print_info "Téléchargement du binaire pré-compilé..."
        ARCH=$(uname -m)
        if [ "$ARCH" = "x86_64" ]; then
            wget -q https://github.com/hubblo-org/scaphandre/releases/download/v${SCAPHANDRE_VERSION}/scaphandre-v${SCAPHANDRE_VERSION}-x86_64-unknown-linux-gnu.tar.gz -O /tmp/scaphandre.tar.gz
            tar -xzf /tmp/scaphandre.tar.gz -C /tmp/
            sudo mv /tmp/scaphandre /usr/local/bin/
            sudo chmod +x /usr/local/bin/scaphandre
            rm /tmp/scaphandre.tar.gz
            print_success "Scaphandre installé dans /usr/local/bin/scaphandre"
        else
            print_error "Architecture non supportée: $ARCH"
            print_info "Compilation depuis les sources requise"
            return 1
        fi
        
    elif command -v yum &> /dev/null; then
        print_info "Installation via YUM (RHEL/CentOS)..."
        sudo yum install -y scaphandre || {
            print_warning "Package non disponible via yum"
            print_info "Téléchargement du binaire..."
            wget -q https://github.com/hubblo-org/scaphandre/releases/download/v${SCAPHANDRE_VERSION}/scaphandre-v${SCAPHANDRE_VERSION}-x86_64-unknown-linux-gnu.tar.gz -O /tmp/scaphandre.tar.gz
            tar -xzf /tmp/scaphandre.tar.gz -C /tmp/
            sudo mv /tmp/scaphandre /usr/local/bin/
            sudo chmod +x /usr/local/bin/scaphandre
            rm /tmp/scaphandre.tar.gz
        }
        
    else
        print_error "Gestionnaire de paquets non supporté"
        print_info "Visitez: https://github.com/hubblo-org/scaphandre/releases"
        return 1
    fi
    
    # Vérifier l'installation
    if command -v scaphandre &> /dev/null; then
        print_success "Installation réussie!"
        scaphandre --version
    else
        print_error "L'installation a échoué"
        return 1
    fi
}

# Vérification de l'installation
check_installation() {
    print_info "Vérification de l'installation de Scaphandre..."
    
    if ! command -v scaphandre &> /dev/null; then
        print_error "Scaphandre n'est pas installé"
        print_info "Exécutez: ./setup_scaphandre.sh install"
        return 1
    fi
    
    print_success "Scaphandre est installé"
    scaphandre --version
    
    # Tester la collecte
    print_info "Test de collecte des métriques (5 secondes)..."
    timeout 5s scaphandre stdout 2>/dev/null || {
        print_warning "Impossible de collecter les métriques"
        print_info "Vérifiez que le module RAPL est chargé: lsmod | grep rapl"
        print_info "Vérifiez les permissions: ls -la /sys/class/powercap/"
    }
    
    return 0
}

# Exécution de Scaphandre en mode JSON
run_scaphandre_json() {
    local OUTPUT_FILE=${1:-/tmp/scaphandre_metrics.json}
    local DURATION=${2:-30}
    
    print_info "Collecte des métriques Scaphandre pendant ${DURATION}s..."
    print_info "Sortie: $OUTPUT_FILE"
    
    if ! command -v scaphandre &> /dev/null; then
        print_error "Scaphandre n'est pas installé"
        return 1
    fi
    
    # Créer le répertoire si nécessaire
    mkdir -p $(dirname $OUTPUT_FILE)
    
    # Lancer Scaphandre en mode JSON
    timeout ${DURATION}s scaphandre json -t 1 -s > "$OUTPUT_FILE" 2>/dev/null || {
        print_error "Erreur lors de la collecte"
        return 1
    }
    
    print_success "Métriques collectées: $OUTPUT_FILE"
    
    # Afficher un résumé si le fichier existe et est valide
    if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
        print_info "Résumé des métriques:"
        if command -v jq &> /dev/null; then
            jq -r '.host.consumption // "N/A" | "Consommation moyenne: \(.) W"' "$OUTPUT_FILE" 2>/dev/null || \
                head -5 "$OUTPUT_FILE"
        else
            head -5 "$OUTPUT_FILE"
        fi
    fi
}

# Exécution de Scaphandre avec Docker
run_scaphandre_docker() {
    print_info "Lancement de Scaphandre dans Docker..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker n'est pas installé"
        return 1
    fi
    
    print_info "Exposition des métriques sur http://localhost:8080/metrics"
    print_info "Appuyez sur Ctrl+C pour arrêter"
    
    docker run --rm \
        -v /sys/class/powercap:/sys/class/powercap:ro \
        -v /proc:/proc:ro \
        -p 8080:8080 \
        -ti hubblo/scaphandre prometheus \
        --address :: \
        --port 8080 || {
        print_error "Erreur lors du lancement de Docker"
        print_info "Essayez en mode privilégié: docker run --privileged ..."
        return 1
    }
}

# Exécution de Scaphandre en mode Prometheus
run_scaphandre_prometheus() {
    local PORT=${1:-8080}
    
    print_info "Lancement de Scaphandre en mode Prometheus..."
    print_info "Métriques disponibles sur: http://localhost:${PORT}/metrics"
    print_info "Appuyez sur Ctrl+C pour arrêter"
    
    if ! command -v scaphandre &> /dev/null; then
        print_error "Scaphandre n'est pas installé"
        return 1
    fi
    
    scaphandre prometheus --port ${PORT}
}

# Menu principal
show_menu() {
    echo ""
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║     Scaphandre Setup - OptiVolt Automation            ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    echo "Scaphandre est un agent de métrologie pour mesurer la"
    echo "consommation électrique (en Watts) de vos services."
    echo ""
    echo "Actions disponibles:"
    echo "  ./setup_scaphandre.sh install     - Installer Scaphandre"
    echo "  ./setup_scaphandre.sh check       - Vérifier l'installation"
    echo "  ./setup_scaphandre.sh run         - Collecter les métriques (JSON)"
    echo "  ./setup_scaphandre.sh prometheus  - Exposer les métriques HTTP"
    echo "  ./setup_scaphandre.sh docker      - Lancer via Docker"
    echo ""
}

# Point d'entrée principal
main() {
    case "$ACTION" in
        install)
            check_prerequisites
            install_scaphandre
            ;;
        check)
            check_prerequisites
            check_installation
            ;;
        run)
            OUTPUT_FILE=${2:-"/tmp/scaphandre_metrics.json"}
            DURATION=${3:-30}
            run_scaphandre_json "$OUTPUT_FILE" "$DURATION"
            ;;
        prometheus)
            PORT=${2:-8080}
            run_scaphandre_prometheus "$PORT"
            ;;
        docker)
            run_scaphandre_docker
            ;;
        menu|help|--help|-h)
            show_menu
            ;;
        *)
            print_error "Action inconnue: $ACTION"
            show_menu
            exit 1
            ;;
    esac
}

main "$@"
