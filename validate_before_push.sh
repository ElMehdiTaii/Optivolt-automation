#!/bin/bash

# Script de validation pré-push pour l'intégration Scaphandre
# Vérifie que tout est prêt avant de pousser vers GitLab

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     Validation Pré-Push - OptiVolt + Scaphandre               ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Fonction pour marquer les erreurs
mark_error() {
    echo -e "${RED}✗ ERREUR:${NC} $1"
    ERRORS=$((ERRORS + 1))
}

# Fonction pour marquer les avertissements
mark_warning() {
    echo -e "${YELLOW}⚠ ATTENTION:${NC} $1"
    WARNINGS=$((WARNINGS + 1))
}

# Fonction pour marquer les succès
mark_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Fonction pour afficher les infos
mark_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

echo "═══════════════════════════════════════════════════════════════"
echo "  1. Vérification des fichiers critiques"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# GitLab CI
if [ -f ".gitlab-ci.yml" ]; then
    mark_success ".gitlab-ci.yml présent"
    
    # Vérifier la syntaxe YAML basique
    if grep -q "stages:" .gitlab-ci.yml && grep -q "power-monitoring" .gitlab-ci.yml; then
        mark_success "Stage power-monitoring configuré"
    else
        mark_error "Stage power-monitoring manquant dans .gitlab-ci.yml"
    fi
else
    mark_error ".gitlab-ci.yml manquant"
fi

# Scripts
REQUIRED_SCRIPTS=(
    "scripts/setup_scaphandre.sh"
    "scripts/collect_metrics.sh"
    "scripts/generate_metrics.py"
    "scripts/generate_dashboard.py"
)

for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            mark_success "$script présent et exécutable"
        else
            mark_warning "$script présent mais non exécutable (chmod +x nécessaire)"
        fi
    else
        mark_error "$script manquant"
    fi
done

# OptiVolt CLI
if [ -f "OptiVoltCLI/Program.cs" ]; then
    mark_success "OptiVoltCLI/Program.cs présent"
    
    # Vérifier que les commandes Scaphandre sont présentes
    if grep -q "scaphandreCommand" OptiVoltCLI/Program.cs; then
        mark_success "Commandes Scaphandre intégrées dans le CLI"
    else
        mark_error "Commandes Scaphandre manquantes dans Program.cs"
    fi
else
    mark_error "OptiVoltCLI/Program.cs manquant"
fi

# Configuration
if [ -f "config/hosts.json" ]; then
    mark_success "config/hosts.json présent"
else
    mark_warning "config/hosts.json manquant (peut causer des erreurs au runtime)"
fi

# Documentation
DOCS=(
    "docs/SCAPHANDRE_INTEGRATION.md"
    "docs/SCAPHANDRE_QUICKREF.md"
    "docs/INTEGRATION_SUMMARY.md"
)

for doc in "${DOCS[@]}"; do
    if [ -f "$doc" ]; then
        mark_success "$doc présent"
    else
        mark_warning "$doc manquant"
    fi
done

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  2. Vérification de la syntaxe GitLab CI"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Vérifier les stages
EXPECTED_STAGES=("build" "deploy" "test" "metrics" "power-monitoring" "report")
for stage in "${EXPECTED_STAGES[@]}"; do
    if grep -q "  - $stage" .gitlab-ci.yml; then
        mark_success "Stage '$stage' configuré"
    else
        mark_error "Stage '$stage' manquant"
    fi
done

# Vérifier les jobs power
if grep -q "power:scaphandre-setup:" .gitlab-ci.yml; then
    mark_success "Job 'power:scaphandre-setup' configuré"
else
    mark_error "Job 'power:scaphandre-setup' manquant"
fi

if grep -q "power:collect-energy:" .gitlab-ci.yml; then
    mark_success "Job 'power:collect-energy' configuré"
else
    mark_error "Job 'power:collect-energy' manquant"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  3. Vérification de la compilation .NET"
echo "═══════════════════════════════════════════════════════════════"
echo ""

cd OptiVoltCLI

if command -v dotnet &> /dev/null; then
    mark_info "Tentative de compilation du projet..."
    
    if dotnet build OptiVoltCLI.csproj > /tmp/build_output.log 2>&1; then
        mark_success "Compilation réussie"
    else
        mark_error "Échec de compilation - voir /tmp/build_output.log"
        tail -10 /tmp/build_output.log
    fi
else
    mark_warning "dotnet CLI non disponible - impossible de vérifier la compilation"
fi

