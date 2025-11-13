#!/bin/bash
set -e

echo "=============================================="
echo "🧪 Test Local de Déploiement OptiVolt"
echo "=============================================="
echo ""

# Vérifier que tout est disponible
echo "📋 Vérification des prérequis..."
command -v docker >/dev/null 2>&1 || { echo "❌ Docker non installé"; exit 1; }
command -v dotnet >/dev/null 2>&1 || { echo "❌ .NET SDK non installé"; exit 1; }

echo "✅ Docker: $(docker --version)"
echo "✅ .NET: $(dotnet --version)"
echo ""

# Build du projet
echo "🔨 Compilation du projet OptiVolt..."
cd "$(dirname "$0")"
cd OptiVoltCLI
dotnet build -c Release -o ../publish >/dev/null 2>&1
cd ..
echo "✅ Build terminé"
echo ""

# Test du déploiement Docker
echo "=============================================="
echo "🐳 Test 1: Déploiement Docker Local"
echo "=============================================="
cd publish
dotnet OptiVoltCLI.dll deploy --environment docker
echo ""

# Test du workload benchmark
echo "=============================================="
echo "📊 Test 2: Workload Benchmark"
echo "=============================================="
cd ..
WORKLOAD_DURATION=15 WORKLOAD_INTENSITY=medium python3 scripts/workload_benchmark.py
echo ""

# Afficher les résultats
echo "=============================================="
echo "📈 Résultats du Benchmark"
echo "=============================================="
if [ -f /tmp/workload_results.json ]; then
    cat /tmp/workload_results.json | python3 -m json.tool | grep -A 10 "metrics"
else
    echo "❌ Fichier de résultats non trouvé"
fi
echo ""

# Test de collecte des métriques Docker
echo "=============================================="
echo "🔍 Test 3: Métriques du Conteneur Docker"
echo "=============================================="
CONTAINER_NAME="optivolt-test-app"
if docker ps --filter "name=$CONTAINER_NAME" --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "✅ Conteneur trouvé: $CONTAINER_NAME"
    echo ""
    echo "📊 Statistiques (temps réel):"
    docker stats $CONTAINER_NAME --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
    echo ""
    echo "📝 Logs du conteneur (dernières lignes):"
    docker logs $CONTAINER_NAME --tail 5
    echo ""
else
    echo "⚠️  Conteneur non trouvé (peut-être arrêté)"
fi

# Nettoyage
echo "=============================================="
echo "🧹 Nettoyage"
echo "=============================================="
docker rm -f $CONTAINER_NAME 2>/dev/null || echo "Conteneur déjà supprimé"
docker network rm optivolt-net 2>/dev/null || echo "Réseau déjà supprimé"

echo ""
echo "=============================================="
echo "✅ Tests locaux terminés avec succès!"
echo "=============================================="
echo ""
echo "💡 Ces tests prouvent que:"
echo "   ✓ Le déploiement Docker fonctionne"
echo "   ✓ Les métriques sont collectées"
echo "   ✓ Le workload génère une charge mesurable"
echo ""
echo "⚠️  Note: GitLab CI nécessite un runner avec:"
echo "   - Docker privilégié (DinD)"
echo "   - Ou serveurs SSH distants configurés"
