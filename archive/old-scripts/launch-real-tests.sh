#!/bin/bash

#######################################################################
# Lancement Tests Réels : Docker Extrême + Préparation Unikraft
#######################################################################

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  OptiVolt - Tests RÉELS: Optimisations Extrêmes             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

#######################################################################
# Partie 1 : Container Docker avec contraintes MicroVM
#######################################################################
echo "🚀 Partie 1/2 : Container Docker simulant MicroVM"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Création container avec contraintes extrêmes (comme Firecracker):"
echo "  • RAM: 128 MB (limite stricte)"
echo "  • CPU: 0.5 vCPU"
echo "  • Image: Alpine minimal"
echo "  • Workload: Python optimisé"
echo ""

# Arrêter ancien si existe
docker stop optivolt-microvm-real 2>/dev/null || true
docker rm optivolt-microvm-real 2>/dev/null || true

# Lancer container optimisé
docker run -d \
  --name optivolt-microvm-real \
  --memory="128m" \
  --memory-swap="128m" \
  --cpus="0.5" \
  --cpu-shares=512 \
  --pids-limit=50 \
  --network=monitoring_default \
  --restart=unless-stopped \
  python:3.11-alpine \
  sh -c '
echo "OptiVolt MicroVM Real - Démarré"
python3 << PYTHON_EOF
import time, random, math

print("🚀 OptiVolt MicroVM (contraintes extrêmes)")
print("💾 RAM: 128 MB max")
print("⚡ CPU: 0.5 vCPU max")

iteration = 0
while True:
    # Monte Carlo optimisé
    inside = sum(1 for _ in range(500) if random.random()**2 + random.random()**2 < 1)
    pi_estimate = (inside / 500) * 4
    
    iteration += 1
    if iteration % 10 == 0:
        print(f"Iteration {iteration}: π ≈ {pi_estimate:.4f}")
    
    time.sleep(0.5)
PYTHON_EOF
'

echo "✅ Container optivolt-microvm-real lancé"
echo ""

# Arrêter/créer container unikernel simulé
docker stop optivolt-unikernel-real 2>/dev/null || true
docker rm optivolt-unikernel-real 2>/dev/null || true

docker run -d \
  --name optivolt-unikernel-real \
  --memory="64m" \
  --memory-swap="64m" \
  --cpus="0.25" \
  --cpu-shares=256 \
  --pids-limit=20 \
  --network=monitoring_default \
  --restart=unless-stopped \
  alpine:3.18 \
  sh -c '
echo "OptiVolt Unikernel Simulation - Démarré"
echo "💾 RAM: 64 MB max"
echo "⚡ CPU: 0.25 vCPU max"
i=0
while true; do
    i=$((i + 1))
    awk "BEGIN { x=rand(); y=rand(); if(x*x+y*y<1) print 1; else print 0 }" > /dev/null
    if [ $((i % 100)) -eq 0 ]; then
        echo "Iteration $i - Unikernel minimal"
    fi
    sleep 0.1
done
'

echo "✅ Container optivolt-unikernel-real lancé"
echo ""

#######################################################################
# Partie 2 : Installation Unikraft (background)
#######################################################################
echo "📦 Partie 2/2 : Installation Unikraft"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠️  Installation Unikraft lancée en arrière-plan"
echo "   (cela prend 10-30 minutes)"
echo ""

# Lancer installation Unikraft en background
nohup bash /workspaces/Optivolt-automation/scripts/setup-unikraft.sh \
  > /tmp/unikraft-install.log 2>&1 &

UNIKRAFT_PID=$!
echo "✅ Installation Unikraft lancée (PID: $UNIKRAFT_PID)"
echo "   Logs: tail -f /tmp/unikraft-install.log"
echo ""

#######################################################################
# Vérification
#######################################################################
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Vérification containers"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

sleep 3

docker ps --filter "name=optivolt" --format "table {{.Names}}\t{{.Status}}\t{{.Size}}"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Tests réels lancés avec succès !"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Containers actifs:"
echo "   1. optivolt-docker (baseline: 256MB RAM, 1.0 CPU)"
echo "   2. optivolt-microvm-real (optimisé: 128MB RAM, 0.5 CPU)"
echo "   3. optivolt-unikernel-real (minimal: 64MB RAM, 0.25 CPU)"
echo ""
echo "📊 Métriques en temps réel:"
echo "   docker stats optivolt-docker optivolt-microvm-real optivolt-unikernel-real"
echo ""
echo "📈 Dashboard Grafana:"
echo "   http://localhost:3000/d/optivolt-unified"
echo "   (Les nouveaux containers apparaîtront dans ~30 secondes)"
echo ""
echo "🦄 Installation Unikraft:"
echo "   En cours en arrière-plan (10-30 minutes)"
echo "   Progression: tail -f /tmp/unikraft-install.log"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