cd ..

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  4. Vérification de la structure du projet"
echo "═══════════════════════════════════════════════════════════════"
echo ""

EXPECTED_DIRS=(
    "OptiVoltCLI"
    "scripts"
    "config"
    "docs"
    "results"
)

for dir in "${EXPECTED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        mark_success "Répertoire '$dir' présent"
    else
        mark_warning "Répertoire '$dir' manquant"
        if [ "$dir" = "results" ]; then
            mark_info "Le répertoire 'results' sera créé automatiquement"
        fi
    fi
done

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  5. Vérification Git"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if [ -d ".git" ]; then
    mark_success "Répertoire Git initialisé"
    
    # Vérifier les fichiers non suivis
    UNTRACKED=$(git ls-files --others --exclude-standard | wc -l)
    if [ "$UNTRACKED" -gt 0 ]; then
        mark_warning "$UNTRACKED fichier(s) non suivi(s)"
        mark_info "Exécutez: git status"
    else
        mark_success "Tous les fichiers sont suivis"
    fi
    
    # Vérifier les modifications non commitées
    MODIFIED=$(git diff --name-only | wc -l)
    if [ "$MODIFIED" -gt 0 ]; then
        mark_warning "$MODIFIED fichier(s) modifié(s) non commité(s)"
        mark_info "Fichiers modifiés:"
        git diff --name-only | sed 's/^/    /'
    else
        mark_success "Aucune modification non commitée"
    fi
    
    # Vérifier la branche
    BRANCH=$(git branch --show-current)
    mark_info "Branche actuelle: $BRANCH"
    
    # Vérifier le remote
    if git remote -v | grep -q "origin"; then
        REMOTE=$(git remote get-url origin)
        mark_success "Remote configuré: $REMOTE"
    else
        mark_warning "Aucun remote 'origin' configuré"
    fi
else
    mark_error "Pas de répertoire .git - initialiser Git d'abord"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  6. Vérifications spécifiques Scaphandre"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Vérifier que collect_metrics.sh contient la fonction Scaphandre
if grep -q "collect_scaphandre_metrics" scripts/collect_metrics.sh; then
    mark_success "Fonction collect_scaphandre_metrics présente"
else
    mark_error "Fonction collect_scaphandre_metrics manquante dans collect_metrics.sh"
fi

# Vérifier l'intégration dans le JSON
if grep -q "SCAPHANDRE_METRICS" scripts/collect_metrics.sh; then
    mark_success "Variable SCAPHANDRE_METRICS utilisée"
else
    mark_error "Variable SCAPHANDRE_METRICS manquante"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  7. Points d'attention pour GitLab CI"
echo "═══════════════════════════════════════════════════════════════"
echo ""

mark_info "Les jobs power-monitoring sont configurés avec 'allow_failure: true'"
mark_info "Cela signifie que le pipeline continuera même si RAPL n'est pas disponible"
mark_info ""
mark_info "Dans GitLab CI (conteneurs Docker):"
mark_info "  • RAPL ne sera probablement PAS disponible"
mark_info "  • Les jobs créeront un JSON avec 'available: false'"
mark_info "  • Le pipeline continuera normalement"
mark_info ""
mark_info "Sur un runner bare-metal:"
mark_info "  • RAPL sera disponible si le CPU le supporte"
mark_info "  • Les métriques réelles seront collectées"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  RÉSUMÉ"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ PARFAIT !${NC} Tout est prêt pour le push"
    echo ""
    echo "Commandes à exécuter:"
    echo "  git add ."
    echo "  git commit -m 'feat: Integrate Scaphandre power monitoring'"
    echo "  git push origin $(git branch --show-current 2>/dev/null || echo 'main')"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ AVERTISSEMENTS${NC}: $WARNINGS avertissement(s)"
    echo ""
    echo "Le push devrait fonctionner, mais vérifiez les avertissements ci-dessus."
    echo ""
    echo "Pour continuer quand même:"
    echo "  git add ."
    echo "  git commit -m 'feat: Integrate Scaphandre power monitoring'"
    echo "  git push origin $(git branch --show-current 2>/dev/null || echo 'main')"
    exit 0
else
    echo -e "${RED}✗ ERREURS${NC}: $ERRORS erreur(s), $WARNINGS avertissement(s)"
    echo ""
    echo "Corrigez les erreurs avant de pousser vers GitLab."
    echo ""
    echo "Pour plus d'informations, consultez:"
    echo "  • docs/SCAPHANDRE_INTEGRATION.md"
    echo "  • docs/INTEGRATION_SUMMARY.md"
    exit 1
fi
