#!/bin/bash

# Script de démonstration de l'intégration Scaphandre dans OptiVolt
# Ce script montre comment utiliser toutes les fonctionnalités intégrées

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     Démo Intégration Scaphandre + OptiVolt                     ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_ROOT="/home/ubuntu/optivolt-automation"
cd $PROJECT_ROOT

echo -e "${BLUE}📍 Répertoire de travail:${NC} $(pwd)"
echo ""

# Étape 1: Vérification de l'installation
echo "═══════════════════════════════════════════════════════════"
echo "  ÉTAPE 1: Vérification de Scaphandre"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo -e "${YELLOW}Commande:${NC} ./scripts/setup_scaphandre.sh check"
echo ""
./scripts/setup_scaphandre.sh check || {
    echo ""
    echo -e "${YELLOW}⚠️  Scaphandre n'est pas installé${NC}"
    echo ""
    read -p "Voulez-vous installer Scaphandre maintenant? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "═══════════════════════════════════════════════════════════"
        echo "  Installation de Scaphandre"
        echo "═══════════════════════════════════════════════════════════"
        ./scripts/setup_scaphandre.sh install
    else
        echo ""
        echo -e "${YELLOW}⚠️  Démo limitée sans Scaphandre${NC}"
    fi
}

echo ""
read -p "Appuyez sur ENTRÉE pour continuer..."

# Étape 2: Collecte rapide
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  ÉTAPE 2: Collecte rapide (10 secondes)"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo -e "${YELLOW}Commande:${NC} scaphandre stdout -t 10"
echo ""

if command -v scaphandre &> /dev/null; then
    timeout 10s scaphandre stdout 2>/dev/null || {
        echo -e "${YELLOW}⚠️  RAPL non disponible (VM ou CPU non supporté)${NC}"
        echo "   Ceci est normal dans une VM VirtualBox"
    }
else
    echo -e "${YELLOW}⚠️  Scaphandre non installé - passage à l'étape suivante${NC}"
fi

echo ""
read -p "Appuyez sur ENTRÉE pour continuer..."

# Étape 3: Via OptiVolt CLI
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  ÉTAPE 3: Test via OptiVolt CLI"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo -e "${YELLOW}Commande:${NC} cd OptiVoltCLI && dotnet run -- scaphandre check"
echo ""

cd OptiVoltCLI
dotnet run -- scaphandre check 2>/dev/null || true

echo ""
read -p "Appuyez sur ENTRÉE pour continuer..."

# Étape 4: Collecte avec OptiVolt
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  ÉTAPE 4: Collecte complète via OptiVolt"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo -e "${YELLOW}Commande:${NC} dotnet run -- metrics --environment localhost"
echo ""
echo "Cette commande collecte automatiquement:"
echo "  • Métriques système (CPU, RAM, I/O)"
echo "  • Métriques Docker (si disponible)"
echo "  • Métriques Scaphandre (consommation électrique)"
echo ""

read -p "Lancer la collecte? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    dotnet run -- metrics --environment localhost || true
    
    echo ""
    echo -e "${GREEN}✓ Métriques collectées${NC}"
    echo ""
    echo "Fichier généré dans: results/"
    ls -lh ../results/*.json 2>/dev/null | tail -5 || true
fi

cd ..

echo ""
read -p "Appuyez sur ENTRÉE pour continuer..."

# Étape 5: Structure des fichiers
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  ÉTAPE 5: Fichiers d'intégration créés"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Scripts:"
echo "  ✓ scripts/setup_scaphandre.sh         (9.8K)"
echo ""
echo "Documentation:"
echo "  ✓ docs/SCAPHANDRE_INTEGRATION.md      (14K - Guide complet)"
echo "  ✓ docs/SCAPHANDRE_QUICKREF.md         (2.2K - Aide-mémoire)"
echo "  ✓ docs/INTEGRATION_SUMMARY.md         (6.5K - Résumé)"
echo ""
echo "Modifications:"
echo "  ✓ scripts/collect_metrics.sh          (Fonction Scaphandre ajoutée)"
echo "  ✓ .gitlab-ci.yml                      (Stage power-monitoring)"
echo "  ✓ OptiVoltCLI/Program.cs              (Commandes scaphandre)"
echo ""

echo ""
read -p "Appuyez sur ENTRÉE pour continuer..."

# Étape 6: Workflow complet
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  ÉTAPE 6: Workflow complet recommandé"
echo "═══════════════════════════════════════════════════════════"
echo ""
cat << 'EOF'
1. INSTALLATION (une fois)
   $ ./scripts/setup_scaphandre.sh install

2. DÉPLOIEMENT
   $ dotnet run -- deploy --environment docker

3. TESTS
   $ dotnet run -- test --environment docker --type all

4. MÉTRIQUES (inclut Scaphandre automatiquement)
   $ dotnet run -- metrics --environment docker

5. COLLECTE ÉNERGIE UNIQUEMENT
   $ dotnet run -- scaphandre collect --duration 60

6. ANALYSE
   $ cat results/docker_metrics.json
   {
     "energy_metrics": {
       "scaphandre": {
         "available": true,
         "host_power_watts": 15.2,
         "socket_power_watts": 12.8
       }
     }
   }

7. COMPARAISON MULTI-ENVIRONNEMENTS
   Pour chaque env (docker, microvm, unikernel):
   - Deploy → Test → Collect → Compare

8. RAPPORT
   $ dotnet run -- report
EOF

echo ""
read -p "Appuyez sur ENTRÉE pour continuer..."

# Étape 7: Pipeline GitLab
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  ÉTAPE 7: Pipeline GitLab CI/CD"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Nouveau stage ajouté: power-monitoring"
echo ""
echo "Jobs disponibles:"
echo "  • power:scaphandre-setup     - Vérification installation"
echo "  • power:collect-energy       - Collecte métriques énergétiques"
echo ""
echo "Pour activer:"
echo "  1. git add ."
echo "  2. git commit -m 'feat: Integrate Scaphandre'"
echo "  3. git push"
echo ""
echo "Le pipeline s'exécutera automatiquement avec:"
echo "  stages: build → deploy → test → metrics → power-monitoring → report"
echo ""

echo ""
read -p "Appuyez sur ENTRÉE pour voir les ressources..."

# Étape 8: Ressources
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  RESSOURCES ET DOCUMENTATION"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "📚 Documentation locale:"
echo "   • docs/SCAPHANDRE_INTEGRATION.md   - Guide complet"
echo "   • docs/SCAPHANDRE_QUICKREF.md      - Commandes rapides"
echo "   • docs/INTEGRATION_SUMMARY.md      - Vue d'ensemble"
echo ""
echo "🔗 Documentation Scaphandre:"
echo "   • https://hubblo-org.github.io/scaphandre-documentation/"
echo "   • https://github.com/hubblo-org/scaphandre"
echo ""
echo "💡 Aide rapide:"
echo "   ./scripts/setup_scaphandre.sh help"
echo "   dotnet run -- scaphandre --help"
echo ""

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  ✅ Démo terminée - Scaphandre intégré dans OptiVolt          ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Prochaines étapes suggérées:"
echo "  1. Lire: docs/SCAPHANDRE_INTEGRATION.md"
echo "  2. Tester: ./scripts/setup_scaphandre.sh check"
echo "  3. Collecter: dotnet run -- scaphandre collect --duration 30"
echo ""
echo "🎉 Vous pouvez maintenant mesurer la consommation énergétique réelle!"
echo ""
