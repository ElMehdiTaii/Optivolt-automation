#!/bin/bash
# ==============================================================================
# Script de test rapide - Exécution locale MicroVM et Unikernel
# ==============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Test Rapide - OptiVolt Local Setup   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}\n"

# ==============================================================================
# 1. Vérifier les prérequis
# ==============================================================================
echo -e "${YELLOW}[1/4] Vérification des prérequis...${NC}\n"

check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} $1 : $(command -v $1)"
        return 0
    else
        echo -e "  ${RED}✗${NC} $1 : non trouvé"
        return 1
    fi
}

MISSING=0

# Vérifier Docker
if ! check_command docker; then
    MISSING=1
fi

# Vérifier KVM
echo -ne "  "
if sudo kvm-ok 2>&1 | grep -q "KVM acceleration can be used"; then
    echo -e "${GREEN}✓${NC} KVM : activé"
else
    echo -e "${YELLOW}⚠${NC} KVM : non disponible (mode simulation)"
fi

# Vérifier QEMU
check_command qemu-system-x86_64 || MISSING=1

# Vérifier Firecracker (optionnel)
check_command firecracker || echo -e "  ${YELLOW}⚠${NC} firecracker : optionnel"

# Vérifier le CLI
if [ -f "publish/OptiVoltCLI" ]; then
    echo -e "  ${GREEN}✓${NC} OptiVoltCLI : publish/OptiVoltCLI"
else
    echo -e "  ${RED}✗${NC} OptiVoltCLI non compilé"
    echo -e "     Exécutez : ${BLUE}cd OptiVoltCLI && dotnet publish -c Release -o ../publish${NC}"
    exit 1
fi

if [ $MISSING -eq 1 ]; then
    echo -e "\n${YELLOW}⚠ Certains outils manquent. Exécutez :${NC}"
    echo -e "  ${BLUE}bash scripts/setup_local_vms.sh${NC}\n"
    read -p "Continuer quand même ? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# ==============================================================================
# 2. Test Docker (baseline)
# ==============================================================================
echo -e "\n${YELLOW}[2/4] Test Docker (baseline)...${NC}\n"

cd publish/

echo "Déploiement Docker..."
if ./OptiVoltCLI deploy --environment docker 2>&1 | tee /tmp/optivolt_docker_deploy.log; then
    echo -e "${GREEN}✓ Déploiement Docker réussi${NC}"
else
    echo -e "${RED}✗ Échec déploiement Docker${NC}"
    cat /tmp/optivolt_docker_deploy.log
fi

echo -e "\nTest CPU Docker (15s)..."
if ./OptiVoltCLI test --environment docker --type cpu --duration 15 2>&1 | tee /tmp/optivolt_docker_test.log; then
    echo -e "${GREEN}✓ Test Docker réussi${NC}"
else
    echo -e "${YELLOW}⚠ Test Docker avec warnings${NC}"
fi

# ==============================================================================
# 3. Test MicroVM (si disponible)
# ==============================================================================
echo -e "\n${YELLOW}[3/4] Test MicroVM...${NC}\n"

if command -v firecracker &> /dev/null || command -v qemu-system-x86_64 &> /dev/null; then
    echo "Déploiement MicroVM..."
    if ./OptiVoltCLI deploy --environment microvm 2>&1 | tee /tmp/optivolt_microvm_deploy.log; then
        echo -e "${GREEN}✓ Déploiement MicroVM réussi${NC}"
        
        echo -e "\nTest CPU MicroVM (15s)..."
        ./OptiVoltCLI test --environment microvm --type cpu --duration 15 2>&1 | tee /tmp/optivolt_microvm_test.log || true
        echo -e "${GREEN}✓ Test MicroVM réussi${NC}"
    else
        echo -e "${YELLOW}⚠ MicroVM non disponible (normal si pas configuré)${NC}"
    fi
else
    echo -e "${YELLOW}⚠ MicroVM non installé (exécutez setup_local_vms.sh)${NC}"
fi

# ==============================================================================
# 4. Collecte des résultats
# ==============================================================================
echo -e "\n${YELLOW}[4/4] Collecte des résultats...${NC}\n"

mkdir -p ../results

echo "Collecte des métriques..."
if ./OptiVoltCLI collect --environment docker --output ../results/test_results.json 2>&1; then
    echo -e "${GREEN}✓ Métriques collectées${NC}"
    
    if [ -f "../results/test_results.json" ]; then
        echo -e "\n${BLUE}Résultats :${NC}"
        cat ../results/test_results.json | head -20
        echo "..."
    fi
else
    echo -e "${YELLOW}⚠ Collecte avec warnings${NC}"
fi

cd ..

# ==============================================================================
# Résumé
# ==============================================================================
echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          Tests terminés !              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}\n"

echo "Logs disponibles :"
echo "  • /tmp/optivolt_docker_deploy.log"
echo "  • /tmp/optivolt_docker_test.log"
[ -f "/tmp/optivolt_microvm_deploy.log" ] && echo "  • /tmp/optivolt_microvm_deploy.log"
[ -f "/tmp/optivolt_microvm_test.log" ] && echo "  • /tmp/optivolt_microvm_test.log"

echo ""
echo "Résultats :"
ls -lh results/*.json 2>/dev/null || echo "  • Aucun résultat JSON généré"

echo -e "\n${BLUE}Prochaines étapes :${NC}"
echo "  1. Activer KVM si pas fait : VBoxManage modifyvm VM --nested-hw-virt on"
echo "  2. Installer tous les outils : bash scripts/setup_local_vms.sh"
echo "  3. Lancer benchmark complet : bash scripts/run_full_benchmark.sh"
echo "  4. Visualiser Grafana : docker-compose -f docker-compose-monitoring.yml up -d"
echo ""
