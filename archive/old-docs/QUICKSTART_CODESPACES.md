# ⚡ QuickStart - OptiVolt sur GitHub Codespaces

## 🎯 Démarrage en 3 Étapes (< 5 minutes)

### Étape 1 : Vérifier l'Environnement ✅

```bash
# Vérifier que Docker fonctionne
docker ps

# Vérifier .NET SDK
dotnet --version  # Doit afficher 8.0+

# Vérifier les containers monitoring
docker ps | grep optivolt
```

**Résultat attendu :** 4-6 containers actifs (prometheus, grafana, cadvisor, node-exporter)

---

### Étape 2 : Compiler OptiVoltCLI 🔨

```bash
# Compiler le CLI
cd /workspaces/Optivolt-automation/OptiVoltCLI
dotnet publish -c Release -o ../publish

# Vérifier la compilation
cd /workspaces/Optivolt-automation
./publish/OptiVoltCLI --version
```

**Résultat attendu :** Version OptiVoltCLI affichée

---

### Étape 3 : Lancer un Benchmark 🚀

```bash
# Benchmark complet (Docker + MicroVM + Unikernel) - 60 secondes
cd /workspaces/Optivolt-automation
bash scripts/run_real_benchmark.sh 60
```

**Résultat attendu :**
```
✅ Phase 1: Test Docker (20s)      - CPU: 12.2%
✅ Phase 2: Test MicroVM (20s)     - CPU: 9.8%
✅ Phase 3: Test Unikernel (20s)   - CPU: 10.0%
📊 Résultats: results/comparison.json
```

---

## 📊 Visualiser les Résultats dans Grafana

### Accès Rapide

1. **VS Code** → Onglet **PORTS** (panneau bas)
2. Trouver la ligne **3000** (Grafana)
3. Cliquer sur l'icône **🌐** (globe) à droite
4. **Login :** `admin` / `admin`

### Navigation

1. Menu **☰** (haut gauche)
2. **Dashboards** → **Browse**
3. Sélectionner **"OptiVolt - Docker vs MicroVM vs Unikernel"**

**Vous verrez :**
- 📈 Graphiques CPU temps réel
- 💾 Graphiques Mémoire
- 📊 Stats par environnement
- 📋 Tableau récapitulatif

📖 **Guide complet :** [GRAFANA_CODESPACES_ACCESS.md](GRAFANA_CODESPACES_ACCESS.md)

---

## 🎨 Commandes Essentielles

### OptiVoltCLI

```bash
cd /workspaces/Optivolt-automation/publish

# Déployer un environnement
./OptiVoltCLI deploy --environment docker

# Lancer un test CPU (30 secondes)
./OptiVoltCLI test --environment docker --type cpu --duration 30

# Collecter les métriques
./OptiVoltCLI collect --environment docker
```

### Scripts de Benchmark

```bash
# Benchmark rapide (30 secondes)
bash scripts/run_real_benchmark.sh 30

# Benchmark standard (60 secondes)
bash scripts/run_real_benchmark.sh 60

# Benchmark long (120 secondes - plus précis)
bash scripts/run_real_benchmark.sh 120
```

### Monitoring

```bash
# Démarrer/Redémarrer la stack monitoring
bash start-monitoring.sh

# Vérifier les containers
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Logs Grafana
docker logs optivolt-grafana -f

# Logs Prometheus
docker logs optivolt-prometheus -f
```

---

## 📁 Fichiers Importants

| Fichier | Description |
|---------|-------------|
| `config/hosts.json` | Configuration environnements (Docker/MicroVM/Unikernel) |
| `results/comparison.json` | Résultats benchmark comparatif |
| `docker-compose-monitoring.yml` | Configuration stack monitoring |
| `scripts/run_real_benchmark.sh` | Script benchmark principal |
| `GRAFANA_CODESPACES_ACCESS.md` | Guide accès Grafana complet |
| `GUIDE_TESTS_REELS.md` | Guide tests et benchmarks |

---

## 🔍 Explorer les Résultats

### Fichiers JSON Générés

```bash
# Voir le résumé comparatif
cat results/comparison.json | jq

# Métriques Docker
cat results/docker_metrics.json | jq

# Métriques MicroVM
cat results/microvm_metrics.json | jq

# Métriques Unikernel
cat results/unikernel_metrics.json | jq
```

### Requêtes Prometheus

Accéder à **port 9090** (Prometheus Explorer)

```promql
# CPU par container
rate(container_cpu_usage_seconds_total{name=~"optivolt.*"}[1m]) * 100

# Mémoire par container
container_memory_usage_bytes{name=~"optivolt.*"} / 1024 / 1024

# Top 5 containers CPU
topk(5, rate(container_cpu_usage_seconds_total[1m]) * 100)
```

---

## 🐛 Dépannage Rapide

### Problème : Containers ne démarrent pas

```bash
# Redémarrer la stack
docker-compose -f docker-compose-monitoring.yml down
bash start-monitoring.sh

# Attendre 20 secondes
sleep 20

# Vérifier
docker ps | grep optivolt
```

### Problème : CLI ne compile pas

```bash
# Nettoyer et recompiler
cd OptiVoltCLI
dotnet clean
dotnet restore
dotnet publish -c Release -o ../publish
```

### Problème : Grafana dashboard vide

```bash
# Relancer un benchmark
bash scripts/run_real_benchmark.sh 30

# Dans Grafana : Ajuster "Time Range" à "Last 5 minutes"
# Refresh auto : 10 secondes
```

### Problème : Accès Grafana refusé

```bash
# Vérifier Grafana
docker logs optivolt-grafana | tail -20

# Redémarrer si nécessaire
docker restart optivolt-grafana

# Attendre 10 secondes et réessayer
```

---

## 🎯 Prochaines Étapes

### 1. Explorer les Dashboards Grafana
- Personnaliser les panels
- Créer vos propres requêtes PromQL
- Exporter les données en CSV

### 2. Tests Personnalisés
- Modifier la durée des tests
- Tester différentes charges
- Comparer plusieurs exécutions

### 3. Approfondir
- Lire [GUIDE_TESTS_REELS.md](GUIDE_TESTS_REELS.md)
- Explorer les scripts Python d'analyse
- Consulter [docs/API_INTEGRATION.md](docs/API_INTEGRATION.md)

---

## 📚 Documentation Complète

| Guide | Utilisation |
|-------|------------|
| [README.md](README.md) | Documentation principale complète |
| [GRAFANA_CODESPACES_ACCESS.md](GRAFANA_CODESPACES_ACCESS.md) | Guide accès et utilisation Grafana |
| [GUIDE_TESTS_REELS.md](GUIDE_TESTS_REELS.md) | Tests et benchmarks détaillés |
| [COMPTE_RENDU_TACHES.md](COMPTE_RENDU_TACHES.md) | État projet et progression |
| [docs/GITHUB_CODESPACES_SETUP.md](docs/GITHUB_CODESPACES_SETUP.md) | Configuration Codespaces |

---

## ⚡ Commandes en Un Coup d'Œil

```bash
# Tout en une commande
cd /workspaces/Optivolt-automation && \
  cd OptiVoltCLI && dotnet publish -c Release -o ../publish && cd .. && \
  bash start-monitoring.sh && \
  sleep 20 && \
  bash scripts/run_real_benchmark.sh 60

# Puis ouvrir Grafana (VS Code → PORTS → 3000 → 🌐)
```

---

**🚀 Vous êtes prêt ! Bon benchmarking !**

*Pour toute question, voir les guides détaillés dans `/docs` ou consulter les scripts dans `/scripts`.*
