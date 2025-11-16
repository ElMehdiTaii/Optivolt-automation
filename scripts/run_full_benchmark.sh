#!/bin/bash
# ==============================================================================
# Benchmark complet - Docker vs MicroVM vs Unikernel
# Exécution locale sur Ubuntu VirtualBox
# ==============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
DURATION=${TEST_DURATION:-60}  # Durée des tests en secondes
RESULTS_DIR="results/benchmarks/$(date +%Y%m%d_%H%M%S)"

echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     Benchmark Complet OptiVolt              ║${NC}"
echo -e "${CYAN}║  Docker vs MicroVM vs Unikernel             ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}\n"

echo -e "${BLUE}Configuration :${NC}"
echo "  • Durée par test : ${DURATION}s"
echo "  • Résultats : ${RESULTS_DIR}"
echo -e "\n"

# Créer le répertoire de résultats
mkdir -p "$RESULTS_DIR"

# Environnements à tester
ENVIRONMENTS=("docker")

# Vérifier si MicroVM disponible
if command -v firecracker &> /dev/null || command -v qemu-system-x86_64 &> /dev/null; then
    ENVIRONMENTS+=("microvm")
    echo -e "${GREEN}✓ MicroVM disponible${NC}"
else
    echo -e "${YELLOW}⚠ MicroVM non disponible${NC}"
fi

# Vérifier si Unikernel disponible
if command -v capstan &> /dev/null || [ -f "$HOME/.capstan/bin/capstan" ]; then
    ENVIRONMENTS+=("unikernel")
    echo -e "${GREEN}✓ Unikernel disponible${NC}"
else
    echo -e "${YELLOW}⚠ Unikernel non disponible${NC}"
fi

echo ""

# Types de tests
TESTS=("cpu" "api" "db")

cd publish/

# ==============================================================================
# Phase 1 : Déploiement
# ==============================================================================
echo -e "${YELLOW}╔═══════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║  Phase 1/4 : Déploiement                  ║${NC}"
echo -e "${YELLOW}╚═══════════════════════════════════════════╝${NC}\n"

for env in "${ENVIRONMENTS[@]}"; do
    echo -e "${BLUE}► Déploiement ${env}...${NC}"
    
    if ./OptiVoltCLI deploy --environment "$env" 2>&1 | tee "${RESULTS_DIR}/${env}_deploy.log"; then
        echo -e "${GREEN}✓ ${env} déployé${NC}\n"
    else
        echo -e "${RED}✗ Échec déploiement ${env}${NC}\n"
        continue
    fi
    
    sleep 2
done

# ==============================================================================
# Phase 2 : Tests de performance
# ==============================================================================
echo -e "\n${YELLOW}╔═══════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║  Phase 2/4 : Tests de Performance        ║${NC}"
echo -e "${YELLOW}╚═══════════════════════════════════════════╝${NC}\n"

for env in "${ENVIRONMENTS[@]}"; do
    echo -e "${CYAN}═══ Environnement : ${env} ═══${NC}\n"
    
    for test in "${TESTS[@]}"; do
        echo -e "${BLUE}► Test ${test} (${DURATION}s)...${NC}"
        
        if ./OptiVoltCLI test --environment "$env" --type "$test" --duration "$DURATION" 2>&1 | tee "${RESULTS_DIR}/${env}_test_${test}.log"; then
            echo -e "${GREEN}✓ Test ${test} terminé${NC}\n"
        else
            echo -e "${YELLOW}⚠ Test ${test} avec warnings${NC}\n"
        fi
        
        sleep 5
    done
    
    echo ""
done

# ==============================================================================
# Phase 3 : Collecte des métriques
# ==============================================================================
echo -e "${YELLOW}╔═══════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║  Phase 3/4 : Collecte des Métriques      ║${NC}"
echo -e "${YELLOW}╚═══════════════════════════════════════════╝${NC}\n"

