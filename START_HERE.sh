#!/bin/bash
# ==============================================================================
# 🚀 COMMENCEZ ICI - Guide interactif OptiVolt
# ==============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

clear

cat << "EOF"
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║              🚀 OptiVolt - COMMENCEZ ICI                  ║
║          Guide interactif pour vos premiers tests         ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
EOF

echo ""
echo -e "${CYAN}Bienvenue ! Ce script va vous guider pour lancer vos premiers tests.${NC}"
echo ""

# ==============================================================================
# Vérifications préalables
# ==============================================================================
echo -e "${YELLOW}═══ Vérifications préalables ═══${NC}\n"

# Vérifier .NET
if command -v dotnet &> /dev/null; then
    DOTNET_VERSION=$(dotnet --version)
    echo -e "${GREEN}✓${NC} .NET installé : ${DOTNET_VERSION}"
else
    echo -e "${RED}✗${NC} .NET non installé"
    echo -e "${YELLOW}→ Installation requise : https://dotnet.microsoft.com/download${NC}"
    exit 1
fi

# Vérifier Docker (optionnel pour premier test)
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓${NC} Docker installé"
else
    echo -e "${YELLOW}⚠${NC} Docker non installé (sera installé si nécessaire)"
fi

# Vérifier le CLI
if [ -f "publish/OptiVoltCLI" ]; then
    echo -e "${GREEN}✓${NC} OptiVoltCLI déjà compilé"
    CLI_READY=true
else
    echo -e "${YELLOW}⚠${NC} OptiVoltCLI pas encore compilé"
    CLI_READY=false
fi

echo ""

# ==============================================================================
# Menu principal
# ==============================================================================
echo -e "${BOLD}${BLUE}Que voulez-vous faire ?${NC}\n"
echo "  1) 🚀 Test rapide Docker (2 minutes - Recommandé)"
echo "  2) 🔧 Configuration complète (MicroVM + Unikernel)"
echo "  3) 📊 Benchmark complet (nécessite config complète)"
echo "  4) 🎓 Voir le guide détaillé"
echo "  5) ❌ Quitter"
echo ""

read -p "Votre choix [1-5] : " choice

case $choice in
    1)
        echo ""
        echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║    🚀 Test Rapide Docker (2 minutes)        ║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
        echo ""
        
        # Compiler si nécessaire
        if [ "$CLI_READY" = false ]; then
            echo -e "${YELLOW}[1/5] Compilation du CLI...${NC}"
            cd OptiVoltCLI
            dotnet publish -c Release -o ../publish
            cd ..
            echo -e "${GREEN}✓ Compilation terminée${NC}\n"
        else
            echo -e "${GREEN}✓ CLI déjà prêt${NC}\n"
        fi
        
        cd publish
        
        echo -e "${YELLOW}[2/5] Déploiement Docker...${NC}"
        ./OptiVoltCLI deploy --environment docker
        echo ""
        
        echo -e "${YELLOW}[3/5] Test CPU (30 secondes)...${NC}"
        ./OptiVoltCLI test --environment docker --type cpu --duration 30
        echo ""
        
        echo -e "${YELLOW}[4/5] Collecte des métriques...${NC}"
        mkdir -p ../results
        ./OptiVoltCLI collect --environment docker --output ../results/test_rapide.json
        echo ""
        
        echo -e "${YELLOW}[5/5] Résultats :${NC}"
        if [ -f "../results/test_rapide.json" ]; then
            echo -e "${GREEN}✓ Résultats enregistrés dans results/test_rapide.json${NC}"
            echo ""
            echo "Aperçu des résultats :"
            cat ../results/test_rapide.json | head -30
        fi
        
        cd ..
        
        echo ""
        echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║      ✅ Test rapide terminé avec succès !    ║${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
        echo ""
        echo "Prochaines étapes :"
        echo "  • Voir résultats : cat results/test_rapide.json"
        echo "  • Configuration complète : bash START_HERE.sh (choix 2)"
        echo "  • Benchmark complet : bash scripts/run_full_benchmark.sh"
        ;;
        
    2)
        echo ""
        echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║    🔧 Configuration Complète                 ║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
        echo ""
        
        echo -e "${YELLOW}Cette configuration va installer :${NC}"
        echo "  • Docker"
        echo "  • QEMU/KVM"
        echo "  • Firecracker (MicroVM)"
        echo "  • OSv/Capstan (Unikernel)"
        echo ""
        
        echo -e "${RED}⚠️  ATTENTION :${NC}"
        echo "Avant de continuer, assurez-vous d'avoir activé la virtualisation imbriquée :"
        echo ""
        echo "  Sur votre MACHINE HÔTE (VM éteinte) :"
        echo "  ${BLUE}VBoxManage modifyvm \"Ubuntu\" --nested-hw-virt on${NC}"
        echo ""
        
        read -p "Voulez-vous continuer ? [y/N] " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo ""
            echo -e "${YELLOW}Lancement de l'installation...${NC}"
            bash scripts/setup_local_vms.sh
            
            echo ""
            echo -e "${GREEN}✓ Configuration terminée !${NC}"
            echo ""
            echo "Pour tester :"
            echo "  bash scripts/test_local_setup.sh"
        else
            echo "Configuration annulée."
        fi
        ;;
        
    3)
        echo ""
        echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║    📊 Benchmark Complet                      ║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
        echo ""
        
        echo -e "${YELLOW}Ce benchmark va :${NC}"
        echo "  • Tester tous les environnements (Docker, MicroVM, Unikernel)"
        echo "  • Exécuter tous les types de tests (CPU, API, DB)"
        echo "  • Générer des rapports complets"
        echo "  • Durée estimée : 15-30 minutes"
        echo ""
        
        read -p "Lancer le benchmark ? [y/N] " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            bash scripts/run_full_benchmark.sh
        else
            echo "Benchmark annulé."
        fi
        ;;
        
    4)
        echo ""
        cat << EOF
╔════════════════════════════════════════════════════════════╗
║                  📖 GUIDE DÉTAILLÉ                        ║
╚════════════════════════════════════════════════════════════╝

🚀 DÉMARRAGE RAPIDE (5 commandes)
──────────────────────────────────

1. cd /home/ubuntu/optivolt-automation

2. cd OptiVoltCLI && dotnet publish -c Release -o ../publish && cd ..

3. cd publish && ./OptiVoltCLI deploy --environment docker

4. ./OptiVoltCLI test --environment docker --type cpu --duration 30

5. ./OptiVoltCLI collect --environment docker


📚 DOCUMENTATION COMPLÈTE
──────────────────────────

• Guide VirtualBox : docs/LOCAL_VM_SETUP.md
• Résumé complet : docs/VIRTUALBOX_SETUP_SUMMARY.txt
• Documentation API : docs/API_INTEGRATION.md
• État du projet : RAPPORT_ETAT_PROJET.md


🔧 SCRIPTS DISPONIBLES
───────────────────────

• setup_local_vms.sh      → Configuration automatique
• test_local_setup.sh     → Test rapide
• run_full_benchmark.sh   → Benchmark complet


📊 COMMANDES CLI
─────────────────

• deploy   → Déployer un environnement
• test     → Exécuter des tests
• collect  → Collecter les métriques

EOF
        
        echo ""
        read -p "Appuyez sur Entrée pour continuer..."
        ;;
        
    5)
        echo ""
        echo "Au revoir !"
        exit 0
        ;;
        
    *)
        echo ""
        echo -e "${RED}Choix invalide${NC}"
        exit 1
        ;;
esac

echo ""