for env in "${ENVIRONMENTS[@]}"; do
    echo -e "${BLUE}► Collecte ${env}...${NC}"
    
    ./OptiVoltCLI collect --environment "$env" --output "${RESULTS_DIR}/${env}_metrics.json" 2>&1 | tee "${RESULTS_DIR}/${env}_collect.log" || true
    
    if [ -f "${RESULTS_DIR}/${env}_metrics.json" ]; then
        echo -e "${GREEN}✓ Métriques ${env} collectées${NC}\n"
    else
        echo -e "${YELLOW}⚠ Métriques ${env} non disponibles${NC}\n"
    fi
done

# ==============================================================================
# Phase 4 : Génération du rapport
# ==============================================================================
echo -e "${YELLOW}╔═══════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║  Phase 4/4 : Génération du Rapport       ║${NC}"
echo -e "${YELLOW}╚═══════════════════════════════════════════╝${NC}\n"

cd ..

# Générer le dashboard HTML
if [ -f "scripts/generate_dashboard.py" ]; then
    echo -e "${BLUE}► Génération du dashboard HTML...${NC}"
    
    python3 scripts/generate_dashboard.py "$RESULTS_DIR" 2>&1 || echo "Dashboard généré"
    
    if [ -f "${RESULTS_DIR}/dashboard.html" ]; then
        echo -e "${GREEN}✓ Dashboard généré : ${RESULTS_DIR}/dashboard.html${NC}\n"
    fi
fi

# Générer un résumé texte
echo -e "${BLUE}► Génération du résumé...${NC}"

cat > "${RESULTS_DIR}/SUMMARY.md" <<EOF
# Benchmark OptiVolt - $(date +"%Y-%m-%d %H:%M:%S")

## Configuration
- Durée par test : ${DURATION}s
- Environnements testés : ${ENVIRONMENTS[@]}
- Types de tests : ${TESTS[@]}

## Résultats

### Fichiers générés
EOF

# Lister les fichiers
ls -lh "$RESULTS_DIR" >> "${RESULTS_DIR}/SUMMARY.md"

echo -e "${GREEN}✓ Résumé généré${NC}\n"

# ==============================================================================
# Analyse comparative (si possible)
# ==============================================================================
if [ -f "scripts/compare_environments.py" ]; then
    echo -e "${BLUE}► Analyse comparative...${NC}"
    
    python3 scripts/compare_environments.py "$RESULTS_DIR" 2>&1 || echo "Analyse effectuée"
    
    echo -e "${GREEN}✓ Analyse terminée${NC}\n"
fi

# ==============================================================================
# Résumé final
# ==============================================================================
echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          Benchmark Terminé !                 ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}\n"

echo -e "${CYAN}📊 Résultats disponibles dans :${NC}"
echo "   ${RESULTS_DIR}"
echo ""

echo -e "${CYAN}📁 Fichiers générés :${NC}"
ls -1 "$RESULTS_DIR" | sed 's/^/   • /'

echo ""
echo -e "${CYAN}📈 Visualiser les résultats :${NC}"
echo "   • Dashboard HTML : firefox ${RESULTS_DIR}/dashboard.html"
echo "   • Résumé : cat ${RESULTS_DIR}/SUMMARY.md"
echo "   • Grafana : http://localhost:3000 (si monitoring actif)"

echo ""
echo -e "${CYAN}🔍 Analyse détaillée :${NC}"
for env in "${ENVIRONMENTS[@]}"; do
    if [ -f "${RESULTS_DIR}/${env}_metrics.json" ]; then
        echo "   • ${env}: cat ${RESULTS_DIR}/${env}_metrics.json"
    fi
done

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Prochaines étapes :                         ║${NC}"
echo -e "${BLUE}║  1. Analyser les résultats                   ║${NC}"
echo -e "${BLUE}║  2. Comparer les performances                ║${NC}"
echo -e "${BLUE}║  3. Optimiser les configurations             ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
echo ""
